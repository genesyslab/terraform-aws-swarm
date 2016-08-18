

This terraform module will set up swarm masters and workers.  


## Usage

`cp terraform.tfvars.example terraform.tfvars`

Edit your terraform.tfvars with the appropriate information.

If you have make and terraform 0.7, you can do `make plan`, `make apply`

If you have docker, there is a "workstation" that you can use

```
docker run -it --rm \
   -v $(pwd):/workspace \
   -e AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION \
   -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
   -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
     genesysarch/cloud-workstation make apply
```


Please note in the above case that the container must have access to the
deployment key you specify in your terraform.tfvars file.  This means in the
above command that you either mount that with another volume flag or that
the key is in the directory you are invoking the command in.

## Limitations

* Currently uses one availability zone
* Is not using auto scaling groups for workers
* Does nothing to setup volumes 
