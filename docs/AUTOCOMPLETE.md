# Auto Complete

To enable shell auto completion, you have to figure out what shell you want to enable it on. Currently only Bash and Zsh have been tested.

## 1. Identify Your Shell

Either run:

```sh
$ echo $SHELL
/bin/zsh
```

Or:

```sh
$ ps
PID TTY          TIME CMD
7360 pts/5    00:00:00 bash
7371 pts/5    00:00:00 ps
```

## 2. Add completion script to your profile

For Bash: Add the following to your profile (usually `~/.bashrc`, which `~/.bash_profile` sources, or if exists, `/etc/bash_completion.d/`)

```sh
  source $(dirname "$(which awsm)")/awsm-cli/autocomplete/completion.bash
  complete -F _awsm awsm
```

Note: If you added it to `/etc/bash_completion.d`, make sure you test it with `source /etc/bash_completion` afterwards or else it might not work still.

For Zsh: Add the following to your profile (usually `~/.zshrc`)

```sh
  autoload bashcompinit
  bashcompinit
  source $(dirname "$(which awsm)")/awsm-cli/autocomplete/completion.bash
  complete -F _awsm awsm
```

## 3. Profit :moneybag:

```sh
$ awsm [TAB]
_               autoscaling     cloudformation  ec2             route53
```

## 4. Advanced

You may notice there is a subcommand called _underscore_ (i.e. `awsm _`). This is a list of private, internal subcommands that `awsm-cli` uses to expose some of its inner-workings to the advanced shell users.

For example:

```sh
$ awsm _ subcommand-actions --subcommand ec2
describe-availability-zones
describe-images
describe-instances
describe-regions
describe-subnets
describe-vpcs
get-console-output
```

There will be more documentation around each under-the-hood (hence `_`) internal subcommands later.
