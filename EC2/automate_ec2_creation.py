import boto3
import ConfigParser
import time
import os 

## read access & secret key from config.ini
config = ConfigParser.ConfigParser()
config.read('Config.ini')
access_key = config.get('aws-sa-tw', 'AWS_ACCESS_KEY_ID')
secret_key = config.get('aws-sa-tw', 'AWS_SECRET_ACCESS_KEY')



## get connection client to ec2 
ec2 = boto3.client('ec2',
    aws_access_key_id= access_key,
    aws_secret_access_key= secret_key,
    region_name="us-west-2")

ec2_resource = boto3.resource('ec2',
    aws_access_key_id= access_key,
    aws_secret_access_key= secret_key,
    region_name="us-west-2")

## get ec2 Instance ID via Name tag
demo = ec2.describe_instances(Filters=[{'Name': 'tag:Name', 'Values': ['OpenSwan']},
	{'Name': 'instance-state-name', 'Values': ['running']}])
instance_old_id = demo['Reservations'][0]['Instances'][0]['InstanceId']
print('Terminating OpenSwan ec2 instance, instance id is :  ' + instance_old_id)

delete = [instance_old_id]
## terminate openswan old instance
ec2_resource.instances.filter(InstanceIds=delete).terminate()

## query AMI id via Name tag
image = ec2.describe_images(Filters=[{'Name': 'tag:Name', 'Values': ['openswan']}])
ami_id = image['Images'][0]['ImageId']
print(ami_id)
## create ec2 instance for crash openswan
instances = ec2_resource.create_instances(
    	ImageId=ami_id, 
    	MinCount=1, 
    	MaxCount=1,
      ## Your SSH key to connect to EC2
    	KeyName="xxxxxxxxx",
    	InstanceType="t2.micro",
      ## Subnet ID
    	SubnetId="subnet-xxxxxxxxxxxx",
      ## Security Group ID
      SecurityGroupIds=['sg-xxxxxxxxxxxx'],
    )

instance_id = instances[0].instance_id
#print(instance_id)
print('New ec2 instance instance id is:  ' + instance_id)

## Disable SourceDestCheck for OpenSwan use
ec2.modify_instance_attribute(InstanceId=instance_id, SourceDestCheck={'Value': False})
ec2.create_tags(Resources=[instance_id], Tags=[{'Key':'Name', 'Value':'OpenSwan'}])
## Wait 60 secs befor assosiate EIP

print('Wait for 60 seconds ......')
time.sleep(60)
print('Allocating EIP to new OpenSwan ec2 instance !!!!')
## Pre-Allocated EIP ID
response = ec2.associate_address(AllocationId='eipalloc-xxxxxxxxxxxxxx',
                                     InstanceId=instance_id)
## Host IP
hostname ="xxx.xxx.xxx.xxx"

react = os.system("ping -c 75 " + hostname)
	
if react == 0:
	print('New OpenSwan instance is up and running !!')
else:
	print("Network is still initiating!!")
