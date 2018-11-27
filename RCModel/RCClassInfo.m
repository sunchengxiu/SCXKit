//
//  RCClassInfo.m
//  RCModel
//
//  Copyed and modified by 孙承秀 on 2018/10/15.
//  Thank you for YY
//  YYKit <https://github.com/ibireme/YYKit>
//
//  Created by ibireme on 15/5/9.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "RCClassInfo.h"
RCEncodingType RCGetEncodingType(const char *encodingType){
    char *type = (char *)encodingType;
    if (!type) {
        return RCEncodingTypeUnknow;
    }
    size_t size = strlen(type);
    if (size == 0) {
        return RCEncodingTypeUnknow;
    }
    RCEncodingType qualifier = 0;
    bool prefix = true;
    while (prefix) {
        switch (*type) {
            case 'r':
            {
                qualifier |= RCEncodingTypeQualifierConst;
                type ++;
            }
                break;
            case 'n':
            {
                qualifier |= RCEncodingTypeQualifierIn;
                type ++;
            }
                break;
            case 'N':
            {
                qualifier |= RCEncodingTypeQualifierInout;
                type ++;
            }
                break;
            case 'o':
            {
                qualifier |= RCEncodingTypeQualifierOut;
                type ++;
            }
                break;
            case 'O':
            {
                qualifier |= RCEncodingTypeQualifierBycopy;
                type ++;
            }
                break;
            case 'R':
            {
                qualifier |= RCEncodingTypeQualifierByref;
                type ++;
            }
                break;
            case 'V':
            {
                qualifier |= RCEncodingTypeQualifierOneway;
                type ++;
            }
                break;
                
            default:
            {
                prefix = false;
            }
                break;
        }
    }
    size = strlen(type);
    if (size == 0) {
        return qualifier | RCEncodingTypeUnknow;
    }
    switch (*type) {
        case 'v':
            return qualifier | RCEncodingTypeVoid;
        case 'B':
            return qualifier | RCEncodingTypeBool;
        case 'c':
            return qualifier | RCEncodingTypeInt8;
        case 'C':
            return qualifier | RCEncodingTypeUInt8;
        case 's':
            return qualifier | RCEncodingTypeInt16;
        case 'S':
            return qualifier | RCEncodingTypeUInt16;
        case 'i':
            return qualifier | RCEncodingTypeInt32;
        case 'I':
            return qualifier | RCEncodingTypeUInt32;
        case 'l':
            return qualifier | RCEncodingTypeInt32;
        case 'L':
            return qualifier | RCEncodingTypeUInt32;
        case 'q':
            return qualifier | RCEncodingTypeInt64;
        case 'Q':
            return qualifier | RCEncodingTypeUInt64;
        case 'f':
            return qualifier | RCEncodingTypeFloat;
        case 'd':
            return qualifier | RCEncodingTypeDouble;
        case 'D':
            return qualifier | RCEncodingTypeLongDouble;
        case '#':
            return qualifier | RCEncodingTypeClass;
        case ':':
            return qualifier | RCEncodingTypeSEL;
        case '*':
            return qualifier | RCEncodingTypeCString;
        case '^':
            return qualifier | RCEncodingTypePointer;
        case '[':
            return qualifier | RCEncodingTypeCArray;
        case '(':
            return qualifier | RCEncodingTypeUnion;
        case '{':
            return qualifier | RCEncodingTypeStruct;
        case '@':
        {
            if (size == 2 && *(type + 1) == '?') {
                return RCEncodingTypeBlock | qualifier;
            } else {
                return qualifier | RCEncodingTypeObject;
            }
        }
        default:
            return qualifier | RCEncodingTypeUnknow;
            break;
    }
}


@implementation RCObjc_ivar
-(instancetype)initWithIvar:(Ivar)ivar{
    if (!ivar) {
        return nil;
    }
    self = [super init];
    _ivar = ivar;
    // 获取名字
    const char *ivar_name = ivar_getName(ivar);
    if (ivar_name) {
        _name = [NSString stringWithUTF8String:ivar_name];
    }
    // 获取偏移量
    _offset = ivar_getOffset(ivar);
    // 获取编码
    const char *typeEncoding = ivar_getTypeEncoding(ivar);
    if (typeEncoding) {
        _typeEncoding = [NSString stringWithUTF8String:typeEncoding];
        _type = RCGetEncodingType(typeEncoding);
    }
    return self;
}
@end

@implementation RCObjc_method

