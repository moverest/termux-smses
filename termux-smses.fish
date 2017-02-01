
read -p 'echo "Contact name? "' -l contact_name

set -l contact_number (termux-contact-list | jq 'map(select(.name=="'$contact_name'"))[0].number' | tr -d ' "')
if test "$contact_number" = null
    echo Not found.
    return 1
else
    echo Found $contact_number.
    read -p 'echo -n "Continue? [Y/n] "' -l ok
    if test "$ok" = n
        return 2
    end
end

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
            case '*'
                printf 'Command `%s` not found.\n' $cmd
        end
    else
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
    end

end
