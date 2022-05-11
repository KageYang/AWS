Zyxel - Amazon DynamoDB hands-on training

# [Zyxel] Amazon DynamoDB hands-on training
- Agenda
  ![](https://i.imgur.com/fdnWrFs.png)


- Short URL to this page ---> https://pse.is/46r4uq <-----
- Full URL to this page https://hackmd.io/@t-Nm5db5SpqzWkaeZs8sqQ/rJoJjRP89

## Overview ##

### Lab Document ###
- Dynamodb Operation Lab: https://amazon-dynamodb-labs.com/hands-on-labs.html

### Lab Env ###
- https://dashboard.eventengine.run/login?hash=b7d8-16fa9c8c94-b1

選擇 One-time password (OTP) 
![](https://i.imgur.com/Jf3cEhi.png)

設定一個 Team Name (e.g. AWS Jack Hsu)
![](https://i.imgur.com/1QP4COx.png)
![](https://i.imgur.com/eOXYYQQ.png)






# Hands-on Labs for Amazon Dynamodb

### 5. RELATIONAL MODELING & MIGRATION ###

1. "Configure CONFIGURE MYSQL ENVIRONMENT" 置換migration-env-setup.yaml的AZ


```
# 第92行: us-east-1a 更改為 ap-northeast-1a

AvailabilityZone: 'ap-northeast-1a'

```
![](https://i.imgur.com/q8wyIik.png)


2. "Load DynamoDB Table" 置換migration-dms-setup.yaml的AZ
```
# 第39行: us-east-1a 更改為 ap-northeast-1a

AvailabilityZone: 'ap-northeast-1a'

# 第49行: us-east-1a 更改為 ap-northeast-1c

AvailabilityZone: 'ap-northeast-1c'
```
![](https://i.imgur.com/zPxqLiT.png)

### Reference
AWS Blog: Choosing the right dynamodb partition key
https://aws.amazon.com/blogs/database/choosing-the-right-dynamodb-partition-key/


