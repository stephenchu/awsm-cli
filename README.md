# AWSM-CLI

Combines the power of Unix pipes and the official AWS `awscli` cli tool on the command line, plus more. Simply written in Bash.

`awsm-cli` is written and maintained by Stephen Chu (github@stephenchu.com).

Mailing list: https://groups.google.com/forum/#!forum/awsm-cli-users

## Basic Usage

```sh
# Find ec2 instances within all us-west-2 vpcs named 'production' alike:

$ awsm ec2 describe-vpcs -r us-west-2 | grep -w production | awsm ec2 describe-instances
Region     tag:Name  InstanceId           AvailabilityZone  InstanceType  State    PublicIpAddress  PrivateIpAddress  PrivateDnsName                              VpcId         ImageId       LaunchTime                
us-west-2  Foo       i-015ef79784b536dbe  us-west-2a        r3.xlarge     running  n/a              10.42.17.213      ip-10-42-17-213.us-west-2.compute.internal  vpc-d85397bc  ami-1411c474  2016-08-24T20:39:01.000Z

# Count all the instance types of all us-west-2 EC2 instances:

$ awsm ec2 describe-instances -r us-west-2 | tail -n +2 | awk -F $'\t' '{ print $5 }' | sort | uniq -c
    14 c4.large
     3 c4.xlarge
     2 i2.2xlarge
     1 m3.2xlarge
```


## Installation

### Dependencies

First you will have to install these yourself, as different versions are available/supported on different Linux distros.

* [awscli](https://github.com/aws/aws-cli#installation) `>= 1.10.63`
* [jq](https://stedolan.github.io/jq/download/) `>= 1.6`
* [GNU awk](https://www.gnu.org/software/gawk/) `>= 4.1.1`
* [GNU parallel](https://www.gnu.org/software/parallel/) `>= 20160922`

Tip: Run `awsm _ dependencies-check` to ensure you have a working environment:

```sh
$ awsm _ dependencies-check
[INFO] Checking for dependencies used by awsm-cli...
[INFO] Your awscli is working properly.
[INFO] Your jq is working properly.
[INFO] Your GNU awk is working properly.
[INFO] Your GNU parallel is working properly.
[INFO] Summary: Awesome! All required dependencies are installed correctly. Enjoy awsm-cli!
```

### Bash

```sh
$ bash -c 'export DIR=$(mktemp --directory); cd $DIR && git clone --recursive https://github.com/stephenchu/awsm-cli.git .; mv files/* /usr/local/bin/'
```

For shell auto completion, [see AUTOCOMPLETE.md here](docs/AUTOCOMPLETE.md).

## Problems `awsm-cli` Aims to Solve Over the AWS Official `awscli`

### 1. Defaults to human-readable, line-based table format instead of JSON

JSON is great for machine-to-machine parseability and is reasonably humanly readable, but it becomes unreadable quickly when the amount of JSON text exceeds a few pages worth. Line-based, tabular format for each JSON entities allow compact information to be presented to human, at the expense of completeness, is more readable.

`awsm-cli` parses it for you and presents to you a readable, line-based table format.

### 2. Changing its default output format is still humanly unreadable

The `awscli` option `--option table` yields an ugly [table border](http://docs.aws.amazon.com/cli/latest/userguide/controlling-output.html#table-output). Using `--option text` yields a difficult-to-parse multi-line [textual output](http://docs.aws.amazon.com/cli/latest/userguide/controlling-output.html#text-output) as well.

With `awsm-cli`, you append `--jq '.'` (a "dot" means everything in [jq](https://stedolan.github.io/jq/tutorial/)) to swiftly change from tabular format to JSON format that the human-readable results are derived from, plus any JSON filtering/transforming you wish to alter your results using the [powerful features](https://stedolan.github.io/jq/manual/) of Jq:

```sh
$ awsm ec2 describe-instances -r us-west-2 --jq '[.] | map(select(.InstanceType == "t2.small"))'
```

Each line of output in `awsm-cli` is one entity. Plain simple and expected. But if you need to, displaying its representing JSON is only one command line option away.

### 3. Traversing AWS resource object graph involves repetitive conditional logic

Common Laborious Pattern:

```sh
vpc_ids=$(aws ec2 --region us-west-2 describe-vpcs --output text --query 'Vpcs[*].VpcId')
if [ ! -z "$vpc_ids" ]; then
  aws ec2 --region us-west-2 describe-instances ... --filters Name=vpc-id,Values=$(tr $'\t' ',' <<< "$vpc_ids")
else
  aws ec2 --region us-west-2 describe-instances ...
fi
```

Pattern Explained:

1. Find some AWS resource identifiers. Make sure you know your `--query` JSON hierachy. Store them in a variable.
1. Do a `if` condition check for the above variable, becuase you then need to conditionally put the `--filters` clause.
1. Conditionally execute your subsequent `awscli` command with the filtering clause containing (or not) your pre-fetched values (in CSV).
1. Don't forget you also have to customize your `--output`, or pick out relevant information you need. Again remember your JSON hierarchy.

Now this example is a simple relationship of `VPC -> instances`. Try: `VPC -> subnets -> autoscaling groups -> instances`.

Instead, `awsm-cli` allows you to just do:

```sh
$ awsm ec2 describe-vpcs -r us-west-2 | awsm ec2 describe-instances
```

`awsm-cli` uses Unix pipes to intuitively traverse AWS resource relationships from one to another. You can even combine other command line tools that works with stdin/stdout (e.g. grep, sed, awk, etc.) to avoid writing complicated shell scripts to get what you want.

Unix pipes is simply the most intuitive and error-free way in command line to avoid writing shell scripts imperatively to get what you want.


## Features

* Uses Unix pipes to walk the AWS resources relationships
* All subcommands support option `--jq '.'` to change from textual outputs to their native JSON outputs via the more powerful JQ filters.
* All subcommands support printing the underlying native `awscli` executed commands via `--log-aws-cli`
* All subcommands support printing the underlying `jq` filter used via `--log-jq`
* All region-specific subcommands support displaying multiple regions' worth of data via `--region "us-west-1 us-west-2"`, something that takes multiple page loads on the AWS web console
* Nicely align any `awsm-cli` output using `column` by piping any stdout into `| awsm _ column`.
* Supports multi-column sort piping any stdout into `| awsm _ sort -k 2,2 -k 3,3`.


## Supported AWS Subcommands

Look in [files/awsm-cli/*.sh](files/awsm-cli), or, better yet, run:

```sh
$ aws _ subcommands
_
autoscaling
cloudformation
ec2
.
.
.

$ aws _ subcommand-actions --subcommand ec2
describe-availability-zones
describe-images
describe-instances
describe-instance-status
describe-regions
.
.
.
```

## How It Works

See [DESIGN.md](docs/DESIGN.md).

## Contribute

Yes, please, thank you! See [CONTRIBUTE.md](docs/CONTRIBUTE.md).

## About the Author

Stephen Chu (github@stephenchu.com)

A software developer, who had done a little bit of Ruby, Python, Java, C#, JRuby, Bash, and he played a little with Rails, Postgres, MySql, Oracle, Terraform, Packer, Cassandra, Kafka, ZooKeeper, Docker, and AWS. He specializes in writing low maintenance-cost software.
