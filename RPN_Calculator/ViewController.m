//
//  ViewController.m
//  RPN_Calculator
//
//  Created by Veaceslav Macarov on 07.09.15.
//  Copyright (c) 2015 Veaceslav Macarov. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *infixTextField;
@property (weak, nonatomic) IBOutlet UILabel *postfixLabel;
@property (weak, nonatomic) IBOutlet UILabel *resultLabel;
@end

@implementation ViewController

#pragma mark - App Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Selectors

- (IBAction)onPolishAlgorithm:(id)sender
{
    NSString *infix = self.infixTextField.text;
    infix = [infix stringByReplacingOccurrencesOfString:@"*-" withString:@"*_"];
    infix = [infix stringByReplacingOccurrencesOfString:@"/-" withString:@"/_"];
    [self infixToPostfix:infix];
    [self.view endEditing:YES];
}

#pragma mark - Private methods

- (void)infixToPostfix:(NSString*)originalString
{
    NSDictionary * priorities = @{
                                  @"*" : @(2),
                                  @"/" : @(2),
                                  @"-" : @(1),
                                  @"+" : @(1),
                                  };
    NSString * operatorsString = [priorities.allKeys componentsJoinedByString:@""];
    NSCharacterSet * numbersSet = [NSCharacterSet characterSetWithCharactersInString: @"0123456789"];
    NSCharacterSet * operatorsSet = [NSCharacterSet characterSetWithCharactersInString: operatorsString ];
    NSCharacterSet * bracketsSet = [NSCharacterSet characterSetWithCharactersInString: @"()_"];
    
    NSMutableCharacterSet * allowedCharSet = [[NSMutableCharacterSet alloc] init];
    [allowedCharSet formUnionWithCharacterSet:numbersSet];
    [allowedCharSet formUnionWithCharacterSet:operatorsSet];
    [allowedCharSet formUnionWithCharacterSet:bracketsSet];
    
    NSCharacterSet * forbiddenCharSet = [allowedCharSet invertedSet];

    NSString * cleanString = [[originalString componentsSeparatedByCharactersInSet:forbiddenCharSet] componentsJoinedByString:@""];
    
    NSMutableArray *operatorStack = [NSMutableArray array];
    NSMutableArray *output = [NSMutableArray array];
    
    for (int index = 0; index < cleanString.length; index++) {
        unichar achar = [cleanString characterAtIndex:index];
        NSString * stringChar = [NSString stringWithCharacters:&achar length:1];
        
        if ([numbersSet characterIsMember:achar]) {
            // number
            int next = index;
            unichar nextDigit = achar;
            NSMutableString * number = [NSMutableString string];
            while (next < cleanString.length)
            {
                nextDigit = [cleanString characterAtIndex:next];
                if ([numbersSet characterIsMember:nextDigit]){
                    [number appendString:[NSString stringWithCharacters:&nextDigit length:1]];
                } else {
                    break;
                }
                next ++;
            }
            [output addObject: number ];
            index = next-1;
            
        } else if ([operatorsSet characterIsMember:achar] || [bracketsSet characterIsMember:achar]) {
            
            NSInteger currentOperatorPriority = [priorities[stringChar] integerValue];
            
            unichar acharNext = [cleanString characterAtIndex:index];
            NSString * stringCharNext = [NSString stringWithCharacters:&acharNext length:1];
            
            [operatorStack enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSInteger topOperatorPriority = [priorities [[operatorStack lastObject]] integerValue];
              
                if ([obj isEqualToString:@"("] ) {
                    *stop = YES;
                } else if ([obj isEqualToString:@")"]) {
                    //*stop = YES;
                    
                    int a = 0;
                    int b = 0;
                    
                    NSString *tempStr;
                    for (int j = 0; j<operatorStack.count; j++) {
                        if ([operatorStack[j] isEqualToString:@"("]) {
                            a = j;
                            if (j > 0) {
                                tempStr = operatorStack[j-1];
                            }
                        } else if ([operatorStack[j] isEqualToString:@")"]) {
                            b = j;
                        }
                    }
                    int c = b - a;
                    if (![operatorStack[c] isEqualToString:@"("] && ![operatorStack[c] isEqualToString:@")"]) {
                        [output addObject: operatorStack[c]];
                        [operatorStack removeObjectAtIndex:c];
                        [operatorStack removeObjectAtIndex:0];
                        [operatorStack addObject:tempStr];
                    }
                  
                } else if (currentOperatorPriority <= topOperatorPriority){
                    
                    if (![operatorStack containsObject:@"("]) {
                        if (![stringCharNext isEqualToString:@"("]) {
                            [output addObject: [operatorStack lastObject]];
                            [operatorStack removeLastObject];
                        }
                    }
                }
            }];
            [operatorStack addObject:stringChar];
        }
        
        if (index >= cleanString.length-1) {
            [operatorStack removeObject:@"("];
            [operatorStack removeObject:@")"];
            
            [operatorStack enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                  [output addObject: [operatorStack lastObject]];
                  [operatorStack removeLastObject];
            }];
        }
    }
    
    // add unary sign
    // if _* minus* -> !
    // if _/ minus* -> ?
    
    for (int i = 0; i < output.count; i++) {
        NSString *obj = output[i];
        if ([obj isEqualToString:@"_"]) {
            NSString *obj2 = output[i+1];
            if ([obj2 isEqualToString:@"*"]) {
                [output removeObject:obj];
                [output replaceObjectAtIndex:i withObject:@"!"];
            }
        }
        if ([obj isEqualToString:@"_"]) {
            NSString *obj2 = output[i+1];
            if ([obj2 isEqualToString:@"/"]) {
                [output removeObject:obj];
                [output replaceObjectAtIndex:i withObject:@"?"];
            }
        }
    }
    
    NSMutableString *postFix = [NSMutableString string];
    for ( int i = 0; i < output.count; i++) {
        NSString *string = output[i];
        [postFix insertString:string atIndex:postFix.length];
        [postFix insertString:@" " atIndex:postFix.length];
    }
    
    self.postfixLabel.text = postFix;
    
    double result = [self evaluatePostfixNotationArray:output];
    
    self.resultLabel.text = [NSString stringWithFormat:@"%f",result];
}