-(instancetype)initWithMethod:(Method)method{
    if (!method) {
        return nil;
    }
    self = [super init];
    // 方法
    _method = method;
    // 方法名字
    _sel = method_getName(method);
    const char *selName = sel_getName(_sel);
    if (selName) {
        _name = [NSString stringWithUTF8String:selName];
    }
    // 方法实现
    _imp = method_getImplementation(method);
    // 类型编码
    const char *typeEncoding = method_getTypeEncoding(method);
    if (typeEncoding) {
        _typeEncoding = [NSString stringWithUTF8String:typeEncoding];
    }
    // 返回值类型
    char *returnType = method_copyReturnType(method);
    if (returnType) {
        _returnTypeEncoding = [NSString stringWithUTF8String:returnType];
        free(returnType);
    }
    // 参数类型
    unsigned int argCount = method_getNumberOfArguments(method);
    if (argCount > 0) {
        NSMutableArray *argTypes = [NSMutableArray array];
        for (unsigned int i = 0 ; i < argCount; i ++) {
            char *type = method_copyArgumentType(method, i);
            NSString *typeEncoding = type ? [NSString stringWithUTF8String:type] : nil;
            [argTypes addObject:typeEncoding?typeEncoding:@""];
            if (type) {
                free(type);
            }
        }
        _argumentTypeEncodings = argTypes;
    }
    return self;
}

@end

@implementation RCObjc_property

-(instancetype)initWithProperty:(objc_property_t)property{
    if (!property) {
        return nil;
    }
    self = [super init];
    _property = property;
    const char *name = property_getName(property);
    if (name) {
        _name = [NSString stringWithUTF8String:name];
    }
    unsigned int count ;
    objc_property_attribute_t *att = property_copyAttributeList(property, &count);
    RCEncodingType type = 0;
    for (unsigned int i = 0 ; i < count; i ++) {
        objc_property_attribute_t attribute = att[i];
        switch (attribute.name[0]) {
            case 'T':
            {
                if (attribute.value) {
                    _typeEncoding = [NSString stringWithUTF8String:attribute.value];
                    type = RCGetEncodingType(attribute.value);
                    if ((type & RCEncodingTypeMask) == RCEncodingTypeObject && _typeEncoding.length) {
                        NSScanner *scanner = [NSScanner scannerWithString:_typeEncoding];
                        // 是否以@\开头
                        if (![scanner scanString:@"@\"" intoString:NULL]) {
                            continue;
                        }
                        NSString *temp;
                        // 先是扫面类名
                        if ([scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\"<"] intoString:&temp]) {
                            if (temp) {
                                _cls = objc_getClass(temp.UTF8String);
                            }
                        }
                        // 后面跟着协议，接着上面的类名继续向下扫描协议，每<>是一对
                        NSMutableArray *protocols = [NSMutableArray array];
                        while ([scanner scanString:@"<" intoString:NULL]) {
                            NSString *protocol ;
                            if ([scanner scanUpToString:@">" intoString:&protocol]) {
                                if (protocol) {
                                    [protocols addObject:protocol];
                                }
                            }
                            [scanner scanString:@">" intoString:NULL];
                        }
                        _protocols = protocols;
                    }
                }
            }
                break;
            case 'V':
            {
                if (attribute.value) {
                    _ivarName = [NSString stringWithUTF8String:attribute.value];
                }
            }
                break;
            case 'R':
            {
                type |= RCEncodingTypePropertyReadonly;
            }
                break;
            case 'C':
            {
                type |= RCEncodingTypePropertyCopy;
            }
                break;
            case '&':
            {
                type |= RCEncodingTypePropertyRetain;
            }
                break;
            case 'N':
            {
                type |= RCEncodingTypePropertyNonatomic;
            }
                break;
            case 'D':
            {
                type |= RCEncodingTypePropertyDynamic;
            }
                break;
            case 'W':
            {
                type |= RCEncodingTypePropertyWeak;
            }
                break;
            case 'G':
            {
                type |= RCEncodingTypePropertyCustomGetter;
                if (attribute.value) {
                    _getter = NSSelectorFromString([NSString stringWithUTF8String:attribute.value]);
                }
                
            }
                break;
            case 'S':
            {
                type |= RCEncodingTypePropertyCustomSetter;
                if (attribute.value) {
                    _setter = NSSelectorFromString([NSString stringWithUTF8String:attribute.value]);
                }
            }
                break;
                
            default:
                break;
        }
    }
    if (att) {
        free(att);
        att = nil;
    }
    _type = type;
    // 系统生成的 getter 和 setter 方法
    if (_name.length) {
        if (!_getter) {
            _getter = NSSelectorFromString(_name);
        }
        if (!_setter) {
            _setter = NSSelectorFromString([NSString stringWithFormat:@"set%@%@:", [_name substringToIndex:1].uppercaseString, [_name substringFromIndex:1]]);
        }
    }
    return self;
}
@end


