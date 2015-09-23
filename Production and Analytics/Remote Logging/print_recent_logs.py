import json
import httplib, urllib

import sys
sys.path.insert(0, '/Users/sanjain/Documents/Samvit Jain/LinkMeUp/Production and Analytics/Data Requests')

from get_class_data import returnClassData
from print_single_log import printSessionLogs, printFiltered

def main (argv):

    if len(argv) > 1: 
        logObjectId = argv[1]

    else:
        print "Usage %s - must specify number of logs to print" % argv[0]
        return

    connection = httplib.HTTPSConnection('api.parse.com', 443)
    params = urllib.urlencode({"limit": argv[1],"skip": 0, "order": "-createdAt"})
    connection.connect()
    connection.request('GET', '/1/classes/Logs?%s' % params, '', {
           "X-Parse-Application-Id": "",
           "X-Parse-REST-API-Key": ""
         })
    result = json.loads(connection.getresponse().read())
    request_data = result.get('results', None)

    # print request_data

    # if non-empty array, print newline
    if len(request_data):
        print

    for session in request_data:

        printSessionLogs(session)

        print

# execute main
if __name__ == "__main__":
    main(sys.argv)
