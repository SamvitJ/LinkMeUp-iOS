import json
import csv
import os

date = "07:23:15"
emailList = []

with open("/Users/sanjain/Documents/Samvit Jain/LinkMeUp/Exported Parse Data/%s/_User.json" % date) as json_file:
	json_data = json.load(json_file)

	for user in json_data['results']:
		email = user.get('email', None)

		if email is not None:
			emailList.append(email)

print emailList

newDir = "%s" % date

if not os.path.exists(newDir):
	os.makedirs(newDir)

with open("%s/UserEmails.csv" % newDir,"w+") as csvFile:
	writer = csv.writer(csvFile)
	writer.writerow(emailList)

with open("%s/UserEmails.txt" % newDir, "w+") as txtFile:
	for email in emailList:
		txtFile.write("%s\n" % email)
