import json
import boto3
import uuid
import os
import urllib.request
import sys
import urllib.parse
from urllib.parse import unquote_plus


S3_BUCKET_NAME = '106047455-publicshare'
DURATION_SECONDS = '3600'
SNS_TOPIC = 'arn:aws:sns:us-east-1:211259373114:send-s3-presignedurl'

## shorten the presigned url length via tinyurl
def tiny_url(url):
    apiurl = "http://tinyurl.com/api-create.php?url="
    tinyurl = urllib.request.urlopen(apiurl + url).read()
    return tinyurl.decode("utf-8")
    
def lambda_handler(event, context):
    # TODO implement
    print('Event: {}'.format(event))
    
    FILE_NAME = event['Records'][0]['s3']['object']['key']
    
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
    
    ## Get the sns client
    sns_client = boto3.client('sns')
    sns_client.publish(
        TopicArn = SNS_TOPIC,
        Subject = 'Generate PreSigned URL',
        Message = 'PreSigned URL ( link will be expired in 10 minutes): \n' + shorten_url)

    return {
        'statusCode': 200,
        'body': '{}\n'.format(url)
    }
