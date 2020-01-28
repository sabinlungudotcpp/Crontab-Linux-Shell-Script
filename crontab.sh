# *** Operating Systems Group Course Work ***
# *** Developed By: Jonathan Sung, Sabin Constantin Lungu and Abdulmajeed Aldayel***
# *** Last Modify Date: 04/11/2019
#OS_Group_Coursework_40413556_40397517_40414231
# *** START OF CODE: ***

#!/bin/bash

#set name variable to system username
name="$USER"

#Global return value for returning strings from functions
#(because bash can only return integers with $?)
retval=""
declare -a global_ret_array
global_command_value=""

#this array stores regex to help with the validation of different input types
#e.g. 1, */5, 7-10
regex=(
'^([+-]?[1-9][0-9]*|0)$'
'^[*]$'
'^[*]/[1-9][0-9]*$'
'^([1-9][0-9]*|0)-([1-9][0-9]*|0)$'
'^(([1-9][0-9]*|0)[,])+([1-9][0-9]*|0)$'
)
month_name=(
"January"
"February"
"March"
"April"
"May"
"June"
"July"
"August"
"September"
"October"
"November"
"December"
)

week_name=(
"Monday"
"Tuesday"
"Wednesday"
"Thursday"
"Friday"
"Saturaday"
"Sunday"
)

#Creates a tempFile to store data (if one does not already exist)
function checkTempFileExists {
	FILE=temp_crontab
	if ! [ -f "$FILE" ]; then
		touch temp_crontab
	fi
}

