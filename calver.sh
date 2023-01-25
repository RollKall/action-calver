#!/usr/bin/env bash

### Variables
##############################################################################

# BASE
ORGANIZATION="${ORGANIZATION:-}"
REPOSITORY="${REPOSITORY:-}"
CURRENT_YEAR=$(date +'%-y')  # no padding
CURRENT_MONTH=$(date +'%-m') # no padding
RESET_COUNT=0
PATTERN='^[0-9]+$'

# VERSION
MAJOR_VERSION="${MAJOR_VERSION:-}"
MINOR_VERSION="${MINOR_VERSION:-}"
MICRO_VERSION="${MICRO_VERSION:-}"

### Public Functions
#########################################################

function main(){

    # Run Commands
    get_release_version
    
}

function get_release_version(){

    local exit_code=0

    # Prerequisites
    _verify_cli_exists "gh"
    _verify_cli_exists "jq"
    
    # Get Variables
    _get_release_version
    echo "release-version=$(echo $MAJOR_VERSION.${MINOR_VERSION}.${MICRO_VERSION})" >> $GITHUB_OUTPUT

}

### Internal-Use Only
#########################################################

function _verify_cli_exists(){

    local exit_code=0

    if ! command -v ${1} &> /dev/null; \
    then
        echo -e "\e[91;1mERROR: Can not find '${1}' executable in PATH\e[0m" 
        exit_code=1  
    fi

    return ${exit_code}
}

function _get_release_version(){

    ### MAJOR VERSION - read, create, update
    #########################################################

    # read
    MAJOR_VERSION=$(gh api -H 'Accept: application/vnd.github+json' /repos/${ORGANIZATION}/${REPOSITORY}/actions/variables/MAJOR_VERSION | jq '.value | tonumber? // .')

    if ! [[ $MAJOR_VERSION =~ $PATTERN ]]
    then
        # create
        gh api -H 'Accept: application/vnd.github+json' /repos/${ORGANIZATION}/${REPOSITORY}/actions/variables -f name='MAJOR_VERSION' -f value=$CURRENT_YEAR
        echo "Variable 'MAJOR_VERSION' Created"
    else 
        if [ $MAJOR_VERSION == $CURRENT_YEAR ]
        then
            :
        else
            # update
            gh api --method PATCH -H "Accept: application/vnd.github+json" /repos/${ORGANIZATION}/${REPOSITORY}/actions/variables/MAJOR_VERSION -f name='MAJOR_VERSION' -f value=$CURRENT_YEAR
            echo "Variable 'MAJOR_VERSION' updated to '$CURRENT_YEAR'"
        fi
    fi

    ### MINOR VERSION - read, create, update
    #########################################################

    MINOR_VERSION=$(gh api -H 'Accept: application/vnd.github+json' /repos/${ORGANIZATION}/${REPOSITORY}/actions/variables/MINOR_VERSION | jq '.value | tonumber? // .')

    if ! [[ $MINOR_VERSION =~ $PATTERN ]]
    then
        # create
        gh api -H 'Accept: application/vnd.github+json' /repos/${ORGANIZATION}/${REPOSITORY}/actions/variables -f name='MINOR_VERSION' -f value=$CURRENT_MONTH
        echo "Variable 'MINOR_VERSION' Created"
    else 
        if [ $MINOR_VERSION == $CURRENT_MONTH ]
        then
            :
        else
            # update
            gh api --method PATCH -H "Accept: application/vnd.github+json" /repos/${ORGANIZATION}/${REPOSITORY}/actions/variables/MINOR_VERSION -f name='MINOR_VERSION' -f value=$CURRENT_MONTH
            echo "Variable 'MAJOR_VERSION' updated to '$CURRENT_MONTH'"
            RESET_COUNT=1
        fi
    fi

    # ### MICRO VERSION - read, create, update
    # #########################################################
 
    if [ $RESET_COUNT -eq 1 ]
    then
        MICRO_VERSION=0
    else
        # read
        MICRO_VERSION=$(gh api -H 'Accept: application/vnd.github+json' /repos/${ORGANIZATION}/${REPOSITORY}/actions/variables/MICRO_VERSION | jq '.value | tonumber? // .')
        if ! [[ $MICRO_VERSION =~ $PATTERN ]]
        then
            # create
            gh api -H 'Accept: application/vnd.github+json' /repos/${ORGANIZATION}/${REPOSITORY}/actions/variables -f name='MICRO_VERSION' -f value='0'
            echo "Variable 'MICRO_VERSION' Created"
            
            # end function
            return 0
        else
            MICRO_VERSION=$(($MICRO_VERSION+1))
        fi
    fi

    # update
    gh api --method PATCH -H "Accept: application/vnd.github+json" /repos/${ORGANIZATION}/${REPOSITORY}/actions/variables/MICRO_VERSION -f name='MICRO_VERSION' -f value=${MICRO_VERSION}
    echo "Variable 'MICRO_VERSION' updated to '$MICRO_VERSION'"

}

#### Runtime
#########################################################
main
