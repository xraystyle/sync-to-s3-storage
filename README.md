Sync Data To S3 Storage
---------------------------------------

This is a script that can be used to back up files on a system to Amazon Web Servics S3 Storage buckets. The script is written to run as a cron job.

The script depends on the presence of the AWS command line tools on the system to be backed up. More info on getting started with the AWS CLI tools can be found here: http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-set-up.html

Once you've set up AWS CLI tools, there are only a few tweaks that need to be made to the script. Near the top, there is an array named "@dirs_array". Add all the directories you want to back up as strings in this array. Make sure you put a full path and a trailing slash on the end of each directory in the array, e.g. @dirs_array = ["/data/", "/home/"].

Second, change each instance of "/path/to/log/s3sync.log" in the script to the path where you actually want the logfile to live. Bonus points, add it to logrotate.d so that it gets rotated every so often.

The Amazon cli command "aws s3 sync" functions in a similar way to a standard rsync. If no copy of a file exists in the S3 bucket, one will be copied in. The script is currently set to delete files from the bucket if the local copies have been deleted since the last check. This behavior can be changed by removing the "--delete" from the end of the sync command on line 45 of the script.

The script itself is well-commented with more notes and details. 


Notes On Performance And Errors
--------------------------------------------

Due to the way the Amazon S3 Sync command is written, it won't actually start copying files until it has built a complete list of local files and compared them to the remote. This script takes the directories specified in the backup list, then begins syncing each subfolder of the directories specified. Because of this, it's advisable to specify only a single directory above the data you want to sync in the backup directories list.

Example: Say you have a server with the path "/media/raid_array/user_data/home/" and you have some number of home folders in that directory you want to back up. You'd be better off specifying that entire path to back up, rather than, say, "/media/raid_array/user_data". If the full path is specified, the script will build a file list and sync "home1", then build the list and sync "home2", then "home3", and so on. If the script encounters an error or is interrupted, the syncing already done won't have to be done a second time. However, if you specify "/media/raid_array/user_data" thinking that it will just get all the homes, it will, but it will have to build a file list for every file in every home directory before it starts copying anything. This can take a VERY long time, depending on the amount of data to be copied.