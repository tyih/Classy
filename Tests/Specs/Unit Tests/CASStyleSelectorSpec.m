//
//  CASStyleSelectorSpec.m
//  ClassyTests
//
//  Created by Jonas Budelmann on 30/10/13.
//  Copyright (c) 2013 Jonas Budelmann. All rights reserved.
//

#import "CASStyleSelector.h"
#import "UIView+CASAdditions.h"
#import "CASExampleView.h"

/**
 *  Test helper method for making sure we have created correct view hierarchy
 */
NSString * CASStringViewHierarchyFromView(UIView *view) {
    NSMutableString *viewHierarchy = NSMutableString.new;
	for (UIView *ancestor = view; ancestor != nil; ancestor = ancestor.superview) {
        if (ancestor.cas_styleClass.length) {
            [viewHierarchy insertString:[NSString stringWithFormat:@".%@", ancestor.cas_styleClass] atIndex:0];
        }
        [viewHierarchy insertString:[NSString stringWithFormat:@" > %@", NSStringFromClass(ancestor.class)] atIndex:0];
    }
    return [viewHierarchy stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" >"]];
}

SpecBegin(CASStyleSelector)

- (void)testSelectViewClass {
    CASStyleSelector *selector = CASStyleSelector.new;

    selector.viewClass = UIView.class;
    expect(selector.stringValue).to.equal(@"UIView");
    expect([selector shouldSelectView:UIView.new]).to.beTruthy();
    expect([selector shouldSelectView:UISlider.new]).to.beFalsy();

    selector.viewClass = UITabBar.class;
    expect(selector.stringValue).to.equal(@"UITabBar");
    expect([selector shouldSelectView:UITabBar.new]).to.beTruthy();
    expect([selector shouldSelectView:UINavigationBar.new]).to.beFalsy();
}

- (void)testSelectViewWithIndirectSuperview {
    CASStyleSelector *parentSelector = CASStyleSelector.new;
    parentSelector.viewClass = UIControl.class;
    parentSelector.parent = YES;

    CASStyleSelector *selector = CASStyleSelector.new;
    selector.viewClass = UISlider.class;
    selector.parentSelector = parentSelector;

    UIControl *control = UIControl.new;
    UISlider *slider = UISlider.new;
    [control addSubview:slider];

    expect(selector.stringValue).to.equal(@"UIControl UISlider");
    expect([selector shouldSelectView:UIView.new]).to.beFalsy();
    expect([selector shouldSelectView:slider]).to.beTruthy();

    //add view inbetween control and slider
    UIButton *button = UIButton.new;
    button.cas_styleClass = @"styleClassIrrelevantInThisCase";
    [control addSubview:button];
    [button addSubview:slider];

    expect([selector shouldSelectView:slider]).to.beTruthy();
}

- (void)testSelectViewWithDirectSuperviewOnly {
    CASStyleSelector *parentSelector = CASStyleSelector.new;
    parentSelector.viewClass = UIControl.class;
    parentSelector.parent = YES;

    CASStyleSelector *selector = CASStyleSelector.new;
    selector.viewClass = UISlider.class;
    selector.shouldSelectIndirectSuperview = NO;
    selector.parentSelector = parentSelector;

    UIControl *control = UIControl.new;
    UISlider *slider = UISlider.new;
    [control addSubview:slider];

    expect(selector.stringValue).to.equal(@"UIControl > UISlider");
    expect([selector shouldSelectView:UIView.new]).to.beFalsy();
    expect([selector shouldSelectView:slider]).to.beTruthy();

    //add view inbetween control and slider
    UIButton *button = UIButton.new;
    button.cas_styleClass = @"styleClassIrrelevantInThisCase";
    [control addSubview:button];
    [button addSubview:slider];

    expect([selector shouldSelectView:slider]).to.beFalsy();
}

