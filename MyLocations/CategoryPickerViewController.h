//
//  CategoryPickerViewController.h
//  MyLocations
//
//  Created by Zhang Honghao on 2/1/14.
//  Copyright (c) 2014 org-honghao. All rights reserved.
//

@class CategoryPickerViewController;

@protocol CategoryPickerViewControllerDelegate <NSObject>

- (void)categoryPicker:(CategoryPickerViewController *)picker didPickCategory:(NSString *)categoryName;

@end

@interface CategoryPickerViewController : UITableViewController

@property (nonatomic, weak) id <CategoryPickerViewControllerDelegate> delegate;
@property (nonatomic, strong) NSString *selectedCategoryName;

@end