-(double)evaluatePostfixNotationArray:(NSArray*)postfixComponents
{
    NSString * numbers = @"0123456789";
    NSString * operators = @"?!*/-+";
    
    NSCharacterSet * numbersSet = [NSCharacterSet characterSetWithCharactersInString: numbers];
    NSCharacterSet * operatorsSet = [NSCharacterSet characterSetWithCharactersInString: operators];
    
    NSMutableArray * stack = [NSMutableArray array];
    for (NSInteger compIdx=0; compIdx < postfixComponents.count; compIdx++)
    {
            NSString * charStr = postfixComponents[compIdx];
            unichar firstCharForComponent = [charStr characterAtIndex:0];
            
            if ([numbersSet characterIsMember:firstCharForComponent]){
                // number
                [stack addObject: charStr];
                
                
            } else if ([operatorsSet characterIsMember:firstCharForComponent]) {
                // operator
                NSIndexSet * indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange( stack.count - 2, 2)];
                
                NSArray * operands;
                if (stack.count >= 2){
                    operands = [stack objectsAtIndexes: indexSet];
                } else {
                    continue;
                }
                double result = [self applyOperator:charStr toOperands:operands];
                
                [stack removeObjectsAtIndexes:indexSet];
                [stack addObject: [NSString stringWithFormat:@"%f", result]];
            }
        }
    double result = [[stack firstObject] doubleValue];
    return result;
}

-(double)applyOperator:(NSString *)operator toOperands:(NSArray *)operands
{
    void(^calculationBlock)(NSString * operand, NSUInteger idx, BOOL *stop) ;
    __block double result = 0;
    
    if ([operator isEqualToString:@"!"]){
        calculationBlock = ^(NSString * operand, NSUInteger idx, BOOL *stop) {
            if (idx == 0){
                result = operand.doubleValue;
            } else {
                result *= -operand.doubleValue;
            }
        };
    }
    
    if ([operator isEqualToString:@"?"]){
        calculationBlock = ^(NSString * operand, NSUInteger idx, BOOL *stop) {
            if (idx == 0){
                result = operand.doubleValue;
            } else {
                result /= -operand.doubleValue;
            }
        };
    }
    
    if ([operator isEqualToString:@"/"]){
        calculationBlock = ^(NSString * operand, NSUInteger idx, BOOL *stop) {
            if (idx == 0){
                result = operand.doubleValue;
            } else {
                result /= operand.doubleValue;
            }
        };
    }
    if ([operator isEqualToString:@"-"]){
        calculationBlock = ^(NSString * operand, NSUInteger idx, BOOL *stop) {
            if (idx == 0){
                result = operand.doubleValue;
            } else {
                result -= operand.doubleValue;
            }
        };
    }
    if ([operator isEqualToString:@"*"]){
        calculationBlock = ^(NSString * operand, NSUInteger idx, BOOL *stop) {
            if (idx == 0){
                result = operand.doubleValue;
            } else {
                result *= operand.doubleValue;
            }
        };
    }
    if ([operator isEqualToString:@"+"]){
        calculationBlock = ^(NSString * operand, NSUInteger idx, BOOL *stop) {
            result += operand.doubleValue;
        };
    }
    
    [operands enumerateObjectsUsingBlock: calculationBlock];
    return result;
}
@end
