import boto3
from boto.ec2 import connect_to_region

# Command Line input EC2 Instance ID
instance = input('InstanceID : ')

ec2_resource = boto3.resource('ec2')

# Filter Designated EC2 Instance ID
for instance in ec2_resource.instances.filter(
	        InstanceIds=[
			     instance
			    ],
	):
# Create Snapshot for all EBS volumes attached to this EC2 Instance
    for volume in instance.volumes.all():
    	print(volume.id)	
    	snapshot = ec2_resource.create_snapshot(
    		VolumeId=volume.id
    )
    	print(f'Snapshot {snapshot.id} created for volume {volume.id}')
