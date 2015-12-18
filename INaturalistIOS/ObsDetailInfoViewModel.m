//
//  ObsDetailInfoViewModel.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/18/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

@import MapKit;

#import <FontAwesomeKit/FAKIonIcons.h>
#import <UIColor-HTMLColors/UIColor+HTMLColors.h>

#import "ObsDetailInfoViewModel.h"
#import "Observation.h"
#import "DisclosureCell.h"
#import "ObsDetailMapCell.h"
#import "UIColor+ExploreColors.h"
#import "ObsDetailNotesCell.h"
#import "ObsDetailDataQualityCell.h"

@interface ObsDetailInfoViewModel () <MKMapViewDelegate>
@end

@implementation ObsDetailInfoViewModel

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    static NSString *const AnnotationViewReuseID = @"ObservationAnnotationMarkerReuseID";
    
    MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:AnnotationViewReuseID];
    if (!annotationView) {
        annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation
                                                      reuseIdentifier:AnnotationViewReuseID];
        annotationView.canShowCallout = NO;
    }
    
    // style for iconic taxon of the observation
    FAKIcon *mapMarker = [FAKIonIcons iosLocationIconWithSize:35.0f];
    [mapMarker addAttribute:NSForegroundColorAttributeName value:[UIColor colorForIconicTaxon:self.observation.iconicTaxonName]];
    FAKIcon *mapOutline = [FAKIonIcons iosLocationOutlineIconWithSize:35.0f];
    [mapOutline addAttribute:NSForegroundColorAttributeName value:[[UIColor colorForIconicTaxon:self.observation.iconicTaxonName] darkerColor]];
    
    // offset the marker so that the point of the pin (rather than the center of the glyph) is at the location of the observation
    [mapMarker addAttribute:NSBaselineOffsetAttributeName value:@(35.0f)];
    [mapOutline addAttribute:NSBaselineOffsetAttributeName value:@(35.0f)];
    annotationView.image = [UIImage imageWithStackedIcons:@[mapMarker, mapOutline] imageSize:CGSizeMake(35.0f, 70)];
    
    return annotationView;
}

- (void)mapView:(MKMapView *)map didSelectAnnotationView:(MKAnnotationView *)view {
    // do nothing
    return;
}


