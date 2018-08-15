# termux-smses
A simple fish script to send SMSes interactively with termux.

## Usage

To run the script, you need to install the [Termux API addon](https://termux.com/add-on-api.html) and the [ssh server](https://termux.com/ssh.html) on your phone. You will also need `fish` and `jq` to run the script (wherever you are running the script).

To start the script on the phone:

```
fish termux-smses
```

Remotely:

```
fish termux-smses <host name> [port]
```

By default, `port` is set to 8022.

Once connected, you will see the prompt:

```
Remote phone: 192.168.43.1:8022
Type "/help" for help.
no number set>
```

You will need to set a phone number to which the messages will be sent. To do so, use the `/setnumber +XXXXXXX` or the `/setcontact Contact Name` command.

Once the receiver set, you can type messages to be sent. You can use the shell command substitution to send the result of a shell command in a message.


```
> Hi there, my current directory contains: ##ls##.
Sent:
Hi there, my current directory contains: LICENSE README.md termux-smses.fish.
```

New lines will be replaced with spaces. You can override this behavior by starting the command with a `%` like so:

```
> Hi there, my current directory contains: ##%printf '\n - %s' (ls)##
Sent:
Hi there, my current directory contains:
 - LICENSE
 - README.md
 - termux-smses.fish
```
