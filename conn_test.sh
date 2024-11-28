#!/usr/bin/env bash
# http://developers.xstore.pro/documentation/
# https://www.linux-magazine.com/Online/Features/OpenSSL-with-Bash
# https://stackoverflow.com/questions/16056135/how-to-use-openssl-to-encrypt-decrypt-files

LOGIN_ENC_PASSWD='topsecretpassphrase';
REMOTE_USER='ec2-user';
REMOTE_PUBLIC_IP='VVV.XXX.YYY.ZZZ';
REMOTE_SSH_KEY=~/.ssh/AWS.pem;

if [[ -z "${LOGIN_ENC_PASSWD}" ]] \
|| [[ -z "${REMOTE_USER}" ]] \
|| [[ -z "${REMOTE_PUBLIC_IP}" ]]; then
  echo "Verify (one or more) required variable values:";
  echo "LOGIN_ENC_PASSWD / REMOTE_USER / REMOTE_PUBLIC_IP";
  exit 1;
fi;

## Is this part to be executed only locally, NOT on a "remote/cloud machine"?:
  if [[ -f './login.json' ]] && [[ -w ./ ]] ; then
    echo "Encrypting XTB login information from login.json file.";
    if [[ -f './login.json.enc' ]] && [[ -w './login.json.enc' ]]; then
      read -r -p "Current login.json.enc will be overwritten! Do you wish to continue? [y/N]: ";
      : "${REPLY:=No}";
      if [[ "${REPLY}" != [Yy]* ]]; then
        echo "Aborting.";
        exit 2;
      fi;
    fi;
    openssl enc -pbkdf2 -aes-256-cbc -in './login.json' -out './login.json.enc' -k "${LOGIN_ENC_PASSWD}" && rm './login.json';
  elif [[ -f './login.json.enc' ]] && [[ -r './login.json.enc' ]]; then
    echo "Verify the encrypted XTB login information from login.json.enc file.";
    read -r -p "Does the file contain (presumably) valid information? ";
  else
    echo "XTB login information not present or unreadable. Aborting.";
    exit 3;
  fi;

  if  [[ ! -f "${REMOTE_SSH_KEY}" ]]; then
    echo "No remote SSH key file present. Aborting.";
    exit 4;
  fi;
  scp -i "${REMOTE_SSH_KEY}" ./[!_]* "${REMOTE_USER}"@"${REMOTE_PUBLIC_IP}":~/
  ssh -i "${REMOTE_SSH_KEY}" "${REMOTE_USER}"@"${REMOTE_PUBLIC_IP}"
##

#IN DEVELOPMENT:
#cat <(openssl enc -d -pbkdf2 -aes-256-cbc -in './login.json.enc' -out - -k "${LOGIN_ENC_PASSWD}") - | openssl s_client -quiet -connect xapi.xtb.com:5112 2>/dev/null | jq | tee -a output.json
#cat <(openssl enc -d -pbkdf2 -aes-256-cbc -in './login.json.enc' -out - -k "${LOGIN_ENC_PASSWD}") - | openssl s_client -quiet -connect xapi.xtb.com:5112 2>/dev/null | jq | tee -a output.json

#create named pipe './input' (if not present) for communication with background openssl process
#[[ ! -p input ]] && mkfifo input;
#[[ -z "${LOGIN_ENC_PASSWD}" ]] && source <(grep '^LOGIN_ENC_PASSWD' conn_test.sh);
#openssl s_client -quiet -connect xapi.xtb.com:5112 <input 1>output 2>/dev/null & cat <(openssl enc -d -pbkdf2 -aes-256-cbc -in './login.json.enc' -out - -k "${LOGIN_ENC_PASSWD}") >input;
