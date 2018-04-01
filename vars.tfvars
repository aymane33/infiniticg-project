aws_profile="personal-account"//this is personal aws account profile
aws_region="us-west-2"
vpc-id = "vpc-eeefad97" //infiniticg vpc
//Private subnet ids for mgmt vpc (a,c,d in order)
private-subnet-list-ids=["subnet-e5b165ae","subnet-f650fa8f"]
public-subnet-list-ids=["subnet-c3be6a88","subnet-2f55ff56"]//used for elb
//ssh key used for testing
sshKey="aws_personal_oregon" // remove this part after testing
ec2AMI="ami-223f945a"//rehl 7//"ami-4e79ed36"//ubuntu
cidr="10.10.0.0/16"




