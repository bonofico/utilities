#!/bin/bash -e

usage() {
  echo "Usage: $(basename "$0") <action> [-n <name>] [-r <role>] [-m <vm_type>] [-p <project_id>] [-q] [-v] [-c <client_role>]"
  echo ""
  echo "Actions:"
  echo " * list-vms (list current vms in project)"
  echo " * list-vm-types (list available machine types in project)"
  echo " * list-roles (list available roles for machines)"
  echo " * list-projects (list available projects)"
  echo " * ssh, start, stop, delete (requires vm name)"
  echo " * create (requires vm name & role, if no type is specified the default will be used)"
  echo ""
  echo ""
  echo "Additional flags:"
  echo ""
  echo " -p project_id - set project id (for multiple project support)"
  echo " -c client_role - sets a custom role for the machine (available when -r is set to chefclient)"
  echo " -q - no prompt (will not ask for interactive approval on delete)"
  echo " -v - enable verbose mode (print gcloud command prior to execution)"
  echo ""
  exit 3
}

generate_create_vm_command() {
  local chef_server_image="chefserver-image"
  local chef_client_image="chefclient-image"
  local chef_server_name="chefserver"
  local create_command=""
  local vm_name="$1"
  local vm_role="$2"
  local machine_type="$3"
  local client_role="$4"
  if [[ "$vm_role" == "chefserver" ]]
  then
    create_command="${chef_server_name} --image ${chef_server_image} --machine-type ${machine_type} --tags \"https-server\""
  elif [[ "$vm_role" == "chefclient" ]]
  then
    create_command="${vm_name} --image ${chef_client_image} --machine-type ${machine_type} --tags \"http-server\" --metadata startup-script=\"chef-client -r role[${client_role}] > /tmp/chef_client.log 2>&1\""
  else
    create_command="${vm_name} --image ${chef_client_image} --machine-type ${machine_type} --tags \"http-server\" --metadata startup-script=\"chef-client -r role[${vm_role}] > /tmp/chef_client.log 2>&1\""
  fi
  echo "$create_command"
}

validate_role() {
  local role="$1"
  if ! [[ " $ROLES " =~ " $role " ]]
  then
    echo
    echo "VM role must be one of:"
    for THE_ROLE in ${ROLES}
    do
      echo "     ${THE_ROLE}"
    done
    echo
    exit 4
  fi
}

run_command() {
  if ${VERBOSE}
  then
    echo "gcloud command used is: \"$@\""
    echo
  fi
  eval "$@"
} 

ROLES="chefserver mysql cassandra elasticsearch kibana nginx prometheus chefclient"
SILENT=false
VERBOSE=false
GCLOUD_COMMAND="gcloud"
MACHINE="n1-standard-1"
ZONE="europe-west1-b"

case "$1" in
  start)
    ACTION="start"
    shift
    ;;
  stop)
    ACTION="stop"
    shift
    ;;
  create)
    ACTION="create"
    shift
    ;;
  delete)
    ACTION="delete"
    shift
    ;;
  ssh)
    ACTION="ssh"
    shift
    ;;
  list-vms)
    ACTION="list-vms"
    shift
    ;;
  list-vm-types)
    ACTION="list-vm-types"
    shift
    ;;
  list-roles)
    ACTION="list-roles"
    shift
    ;;
  list-projects)
    ACTION="list-projects"
    shift
    ;;
  *)
    usage
    ;;
esac

while [[ $# -gt 0 ]]
do
  case "$1" in
    -n)
      NAME="$2"
      shift 2
      ;;
    -r)
      ROLE="$2"
      shift 2
      ;;
    -p)
      PROJECT="$2"
      shift 2
      ;;
    -m)
      MACHINE="$2"
      shift 2
      ;;
    -c)
      CLIENT_ROLE="$2"
      shift 2
      ;;
    -v)
      VERBOSE=true
      shift
      ;;
    -q)
      SILENT=true
      shift
      ;;
    *)
      usage
      ;;
  esac
done

if ! [[ "$ACTION" =~ ^list\-[a-z]+ ]] && [[ ! $NAME ]]
then
  echo ""
  echo "VM name must be set if action is not list"
  echo ""
  usage
fi

if [[ $PROJECT ]]
then
  GCLOUD_COMMAND+=" --project $PROJECT"
fi

if $SILENT
then
  GCLOUD_COMMAND+=" -q"
fi

case "$ACTION" in
  list-vms)
    echo
    run_command ${GCLOUD_COMMAND} compute instances list --zones ${ZONE}
    echo
    ;;
  list-vm-types)
    echo
    run_command ${GCLOUD_COMMAND} compute machine-types list --zones ${ZONE}
    echo
    ;;
  list-roles)
    validate_role ""
    ;;
  list-projects)
    echo
    run_command ${GCLOUD_COMMAND} projects list
    echo
    ;;
  create)
    validate_role "$ROLE"
    if [[ "$ROLE" == "chefserver" ]] && [[ "$NAME" != "chefserver" ]]
    then
      echo "Overriding chef server machine name to 'chefserver' to allow connectivity from all clients"
    fi
    command=$(generate_create_vm_command "$NAME" "$ROLE" "$MACHINE" "$CLIENT_ROLE")
    run_command ${GCLOUD_COMMAND} compute instances create ${command} --zone ${ZONE}
    #eval "${GCLOUD_COMMAND} compute instances create ${command} --zone ${ZONE}"
    echo "vm was created & started, it will run chef to provision the required role (chef run output can be found in /tmp/chef_client.log on the machine)"
    ;;
  ssh)
    run_command ${GCLOUD_COMMAND} compute ssh --zone ${ZONE} "${NAME}"
    ;;
  *)
    run_command ${GCLOUD_COMMAND} compute instances ${ACTION} "${NAME}" --zone ${ZONE}
    ;;
esac

exit 0
