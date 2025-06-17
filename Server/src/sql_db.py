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
# sql_db.py
# several helper functions for interacting with the sqlite database
# by JCSteiner


############################# LOADS DEPENDENCIES ##############################
# imports the ability to interact with our database
import sqlite3


############################## HELPER FUNCTIONS ###############################

# add task. need parameters task_type, task_opt, implant_id, task_time
def add_task(task_type, task_opt, implant_id, task_time, operator):

    mydb = sqlite3.connect("SGCC.db")
    mycursor = mydb.cursor()

    # defines the sql query to insert a new record
    sql =  "INSERT INTO tasks (task_type, task_opt, implant_id, task_time, operator, results) VALUES (?, ?, ?, ?, ?, ?)"
    # the values we want to insert
    val = (task_type, task_opt, implant_id, task_time, operator, "pending")

    # executes the command and updates the database
    mycursor.execute(sql, val)
    mydb.commit()

# adds an implant to the database
def add_implant(implant_type, key, iv, commands):

    mydb = sqlite3.connect("SGCC.db")
    mycursor = mydb.cursor()

    # defines the sql query to insert a new record
    sql =  "INSERT INTO implants (implant_type, key, iv, commands) VALUES (?, ?, ?, ?)"
    # the values we want to insert
    val = (implant_type, key, iv, commands)

    # executes the command and updates the database
    mycursor.execute(sql, val)
    mydb.commit()

# gets crypto keys from the implants table
def get_crypto(implant_id):

    mydb = sqlite3.connect("SGCC.db")
    mycursor = mydb.cursor()

    sql = "SELECT key, iv FROM implants WHERE rowid = ?"
    val = tuple([implant_id])

    res = mycursor.execute(sql, val)
    return res.fetchone()

# adds results info to the tasks table
def add_result(task_id, results, result_time):

    mydb = sqlite3.connect("SGCC.db")
    mycursor = mydb.cursor()

    # query to update a task with the results
    sql = "UPDATE tasks SET results = ?, result_time = ? WHERE rowid = ?"
    # values to update it with
    val = (results, result_time, task_id)

    # executes the command and updates the database
    mycursor.execute(sql, val)
    mydb.commit()

# updates the notes for the implant_id
def add_notes(implant_id, notes):

    mydb = sqlite3.connect("SGCC.db")
    mycursor = mydb.cursor()

    # query to update a task with the results
    sql = "UPDATE implants SET notes = ? WHERE rowid = ?"
    # values to update it with
    val = (notes, implant_id)

    # executes the command and updates the database
    mycursor.execute(sql, val)
    mydb.commit()


# gets pending tasks
def get_pending_tasks(implant_id):

    mydb = sqlite3.connect("SGCC.db")
    mycursor = mydb.cursor()

    # query to get only pending tasks
    sql = "SELECT rowid,task_type,task_opt FROM tasks WHERE results ='pending' AND implant_id = ?"

    # implant_id as a tuple that can be parsed by our sql python connector
    # need to explicitly define it as a tuple since it's one thing
    val = tuple([implant_id])

    # executes the query
    mycursor.execute(sql, val)

    # parses our results and returns to caller
    myresult = mycursor.fetchall()
    results_list = [ _ for _ in myresult ]
    return results_list

# gets task type based on task id
def get_task_type(task_id):

    mydb = sqlite3.connect("SGCC.db")
    mycursor = mydb.cursor()

    # query to get only pending tasks
    sql = "SELECT task_type, operator FROM tasks WHERE rowid = ?"

    # implant_id as a tuple that can be parsed by our sql python connector
    # need to explicitly define it as a tuple since it's one thing
    val = tuple([task_id])

    # executes the query
    res = mycursor.execute(sql, val)

    # parses our results and returns to caller
    myresult = res.fetchall()[0]
    return myresult

# gets the implant id for a specific task
def get_implant_id(task_id):

    mydb = sqlite3.connect("SGCC.db")
    mycursor = mydb.cursor()

    # query to get implant id from a specific task_id
    sql = "SELECT implant_id FROM tasks WHERE rowid = ?"

    # converts the task_id python variable to a query so we can use it
    val = tuple(int(task_id))

    # executes the mysql query
    mycursor.execute(sql, val)

    # parses results. since task_id is a primary key we should only have one result back.
    # results are generally pushed in terms of lists though
    myresult = mycursor.fetchall()
    results_list = [_ for _ in myresult]
    if len(results_list) == 0:
        return results_list[0]

# gets only tasks that are not pending
def get_finished_tasks():

    mydb = sqlite3.connect("SGCC.db")
    mycursor = mydb.cursor()

    # query to get only tasks that are not pending
    sql = "SELECT rowid, task_type, task_opt, implant_id, results, task_time, result_time from tasks WHERE results <> 'pending'"

    # executes
    mycursor.execute(sql)

    # gets results and parses them
    myresult = mycursor.fetchall()
    results_list = [ _ for _ in myresult ]

    # returns to the function caller
    return results_list

# function to get all tasks, regardless of status
def get_all_tasks():
    
    mydb = sqlite3.connect("SGCC.db")
    mycursor = mydb.cursor()

    # query to get all tasks from the database
    sql = "SELECT rowid, task_type, task_opt, implant_id, results, task_time, result_time FROM tasks"

    # executes
    mycursor.execute(sql)

    # gets data and parses
    myresult = mycursor.fetchall()
    results_list = [_ for _ in myresult]

    # returns to function caller
    return results_list

