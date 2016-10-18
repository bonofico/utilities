
## manage_vms.sh ##
manage_vms is a wrapper for running gcloud commands.

#### Prerequisites: ####
 - [google SDK](https://cloud.google.com/appengine/downloads) is installed and the `gcloud` utility is in the user's PATH envrionment variable.
 - `gcloud` is logged in to your ops school google account (run `gcloud auth login` to login).

#### Notices ####
 - All of the machines are built using the chef server so that machine should be up before starting any other role
 - the chef server machine name will always be `chefserver` for easy access from all other machines connecting to it.

#### Usage: ####
> Usage: `manage_vms.sh <action> [-n <name>] [-r <role>] [-m <machine_type>] [-p <project_id>] [-q] [-v]`
>
> ###### Actions: ######
>  * list-vms (list current vms in project).
>  * list-vm-types (list available machine types in project).
>  * list-roles (list available roles for machines).
>  * list-projects (list available projects).
>  * ssh, start, stop, delete (requires vm name).
>  * create (requires vm name & role, if no type is specified the default will be used).
>
> ###### Additional flags: ######
>  * project_id (set project id - for multiple project support).
>  * q - no prompt (will not ask for interactive approval on delete).
>  * v - enable verbose mode (print gcloud command prior to execution)
