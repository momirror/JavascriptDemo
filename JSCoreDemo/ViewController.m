//
//  ViewController.m
//  JSCoreDemo
//
//  Created by msp on 2018/3/28.
//  Copyright © 2018年 . All rights reserved.
//

#import "ViewController.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import <objc/runtime.h>

@interface ViewController ()
@property(nonatomic,strong)JSContext *context;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [self getJSBundleVersion];
    [self addView];
}


/**
 读取JSBundle中的自定义版本号信息
 */
- (void) getJSBundleVersion  {
    NSString * path = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"jsbundle"];
    NSString * jsContent = [[NSString alloc] initWithContentsOfFile:path];
    NSLog(@"content=>%@",jsContent);
    
    JSContext * context = [[JSContext alloc] init];
    JSValue * value;
    [context evaluateScript:jsContent];
    value = [context evaluateScript:@"testVersion"];
    NSLog(@"%@",[value toString]);
}


/**
 js调用native函数，创建一个view
 */
- (void)addView {
    
    _context = [[JSContext alloc] init];
    
    _context.exceptionHandler = ^(JSContext *con, JSValue *exception) {
        NSLog(@"%@", exception);
        con.exception = exception;
    };
    
    __weak typeof(self) weakSelf = self;
    
    
    /**
     注册addView函数给JS调用
     */
    _context[@"addView"] = ^() {
        
        
        NSArray *args = [JSContext currentArguments];
        
        //参数不固定，需要循环获取
        for (JSValue *jsVal in args) {
            NSLog(@"%@", [jsVal toDictionary]);
        }
        
        NSDictionary * params = [args[0] toDictionary];
        UIView * view = [[UIView alloc] init];
        view.frame = CGRectMake([params[@"x"] floatValue], [params[@"y"] floatValue], [params[@"width"] floatValue], [params[@"height"] floatValue]);
        view.backgroundColor = [UIColor redColor];
        [weakSelf.view addSubview:view];
        
        UIButton * btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(0, 20, 100, 30);
        btn.backgroundColor = [UIColor blueColor];
        [btn setTitle:@"调用JS" forState:UIControlStateNormal];
        [btn addTarget:weakSelf action:@selector(callJS) forControlEvents:UIControlEventTouchUpInside];
        [view addSubview:btn];

        
    };
    
    
    /**
     注册log函数给js调用
     */
    _context[@"log"] = ^() {
        
        NSArray *args = [JSContext currentArguments];
        for (JSValue *jsVal in args) {
            NSLog(@"%@", jsVal);
        }
    };
    
    
    [_context evaluateScript:@"var index = 10;"];
    [_context evaluateScript:@"function addIndex(){index++; log(index);}"];
    [_context evaluateScript:@"addView({x:100,y:100,width:100,height:100});"];
}

- (void)callJS {
    
    [_context evaluateScript:@"addIndex();"];;
}


- (NSDictionary*)objToDic:(id)obj {
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    unsigned int propsCount;
    
    objc_property_t *props = class_copyPropertyList([obj class], &propsCount);
    
    for(int i = 0;i < propsCount; i++) {
        
        objc_property_t prop = props[i];
        NSString *propName = [NSString stringWithUTF8String:property_getName(prop)];
        id value = [obj valueForKey:propName];
        if(value == nil) {
            
            value = [NSNull null];
        } else {
            value = [self getObjectInternal:value];
        }
        [dic setObject:value forKey:propName];
    }
    
    return dic;
}

- (id)getObjectInternal:(id)obj {
    
    if([obj isKindOfClass:[NSString class]]
       ||
       [obj isKindOfClass:[NSNumber class]]
       ||
       [obj isKindOfClass:[NSNull class]]) {
        
        return obj;
        
    }
    if([obj isKindOfClass:[NSArray class]]) {
        
        NSArray *objarr = obj;
        NSMutableArray *arr = [NSMutableArray arrayWithCapacity:objarr.count];
        
        for(int i = 0; i < objarr.count; i++) {
            
            [arr setObject:[self getObjectInternal:[objarr objectAtIndex:i]] atIndexedSubscript:i];
        }
        return arr;
    }
    if([obj isKindOfClass:[NSDictionary class]]) {
        
        NSDictionary *objdic = obj;
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:[objdic count]];
        
        for(NSString *key in objdic.allKeys) {
            
            [dic setObject:[self getObjectInternal:[objdic objectForKey:key]] forKey:key];
        }
        return dic;
    }
    return [self objToDic:obj];
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
