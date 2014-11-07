//
//  MRTImageCollectionViewCell.m
//  PicsNearMe
//
//  Created by Michele Titolo on 5/16/14.
//  Copyright (c) 2014 Michele Titolo. All rights reserved.
//

#import "MRTImageCollectionViewCell.h"
#import <SDWebImage/UIImageView+WebCache.h>

@implementation MRTImageCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setImageWithURLString:(NSString *)string
{
    [self.imageView sd_setImageWithURL:[NSURL URLWithString:string] placeholderImage:nil options:SDWebImageRetryFailed];
}

- (void)prepareForReuse
{
    [self.imageView sd_cancelCurrentImageLoad];
}

@end
