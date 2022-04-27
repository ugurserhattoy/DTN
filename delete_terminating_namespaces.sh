#!/bin/bash

function remove_from_the_list
{
    NUM_CHECK='^[0-9]+$'
    NUM_ARR=()
    NS_ARR=()
    for VAR in $@
    do
        if [[ $VAR =~ $NUM_CHECK ]]
        then    
            NUM_ARR+=("$VAR")
        else
            NS_ARR+=("$VAR")
        fi
    done
    if (( ${#NUM_ARR[@]} ))
    then
        for((i=0;i<${#NUM_ARR[*]};i++));
        do
            SED_VAR+="${NUM_ARR[$i]}d;"

        done
    fi
    if (( ${#NS_ARR[@]} ))
    then
        for((i=0;i<${#NS_ARR[*]};i++));
        do
            SED_VAR+="/${NS_ARR[$i]}/d;"
        done        
    fi
    SED_VAR=${SED_VAR%;}
    sed -i "$SED_VAR" stucked.namespaces
}

function delete_terminating_namespaces
{
    for NS in $(cat stucked.namespaces)
    do
        kubectl get namespace "$NS" -o json \
        | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" \
        | kubectl replace --raw /api/v1/namespaces/$NS/finalize -f -
        echo "----------------------------------------------------------------ust-"
        echo "Deleting $NS is completed succesfully"
        echo "----------------------------------------------------------------ust-"
    done
    rm stucked.namespaces
    echo "------------------rest-------------------ust-"
    kubectl get ns | grep Terminating
    echo
}

# create stucked namespaces list
kubectl get ns | grep Terminating | cut -d " " -f 1 > stucked.namespaces
echo
echo "Stucked ones:"
echo
echo "$(kubectl get ns | grep Terminating)"
echo
echo "Namespaces above will be deleted."
echo "Are you OK deleting namespaces above?"
echo "- y for YES will delete them,"
echo "- n for NO will give you the option to remove some of them from the deleting list."
read -p '- Any other input will cancel deleting (y/n): ' AVAR

if [[ "$AVAR" == "n" ]] 
then
    LINE_NUMBER=0
    echo
    echo "-----------------------deleting-list-----------------------------ust-"
    for NS in $(cat stucked.namespaces)
    do
        ((LINE_NUMBER++))
        echo  $LINE_NUMBER"." $NS
    done
    echo
    echo "To remove one or more namespaces from the deleting list"
    echo "Specify namespaces or line numbers with spaces between them"
    echo "     AS AN EXAMPLE: 3 12 cattle-seat 7"
    echo
    read -p 'Which one(s) do you want to eliminate from the deleting list?: ' UINPUT
    remove_from_the_list $UINPUT
    echo
    echo "-----------------------deleting-list-----------------------------ust-"
    cat stucked.namespaces
    echo
    read -p 'Are you OK deleting the namespaces above? (y/n): ' AVAR
    if [[ "$AVAR" == "y" ]]
    then
        delete_terminating_namespaces
    else
        echo
        echo "Cancelled!"
        echo
        rm stucked.namespaces
        exit    
    fi
elif [[ "$AVAR" == "y" ]]
then
    delete_terminating_namespaces
else
    echo
    echo "Cancelled!"
    echo
    rm stucked.namespaces
    exit
fi