import json
import httplib, urllib
import dateutil.parser
from operator import itemgetter

import sys
sys.path.insert(0, '/Users/sanjain/Documents/Samvit Jain/LinkMeUp/Production and Analytics/Data Requests')

from get_class_data import returnClassData


# set up httplib connection to request link data
connection = httplib.HTTPSConnection('api.parse.com', 443)
connection.connect()

# get data from Parse
user_data = returnClassData("_User")
link_data = returnClassData("Link")
logs_data = returnClassData("Logs")

# initialization
user_stats_list = []

print "Number of users: %u" % len(user_data) 

# create user_stats_list
for user in user_data:

    # name else username
    user_name = user.get('name', None)

    if user_name is None:
        user_name = user.get('username', None)

    user_stats = {
        "objectId": user.get('objectId', None),
        "name": user_name,
        "links_sent": 0,
        "friends": 0,
        "sessions": 0
        # "verified": (user.get('mobileVerified', None) or (user.get('mobile_number', None) != None))
    }

    user_stats_list.append(user_stats)

# number of links
for link in link_data:

    sender_pointer = link.get('sender', None)
    sender_id = None

    if sender_pointer is not None:
        sender_id = sender_pointer.get('objectId', None)

    if any(user_stats['objectId'] == sender_id for user_stats in user_stats_list):

        index = map(itemgetter('objectId'), user_stats_list).index(sender_id)
        user_stats_list[index]["links_sent"] += 1
 
# number of sessions
for log in logs_data:

    user_pointer = log.get('user', None)
    user_id = None

    if user_pointer is not None:
        user_id = user_pointer.get('objectId', None)

    if any(user_stats['objectId'] == user_id for user_stats in user_stats_list):

        index = map(itemgetter('objectId'), user_stats_list).index(user_id)
        user_stats_list[index]["sessions"] += 1

# number of friends
for user in user_stats_list:

    user_id = user.get('objectId', None)

    # relational query for user's friends
    params = urllib.urlencode({"where":json.dumps({
        "$relatedTo": {
            "object": {
                "__type": "Pointer",
                "className": "_User",
                "objectId": user_id
            },
        "key": "friends"
       }
    })})
    connection.request('GET', '/1/classes/_User?%s' % params, '', {
        "X-Parse-Application-Id": "",
        "X-Parse-REST-API-Key": ""
    })
    response = connection.getresponse()
    result = json.loads(response.read())

    friends_data = result.get('results', None)

    if friends_data is not None:

        user["friends"] = len(friends_data)


# sort user_stats_list    
user_stats_list_links = sorted(user_stats_list, key=itemgetter('links_sent'), reverse=True)
user_stats_list_friends = sorted(user_stats_list, key=itemgetter('friends'), reverse=True) 
user_stats_list_sessions = sorted(user_stats_list, key=itemgetter('sessions'), reverse=True) 

# print list
for user_stats in user_stats_list_links:

    user_name = user_stats.get('name', None)
    user_id = user_stats.get('objectId', None)
    user_links_sent = user_stats.get('links_sent', None)
    user_friends = user_stats.get('friends', None)
    user_sessions = user_stats.get('sessions', None)
    # user_status = user_stats.get('verified', None)

    print "%-25s %s   Links sent: %-4u  Friends: %-3u  Sessions: %-3u" % (user_name[:20], user_id, user_links_sent, user_friends, user_sessions)


# for user in user_data:

#     objectId = user.get('objectId', None)

#     if (objectId == 'QBjQaNUYOW'):

#         # relational query for links sent by this user
#         params = urllib.urlencode({"where":json.dumps({
#             "sender": {
#                 "__type": "Pointer",
#                 "className": "_User",
#                 "objectId": objectId
#             }
#         })})
#         connection.request('GET', '/1/classes/Link?%s' % params, '', {
#             "X-Parse-Application-Id": "",
#             "X-Parse-REST-API-Key": ""
#         })
#         response = connection.getresponse()
#         result = json.loads(response.read())
#         link_data = result.get('results', None)

#         for link in link_data:

#             link_title = link.get('title', None)

#             link_sender = link.get('sender', None)
#             link_sender_id = link_sender.get('objectId', None)

#             link_date_ISO = link.get('createdAt', None)
#             link_datetime = dateutil.parser.parse(link_date_ISO)

#             print "%s  %-70s  %s" % (link_sender_id, link_title[:66], link_datetime)

