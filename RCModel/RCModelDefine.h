//
//  RCModelDefine.h
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

#ifndef RCModelDefine_h
#define RCModelDefine_h

/**
 encoding type
 */
typedef NS_OPTIONS(NSUInteger, RCEncodingType) {
    /**
     类型编码
     */
    RCEncodingTypeMask      = 0xFF ,
    
    /**
     unknow
     */
    RCEncodingTypeUnknow    = 0 ,
    
    /**
     void
     */
    RCEncodingTypeVoid      = 1 ,
    
    /**
     bool
     */
    RCEncodingTypeBool      = 2 ,
    
    /**
     char / bool
     */
    RCEncodingTypeInt8      = 3 ,
    
    /**
     unsigned char
     */
    RCEncodingTypeUInt8     = 4 ,
    
    /**
     short
     */
    RCEncodingTypeInt16     = 5 ,
    
    /**
     unsigned short
     */
    RCEncodingTypeUInt16    = 6 ,
    
    /**
     int
     */
    RCEncodingTypeInt32     = 7 ,
    
    /**
     unsigned int
     */
    RCEncodingTypeUInt32    = 8 ,
    
    /**
     long long
     */
    RCEncodingTypeInt64     = 9 ,
    
    /**
     unsigned long long
     */
    RCEncodingTypeUInt64    = 10 ,
    
    /**
     float
     */
    RCEncodingTypeFloat     = 11 ,
    
    /**
     double
     */
    RCEncodingTypeDouble    = 12 ,
    
    /**
     long double
     */
    RCEncodingTypeLongDouble= 13 ,
    
    /**
     id
     */
    RCEncodingTypeObject    = 14 ,
    
    /**
     class
     */
    RCEncodingTypeClass     = 15 ,
    
    /**
     SEL
     */
    RCEncodingTypeSEL       = 16 ,
    
    /**
     Block
     */
    RCEncodingTypeBlock     = 17 ,
    
    /**
     void *
     */
    RCEncodingTypePointer   = 18 ,
    
    /**
     struct
     */
    RCEncodingTypeStruct    = 19 ,
    
    /**
     union
     */
    RCEncodingTypeUnion     =20 ,
    
    /**
     CString (char *)
     */
    RCEncodingTypeCString   = 21 ,
    
    /**
     CArray (char[10])
     */
    RCEncodingTypeCArray    = 22 ,
    
    /**
     方法编码修饰符
     */
    RCEncodingTypeQualifierMask = 0xFF00 ,
    
    /**
     const
     */
    RCEncodingTypeQualifierConst = 1 << 8 ,
    
    /**
     in
     */
    RCEncodingTypeQualifierIn = 1 << 9 ,
    
    /**
     inout
     */
    RCEncodingTypeQualifierInout = 1 << 10 ,
    
    /**
     out
     */
    RCEncodingTypeQualifierOut = 1 << 11 ,
    
    /**
     Bycopy
     */
    RCEncodingTypeQualifierBycopy = 1 << 12 ,
    
    /**
     Byref
     */
    RCEncodingTypeQualifierByref = 1 << 13 ,
    
    /**
     oneway
     */
    RCEncodingTypeQualifierOneway = 1 << 14 ,
    
    /**
     修饰类型
     */
    RCEncodingTypePropertyMask = 0xFF0000 ,
    
    /**
     readonly
     */
    RCEncodingTypePropertyReadonly     = 1 << 16,
    
    /**
     copy
     */
    RCEncodingTypePropertyCopy         = 1 << 17,
    
    /**
     retain
     */
    RCEncodingTypePropertyRetain       = 1 << 18,
    
    /**
     nonatomic
     */
    RCEncodingTypePropertyNonatomic    = 1 << 19,
    
    /**
     weak
     */
    RCEncodingTypePropertyWeak         = 1 << 20,
    
    /**
     custom getter
     */
    RCEncodingTypePropertyCustomGetter = 1 << 21,
    
    /**
     custom setter
     */
    RCEncodingTypePropertyCustomSetter = 1 << 22,
    
    /**
     dynamic
     */
    RCEncodingTypePropertyDynamic      = 1 << 23,
    
};
typedef NS_ENUM (NSUInteger, RCEncodingNSType) {
    RCEncodingTypeNSUnknown = 0,
    RCEncodingTypeNSString,
    RCEncodingTypeNSMutableString,
    RCEncodingTypeNSValue,
    RCEncodingTypeNSNumber,
    RCEncodingTypeNSDecimalNumber,
    RCEncodingTypeNSData,
    RCEncodingTypeNSMutableData,
    RCEncodingTypeNSDate,
    RCEncodingTypeNSURL,
    RCEncodingTypeNSArray,
    RCEncodingTypeNSMutableArray,
    RCEncodingTypeNSDictionary,
    RCEncodingTypeNSMutableDictionary,
    RCEncodingTypeNSSet,
    RCEncodingTypeNSMutableSet,
};
#endif /* RCModelDefine_h */