# gets what next implant id should be
def get_new_implantid():

    mydb = sqlite3.connect("SGCC.db")
    mycursor = mydb.cursor()

    # gets the max current implant id
    sql = "SELECT max(rowid) from implants"

    res = mycursor.execute(sql)

    implant_id = res.fetchone()[0]

    # if the implant id exists, adds 1, otherwise, sets it to 1
    try:
        new_implant_id = int(implant_id) + 1
    except:
        new_implant_id = 1

    return new_implant_id

# adds a socks server to the database
def add_socks_server(implant_id, socks_pid):

    mydb = sqlite3.connect("SGCC.db")
    mycursor = mydb.cursor()

    sql = "INSERT INTO socks (implant_id, pid) VALUES (?, ?)"

    mycursor.execute(sql, (implant_id, socks_pid))

    mydb.commit()

# gets the pid for a socks server based on implant id
def get_socks_pid(implant_id):

    mydb = sqlite3.connect("SGCC.db")
    mycursor = mydb.cursor()

    sql = "SELECT pid FROM socks WHERE implant_id = ?"

    res = mycursor.execute(sql, tuple([implant_id]))

    return res.fetchone()

# deletes a given entry from the socks table
def remove_pid(implant_id, pid):

    mydb = sqlite3.connect("SGCC.db")
    mycursor = mydb.cursor()

    sql = "DELETE FROM socks WHERE implant_id = ? AND pid = ?"

    mycursor.execute(sql, (implant_id, pid))

    mydb.commit()

# logs sa and results info to the logs database
def log(sa_str, task_id, results_str, implant_id, task_type, result_time, operator):

    mydb = sqlite3.connect("SGCC.db")
    mycursor = mydb.cursor()

    res = mycursor.execute("SELECT task_opt,task_time FROM tasks WHERE rowid = ?", tuple([task_id]))

    task_opt, task_time = res.fetchone()

    log_str = tuple(sa_str.split('<sa>') + [task_id, implant_id, task_type, task_opt, task_time, result_time, operator, results_str])

    sql = "INSERT INTO logs (ip,mac,dhcp,hostname,username,domain,fqdn,pid,ppid,task_id,implant_id,task_type,task_opt,task_time,result_time,operator,results_str) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"

    mycursor.execute(sql, tuple(log_str))

    mydb.commit()

# gets all logs
def get_logs():

    mydb = sqlite3.connect("SGCC.db")
    mycursor = mydb.cursor()

    sql = "SELECT * from logs"

    res = mycursor.execute(sql)

    return res.fetchall()

# gets what commands an implant has been set to run
def get_implants_possible_commands(implant_id):

    mydb = sqlite3.connect("SGCC.db")
    mycursor = mydb.cursor()

    sql = "SELECT commands FROM implants WHERE rowid = ?"

    val = tuple([implant_id])

    res = mycursor.execute(sql, val)

    return res.fetchall()

# runs sql queries to get for the gui
def query_for_gui():

    mydb = sqlite3.connect("SGCC.db")
    mycursor = mydb.cursor()

    sql = "SELECT rowid, implant_type, notes from implants"

    res = mycursor.execute(sql)

    implants_and_format = res.fetchall()

    return implants_and_format

def query_for_gui2(implant_id):

    mydb = sqlite3.connect("SGCC.db")
    mycursor = mydb.cursor()

    sql = "SELECT ip, hostname, username from logs WHERE implant_id = ?"

    res = mycursor.execute(sql, tuple([implant_id]))

    overall_sa = res.fetchall()[-1]

    return overall_sa

def query_for_gui3(implant_id):

    mydb = sqlite3.connect("SGCC.db")
    mycursor = mydb.cursor()

    sql = "SELECT task_time, operator, task_type, task_opt, result_time, results_str FROM logs WHERE implant_id = ?"

    res = mycursor.execute(sql, tuple([implant_id]))

    implant_history = res.fetchall()

    return implant_history

def query_for_gui4(implant_id):

    mydb = sqlite3.connect("SGCC.db")
    mycursor = mydb.cursor()

    sql = "SELECT task_time, operator, task_type, task_opt, result_time, results FROM tasks WHERE results ='pending' AND implant_id = ?"

    res = mycursor.execute(sql, tuple([implant_id]))

    implant_history = res.fetchall()

    return implant_history

# checks to see if a username and password hash are legit
def is_valid_user(username, password):

    mydb = sqlite3.connect("SGCC.db")
    mycursor = mydb.cursor()

    sql = "SELECT rowid, username FROM users WHERE username = ? AND password = ?"
    val = (username, password)

    res = mycursor.execute(sql, val).fetchone()

    return res

# checks to see if the user exists period
def user_exists(username):

    mydb = sqlite3.connect("SGCC.db")
    mycursor = mydb.cursor()

    sql = "SELECT * FROM users WHERE username = ?"
    val = tuple([username])

    res = mycursor.execute(sql, val).fetchone()

    return res

# adds a user and their password hash to the database
def add_user(username, password):

    mydb = sqlite3.connect("SGCC.db")
    mycursor = mydb.cursor()

    mycursor.execute('INSERT INTO users VALUES (?, ?)', (username, password))
    mydb.commit()