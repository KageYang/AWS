import json
import boto3
import uuid
import os
import urllib.request
import sys
import urllib.parse
from urllib.parse import unquote_plus


S3_BUCKET_NAME = 'YOUR_BUCKET_NAME'
DURATION_SECONDS = '3600'

## shorten the presigned url length via tinyurl
def tiny_url(url):
    apiurl = "http://tinyurl.com/api-create.php?url="
    tinyurl = urllib.request.urlopen(apiurl + url).read()
    return tinyurl.decode("utf-8")
    
    
    FILE_NAME = 'Your_FILE_NAME'
    
    ## Translate file name which contains space
    NEW_FILE_NAME = urllib.parse.unquote_plus(FILE_NAME)
    print(NEW_FILE_NAME)
    
    # Get the s3 client.
    s3 = boto3.client('s3')
    url = s3.generate_presigned_url(ClientMethod = 'get_object',
                                    Params = {'Bucket' : S3_BUCKET_NAME, 'Key' : FILE_NAME},
                                               ExpiresIn = DURATION_SECONDS )
    shorten_url = tiny_url(url)
    print(url)
    print(shorten_url)
