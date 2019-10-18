#!/bin/bash
# createhost_api.sh
# version 1.00
# date 04/10/2019


# Usage info
show_help() {
cat << EOF
Usage: ${0##*/} -u=<user centreon> -p=<passwd centreon> -r=<url Rest API Centreon> -H=<Host> -I=<IP Host> -A=<Alias> -C=<Community SNMP> -T=<Host template> -V=<Version SNMP> -P=<Poller Monitoring> -G=<HostGroup>
This program send submit to Centreon Rest API
    -u|--user User Centreon.
    -p|--password Password Centreon.
    -r|--url url Rest API Centreon ex : http(s)://<ip centreon>
    -H|--Hostname Hostname of service
    -s|--service passive service
    -S|--Status Service status 0 Ok,1 Warning,2 Critical,3 Unknown
    -o|--output Service message
    -d|--perfdata Service perfdata optionnal
    -i|--insecure for only https optionnal
    -h|--help     help
EOF
}

for i in "$@"
do
  case $i in
    -u=*|--user=*)
      USER_CENTREON="${i#*=}"
      shift # past argument=value
      ;;
    -p=*|--password=*)
      PWD_CENTREON="${i#*=}"
      shift # past argument=value
      ;;
    -r=*|--url=*)
      URL="${i#*=}"
      shift # past argument=value
      ;;
    -H=*|--Hostname=*)
      HOSTNAME="${i#*=}"
      shift # past argument=value
      ;;
    -I=*|--ip=*)
      IPHOST="${i#*=}"
      shift # past argument=value
      ;;
    -A=*|--alias=*)
      ALIAS="${i#*=}"
      shift # past argument=value
      ;;
    -C=*|--community=*)
      COMMUNITY="${i#*=}"
      shift # past argument=value
      ;;
    -T=*|--htpl=*)
      HTPL="${i#*=}"
      shift # past argument=value
      ;;
    -V=*|--version=*)
      VERSION="${i#*=}"
      shift # past argument=value
      ;;
    -P=*|--poller=*)
      POLLER="${i#*=}"
      shift # past argument=value
      ;;
    -G=*|--hostgroup=*)
      HOSTGROUP="${i#*=}"
      shift # past argument=value
      ;;
    -i=*|--insecure=*)
      INSECURE="${i#*=}"
      shift # past argument=value
      ;;
    -h|--help)
      show_help
      exit 2
      ;;
    *)
            # unknown option
    ;;
  esac
done

# Check for missing parameters
if [[ -z "$USER_CENTREON" ]] || [[ -z "$PWD_CENTREON" ]] || [[ -z "$URL" ]] || [[ -z "$HOSTNAME" ]] || [[ -z "$IPHOST" ]] || [[ -z "$ALIAS" ]] || [[ -z "$COMMUNITY" ]] || [[ -z "$HTPL" ]] || [[ -z "$VERSION" ]] || [[ -z "$POLLER" ]] || [[ -z "$HOSTGROUP" ]]; then
    echo "Missing parameters!"
    show_help
    exit 2
fi

# Check yes/no
if [[ $INSECURE =~ ^[yY][eE][sS]|[yY]$ ]]; then
  INSECURE="--insecure "
else
  INSECURE=""
fi

CURL="/usr/bin/curl"
JQ="/usr/bin/jq"
SED="/bin/sed"

TOKEN=`$CURL -s $INSECURE -s -d "username=$USER_CENTREON&password=$PWD_CENTREON" -H "Content-Type: application/x-www-form-urlencoded" -X POST $URL/centreon/api/index.php?action=authenticate | $JQ '.["authToken"]'| $SED -e 's/^"//' -e 's/"$//'`

TIMESTAMP=`date +%s`

RESULT=`$CURL -s $INSECURE -X POST $URL'/centreon/api/index.php?action=action&object=centreon_clapi' -H 'Content-Type: application/json'  -H 'centreon-auth-token: '${TOKEN}'' -d '{"action": "add","object": "host","values": "'"${HOSTNAME};${ALIAS};${IPHOST};${HTPL};${POLLER};${HOSTGROUP}"'" }'`

RESULT=`$CURL -s $INSECURE -X POST $URL'/centreon/api/index.php?action=action&object=centreon_clapi' -H 'Content-Type: application/json'  -H 'centreon-auth-token: '${TOKEN}'' -d '{"action": "setparam","object": "host","values": "'"${HOSTNAME};snmp_community;${COMMUNITY}"'" }'`

RESULT=`$CURL -s $INSECURE -X POST $URL'/centreon/api/index.php?action=action&object=centreon_clapi' -H 'Content-Type: application/json'  -H 'centreon-auth-token: '${TOKEN}'' -d '{"action": "setparam","object": "host","values": "'"${HOSTNAME};snmp_version;${VERSION}"'" }'`

RESULT=`$CURL -s $INSECURE -X POST $URL'/centreon/api/index.php?action=action&object=centreon_clapi' -H 'Content-Type: application/json'  -H 'centreon-auth-token: '${TOKEN}'' -d '{"action": "applytpl","object": "host","values": "'"${HOSTNAME}"'" }'`


echo $RESULT
