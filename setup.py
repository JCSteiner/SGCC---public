###############################################################################
#                          SKINNY GUERRILLA C2 SETUP                          
#     _____ _    _                      _____                      _ _ _       
#    / ____| |  (_)                    / ____|                    (_) | |      
#   | (___ | | ___ _ __  _ __  _   _  | |  __ _   _  ___ _ __ _ __ _| | | __ _ 
#    \___ \| |/ / | '_ \| '_ \| | | | | | |_ | | | |/ _ \ '__| '__| | | |/ _` |
#    ____) |   <| | | | | | | | |_| | | |__| | |_| |  __/ |  | |  | | | | (_| |
#   |_____/|_|\_\_|_| |_|_| |_|\__, |  \_____|\__,_|\___|_|  |_|  |_|_|_|\__,_|
#                               __/ |                                          
#                              |___/                                           
#

print("""###############################################################################
                          SKINNY GUERRILLA C2 SETUP                          
     _____ _    _                      _____                      _ _ _       
    / ____| |  (_)                    / ____|                    (_) | |      
   | (___ | | ___ _ __  _ __  _   _  | |  __ _   _  ___ _ __ _ __ _| | | __ _ 
    \\___ \\| |/ / | '_ \\| '_ \\| | | | | | |_ | | | |/ _ \\ '__| '__| | | |/ _` |
    ____) |   <| | | | | | | | |_| | | |__| | |_| |  __/ |  | |  | | | | (_| |
   |_____/|_|\\_\\_|_| |_|_| |_|\\__, |  \\_____|\\__,_|\\___|_|  |_|  |_|_|_|\\__,_|
                               __/ |                                          
                              |___/                                           
###############################################################################
Setup.py: Used to delete all data or do initial setup
""")

##################################### MAIN ####################################
if __name__ == "__main__":

    # initializes a dictionary to store our c2 settings from c2_settings.conf
    c2_settings = dict()

    # opens the conf file, and reads int the c2 settings appicable
    infile = open('./Server/c2_settings.conf', 'r')
    for line in infile:
        # gets rid of the newline character from the line
        line = line.strip()

        # gets the variable, and the associated value from the line
        key, val = line.split(',')

        # stores in the dictionary
        c2_settings[key] = val
        
    infile.close()

    # loads connection to mysql database
    import sqlite3

    # user protection
    are_you_sure = input('\nARE YOU SURE YOU WANT TO RUN? THIS WILL DELETE ALL EXSITING TASK AND IMPLANT DATA! (Y/n)\n')

    # if the user selected yes
    if are_you_sure.lower() in ['yes', 'y', 'ye', 'yeah', 'sure', 'totally', 'affirmative']:

        # makes a connection to the mysql database and initializes our cursor
        mydb = sqlite3.connect("./Server/SGCC.db")                       
        mycursor = mydb.cursor()

        # attempts to delete then recreate table, otherwise just creates
        create_table_str =  'CREATE TABLE tasks (task_type VARCHAR(255),'
        create_table_str += 'task_opt VARCHAR(255), implant_id VARCHAR(255), results VARCHAR(255), task_time VARCHAR(255),'
        create_table_str += 'result_time VARCHAR(255), operator VARCHAR(50))'
        try:
            mycursor.execute("DROP TABLE tasks")

            mycursor.execute(create_table_str)
        except:
            mycursor.execute(create_table_str)
            
        # if we can query the database, it should be successfully set up
        try:

            mycursor.execute("SELECT * from tasks")
            print('[+] Initialized tasks table.')

        except:
            print('[!] Ran into an issue trying to setup the tasks table.')
            exit


        # attempts to delete then recreate table, otherwise just creates
        create_table_str =  'CREATE TABLE implants (implant_type VARCHAR(255), key VARCHAR(255), iv VARCHAR(255), commands VARCHAR(255), notes VARCHAR(255))'
        try:
            mycursor.execute("DROP TABLE implants")

            mycursor.execute(create_table_str)
        except:
            mycursor.execute(create_table_str)
            
        # if we can query the database, it should be successfully set up
        try:

            mycursor.execute("SELECT * from implants")
            print('[+] Initialized implants table.')

        except:
            print('[!] Ran into an issue trying to setup the implants table.')
            exit


        # attempts to delete then recreate table, otherwise just creates
        create_table_str =  'CREATE TABLE socks (implant_id VARCHAR(255), pid VARCHAR(255))'
        try:
            mycursor.execute("DROP TABLE socks")

            mycursor.execute(create_table_str)
        except:
            mycursor.execute(create_table_str)
            
        # if we can query the database, it should be successfully set up
        try:

            mycursor.execute("SELECT * from socks")
            print('[+] Initialized the socks table.')

        except:
            print('[!] Ran into an issue trying to setup the socks table.')
            exit


        #################### LOGS TABLE

        # attempts to delete then recreate table, otherwise just creates
        create_table_str =  f'CREATE TABLE logs (ip VARCHAR(2000), mac VARCHAR(2000), dhcp VARCHAR(2000), hostname VARCHAR(100), username VARCHAR(100), domain VARCHAR(100), fqdn VARCHAR(100), pid INTEGER, ppid INTEGER, task_id INTEGER, implant_id INTEGER, task_type VARCHAR(255), task_opt VARCHAR(255), task_time VARCHAR(255), result_time VARCHAR(255), operator VARCHAR(50), results_str VARCHAR({int(c2_settings['max_data_size'])+1}))'
        try:
            mycursor.execute("DROP TABLE logs")

            mycursor.execute(create_table_str)
        except:
            mycursor.execute(create_table_str)
            
        # if we can query the database, it should be successfully set up
        try:

            mycursor.execute("SELECT * from logs")
            print('[+] Initialized logs table.')

        except:
            print('[!] Ran into an issue trying to setup the logs table.')
            exit

        #################### LOGS TABLE

        # attempts to delete then recreate table, otherwise just creates
        create_table_str =  f'CREATE TABLE users (username VARCHAR(50), password VARCHAR(255))'
        try:
            mycursor.execute("DROP TABLE users")

            mycursor.execute(create_table_str)
        except:
            mycursor.execute(create_table_str)
            
        # if we can query the database, it should be successfully set up
        try:

            mycursor.execute("SELECT * from users")
            print('[+] Initialized database and users table.')

        except:
            print('[!] Ran into an issue trying to setup the users table.')
            exit

        print('[+] Run .\\Server\\server.py and .\\Client\\client.py to begin.')

    else:
        print('Quitting...')