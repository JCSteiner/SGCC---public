# Skinny Guerrilla Command and Control - Readme

## Background

The <i>Skinny Guerrilla Command and Control</i> (SGCC) gets its name from its goal to generate minimalist implants with only the commands necessary for the operator to accomplish their objective.

Other popular C2 frameworks add more and more implant features over time, which can be useful. However if a feature is unused by the operator, it is effectively just bloat that could lead to being caught on yara rules or memory scanning.

This framework seeks to solve that problem by allowing each implant to have its functions "turned on" or "turned off" upon its creation. Do you want to have an implant with just the ability to execute shell commands? Do you want an implant to only have a socks proxy? This is possible with the SGCC!

## Setup

### Setup.py
First install requirements with `pip install -r requirements.txt`, then run the setup file with `python setup.py`. You will be asked if you are sure you are want to complete setup, as this will delete all data and logs for the C2, choose yes by inputting `y`.

Setup.py initializes the sqlite database `SGCC.db` with the tables `tasks`, `implants`, `socks`, and `logs`.

The `tasks` table is used to store the information relevant to each task suchas the command and its arguments, the implant it was assigned to, and the time results were received. The rowid for this table corresponds to the column `task_id` in other tables.

The `implants` table is used to store infomration suchas the encryption keys for the implant and what commands the implant is allowed to use. The rowid for this table corresponds to the column `implant_id` in other tables.

The `socks` table is used to track the pid that socks proxy servers are launched with so they can be killed when the socks proxy is no longer needed.

The `logs` table is used to track useful pieces of information related to the target.

### c2_settings.conf

This file is used to provide the server with configuration changes for the C2 server and implants created to call back to it. It is a simple csv file that has the following parameters:
1. ip - this is the ip address that the C2 server will be set to run on, and implants will call back to. Be sure to specify [ip]:[port].
2. task_uri - this is the uri that will be used to host tasks.
3. result_uri - this uri will handle results sent back to your C2.
4. upload_uri - this uri will host files that we are intending to upload to the target via the implant connection.

### Begin
Now on the machine you plan to use as a server, run `server.py` (with the arguments `cert.pem` `private.key` if you plan to use SSL). And interact with the server via `client.py` in the Client folder.

### Server

The server has direct access to the sqlite backend of the C2 framework. The server also hosts all web pages used for the REST API.

The wrapper script for the C2 server is `server.py`. 

The flask app that is hosted by server.py makes many calls to the classes in `resources.py`. `Resources.py` makes calls to functions within `sql_db.py` for interacting with the sqlite database and `crypto.py` for encrypting or decrypting data.

The sqlite database stores all our data in the database "SGCC.db" and the tables "tasks", "implants", "socks", and "logs".

The flask app manages the following endpoints:

1. /tasks : You will also need to specify /[implant_id] when querying.
    
    a.  On GET, /tasks will make a sqlite query for the rowid, task_type, and task_options for every task entry where the "results" column is equal to the default "pending". Before presenting to the end user, the C2 server will "sign" the task with a shared key by performing a SHA256 hash of string "[rowid],[task_type],[task_opt]" and then AES-256 encrypting it with a shared key with the implant. That hash is then base64 encoded, and inputed into another round of AES-256 encryption with the same shared key, and then base64 encoded again. This is done for each entry, with a newline character as the delimeter between entries. 
    
    b. On POST, /tasks will be updated with the requested task. This is done when a C2 client wants to have an implant run a specific task.

2. /results : You will also need to specify [implant_id] when querying.

    a. On GET, /results will return completed tasks in an html table and 200 status code. 
    
    b. On POST, /results will take the body of the request, base64 decode it, query the sqlite database for the implant id associated with the task_id, then use the shared key to AES-256 decrypt it. Then the implant will split the returned value of the results with the "signature" of the results from the implant. The base64 "signature" will be decoded, decrypted, and then if the hash is equal to the SHA256 hash of the results, then the results will be printed to the server terminal and the mysql database will be updated with the last time of results.

3. /history : 

    a. On GET, /history will return a query result formatted into an HTML table of all the tasks and results in the mysql database. 
    
    b. On POST, /history will return a 200 status code.
4. /implants : you must also specify implant type

    a. on GET, implants will return a 200 status code. 
    
    b. On POST, /implants will generate a new auto-obfuscated implant based in the format specified by the request. The default save location is the Payloads folder.

