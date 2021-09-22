This module creates an IAM user
which is going to be used
by other Terraform modules.
The idea is to limit blast radius
in case if something goes awry
when using those modules.

The general security concept is the following:
* Admin IAM user applies this module
  and creates a terraform IAM user.
* Other modules **must not**
  have access to the admin IAM user credentials.
* They use the terraform IAM user instead
  which has limited access rights.
* Optionally they may assume IAM roles
  i.e. they authenticate
  as the terraform IAM user
  and then assume a specific IAM role
  which should have necessary access rights
  in order to accomplish the task.