#pragma mark - UITableView delegate/datasource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < 2) {
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    } else if (indexPath.section == 2) {
        if (indexPath.item == 0) {
            // notes
            ObsDetailNotesCell *cell = [tableView dequeueReusableCellWithIdentifier:@"notes"];
            cell.notesTextView.dataDetectorTypes = UIDataDetectorTypeLink;
            
            NSError *err;
            cell.notesTextView.attributedText = [[NSAttributedString alloc] initWithData:[self.observation.inatDescription dataUsingEncoding:NSUTF8StringEncoding]
                                                                                 options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType }
                                                                      documentAttributes:nil
                                                                                   error:&err];
            
            return cell;
        } else if (indexPath.item == 1) {
            // map
            ObsDetailMapCell *cell = [tableView dequeueReusableCellWithIdentifier:@"map"];
            cell.mapView.delegate = self;
            cell.mapView.userInteractionEnabled = NO;
            
            if (self.observation.latitude.floatValue) {
                CLLocationCoordinate2D coords = CLLocationCoordinate2DMake(self.observation.latitude.floatValue, self.observation.longitude.floatValue);
                CLLocationDistance distance = self.observation.positionalAccuracy.integerValue ?: 500;
                cell.mapView.region = MKCoordinateRegionMakeWithDistance(coords, distance, distance);
                
                MKPointAnnotation *pin = [[MKPointAnnotation alloc] init];
                pin.coordinate = coords;
                pin.title = @"Title";
                [cell.mapView addAnnotation:pin];
            } else {
                cell.mapView.hidden = YES;
            }
            
            if (self.observation.placeGuess && self.observation.placeGuess.length > 0) {
                cell.locationNameLabel.text = self.observation.placeGuess;
            } else {
                cell.locationNameLabel.text = NSLocalizedString(@"No location.", nil);
            }
            
            return cell;
        }
    } else if (indexPath.section == 3) {
        // data quality
        ObsDetailDataQualityCell *cell = [tableView dequeueReusableCellWithIdentifier:@"dataQuality"];
        
        if ([self.observation.qualityGrade isEqualToString:@"research"]) {
            cell.dataQuality = ObsDataQualityResearch;
        } else if ([self.observation.qualityGrade isEqualToString:@"needs_id"]) {
            cell.dataQuality = ObsDataQualityNeedsID;
        } else {
            // must be casual?
            cell.dataQuality = ObsDataQualityCasual;
        }
        
        return cell;
        
    } else if (indexPath.section == 4) {
        // projects
        DisclosureCell *cell = [tableView dequeueReusableCellWithIdentifier:@"disclosure"];
        
        cell.titleLabel.text = NSLocalizedString(@"Projects", nil);
        FAKIcon *project = [FAKIonIcons iosBriefcaseOutlineIconWithSize:44];
        [project addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#777777"]];
        cell.cellImageView.image = [project imageWithSize:CGSizeMake(44, 44)];
        
        cell.secondaryLabel.text = [NSString stringWithFormat:@"%ld", (unsigned long)self.observation.projectObservations.count];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        if (self.observation.projectObservations.count > 0) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        return cell;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"rightDetail"];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
        case 1:
            return [super tableView:tableView titleForHeaderInSection:section];
            break;
        case 3:
            // data quality
            return NSLocalizedString(@"Data Quality", @"Header for data quality section of obs detail");
            break;
        case 2:     // notes/map - no header
        case 4:     // projects - no header
        default:
            return nil;
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
        case 1:
            return [super tableView:tableView heightForHeaderInSection:section];
            break;
        case 3:
        case 4:
            return 34;
            break;
        case 2:
        default:
            return 0;
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < 2) {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    } else if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            // notes
            if (self.observation.inatDescription && self.observation.inatDescription.length > 0) {
                return [self heightForRowInTableView:tableView withBodyText:self.observation.inatDescription];
            } else {
                return CGFLOAT_MIN;
            }
        } else if (indexPath.row == 1) {
            // maps
            return 180;
        }
    } else if (indexPath.section == 3) {
        // data quality
        return 80;
    } else if (indexPath.section == 4) {
        // projects
        return 44;
    }
    
    return CGFLOAT_MIN;
}

- (CGFloat)heightForRowInTableView:(UITableView *)tableView withBodyText:(NSString *)text {
    // 24 for some padding on the left/right
    CGFloat usableWidth = tableView.bounds.size.width - 24;
    CGSize maxSize = CGSizeMake(usableWidth, CGFLOAT_MAX);
    UIFont *font = [UIFont systemFontOfSize:14.0f];
    
    CGRect textRect = [text boundingRectWithSize:maxSize
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:@{ NSFontAttributeName: font }
                                         context:nil];
    
    // 37 for notes label+padding above, and 8 for padding below
    return MAX(44, textRect.size.height + 37 + 8);
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section < 2) {
        return [super tableView:tableView numberOfRowsInSection:section];
    } else if (section == 2) {
        // notes/map
        return 2;
    } else if (section == 3 || section == 4) {
        // data quality, projects
        return 1;
    } else {
        return 0;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // notes/map, data quality, projects
    return [super numberOfSectionsInTableView:tableView] + 3;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < 2) {
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    } else if (indexPath.section == 2) {
        // notes / map
        if (indexPath.item == 1) {
            // map
            // map
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            
            if (self.observation.latitude) {
                // show the map view
                [self.delegate inat_performSegueWithIdentifier:@"map" sender:nil];
            }
        }
    } else if (indexPath.section == 3) {
        // data quality
        // do nothing
    } else if (indexPath.section == 4) {
        // projects
        if (self.observation.projectObservations.count > 0) {
            [self.delegate inat_performSegueWithIdentifier:@"projects" sender:nil];
        }
    }
}

#pragma mark - section type helper

- (ObsDetailSection)sectionType {
    return ObsDetailSectionInfo;
}

@end