//
//  LoginViewController.m
//  Wochuke
//
//  Created by he songhang on 13-6-27.
//  Copyright (c) 2013年 he songhang. All rights reserved.
//

#import "LoginViewController.h"
#import "RegiterViewController.h"
#import <Ice/Ice.h>
#import <Guide.h>
#import "ICETool.h"
#import "ShareVaule.h"
#import "AppDelegate.h"
#import "SVProgressHUD.h"
#import <ShareSDK/ShareSDK.h>
#import "NSString+BeeExtension.h"

@interface LoginViewController ()

@end

@implementation LoginViewController{
    NSString *_qqId;
    NSString *_sinaId;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if (_sinaId) {
        [_sinaId release];
        _sinaId = nil;
    }
    if (_qqId) {
        [_qqId release];
        _qqId = nil;
    }
    if ([[ShareVaule shareInstance].tencentOAuth isSessionValid]) {
        _qqId = [[[ShareVaule shareInstance].tencentOAuth openId]retain];
    }
    if([ShareSDK hasAuthorizedWithType:ShareTypeSinaWeibo]){
        [ShareSDK getUserInfoWithType:ShareTypeSinaWeibo
                          authOptions:nil
                               result:^(BOOL result, id<ISSUserInfo> userInfo, id<ICMErrorInfo> error){
                                   if (result) {
                                       NSString *sinaId = userInfo.uid;
                                       _sinaId = [sinaId retain];
                                   }
                               }];
    }

}
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    
    UIImage *backImage = [[UIImage imageNamed:@"bg_register&login_card"]resizableImageWithCapInsets:UIEdgeInsetsMake(12, 12, 12, 12)];
    [_iv_back setImage:backImage];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loginWithName:(NSString *)account andPassword:(NSString *)password
{
    [SVProgressHUD show];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        @try {
            id<JCAppIntfPrx> proxy = [[ICETool shareInstance] createProxy];
            @try {
                JCUser *user = [proxy login:account password:[password MD5]];
                if (user.id_.length>0) {
                    NSMutableDictionary *snsId = (NSMutableDictionary *)user.snsIds;
                    if (_qqId) {
                        [snsId setObject:_qqId forKey:@"qqId"];
                        user.snsIds = snsId;
                        [proxy saveUser:user];
                    }
                    if (_sinaId) {
                        [snsId setObject:_sinaId forKey:@"sinaId"];
                        user.snsIds = snsId;
                        [proxy saveUser:user];
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [SVProgressHUD dismiss];
                        [ShareVaule shareInstance].userId = user.id_;
                        [ShareVaule shareInstance].user = user;
                        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                    });

                }
            }
            @catch (NSException *exception) {
                [SVProgressHUD dismiss];
                if ([exception isKindOfClass:[JCGuideException class]]) {
                    JCGuideException *_exception = (JCGuideException *)exception;
                    if (_exception.reason_) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [SVProgressHUD showErrorWithStatus:_exception.reason_];
                        });
                    }else{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [SVProgressHUD showErrorWithStatus:ERROR_MESSAGE];
                        });
                    }
                }else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [SVProgressHUD showErrorWithStatus:ERROR_MESSAGE];
                    });
                }
            }
            @finally {
                
            }
        }@catch (ICEException *exception) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:@"服务访问异常"];
            });
        }
        
    });
}

- (void)login
{
    if ([_tf_name.text length] == 0) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:nil
                                                     message:@"请输入邮箱或昵称"
                                                    delegate:nil
                                           cancelButtonTitle:@"确定"
                                           otherButtonTitles:nil];
        [av show];
        [av release];
        return;
    }
    if ([_tf_password.text length] == 0) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:nil
                                                     message:@"请输入密码"
                                                    delegate:nil
                                           cancelButtonTitle:@"确定"
                                           otherButtonTitles:nil];
        [av show];
        [av release];
        return;
    }
    [self loginWithName:_tf_name.text andPassword:_tf_password.text];
}

