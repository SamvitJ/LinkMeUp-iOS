import os 
import json
import sys
import datetime

sys.path.insert(0, '/Users/sanjain/Documents/Samvit Jain/LinkMeUp/Production and Analytics/Data Requests')

from get_class_data import returnClassData

# initialization
mobile_number_list = []
mobile_number_usa_list = []

# get data from Parse
user_data = returnClassData("_User")

# populate mobile_number_list
for user in user_data:

    user_mobile_number = user.get("mobile_number", None)
    user_createdAt = user.get("createdAt", None)

    three_days_ago = datetime.datetime.utcnow() - datetime.timedelta(days=3)

    if user_mobile_number is not None and user_createdAt <= three_days_ago.isoformat():
        print user_mobile_number
        mobile_number_list.append(user_mobile_number)

        # add domestic numbers to mobile_number_usa_list
        isDomestic = False

        if user_mobile_number[:1] == "+":
        	if user_mobile_number[1:2] == "1" and len(user_mobile_number[2:]) == 10:
        		isDomestic = True
        else: 
        	isDomestic = True

        if isDomestic:
        	mobile_number_usa_list.append(user_mobile_number)

print "All numbers - list length: %u" % len(mobile_number_list)
print "USA numbers - list length: %u" % len(mobile_number_usa_list)

# write list to text and json files
newDir = "Mobile Numbers"

if not os.path.exists(newDir):
    os.makedirs(newDir)

with open("%s/mobile_numbers.txt" % newDir, "w+") as text_file:
    for mobile_number in mobile_number_list:
        text_file.write("%s\n" % mobile_number)

with open("%s/mobile_numbers_usa.txt" % newDir, "w+") as text_file:
    for mobile_number in mobile_number_usa_list:
        text_file.write("%s\n" % mobile_number)