- (void)testSelectViewWithStyleClass {
    CASStyleSelector *selector = CASStyleSelector.new;
    selector.styleClass = @"big";

    selector.viewClass = UIView.class;
    UIView *view = UIView.new;
    expect(selector.stringValue).to.equal(@"UIView.big");
    expect([selector shouldSelectView:view]).to.beFalsy();
    view.cas_styleClass = @"big";
    expect([selector shouldSelectView:view]).to.beTruthy();

    selector.viewClass = UITabBar.class;

    UITabBar *tabBar = UITabBar.new;
    expect(selector.stringValue).to.equal(@"UITabBar.big");
    expect([selector shouldSelectView:tabBar]).to.beFalsy();
    tabBar.cas_styleClass = @"big";
    expect([selector shouldSelectView:tabBar]).to.beTruthy();
}

- (void)testSelectViewWithSubclassMatch {
    CASStyleSelector *selector = CASStyleSelector.new;
    selector.viewClass = UIControl.class;
    selector.shouldSelectSubclasses = YES;

    expect(selector.stringValue).to.equal(@"^UIControl");
    expect([selector shouldSelectView:UIControl.new]).to.beTruthy();
    expect([selector shouldSelectView:UIButton.new]).to.beTruthy();
    expect([selector shouldSelectView:UIView.new]).to.beFalsy();
    expect([selector shouldSelectView:UINavigationBar.new]).to.beFalsy();
}

- (void)testSelectViewWithComplexMixedMatchers {
    CASStyleSelector *parentSelector3 = CASStyleSelector.new;
    parentSelector3.viewClass = UIButton.class;
    parentSelector3.styleClass = @"top";
    parentSelector3.parent = YES;

    CASStyleSelector *parentSelector2 = CASStyleSelector.new;
    parentSelector2.viewClass = UIView.class;
    parentSelector2.shouldSelectSubclasses = YES;
    parentSelector2.shouldSelectIndirectSuperview = NO;
    parentSelector2.parent = YES;
    parentSelector2.parentSelector = parentSelector3;

    CASStyleSelector *parentSelector1 = CASStyleSelector.new;
    parentSelector1.viewClass = UIControl.class;
    parentSelector1.styleClass = @"mid";
    parentSelector1.parent = YES;
    parentSelector1.parentSelector = parentSelector2;

    CASStyleSelector *selector = CASStyleSelector.new;
    selector.viewClass = UISlider.class;
    selector.shouldSelectIndirectSuperview = NO;
    selector.parentSelector = parentSelector1;

    expect(selector.stringValue).to.equal(@"UIButton.top > ^UIView UIControl.mid > UISlider");

    // view heirarchy 1
    UIButton *topButton = UIButton.new;
    topButton.cas_styleClass = @"top";

    UIView *view = UIView.new;
    [topButton addSubview:view];

    UIControl *midControl = UIControl.new;
    midControl.cas_styleClass = @"mid";
    [view addSubview:midControl];

    UISlider *slider = UISlider.new;
    [midControl addSubview:slider];

    expect(CASStringViewHierarchyFromView(slider)).to.equal(@"UIButton.top > UIView > UIControl.mid > UISlider");
    expect([selector shouldSelectView:slider]).to.beTruthy();

    // view heirarchy 2
    [view removeFromSuperview];
    expect(CASStringViewHierarchyFromView(slider)).to.equal(@"UIView > UIControl.mid > UISlider");
    expect([selector shouldSelectView:slider]).to.beFalsy();

    // view heirarchy 3
    UIButton *button = UIButton.new;
    [topButton addSubview:button];

    CASExampleView *exampleView = CASExampleView.new;
    [button addSubview:exampleView];

    [exampleView addSubview:view];
    expect(CASStringViewHierarchyFromView(slider)).to.equal(@"UIButton.top > UIButton > CASExampleView > UIView > UIControl.mid > UISlider");
    expect([selector shouldSelectView:slider]).to.beTruthy();
}

SpecEnd