@implementation RCClassInfo{
    BOOL _needUpdate;
}

- (instancetype)initWithClass:(Class)cls{
    if (!cls) {
        return nil;
    }
    self = [super init];
    // 类名
    _name = NSStringFromClass(cls);
    // 当前类
    _cls = cls;
    // 父类
    _superCls = class_getSuperclass(cls);
    // 当前类是否是元类
    _isMeta = class_isMetaClass(cls);
    if (!_metaCls) {
        // 获取元类
        _metaCls = objc_getMetaClass(class_getName(cls));
    }
    // 更新类信息
    [self _update];
    // 父类信息
    _superClsInfo = [self.class classInfoWithClass:_superCls];
    return self;
    
}

/**
 是否需要更新类信息

 @return 是否需要更新类信息
 */
-(BOOL)needUpdate{
    return _needUpdate;
}
// 设置标识，需要更细类信息
-(void)setNeedUpdate{
    _needUpdate = YES;
}
+(instancetype)classInfoWithClass:(Class)cls{
    if (!cls) {
        return nil;
    }
    static CFMutableDictionaryRef classCache;
    static CFMutableDictionaryRef metaCache;
    static dispatch_semaphore_t lock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        classCache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        metaCache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        lock = dispatch_semaphore_create(1);
        
    });
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    RCClassInfo *classInfo = CFDictionaryGetValue(class_isMetaClass(cls) ? metaCache : classCache, (__bridge const void *)(cls));
    if (classInfo && classInfo->_needUpdate) {
        [classInfo _update];
    }
    dispatch_semaphore_signal(lock);
    if (!classInfo) {
        classInfo = [[RCClassInfo alloc] initWithClass:cls];
        if (classInfo) {
            dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
            CFDictionarySetValue(classInfo.isMeta ? metaCache : classCache, (__bridge const void *)(cls), (__bridge const void *)(classInfo));
            dispatch_semaphore_signal(lock);
        }
    }
    return classInfo;
}
+(instancetype)classInfoWithClassName:(NSString *)className{
    Class cls = NSClassFromString(className);
    return [self classInfoWithClass:cls];
}
- (void)_update{
    _ivarList = nil;
    _propertyList = nil;
    _methodList = nil;
    Class cls = self.cls;
    unsigned int methodCount;
    // 方法列表
    Method *methodList = class_copyMethodList(cls, &methodCount);
    if (methodList) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        _methodList = dic;
        for (unsigned int i = 0 ; i < methodCount; i ++) {
            Method method = methodList[i];
            RCObjc_method *methodInfo = [[RCObjc_method alloc] initWithMethod:method];
            if (methodInfo.name) {
                dic[methodInfo.name] = methodInfo;
            }
        }
        free(methodList);
    }
    unsigned int propertyCount;
    // property list
    objc_property_t *propertyList = class_copyPropertyList(cls, &propertyCount);
    if (propertyList) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        _propertyList = dic;
        for (unsigned int i = 0 ; i < propertyCount; i ++) {
            objc_property_t property = propertyList[i];
            RCObjc_property *propertyInfo = [[RCObjc_property alloc] initWithProperty:property];
            if (propertyInfo.name) {
                dic[propertyInfo.name] = propertyInfo;
            }
        }
        free(propertyList);
    }
    
    // ivar 列表
    unsigned int ivarCount;
    Ivar *ivarList = class_copyIvarList(cls, &ivarCount);
    if (ivarList) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        _ivarList = dic;
        for (unsigned int i = 0 ; i < ivarCount; i ++) {
            Ivar ivar = ivarList[i];
            RCObjc_ivar *ivarInfo = [[RCObjc_ivar alloc] initWithIvar:ivar];
            if (ivarInfo.name) {
                dic[ivarInfo.name] = ivarInfo;
            }
        }
        free(ivarList);
    }
    
    if (!_ivarList) {
        _ivarList = @{};
    }
    if (!_methodList) {
        _methodList = @{};
    }
    if (!propertyList) {
        _propertyList = @{};
    }
    _needUpdate = NO;
}
@end
