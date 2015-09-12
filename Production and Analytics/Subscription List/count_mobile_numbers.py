with open("Mobile Numbers/mobile_numbers_usa.txt", "r") as usa_numbers_file:

    usa_numbers_list = usa_numbers_file.read().splitlines()
    print len(usa_numbers_list)