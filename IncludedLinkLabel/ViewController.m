//
//  ViewController.m
//  IncludedLinkLabel
//
//  Created by Jung Giuk on 2013/02/10.
//  Copyright (c) 2013年 Jung Giuk. All rights reserved.
//

#import "ViewController.h"
#import "IncludedLinkTabelViewCell.h"

@interface ViewController ()
@property (nonatomic, strong) NSArray *contents;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"CellContents" ofType:@"txt"];
    self.contents = [[NSString stringWithContentsOfFile:filePath usedEncoding:nil error:nil] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_contents count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [IncludedLinkTabelViewCell heightForCellWithText:[_contents objectAtIndex:indexPath.row]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";

    IncludedLinkTabelViewCell *cell = (IncludedLinkTabelViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[IncludedLinkTabelViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }

    NSString *description = [_contents objectAtIndex:indexPath.row];
    cell.descriptionText = description;
    cell.descriptionLabel.delegate = self;
    cell.descriptionLabel.userInteractionEnabled = YES;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - IncludedLinkLabelDelegate

- (void)includedLinkLabel:(IncludedLinkLabel *)label didSelectLinkWithURL:(NSURL *)url {
    [[[UIActionSheet alloc] initWithTitle:[url absoluteString] delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Open Link in Safari", nil), nil] showInView:self.view];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:actionSheet.title]];
}

@end