- (void)getUserByKey:(NSString *)idKey idValue:(NSString *)idValue
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        @try {
            id<JCAppIntfPrx> proxy = [[ICETool shareInstance] createProxy];
            @try {
                JCUser *user = [proxy getUserBySns:idKey idValue:idValue];
                if ([user.id_ isEqualToString:@""]) {
                    NSLog(@"getUserByKey QQuser不存在 user.id_ == %@",user.id_);
                    if ([idKey isEqualToString:@"qqId"]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[ShareVaule shareInstance].tencentOAuth getUserInfo];
                        });
                    }
                }else{
                    NSLog(@"getUserByKey QQuser存在 user.id_ == %@",user.id_);
                    NSLog(@"getUserByKey QQuser存在 user.snsIds == %@",user.snsIds);
                    [ShareVaule shareInstance].userId = user.id_;
                    [ShareVaule shareInstance].user = user;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                    });
                }
            }
            @catch (NSException *exception) {
                if ([exception isKindOfClass:[JCGuideException class]]) {
                    JCGuideException *_exception = (JCGuideException *)exception;
                    if (_exception.reason_) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [SVProgressHUD showErrorWithStatus:_exception.reason_];
                        });
                    }else{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [SVProgressHUD showErrorWithStatus:ERROR_MESSAGE];
                        });
                    }
                }else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [SVProgressHUD showErrorWithStatus:ERROR_MESSAGE];
                    });
                }
            }
            @finally {
                
            }
        }@catch (ICEException *exception) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:@"服务访问异常"];
            });
        }
        
    });
}

- (void)regiterByThirdUserInfo:(JCUser *)user idKey:(NSString *)idKey
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        @try {
            id<JCAppIntfPrx> proxy = [[ICETool shareInstance] createProxy];
            @try {
                JCUser *userInfo = [proxy saveUser:user];
                if (userInfo.id_) {
                    NSLog(@"regiterByThirdUserInfo userInfo存在 userInfo.id_ == %@",userInfo.id_);
                    [ShareVaule shareInstance].userId = userInfo.id_;
                    [ShareVaule shareInstance].user = userInfo;
                    NSLog(@"regiterByThirdUserInfo userInfo.id_ == %@",userInfo.id_);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                    });
                } else {
                    NSLog(@"regiterByThirdUserInfo userInfo不存在 userInfo.id_ == %@",userInfo.id_);
                    [SVProgressHUD showErrorWithStatus:@"该用户不存在"];
                }
            }
            @catch (NSException *exception) {
                if ([exception isKindOfClass:[JCGuideException class]]) {
                    JCGuideException *_exception = (JCGuideException *)exception;
                    if (_exception.reason_) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [SVProgressHUD showErrorWithStatus:_exception.reason_];
                        });
                    }else{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [SVProgressHUD showErrorWithStatus:ERROR_MESSAGE];
                        });
                    }
                }else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [SVProgressHUD showErrorWithStatus:ERROR_MESSAGE];
                    });
                }
            }
            @finally {
                
            }
        }@catch (ICEException *exception) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:@"服务访问异常"];
            });
        }
        
    });
}

#pragma mark - IBAction

- (IBAction)backAction:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)regiterAction:(id)sender {
    RegiterViewController *rvc = [[[RegiterViewController alloc] initWithNibName:@"RegiterViewController" bundle:nil] autorelease];
    [self.navigationController pushViewController:rvc animated:YES];
}

- (IBAction)qqLoginAction:(id)sender {
    [ShareVaule shareInstance].tencentOAuth.sessionDelegate = self;
    NSArray *array = [NSArray arrayWithObjects:kOPEN_PERMISSION_GET_USER_INFO, kOPEN_PERMISSION_GET_SIMPLE_USER_INFO, kOPEN_PERMISSION_ADD_ONE_BLOG, nil];
    [[ShareVaule shareInstance].tencentOAuth authorize:array inSafari:NO];
}

- (IBAction)loginAction:(id)sender {
    [self login];
}

