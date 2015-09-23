# Contest Drawing
#
# Requirements: link must have been sent after 2:27 PM PST on July 22, 2015
#               mobile number area code must be 425 (Eastside), 206 (Seattle), 253 (Tacoma), or 360 (W. Washington)
#               email address need NOT be verified to ENTER contest
#               email address must be verified to be declared a winner
#
# Procedure:    sort contest participants by time of first link sent
#               draw random number for every 20 users in sorted list
#                   - if email verified, declare winner
#                   - if not verified, send personal email to request verification
#                   - if still not verified (after 6 hours), draw another random number for that set of 20 and repeat
#
# Pseudocode:   initialize an array of user objectIds called 'candidates'
#               loop through all links sent after 2:27 PM PST on July 22, 2015
#                   - if sender is NOT equal to ZEQEIkpgPV AND sender is not already contained in 'candidates', 
#                     append sender to 'candidates'
#               initialize an array of PFUsers called 'participants'
#               loop through all objectIds in 'candidates'
#                   - if PFUser corresponding to that objectId has a phone number whose area code is 425 or 206,
#                     add PFUser to 'participants'

import json
import httplib, urllib
import os
import dateutil.parser
import datetime
import pytz
import operator

import sys
sys.path.insert(0, '/Users/sanjain/Documents/Samvit Jain/LinkMeUp/Production and Analytics/Data Requests')

from get_class_data import returnClassData

linksUnsorted = []
linkSorted = []

candidateIdList = []
participantList = []

whiteList = ['aiuSTn5mRz', 'R5Np0HPpBH', 'iLC2RikhL3', 'xUv2Tl56dU', 'Ai2pCedWWS', 'jiflPG7Xd1', 'aftT9aLur9', 'epR9xFDRTh', 'djdZqG7osL', 'TqFUnEDiie', 'umHzK7AkTT'] 
#             supersurb,    Anand N.,     Andrew W.,    Tristan H.,   Caren B.,     Adarsh K.,    Justin B.,    akritish,     Sai G.,       Devansh K.,   Ishan N.     

blackList = ['ZRbJayScs3', 'QBjQaNUYOW', 'e4AmThaawe', '4RH2O9bjTN', 'oaluUW5QPZ', 'Ok4Jhbxqen', 'TvXEq0Bl0d', 'V71YkER7ka', 'X0qvVAfjgw', 'UNF2h9Uyg1', '7ea3cG2b80', 't8DgS2nJ0i', '0NSA1byi10', 'do1CSgzC09', 'FEoK16gQPb']
#             Samvit J.,    Ananya J.,    Sanjay J.,    Vishakha A.,  Sunny B.,     Little P.,    Alex M.,      Ishan R.,     Meg H.,       Jacob K.,     Nick W.,      Deena S.      Jihoon L.     David A. H.   Sanjay J.

start_date = datetime.datetime(2015, 7, 22, 2, 27, 00, tzinfo=pytz.utc)
# file_date = "07:23:15"

link_data = returnClassData("Link")
# with open("/Users/sanjain/Documents/Samvit Jain/LinkMeUp/Exported Parse Data/%s/Link.json" % file_date) as link_json:
#     link_data = json.load(link_json)

print "\nUnsorted links\n--------------"

for link in link_data:

    link_title = link.get('title', None)

    link_sender = link.get('sender', None)
    link_sender_id = link_sender.get('objectId', None)

    link_date_ISO = link.get('createdAt', None)
    link_datetime = dateutil.parser.parse(link_date_ISO)

    # print "%s %70s %s" % (link_sender_id, link_title, link_datetime)

    if link_datetime > start_date:

        linksUnsorted.append(link)

        print "%s  %-70s  %s" % (link_sender_id, link_title[:66], link_datetime)

linksSorted = sorted(linksUnsorted, key = operator.itemgetter('createdAt'))

print "\nSorted links\n--------------"

for link in linksSorted:

    link_title = link.get('title', None)

    link_date_ISO = link.get('createdAt', None)
    link_datetime = dateutil.parser.parse(link_date_ISO)

    link_sender = link.get('sender', None)
    link_sender_id = link_sender.get('objectId', None)

    if (link_sender_id != 'ZEQEIkpgPV' and link_sender_id not in candidateIdList):
        candidateIdList.append(link_sender_id)

    print "%s  %-70s  %s" % (link_sender_id, link_title[:66], link_datetime.astimezone(pytz.timezone('US/Pacific')))

print

print candidateIdList

print "\nCandidates\n--------------"

user_data = returnClassData("_User")
# with open("/Users/sanjain/Documents/Samvit Jain/LinkMeUp/Exported Parse Data/%s/_User.json" % file_date) as user_json:
#     user_data = json.load(user_json)
#     user_list = user_data['results']

for candidateId in candidateIdList:

    for user in user_data:

        # objectId
        user_id = user.get('objectId', None)

        if (candidateId == user_id):

            # name else username
            user_name = user.get('name', None)

            if user_name is None:
                user_name = user.get('username', None)

            # mobile phone number
            user_phone = user.get('mobile_number', None)

            print "%-20s %-20s %-20s" % (user_name[:16], user_id, user_phone)

            # check if Greater Seattle Area resident
            if user_phone is not None:

                if ((user_phone[0:3] == '425' or user_phone[0:4] == '1425' or user_phone[0:5] == '+1425' or
                     user_phone[0:3] == '206' or user_phone[0:4] == '1206' or user_phone[0:5] == '+1206' or
                     user_phone[0:3] == '253' or user_phone[0:4] == '1253' or user_phone[0:5] == '+1253' or
                     user_phone[0:3] == '360' or user_phone[0:4] == '1360' or user_phone[0:5] == '+1360')
                    and user_id not in blackList):

                    participantList.append(user)

                elif user_id in whiteList: # non-Seattle area code, but lives in Seattle area

                    participantList.append(user)

            elif user_id in whiteList: # no phone number provided, but lives in Seattle area

                participantList.append(user)

print "\nParticipants\n--------------"

for participant in participantList:

    # objectId
    participant_id = participant.get('objectId', None)

    # name else username
    participant_name = participant.get('name', None)

    if participant_name is None:
        participant_name = participant.get('username', None)

    print "%-20s %-20s" % (participant_name[:16], participant_id)

print


