import os 
import csv
import sys

sys.path.insert(0, '/Users/sanjain/Documents/Samvit Jain/LinkMeUp/Production and Analytics/Data Requests')

from get_class_data import returnClassData

# initialization
email_list = []

# get data from Parse
user_data = returnClassData("_User")

# populate phone_number_list
for user in user_data:

    user_email = user.get("email", None)

    if user_email is None:
    	user_email = user.get("facebook_email", None)

    if user_email is not None:
    	print user_email
        email_list.append(user_email)

print "List length: %u" % len(email_list)

# write list to text and csv files
newDir = "Emails"

if not os.path.exists(newDir):
    os.makedirs(newDir)

with open("%s/emails.txt" % newDir, "w+") as text_file:
    for email in email_list:
        text_file.write("%s\n" % email)

with open("%s/emails.csv" % newDir,"w+") as csv_file:
    writer = csv.writer(csv_file)
    writer.writerow(email_list)