- (IBAction)sinaLoginAction:(id)sender {
    [ShareSDK getUserInfoWithType:ShareTypeSinaWeibo
                      authOptions:nil
                           result:^(BOOL result, id<ISSUserInfo> userInfo, id<ICMErrorInfo> error){
                               if (result) {
                                   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                                       @try {
                                           id<JCAppIntfPrx> proxy = [[ICETool shareInstance] createProxy];
                                           @try {
                                               JCUser *user = [proxy getUserBySns:@"sinaId" idValue:userInfo.uid];
                                               if ([user.id_ isEqualToString:@""]) {
                                                   JCUser *jcUserInfo = [[JCUser alloc] init];
                                                   jcUserInfo.name = userInfo.nickname;
                                                   jcUserInfo.avatar.url = userInfo.icon;
                                                   NSDictionary *snsIds = [NSDictionary dictionaryWithObjectsAndKeys:userInfo.uid, @"sinaId", nil];
                                                   jcUserInfo.snsIds = snsIds;
                                                   NSLog(@"sinaLoginAction user不存在 userInfo.uid == %@",userInfo.uid);
                                                   NSLog(@"sinaLoginAction user不存在 user.snsIds == %@",user.snsIds);
                                                   [self regiterByThirdUserInfo:jcUserInfo idKey:@"sinaId"];
                                               }else{
                                                   NSLog(@"sinaLoginAction user存在 user.snsIds == %@",user.snsIds);
                                                   [ShareVaule shareInstance].userId = user.id_;
                                                   [ShareVaule shareInstance].user = user;
                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                       [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                                                   });
                                               }
                                           }
                                           @catch (NSException *exception) {
                                               if ([exception isKindOfClass:[JCGuideException class]]) {
                                                   JCGuideException *_exception = (JCGuideException *)exception;
                                                   if (_exception.reason_) {
                                                       dispatch_async(dispatch_get_main_queue(), ^{
                                                           [SVProgressHUD showErrorWithStatus:_exception.reason_];
                                                       });
                                                   }else{
                                                       dispatch_async(dispatch_get_main_queue(), ^{
                                                           [SVProgressHUD showErrorWithStatus:ERROR_MESSAGE];
                                                       });
                                                   }
                                               }else{
                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                       [SVProgressHUD showErrorWithStatus:ERROR_MESSAGE];
                                                   });
                                               }
                                           }
                                           @finally {
                                               
                                           }
                                       }@catch (ICEException *exception) {
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               [SVProgressHUD showErrorWithStatus:@"服务访问异常"];
                                           });
                                       }
                                   });
                               }else{
                                   [SVProgressHUD showErrorWithStatus:@"新浪微博登录失败"];
                               }
                           }];
}

#pragma mark - UITextField Delegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    [UIView animateWithDuration:0.3 animations:^{
        self.view.frame = CGRectMake(0, -150, self.view.frame.size.width, self.view.frame.size.height);
    }];
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    if (textField == _tf_password) {
        [UIView animateWithDuration:0.3 animations:^{
            self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        }];
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == _tf_name) {
        [_tf_password becomeFirstResponder];
    }else if (textField == _tf_password){
        [_tf_password resignFirstResponder];
        [self login];
    }
    return YES;
}

#pragma mark - TencentSession Delegate

- (void)tencentDidLogin
{
    [self getUserByKey:@"qqId" idValue:[[ShareVaule shareInstance].tencentOAuth openId]];
}

- (void)tencentDidNotLogin:(BOOL)cancelled
{
    
}

- (void)tencentDidNotNetWork
{
    
}

//获取用户个人信息回调
- (void)getUserInfoResponse:(APIResponse *)response
{
    if (response.retCode == URLREQUEST_SUCCEED) {
        JCUser *user = [[JCUser alloc] init];
        user.name = [response.jsonResponse objectForKey:@"nickname"];
        user.avatar.url = [response.jsonResponse objectForKey:@"figureurl"];
        NSDictionary *snsIds = [NSDictionary dictionaryWithObjectsAndKeys:[[ShareVaule shareInstance].tencentOAuth openId], @"qqId", nil];
        user.snsIds = snsIds;
        [self regiterByThirdUserInfo:user idKey:@"qqId"];
    } else {
        
    }
}


- (void)dealloc {
    [_sinaId release];
    [_qqId release];
    [_tf_name release];
    [_tf_password release];
    [_iv_back release];
    [super dealloc];
}
- (void)viewDidUnload {
    [ShareVaule shareInstance].tencentOAuth.sessionDelegate = nil;
    [self setTf_name:nil];
    [self setTf_password:nil];
    [self setIv_back:nil];
    [super viewDidUnload];
}
@end
