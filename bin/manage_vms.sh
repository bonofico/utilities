#!/bin/bash -e

usage() {
  echo "Usage: $(basename "$0") <action> [-n <name>] [-r <role>] [-m <machine_type>] [-p <project_id>] [-q]"
  echo ""
  echo "Actions:"
  echo " * list-vms (list current vms in project)"
  echo " * list-types (list available machine types in project)"
  echo " * list-roles (list available roles for machines)"
  echo " * list-projects (list available projects)"
  echo " * start, stop, delete (requires vm name)"
  echo " * create (requires vm name & role, if no type is specified the default will be used)"
  echo ""
  echo ""
  echo "Additional flags:"
  echo ""
  echo " -p project_id - set project id (for multiple project support)"
  echo " -q - no prompt (will not ask for interactive approval on delete)"
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
  if [[ "$vm_role" == "chefserver" ]]
  then
    create_command="${chef_server_name} --image ${chef_server_image} --machine-type ${machine_type}"
  else
    create_command="${vm_name} --image ${chef_client_image} --machine-type ${machine_type} --metadata startup-script=\"chef-client -r role[${vm_role}] > /tmp/chef_client.log 2>&1\""
  fi
  echo "$create_command"
}

validate_role() {
  local role="$1"
  if ! [[ " $ROLES " =~ " $role " ]]
  then
    echo "VM role must be one of:"
    echo "$ROLES"
    exit 4
  fi
}

ROLES="mysql cassandra chefserver elasticsearch kibana nginx prometheus"
SILENT=false
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
  list-vms)
    ACTION="list-vms"
    shift
    ;;
  list-types)
    ACTION="list-types"
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
    -q)
      SILENT=true
      shift
      ;;
    *)
      usage
      ;;
  esac
done

if ! [[ "$ACTION" =~ ^list\-[a-z]+$ ]] && [[ ! $NAME ]]
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
    ${GCLOUD_COMMAND} compute instances list --zones ${ZONE}
    ;;
  list-types)
    ${GCLOUD_COMMAND} compute machine-types list --zones ${ZONE}
    ;;
  list-roles)
    validate_role ""
    ;;
  list-projects)
    ${GCLOUD_COMMAND} projects list
    ;;
  create)
    validate_role "$ROLE"
    if [[ "$ROLE" == "chefserver" ]] && [[ "$NAME" != "chefserver" ]]
    then
      echo "Overriding chef server machine name to 'chefserver' to allow conectivity from all clients"
    fi
    command=$(generate_create_vm_command "$NAME" "$ROLE" "$MACHINE")
    eval "${GCLOUD_COMMAND} compute instances create ${command} --zone ${ZONE}"
    ;;
  *)
    ${GCLOUD_COMMAND} compute instances ${ACTION} "${NAME}" --zone ${ZONE}
    ;;
esac

exit 0