5. /socks : you must also specify implant id

    a. on GET, returns a 200 status code.

    b. on POST, spawns a socks server as a child process to the C2 server, the pid for this socks server and its coresponding implant id will be in the sqlite database "socks" table.

6. /upload : you must also specify implant id

    a. on GET, shows the file that the corresponding implant id should be downloading

    b. on POST, takes the data in the body of the post request and writes it to a file.

7. /logs

    a. On GET, displays the logs in a pretty table. By default, logs ip, mac address, DHCP, hostname, username, domain name, fqdn, pid, ppid, task_id, and results string.

    b. On POST, returns 200 status code.

### Client

The client interacts with the server via a REST API. The client will use the command line arguments in client.py to send GET and POST requests to the flask app that the server is running. The client has the following command line arguments.

1. get-history : makes a GET request to the /history endpoint on the C2 server which returns a mysql query for all tasks regardless of their completion status. This exists as a record of all commands that have been run.

2. post-tasks : sends a POST request to /tasks/[implant id] and has the server make a mysql entry to record that the implant has been requested to do the specific task. Use the -i for specifying the implant id and the -t for specifying the task. For tasks that require arguments make sure that the entire -t is in quotes, if you need to pass quotes, escape them with `\"`. The following tasks and syntax you can run are:

    a. `ipconfig` - use this to run `ipconfig /all` on the system
    
    b. `whoami` - use this to run `whoami /all` on the system

    c. `dir [directory]` - use this to dir a specific directory or file using the `ls` powershell commandlet

    d. `pwd` - use this to print the current directory

    e. `rm [item]` - use this to remove an item from the target machine

    f. `netstat-tcp` - lists tcp connections

    g. `download [remote_file]` - downloads the remote file from the target and saves to Server/downloads/Download[task_id]

    h. `upload [local_file] [remote_file]` - uploads the local file from your client machine to the target as remote_file.

    i. `cd [directory]` - changes the directory 

    j. `iex [command]` - whatever follows iex is piped to it.

    k. `socks-start [handler_port] [proxy_port] [cert.pem] [private.key]` - starts a socks proxy, will proxy over the C2 server port `[proxy_port]` and the implant will callback to `[handler_port]`. 

    l. `socks-stop` - stops the socks proxy for this implant

3. new-implant : requests that a new implant be generated by the C2 server. Saves this to your payloads folder by default. -f is for your format of the implant, -c is for which commands you would like (either list all of them individually or select all with "all"), and -o is the output to your local machine.

### Implants

Implants are the executable or script that are run on the target machine that gives the SGCC user control over it. Implants run the following infinitely:
1. get-tasks : gets the tasks awaiting it via a GET request to /tasks/[implant_id] on the C2 server. The HTML GET response is split over the newline character and if the task has data (to prevent operations on null data. Null data occurs in some formats when using the split function and can occur if there are no tasks awaiting the implant) the following operations are performed against it. 

    a. task string is base64 decoded

    b. decoded task_string is AES-256 decrypted with a key shared between the implant and the server

    c. the task_string is split over the string ```,```. This lets the implant get the values task_id, task_type, task_opt, and digest from the string. The task_string is SHA-256 hashed and the digest is AES-256 decrypted. If they are equal, then the "signature" of the task from the server has been verified and we continue.

    d. the task string values task_id, task_type, and task_opt are reassembled with the string ```<br>``` separating them.


    e. the jobs_list array is updated with this task string
2. execute-jobs : the execute jobs function loops over each job in the jobs_list array and uses the task_type value to specify which function to execute next. The appropriate function is given job_args as arguments and the results are returned to execute-jobs. Execute-jobs will then chunk the data according to max_data_size. The response back to the server will be "signed" via a SHA-256 hashing and AES-256 encrypting with the shared key. The POST to /results will be a string with the values task_id, results_chunk, results_time, and the "signature" separated by the string ```<br>```. The result time is the current time of execution in UTC. The jobs_list entry will then be updated (if the chunked response did not contain all the data and there is still more results to be sent) with the full results, and the last byte that was sent (so chunking can resume at that byte). If the last byte is equal to "true" and not an integer value, then all data has been sent and the job will be removed from the job list.

3. sleep : the implant will calculate a random value with the lowest value being (sleep * (1-jitter)) and the highest value being sleep, and then sleep for that amount of time. 

#### Powershell

The implant can be created with as a powershell script. The obfuscations applied include having hardcoded values put in variables, and variable names changed to be dictionary words.