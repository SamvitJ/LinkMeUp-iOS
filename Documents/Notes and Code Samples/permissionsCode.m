[FBRequestConnection startWithGraphPath:@"/me/permissions"
                             parameters:nil
                             HTTPMethod:@"GET"
                      completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
    
    // check that user granted appropriate permissions
    NSArray *permissions = (NSArray *)result[@"data"];
    NSLog(@"%@", permissions);
      
    NSDictionary *email_perm = permissions[1];
    NSDictionary *friends_perm = permissions[2];
      
    if ([email_perm[@"status"] isEqual:@"declined"] || [friends_perm[@"status"] isEqual:@"declined"])
    {
        [PFFacebookUtils unlinkUser:me];
    }
}];