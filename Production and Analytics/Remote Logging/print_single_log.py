import sys
import json
import httplib, urllib
import dateutil.parser
import pytz

def printFiltered (log):

    received_requests = "Data.m:382"
    friends = "Data.m:467"
    pending_sent_requests = "Data.m:506"
    friend_suggestions = "Data.m:611"

    ab_not_saved = "Data.m:577"
    fb_not_linked = "Data.m:677"

    connections_loaded = "Data.m:776"

    received_links = "Data.m:911"
    # sent_links = "Data.m:1046"

    links_loaded = "inboxViewController.m:86"

    black_list = [received_requests, friends, pending_sent_requests, friend_suggestions, ab_not_saved, fb_not_linked, connections_loaded, received_links, links_loaded]

    if not any(x in log for x in black_list):
        print "%s" % log

def printSessionLogs (session):

    name = session.get('name', None)
    user_pointer = session.get('user', None)
    user_objectId = None

    if user_pointer is not None:
        user_objectId = user_pointer.get('objectId', None)

    createdAt_ISO = session.get('createdAt', None)
    createdAt_datetime = dateutil.parser.parse(createdAt_ISO)
    createdAt_local = createdAt_datetime.astimezone(pytz.timezone('US/Pacific'))

    print "%-14s %-16s %s" % ((name[:10] if name else None), user_objectId, createdAt_local)
    print "----------------------------------------------------------------"

    messages = session.get('messages', None)

    for log in messages:

        if log[-1] == '\n':
            log = log[:-1]

        # printFiltered (log)
        print "%s" % log

def main (argv):

    if len(argv) > 1:
        logObjectId = argv[1]

    else:
        print "Usage %s - must specify link objectId" % argv[0]
        return

    connection = httplib.HTTPSConnection('api.parse.com', 443)
    connection.connect()
    connection.request('GET', '/1/classes/Logs/%s' % logObjectId, '', {
           "X-Parse-Application-Id": "",
           "X-Parse-REST-API-Key": ""
         })
    result = json.loads(connection.getresponse().read())

    # print result

    print ""
    printSessionLogs (result)  
    print ""

# execute main
if __name__ == "__main__":
    main(sys.argv)
