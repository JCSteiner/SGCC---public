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
# obfuscate-powershell.py
# one of many resources to obfuscate powrshell files
# this script will randomize all variable and function names

# load dependencies
import random
import string

def obf_powershell(infilePath, outfilePath):

    # prints recommendation to the screen
    if infilePath == outfilePath:
        print('Recommned you call them different filenames to avoid overwrite conflicts.')

    # list of 417 dictionary words
    replacement_words = []
    
    infile = open('./src/wordlist.txt')
    for line in infile:
        replacement_words.append(line.strip())
    infile.close()

    replacement_words = list(set(replacement_words))


    # opens our two files
    infile = open(infilePath, 'r')
    outfile = open(outfilePath, 'w')

    # this will store all varaible names and their replacements, so we can ensure we keep track
    # of what has been replaced and what has not
    vars = dict()

    # gets random letters and numbers 
    randletters = string.ascii_lowercase + string.ascii_uppercase + "0123456789"

    # loops through every line in the powershell input script
    for line in infile:

        # stores a copy of the file so we can edit it to replace special characters with spaces
        # we want to do this so that we can make sure "$x+" and "$x" are treated as the same variable (for example)
        line_copy = line
        line_copy = line_copy.replace('+', ' ')
        line_copy = line_copy.replace('-', ' ')
        line_copy = line_copy.replace(':', ' ')
        line_copy = line_copy.replace('+', ' ')
        line_copy = line_copy.replace('(', ' ')
        line_copy = line_copy.replace('[', ' ')
        line_copy = line_copy.replace(',', ' ')
        line_copy = line_copy.replace('.', ' ')
        line_copy = line_copy.replace(')', ' ')
        line_copy = line_copy.replace(']', ' ')
        line_copy = line_copy.replace('=', ' ')
        line_copy = line_copy.replace('{', ' ')
        line_copy = line_copy.replace('}', ' ')
        line_copy = line_copy.replace(';', ' ')
        line_copy = line_copy.replace('"', ' ')
        line_copy = line_copy.replace('<sa>', ' ')
        line_copy = line_copy.replace('<br>', ' ')
        line_copy = line_copy.replace('<chnk>', ' ')
        line_copy = line_copy.replace('/', ' ')
        line_copy = line_copy.replace('`', ' ')


        # splits into every set of words so we can find the variables
        words = line_copy.split()

        # if the comment character is in the first few characters
        iscomment = "#" in line[0:20]

        # loops through each word
        for word in words:

            # if the first letter is a "$" and it is not a reserved or empty variable
            isvar = word[0] == "$" and word[1] != "_" and word.lower() != "$true" and word.lower() != "$false" and word.lower() != "$null"

            # if we found a variable and it is not already in our dictionary
            if isvar and word not in vars.keys():
                
                # if we have more dictionary words we can use, uses them. otherwise uses a random choice
                if len(replacement_words) != 0:
                    vars[word] = '$' + replacement_words.pop(random.randint(0, len(replacement_words)-1))
                else:
                    # generate a 16 character replacement and put in the dict
                    vars[word] = '$' + ''.join(random.choice(randletters) for i in range(16))

            # if it is not a variable, but is a function
            elif "func_" in word and word not in vars.keys():

                if len(replacement_words) != 0:
                    vars[word] = replacement_words.pop()
                else:
                    # generate a 16 character replacement and put it in the dictionary
                    vars[word] = ''.join(random.choice(randletters) for i in range(16))

            # if the current word is in the dictionary (why we loop through each word)
            if word in vars.keys():
                # replace it with its replacement
                line = line.replace(word, vars[word])

        # writes the line to the output file if it's not a comment
        if not iscomment:
            outfile.write(line)

    # prints the variables replaced
    #for var in vars:
        #print('Variable', var, 'is replaced with',vars[var])


    # closes file handles
    infile.close()
    outfile.close()

    print('Final powershell file saved to:', outfilePath)