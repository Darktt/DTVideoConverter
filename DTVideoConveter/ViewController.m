//
//  ViewController.m
//  DTVideoConveter
//
//  Created by EdenLi on 2016/3/11.
//  Copyright © 2016年 Darktt. All rights reserved.
//

#import "ViewController.h"
#import "DTVideoConverter.h"
#import "DTFileController.h"

@import MobileCoreServices;

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (copy) NSString *destinationPath;

- (IBAction)launchImagePickerAction:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Action

- (void)launchImagePickerAction:(id)sender
{
    UIImagePickerController *picker = [UIImagePickerController new];
    [picker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [picker setMediaTypes:@[(__bridge NSString *)kUTTypeMovie]];
    [picker setAllowsEditing:NO];
    [picker setDelegate:self];
    
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - Other Methods

- (void)convertVideoWithPath:(NSString *)path
{
    DTFileController *fileController = [DTFileController mainController];
    
    if (self.destinationPath == nil) {
        NSString *destinationPath = [fileController cachesPathWithFileName:@"temp.mp4"];
        [self setDestinationPath:destinationPath];
    }
    
    if ([fileController fileExistAtPath:self.destinationPath]) {
        [fileController removeFileAtPath:self.destinationPath];
    }
    
    DTVideoConverterProgressHandler progressHandler = ^(float progress) {
        NSLog(@"Process, %.0f %% Done", progress * 100.0f);
    };
    
    typeof(self) __weak weakSelf = self;
    DTVideoConverterCompletionHandler completionHandler = ^(NSError *error){
        if (error != nil) {
            NSLog(@"Error: %@", error);
            
            return;
        }
        
        NSString *title = @"Convert Finished";
        NSString *message = @"Video is finish convert, choice an action.";
        
        [weakSelf presentActionSheetWithTitle:title message:message];
    };
    
    DTVideoConverter *converter = [DTVideoConverter videoConverterWithSourcePath:path];
    [converter setDestinationPath:self.destinationPath];
    [converter setExportQuality:AVAssetExportPresetHighestQuality];
    [converter setOutputFileType:AVFileTypeMPEG4];
    [converter setProgressHandler:progressHandler];
    [converter startConvertWithCompletionHandler:completionHandler];
}

- (void)presentActionSheetWithTitle:(NSString *)title message:(NSString *)message
{
    typeof(self) __weak weakSelf = self;
    void (^alertActionHandler) (UIAlertAction *) = ^(UIAlertAction *action) {
        [weakSelf presentActivityViewController];
    };
    
    UIAlertAction *activityAction = [UIAlertAction actionWithTitle:@"Show activity" style:UIAlertActionStyleDefault handler:alertActionHandler];
    
    UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleCancel handler:nil];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:activityAction];
    [alertController addAction:doneAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)presentActivityViewController
{
    NSURL *fileURL = [NSURL fileURLWithPath:self.destinationPath];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[fileURL] applicationActivities:nil];
    
    [self presentViewController:activityViewController animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    NSURL *mediaURL = info[UIImagePickerControllerMediaURL];
    
    DTFileController *fileController = [DTFileController mainController];
    NSString *sourcePath = [fileController cachesPathWithFileName:@"source.mov"];
    
    if ([fileController fileExistAtPath:sourcePath]) {
        [fileController removeFileAtPath:sourcePath];
    }
    
    [fileController moveFileAtPath:mediaURL.path toPath:sourcePath];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self convertVideoWithPath:sourcePath];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
