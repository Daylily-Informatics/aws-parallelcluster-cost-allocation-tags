#!/bin/bash

# MIT No Attribution
# Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

parameters=$@

#enable or disable the budget checks for the projects
budget="no"

project=$(echo $@ | sed -n -e 's/.*comment //p' | awk '{print $1}')
slurm_command=$(basename "$0")

if [ -z "${project}" ];then
 echo 'You need to specify a project. "--comment ProjectName"'
 exit 1
fi

cat /opt/slurm/etc/projects_list.conf | grep $USER | grep ${project} > /dev/null
if [ $? -eq 0 ];then
 if [ "${budget}" == "yes" ]; then
     budget=$(aws budgets describe-budget --account-id <account_id> --budget-name "${project}" --query 'Budget.[CalculatedSpend.ActualSpend.Amount,BudgetLimit.Amount]' --output text 2>/dev/null)
     if [ -z "${budget}" ];then
       echo "The Project ${project} does not have any associated budget. Please ask the administrator to create it."
       exit 1
     else
       ActualSpend=$(echo ${budget} | awk '{print $1}')
       BudgetLimit=$(echo ${budget} | awk '{print $2}')
       if (( $(echo "${ActualSpend} < ${BudgetLimit}" | bc -l) ));then
         /opt/slurm/sbin/${slurm_command} $@
         exit 0
       else
         echo "The Project ${project} does not have more budget allocated for this month."
         exit 1
       fi
     fi
  else
    /opt/slurm/sbin/${slurm_command} $@
  fi
else
 echo "You are not allowed to use the project ${project}"
 exit 1
fi