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
# Cryptography File
# crypto.py
# helper functions that contain key management for server and implant
# written by JCSteiner

############################## LOADS DEPENDENCIES #############################
# imports crypto dependencies
from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad, pad
from Crypto.Random import get_random_bytes

# imports the ability to get crypto keys for a given implant
from src.sql_db import get_crypto

# hashing dependencies
import hashlib

# the ability to do base64 actions
import base64

############################### CRYPTO FUNCTIONS ##############################

# function to encrypt
def encrypt(data, implant_id):
    
    # gets the crypto keys
    aes_key_enc, aes_iv_enc = get_crypto(implant_id)

    # decodes
    aes_key = base64.decodebytes(aes_key_enc.encode())
    aes_iv = base64.decodebytes(aes_iv_enc.encode())

    # creates a new object
    cipher = AES.new(aes_key, AES.MODE_CBC, iv=aes_iv)
    padded_data = pad(data, AES.block_size)

    # encryptes
    encrypted_data = cipher.encrypt(padded_data)

    # returns encoded encrypted data
    return base64.encodebytes(encrypted_data)

# function to decrypt
def decrypt(data, implant_id):

    # gets the crypto keys
    aes_key_enc, aes_iv_enc = get_crypto(implant_id)

    # decodes
    aes_key = base64.decodebytes(aes_key_enc.encode())
    aes_iv = base64.decodebytes(aes_iv_enc.encode())

    # creates a new object
    cipher = AES.new(aes_key, AES.MODE_CBC, aes_iv)

    # decryptes
    decrypted_data = unpad(cipher.decrypt(data), AES.block_size)

    # returns decrypted data 
    return decrypted_data


# has the server sign the task we're presenting to the implant
def sign_task(task, implant_id):
    # task - the task string we're presenting to the end user

    # hashes the task string
    digest = hashlib.sha256(task.encode()).digest()

    ciphertext = encrypt(digest, implant_id)

    # returns the encrypted hash of the task string
    return ''.join(ciphertext.decode().split('\n'))


# has the server verify the validity of the results sent to it from the implant
def verify_results(results, digest, implant_id):
    # results - the results string sent to it by the implant
    # digest - the encrypted hash that the implant has sent to us
    # implant_id - the id of the implant that sent us the results, so we can use the right key

    # hashes the result string sent over
    result_digest = hashlib.sha256(results).digest()

    # attempts to use the implant's key to decrypt the SHA hash.
    plaintext = decrypt(digest, implant_id)

    # if the digest from the implant's results is the same as our decrypted hash
    if result_digest == plaintext:
        # successfully verifies that the results are correct
        return True
    # otherwise
    else:
        return False

# function to create random new keys
def new_crypto():

    # generates and encodes random new keys as string
    new_aes_key = ''.join(base64.encodebytes(get_random_bytes(32)).decode().split('\n'))
    new_aes_iv =  ''.join(base64.encodebytes(get_random_bytes(AES.block_size)).decode().split('\n'))

    return (new_aes_key, new_aes_iv)