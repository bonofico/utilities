
## manage_vms.sh ##
#### Prerequisites: ####
 - [google SDK](https://cloud.google.com/appengine/downloads) is installed and the `gcloud` utility is in the user's PATH envrionment variable.
 - `gcloud` is logged in to your ops school google account (run `gcloud auth login` to login).

#### Usage: ####
> Usage: `manage_vms.sh <action> [-n <name>] [-r <role>] [-m <machine_type>] [-p <project_id>] [-q]`
>
> ###### Actions: ######
>  * list-vms (list current vms in project).
>  * list-types (list available machine types in project).
>  * list-roles (list available roles for machines).
>  * start, stop, delete (requires vm name).
>  * create (requires vm name & role, if no type is specified the default will be used).
>
> ###### Additional flags: ######
>  * project_id (set project id - for multiple project support).
>  * q - no prompt (will not ask for interactive approval on delete).
