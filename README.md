Sync Data To S3 Storage
---------------------------------------

This is a script that can be used to back up files on a system to Amazon Web Servics S3 Storage buckets. The script is written to run as a cron job.

The script depends on the presence of the AWS command line tools on the system to be backed up. More info on getting started with the AWS CLI tools can be found here: http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-set-up.html

Once you've set up AWS CLI tools, there are only a few tweaks that need to be made to the script. Near the top, there is an array named "@dirs_array". Add all the directories you want to back up as strings in this array. Make sure you put a full path and a trailing slash on the end of each directory in the array, e.g. @dirs_array = ["/data/", "/home/"].

Second, change each instance of "/path/to/log/s3sync.log" in the script to the path where you actually want the logfile to live. Bonus points, add it to logrotate.d so that it gets rotated every so often.

The Amazon cli command "aws s3 sync" functions in a similar way to a standard rsync. If no copy of a file exists in the S3 bucket, one will be copied in. The script is currently set to delete files from the bucket if the local copies have been deleted since the last check. This behavior can be changed by removing the "--delete" from the end of the sync command on line 45 of the script.

The script itself is well-commented with more notes and details. 