#changes a num to its rank
#e.g. 1 becomes 1st, 52 becomes 52nd, 12 becomes 12th
#Parameter (value)
function num_to_position {
	str=$1
	position_regex=('[1]' '[2]' '[3]') #Check the last digit of each number
	position_message=("$1st" "$1nd" "$1rd")
	#For loop to check the last character for each number and assign
	# 'ST' after 1 'ND' after 2 'RD' after 3 otherwise 'TH'
	for ((z=0; z<${#position_regex[@]}; z++)); do
		if [[ ${str: -1} =~ ${position_regex[$z]} ]]; then
			retval=${position_message[$z]}
			break
		else
			retval="$1th"
		fi
	done
	#These are special cases for 'TH'
	if [ "$1" = 11 ] || [ "$1" = 12 ] || [ "$1" = 13 ]; then
		retval="$1th"
	fi
}

#Parameters (input_value, time_measurement, )
#Return string_message (e.g. every)
function get_time_type_message {
	integer_regex='[0-9]*'
	value="$1"
	type_of_input=-1
	#This loop identifies what type of input the user entered
	#eg. */5 is stepping, 14 is single number, 3-4 is range
	for ((i=0; i<${#regex[@]}; i++)); do
		if [[ $value =~ ${regex[$i]} ]]; then
			type_of_input=$i
			if ! [ $i -eq 1 ]; then
				#This will extract numbers from the user input and put it into an array
				#*/5 would become 5 - 1,2,3 would become 1 2 3 (no commas)
				split_values=( $(echo "${value}" | grep -o '[0-9]*') )
			fi
		fi
	done
#This loop converts all the numbers into ranked numbers and stores it into another edited_array
#e.g. 1 => 1st 2=> 2nd 11=>th ...
	declare -a edited_array
	for ((i=0; i<${#split_values[@]}; i++)); do
		num_to_position "${split_values[$i]}"
		edited_array[$i]=$retval
	done

#this array formats the user data into phrases to used in a sentence
#$3 contains prepositions, e.g. "on", "in" "at"
#$2 contains the word "minute", "hour", "month" etc.
	messages=(
	"$3 $2 ${split_values[0]}"
	"$3 every $2"
	"$3 every ${edited_array[0]} $2"
	"$3 every $2 from ${split_values[0]} through ${split_values[1]}"
	"$3 ${split_values[*]} $2"
	)
	#type_of_input selects which message to return from the function
	message=${messages[$type_of_input]}
	retval="$message"
}
#Parameters (_line_number)
function split_line {
	line_contents=`sed -n "$1p" < temp_crontab`
	#Breaks down the full string into individual components - minute,hour,month etc.
	#into and array called "time"
	#Delimiter is the space
	IFS=' ' read -ra array <<< "$line_contents"
	#command string could have spaces in between, so the command is the tail
	#of the array from index 5
	global_command_value="${array[5]}"
	for (( y=6; y<${#array[@]}; y++ )); do
		global_command_value+=" ${array[$y]}"
	done
	global_ret_array=(${array[*]})
}

function display_menu {
	echo '***OPTIONS***'
	echo '1. Display Jobs'
	echo '2. Insert Job'
	echo '3. Edit Jobs'
	echo '4. Remove Job'
	echo '5. Remove All Jobs'
	echo '9. Exit'
	echo 'Enter an Option'
}

#Displays options for corresponding time inputs
#Parameters (time measurement (e.g. minutes, hour, month etc.))
function display_input_options {
	echo '***INPUT OPTIONS***'
	echo "1. Single specific $1"
	echo "2. Every $1 (*)"
	echo "3. Every X $1(s)"
	echo "4. Between X and Y $1s"
	echo "5. Multiple specific $1(s)"
}

#Display all jobs (unless there are no jobs to show)
function display_crontab {
	get_line_count
	line_count=$?
	#Check if the tempFile is empty
	if [ $line_count -eq 0 ]; then
		echo 'No crontab for' $name
	else
		#Transfer contents of tempFile to crontab file
		crontab temp_crontab
		time_measurements=("minute" "hour" "day-of-the-month" "month" "day-of-the-week")
		preposition=("At" "past" "on" "in" "on")
		for ((j=1; j<($line_count+1); j++)); do
			split_line $j
			#split_line splits a job into its individual components and puts those values into an array
			#global_ret_array is the variable which holds arrays which are returned by functions
			time=(${global_ret_array[*]})
			#global_command_value is also assigned a value in the split_line function
			#command has its own variable because it could have spaces between
			command_value="$global_command_value"
			display_message="Job ${j}: " # This will list the jobs by number e.g. Job1
			#This loop will manage to display the jobs into human readable way
			for ((x=0; x<(${#time_measurements[@]}); x++)); do
				get_time_type_message "${time[$x]}" "${time_measurements[$x]}" "${preposition[$x]}"
				display_message+=" ${retval}" #It will append phrases together to form a sentence.
			done
			echo "${display_message} the command '${command_value}' will run."
			echo ""
		done
	fi
}

#Reads an integer (0-255)
#Asks the user to re-enter input if it is not an integer
#Parameters (input)
function input_integer {
	#Regex only accepts integer values
	#Rejects trailing zeroes (e.g. 000)
	re='^([+-]?[1-9][0-9]*|0)$'
	isValid= false
	#Loop until the input is validated successfully
	until [ ${isValid} ]; do
		read value
		#Checks if the input conforms to the Regex, and is between 0 and 255
		if [[ $value =~ $re ]] && [ $value -le 255 ] && [ $value -ge 0 ]; then
			isValid= true
			break
		else
			echo "Input is not an integer (or is out of range)"
			isValid= false
		fi
	done
	return $value
}

#Checks if an integer is between lower_limit and upper_limit
#Parameters (value, lower_limit, upper_limit)
function isIntegerInRange {
	if [ $1 -ge $2 ] && [ $1 -le $3 ]; then
		true
	else
		false
	fi
}

#Read user input - integer with range-validation
#Parameters (message, lower_limit, upper_limit)
function enter_specific_value {
	echo "Enter $1 ($2-$3)"
	#Boolean value indicates whether the input is an integer and is in range
	isValid= false
	#Loop until the input is validated successfully
	until [ $isValid ]; do
		input_integer
		value=$?
		isIntegerInRange $value $2 $3
		inRange=$?
		#if both conditions are met, the isValid will be set to true
		#and the loop will exit otherwise, isValid will be set to false
		if [ $inRange -eq 0 ]; then
			isVaild= true
			break
		else
			echo "Invalid $1 input"
			echo "Enter $1 $2-$3"
			isValid= false
		fi
	done
	return $value
}

#Asks the user to input a time for the job
#e.g. Asks for the minute input with different input options
#Parameters (message, lower_range, upper_range)
function enter_time_value {
	display_input_options $1
	enter_specific_value "Option" 1 5
	input_option=$?
	if [ "$input_option" = 1 ]; then
		enter_specific_value $1 $2 $3
		value=$?
	elif [ "$input_option" = 2 ]; then
		value="*"
	elif [ "$input_option" = 3 ]; then
		enter_specific_value $1 1 $3
		#step contains the interval value (e.g. every 5 minutes)
		step=$?
		value="*/$step"
	elif [ "$input_option" = 4 ]; then
		#Asks the user to input - between X and Y (e.g. 1-6 months)
		enter_specific_value "Lower limit $1" 1 $3
		lower_limit=$?
		enter_specific_value "Upper limit $1" $lower_limit $3
		upper_limit=$?
		value="$lower_limit-$upper_limit"
	elif [ "$input_option" = 5 ]; then
		#Multiple value input
		#Keeps asking the user to input numbers until they want to stop
		#(e.g. 1,2,3,4,7,8)
		quit= false
		enter_specific_value $1 $2 $3
		time_list="$?"
		echo "$time_list"
		until [ $quit ]; do
			echo "Add another $1? (Y/N)"
			read userinput
			if [ "$userinput" = "Y" ] || [ "$userinput" = "y" ]; then
				enter_specific_value $1 $2 $3
				#Appends the next value onto the variable
				time_list+=",$?"
				echo "$time_list"
			else
				quit= true
				break
			fi
		done
		value=$time_list
	fi
	retval="$value"
}

#Reads in the current data for the job and asks if the user wants to change it
#Parameters (time_measurement, current_value, lower_limit, upper_limit)
function edit_prompt {
	echo "Edit $1: $2? (Y/N)"
	read userinput
	if [ "$userinput" = "Y" ] || [ "$userinput" = "y" ]; then
		enter_time_value $1 $3 $4
		edited_value=$retval
	else
		edited_value=$2
	fi
	retval="$edited_value"
}
#Parameters (current values)
#(minute, hour, DoM, month, DoW, command)
function edit_job {
	edit_prompt "minute" "$1" 0 59
	minute=$retval
	edit_prompt "hour" "$2" 0 23
	hour=$retval
	edit_prompt "Day-of-the-month" "$3" 1 31
	dom=$retval
	edit_prompt "month" "$4" 1 12
	month=$retval
	edit_prompt "Day-of-the-week" "$5" 1 7
	dow=$retval
	# *** ASKS THE USER TO ENTER A COMMAND FOR THE JOB ***
	echo "Edit Command: $6? (Y/N)"
	read userinput
	if [ "$userinput" = "Y" ] || [ "$userinput" = "y" ]; then
		echo "Enter Command"
		read command
	else
		command="$6"
	fi

	# *** PASSING THE VALUES TO THE TEMP FILE ***
	echo "${minute} ${hour} ${dom} ${month} ${dow} ${command}" >> temp_crontab
	crontab temp_crontab #TRANSFERING CONTENT FROM THE TEMP FILE TO crontab FILE
}

function enter_new_job {
	enter_time_value "minute" 0 59
	minute=$retval
	enter_time_value "hour" 0 23
	hour=$retval
	enter_time_value "Day-of-the-month" 1 31
	dom=$retval
	enter_time_value "month" 1 12
	month=$retval
	enter_time_value "Day-of-the-week" 1 7
	dow=$retval
	# *** ASKS THE USER TO ENTER A COMMAND FOR THE JOB ***
	echo "Enter Command"
	read command
	# *** PASSING THE VALUES TO THE TEMP FILE ***
	echo "${minute} ${hour} ${dom} ${month} ${dow} ${command}" >> temp_crontab
	crontab temp_crontab #TRANSFERING CONTENT FROM THE TEMP FILE TO crontab FILE
}

function get_line_count {
	line_count=$(grep "" -c temp_crontab)
	return $line_count
}

#Parameters
#(message (e.g. EDIT, REMOVE))
function select_job {
	get_line_count
	line_count=$?
	if [ $line_count -eq 0 ]; then
		echo "No crontab for ${name} (No jobs to $1)"
	else
		echo "Choose which job you would like to $1."
		#List the jobs with line numbers next to them
		cat -n ./temp_crontab
		enter_specific_value job 1 $line_count
		job=$?
	fi
	return $job
}

#*** START OF MAIN PROGRAM****
set -f
checkTempFileExists
# *** Until the user inputs number 9 it will keep looping ***
until [ "$usercommand" = 9 ]; do
	display_menu
	read usercommand
	if [ "$usercommand" = 1 ]; then
		#1. Display Jobs
		display_crontab
	elif [ "$usercommand" = 2 ]; then
		#2. Insert Job
		enter_new_job
		echo "Job has been inserted successfully."
	elif [ "$usercommand" = 3 ]; then
		#3. Edit a job
		get_line_count
		line_count=$?
		if [ $line_count -eq 0 ]; then
			echo "No crontab for ${name} (No jobs to edit)"
		else
			select_job "EDIT"
			job=$?
			#get line contents and assign it to a variable
			split_line $job
			time=(${global_ret_array[*]})
			command_value="$global_command_value"

			#Arguements are passed into edit_job so you can view its current value
			#and choose if you want to edit it
			edit_job "${time[0]}" "${time[1]}" "${time[2]}" "${time[3]}" "${time[4]}" "${command_value}"
			sed -i "${job}d" temp_crontab
			echo "Job has been edited successfully."
		fi
	elif [ "$usercommand" = 4 ]; then
		#4. Remove a single job
		select_job "REMOVE"
		job=$?
		#Remove line number in tempFile
		sed -i "${job}d" temp_crontab
		echo "Job has been removed successfully."
	elif [ "$usercommand" = 5 ]; then
		#5. Remove all jobs
		#Clear the contents of the tempFile (to sync with the crontab file)
		> temp_crontab
		#Remove all jobs from crontab file
		crontab -r
		echo "All jobs have been removed successfully."
	elif [ "$usercommand" = 9 ]; then
		#9. Goodbye message
		echo 'Exiting program!'
		echo 'Good bye' $name
	else
		#Out of range input (1-5 Or 9)
		echo "Invalid option."
		display_menu
	fi
done
