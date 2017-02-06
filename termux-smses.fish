
set contact_name
set contact_number
set parse_emoji true

set new_line_sequence '&&ln&&'
set emoji '<3'\t'\xE2\x9D\xA4' ':3'\t'\xF0\x9F\x98\xB8'


function print_prompt --argument-names contact_name contact_number
    if test -n $contact_name
        echo -n (set_color yellow)$contact_name(set_color normal) '('(set_color green)$contact_number(set_color normal)')'
    else if test -n $contact_number
        echo -n $contact_number
    else
        echo -n 'no number set'
    end

    echo -n '> '
end

function render_message --argument-names msg
    set -l incmds (string match -ar '##[^#]*##' -- $msg)

    for rawincmd in $incmds
        set -l print_new_lines false
        set -l incmd (string replace -r '##([^#]*)##' '$1' -- $rawincmd)

        if set incmd (string replace -r '^%' '' -- $incmd)
            set print_new_lines true
        end

        set -l incmd_res (eval $incmd)

        if test $print_new_lines = true
            set incmd_res (string join $new_line_sequence -- $incmd_res)
        end

        set msg (string replace $rawincmd "$incmd_res" -- $msg)
    end

    if test $parse_emoji = true
        for e in $emoji
            set -l e (string split \t -- $e)
            set msg (string replace -a $e[1] (printf $e[2]) -- $msg)
        end
    end

    string replace -a $new_line_sequence \n -- $msg
end

echo 'Type "/help" for help.'

set -l msg
set -l continue true
while test $continue = true
    read -p "print_prompt '$contact_name' '$contact_number'" msg

    if string match -q -r '^/' -- $msg
        set -l cmd (string replace -r '^/' '' -- $msg)
        switch $cmd
            case exit
                set continue false
            case quit
                set continue false
            case 'last*'
                set -l args (string split ' ' -- $cmd)
                if set -q args[2]
                    termux-sms-inbox -l $args[2] | jq -r 'map(select(.sender=="'$contact_name'")) | .[] | @text "'(set_color yellow)'At \(.received)'(set_color normal)':\n\(.body)\n"'
                else
                    termux-sms-inbox | jq -r 'map(select(.sender=="'$contact_name'"))[-1] | @text "'(set_color yellow)'At \(.received)'(set_color normal)':\n\(.body)\n"'
                end

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
                    set -l results (termux-contact-list | jq -r 'map(select(.name|contains("'$args[2]'"))) | .[] | "\(.name)\t\(.number)"')

                    if not set -q results[1]
                        echo 'No contact found.'
                    else
                        set -l choice
                        if test (count $results) = 1
                            set choice 1
                        else
                            for i in (seq (count $results))
                                printf '%d. %s (%s)\n' $i (string split \t -- $results[$i])
                            end

                            read -p "echo '> '" choice
                        end

                        if test "$choice" -le 0
                            or test "$choice" -gt (count $results)
                            echo "Invalid input"
                        else
                            set -l contact (string split \t -- $results[$choice])
                            set contact_name $contact[1]
                            set contact_number (string replace -a ' ' '' -- $contact[2])
                        end
                    end



                else
                    echo 'Usage: /setcontact CONTACT NAME'
                end
            case info
                echo 'contact_number:    ' $contact_number
                echo 'contact_name:      ' $contact_name
                echo 'new_line_sequence: ' $new_line_sequence
            case help
                echo '/help                      Show this message'
                echo '/setcontact <contact name> Set contact number from address book'
                echo '/setnumber <phone number>  Set phone number'
                echo '/info                      Show settings'
                echo '/exit                      Exit'
            case '*'
                printf 'Command `%s` not found.\n' $cmd
        end
    else if test -n "$contact_number"

        set -l rendered_msg (render_message $msg)
        printf "%s\n" $rendered_msg | termux-sms-send -n $contact_number
        echo 'Sent:'
        printf "%s\n" $rendered_msg
    else
        echo 'You can\'t send a SMS. You have not set a contact number yet.'
        echo 'Use /setnum or /setcontact to set the number.'
    end

end
