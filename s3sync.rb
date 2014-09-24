#!/usr/bin/ruby -w

# S3 Sync command template below. Dont forget to add --delete on the end when building the command.

# This script depends on having AWS command line tools installed on the system in question.

# aws s3 sync /data/somefolder s3://<s3bucket>/data/somefolder/ --exclude '.DS_Store' --exclude '*/.DS_Store' --exclude 'Thumbs.db' --exclude '*/Thumbs.db' --exclude '.apdisk' --exclude '*/.apdisk' --exclude '.AppleDB/*' --exclude '*/.AppleDB/*' --exclude '.AppleDesktop/*' --exclude '*/.AppleDesktop/*' --exclude '.AppleDouble/*' --exclude '*/.AppleDouble/*' --exclude '.TemporaryItems/*' --exclude '*/.TemporaryItems/*' --exclude '._*' --exclude '*/._*' --exclude '~$*' --exclude '*/~$*' --delete

# Set up necessary variables ------------------------------------------------------------------------------------------

# Place directories to back up in this array. Just add more in and they will
# be backed up the next time the script runs. Directories require a trailing slash.
# e.g. "/data/home/"

@dirs_array = ["/data/"]

# long list of excludes for the 'aws s3 sync' command. 
# Placed here so they only need to be typed out once and can be modified in a single place.
# Feel free to add to or subtract from the list as necessary. This list of excludes skips
# most of the unnecessary files you'd find on a NAS in a typical office. Adjust as needed.
@excludes = "--exclude '.DS_Store' --exclude '*/.DS_Store' --exclude 'Thumbs.db' --exclude '*/Thumbs.db' --exclude '.apdisk' --exclude '*/.apdisk' --exclude '.AppleDB/*' --exclude '*/.AppleDB/*' --exclude '.AppleDesktop/*' --exclude '*/.AppleDesktop/*' --exclude '.AppleDouble/*' --exclude '*/.AppleDouble/*' --exclude '.TemporaryItems/*' --exclude '*/.TemporaryItems/*' --exclude '._*' --exclude '*/._*' --exclude '~$*' --exclude '*/~$*'"





# Method definitions --------------------------------------------------------------------------------------------------


# sync individual directories passed to this method to the readynas s3 bucket.
def sync_dir_to_s3(local_dir)

	# escape spaces in paths
	local_dir = local_dir.gsub(' ', '\ ')

	s3path = "s3://<s3bucket>" + local_dir 

	# use 'cp' if it's a file. 'sync' only works with directories.
	if File.file?(local_dir)

		s3command = "aws s3 cp " + local_dir + " " + s3path

	else

		s3command = "aws s3 sync " + local_dir + " " + s3path + " " + @excludes + " --delete"

	end

	begin		
		
		s3_out = `#{s3command}`.split("\n") # Split s3command on newlines, so each can be output as it's own line.

		# if the output of the command is a blank string, it's because 'sync' found nothing to sync.
		if s3_out.count == 0

			`/bin/echo '#{Time.now}: Skipping #{local_dir}, no changes necessary.' >> /path/to/log/s3sync.log`

		else

			`/bin/echo #{Time.now}: >> /path/to/log/s3sync.log`

			# aws s3 sync gives constant updates to stdout in the form of "completed X of Y parts with Z file(s) remaining".
			# This output can become large enough to choke `echo` when outputting to the logs. All we want is the end of the 
			# string, the part that tells us what file was either uploaded or deleted. e.g. "delete: s3://<s3bucket>/somefolder/somefile.jpg"
			# snatch it with regex and output that part only.
			s3_out.each do |line|

				clean_line = line.match(/((?:upload|delete):+.*$)/)

				# if clean_line is nil, no match was found.
				next if clean_line == nil

				# echo the first match group to the log.
				`/bin/echo '    #{clean_line[1]}' >> /path/to/log/s3sync.log`

			end

		end

	rescue Exception => e

		`/bin/echo '#{Time.now}: Script error: #{e}' >> /path/to/log/s3sync.log`

	end
	


end







# Begin script --------------------------------------------------------------------------------------------------------

`echo \"--------------- #{Time.now}: Beginning sync to S3 Storage ---------------\" >> /path/to/log/s3sync.log`

# Set up the specified directories to be synced to s3,
# skipping dotfiles and other extraneous bullshit.

# Breaking the sync into subfolders means the entire sync
# process isn't interrupted if there's an error or the script is
# interrupted. Also, the script starts syncing files much more quickly
# when it's broken into pieces because it doesn't have to build a file comparison
# list for the ENTIRE tree when it starts, just each time it parses a subfolder.
# An additional benefit is that if a subdir is deleted entirely, it won't be checked
# against the files to sync. Hence, an archived copy will remain in the s3 bucket.
# Example: if we're syncing /data, and /data/images is inadvertantly deleted from the 
# NAS, /data/images is no longer a subdir of /data/ and won't be passed to the method that
# actually runs the s3 sync. Since it never gets checked against the bucket, the bucket's 
# copy will remain intact until deliberately deleted from S3.


@dirs_array.each do |d|

	Dir.foreach(d) { |subdir|

		subdir_path = File.expand_path(d + subdir)

		next if subdir == "."
		next if subdir == ".."
		next if subdir =~ /^\..*/

		# Pass the subdir_path off to the sync method.
		sync_dir_to_s3(subdir_path)

	}
	
end

`echo \"--------------- #{Time.now}: S3 sync completed. ---------------\" >> /path/to/log/s3sync.log`

exit