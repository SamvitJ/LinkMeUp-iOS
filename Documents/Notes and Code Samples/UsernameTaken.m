if (error.code == 202)
{
    NSLog(@"Username is taken");
    
    PFQuery *userQuery = [PFUser query];
    [userQuery whereKey:@"email" equalTo:fbUser[@"email"]];
    [userQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if ([objects count])
        {
            NSLog(@"Email is also taken");
            
            [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:kDidCreateAccountWithSameEmail];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            me.username = oldUsername;
            me.email = nil;
            me[@"facebook_email"] = fbUser[@"email"];
            
            [me saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (error)
                {
                    NSLog(@"Error saving user info to Parse (after discovering existing account with same username AND email) %@ %@", error, [error userInfo]);
                }
            }];
        }
        else
        {
            if ([newUsername isEqualToString:fbUser[@"email"]])
            {
                me.username = [NSString stringWithFormat:@"%@%@", fbUser.first_name, fbUser.last_name];
                
                [me saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (error)
                    {
                        NSLog(@"Error saving user info to Parse (after setting username to full name) %@ %@", error, [error userInfo]);
                    }
                }];
            }
            else // username was set to full name, because email permission was denied
            {
                // set username to name + first three digits of FB id
                me.username = [NSString stringWithFormat:@"%@%@%@",
                               fbUser.first_name, fbUser.last_name, [fbUser[@"id"] substringToIndex: 3]];
                
                [me saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (error)
                    {
                        NSLog(@"Error saving user info to Parse (after setting username to full name + FB id) %@ %@", error, [error userInfo]);
                    }
                }];
            }
        }
    }];
}
