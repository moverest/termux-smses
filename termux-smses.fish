
set -l contact_name
set -l contact_number

echo 'To exit type `/exit`.'

set -l msg
set -l continue true
while test $continue = true
    read -p 'echo -n "> "' msg

    if string match -q -r '^/' -- $msg
        set -l cmd (string replace -r '^/' '' -- $msg)
        switch $cmd
            case exit
                set continue false
            case quit
                set continue false
            case last
                termux-sms-inbox | jq -r 'map(select(.sender=="'$contact_name'"))[-1] | @text "'(set_color yellow)'At \(.received)'(set_color normal)':\n\(.body)\n"'
            case 'setnum*'
                set -l args (string split ' ' -- $cmd)
                if set -q args[2]
                  set contact_number $args[2]
                else
                  echo 'Usage: /setnum NUM'
                end
            case 'setcontact*'
                set -l args (string split -m 1 ' ' -- $cmd)
                if set -q args[2]
                  set -l temp_contact_name $args[2]
                  set -l temp_contact_number (termux-contact-list | jq 'map(select(.name=="'$temp_contact_name'"))[0].number' | tr -d ' "')
                  if test "$temp_contact_number" = null
                      echo Not found.
                      exit 1
                  else
                      echo Using $temp_contact_number.
                      set contact_name $contact_name
                      set contact_number $temp_contact_number
                  end
                else
                  echo 'Usage: /setcontact CONTACT NAME'
                end
            case info
              echo 'contact_number: ' $contact_number
              echo 'contact_name: ' $contact_name
            case '*'
                printf 'Command `%s` not found.\n' $cmd
        end
    else if test -n $contact_number
        set -l incmds (string match -ar '##[^#]*##' -- $msg)

        for rawincmd in $incmds
            set -l incmd (string replace -r '##([^#]*)##' '$1' -- $rawincmd)
            set -l incmd_res (eval $incmd)
            set msg (string replace $rawincmd "$incmd_res" -- $msg)
        end

        echo -n 'Sending...'
        #printf "%s\n" $msg
        termux-sms-send -n $contact_number $msg
        echo ' done.'
    else
      echo 'You can\'t send a SMS. You have not set a contact number yes.'
      echo 'Use /setnum or /setcontact to set the number.'
    end

end
