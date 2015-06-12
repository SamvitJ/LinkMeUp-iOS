// s.o. 1
NSData *imageData = UIImagePNGRepresentation(newImage);

NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
NSString *documentsDirectory = [paths objectAtIndex:0];

NSString *imagePath =[documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png",@"cached"]];

NSLog((@"pre writing to file"));
if (![imageData writeToFile:imagePath atomically:NO]) 
{
    NSLog((@"Failed to cache image data to disk"));
}
else
{
    NSLog((@"the cachedImagedPath is %@",imagePath)); 
}

NSString *theImagePath = [yourDictionary objectForKey:@"cachedImagePath"];
UIImage *customImage = [UIImage imageWithContentsOfFile:theImagePath];


// s.o. 2
NSString *directory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];


// echoprint
NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
NSString *documentsDirectory = paths[0];
NSURL* destinationURL = [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:@"temp_data"]];
[[NSFileManager defaultManager] removeItemAtURL:destinationURL error:nil];


// s.o. 3

 // saving into documents folder
NSString *dir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]; 
NSString *path = [NSString pathWithComponents:[NSArray arrayWithObjects:dir, @"myImage.png", nil]];

BOOL ok = [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];

if (!ok) 
{
    NSLog(@"Error creating file %@", path);
} 
else 
{
    NSFileHandle* myFileHandle = [NSFileHandle fileHandleForWritingAtPath:path];
   [myFileHandle writeData:UIImagePNGRepresentation(yourImage)];
   [myFileHandle closeFile];
}


 // Loading from Documents folder:

NSFileHandle* myFileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
UIImage* loadedImage = [UIImage imageWithData:[myFileHandle readDataToEndOfFile]];















