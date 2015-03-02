//
//  PostsTableViewController.m
//  MELCoda
//
//  Created by Mike Leveton on 3/2/15.
//  Copyright (c) 2015 MEL. All rights reserved.
//

#import "PostsTableViewController.h"
#import "Post.h"

@interface PostsTableViewController ()

@end

@implementation PostsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Recent Articles";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancel:(UIBarButtonItem *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.posts.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"postCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    Post *post = [self.posts objectAtIndex:indexPath.row];
    cell.textLabel.text = post.postTitle;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Post *post = [self.posts objectAtIndex:indexPath.row];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"postSelected" object:post userInfo:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
