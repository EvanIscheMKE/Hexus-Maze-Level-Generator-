//
//  HDLevelGenerator.m
//  HexitSpriteKit
//
//  Created by Evan Ische on 11/26/14.
//  Copyright (c) 2014 Evan William Ische. All rights reserved.
//

#import "HDLevelGenerator.h"

@interface _HDHexaNode : NSObject <NSFastEnumeration>
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, assign) NSUInteger numberOfHitsNeeded;

@property (nonatomic, readonly) NSMutableArray *nodes;
@property (nonatomic, assign) NSUInteger numberOfNodes;

+ (BOOL)_isNodeValid:(_HDHexaNode *)node withinMap:(NSDictionary *)map;
- (_HDHexaNode *)nodeAtIndex:(NSUInteger)index;
- (void)insertNode:(_HDHexaNode *)node atIndex:(NSUInteger)index;
- (void)removeNode:(_HDHexaNode *)node;
- (void)removeNodeAtIndex:(NSUInteger)index;
@end

@implementation _HDHexaNode 

+ (BOOL)_isNodeValid:(_HDHexaNode *)node withinMap:(NSDictionary *)map
{
    if (!map || !node) {
        return NO;
    }
    
    NSIndexPath *indexPath = node.indexPath;
    
    if (map[indexPath]) {
        return NO;
    }
    
    if (indexPath.row < 0) {
        return NO;
    }
    
    if (indexPath.section < 0) {
        return NO;
    }
    
    if (indexPath.row > 18) {
        return NO;
    }
    
    if (indexPath.section > 9) {
        return NO;
    }
    
    return YES;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _nodes = [NSMutableArray new];
    }
    return self;
}

- (NSUInteger)numberOfNodes
{
    return _nodes.count;
}

- (_HDHexaNode *)nodeAtIndex:(NSUInteger)index
{
    if (index > _nodes.count) {
        return nil;
    }
    return [_nodes objectAtIndex:index];
}

- (void)insertNode:(_HDHexaNode *)node atIndex:(NSUInteger)index
{
    [_nodes insertObject:node atIndex:index];
}

- (void)removeNode:(_HDHexaNode *)node;
{
    [_nodes removeObject:node];
}

- (void)removeNodeAtIndex:(NSUInteger)index
{
    [_nodes removeObjectAtIndex:index];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)len                                    {
    return [((id <NSFastEnumeration>)_nodes) countByEnumeratingWithState:state objects:buffer count:len];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<PATH: %@ | HITS: %ld>", self.indexPath, (unsigned long)self.numberOfHitsNeeded];
}

@end

@implementation HDLevelGenerator

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.numberOfTiles = NSNotFound;
        self.difficulty = HDLevelGeneratorDifficultyEasy;
    }
    return self;
}

- (NSUInteger)rollDice
{
    return arc4random() % 2;
}

- (void)generateWithCompletionHandler:(CallbackBlock)handler
{
    NSParameterAssert(handler);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{    
        NSMutableDictionary *nodeMap = [NSMutableDictionary new];
        _HDHexaNode *rootNode = [_HDHexaNode new];
        rootNode.indexPath = [NSIndexPath indexPathForRow:4 inSection:9];
        nodeMap[rootNode.indexPath] = rootNode;
        rootNode.numberOfHitsNeeded = 2;
        
        _HDHexaNode *currentNode = rootNode;
        for (NSUInteger i = 0; i < MIN(self.numberOfTiles, 162); i++) {
            //Create a new node.
            _HDHexaNode *newNode = [_HDHexaNode new];
            newNode.numberOfHitsNeeded = arc4random() % 3 + 1;
            
            do {
                newNode.indexPath = currentNode.indexPath;
                
                NSInteger positionModifier = [self rollDice] ? 1 : -1;
                NSUInteger rollOfDice = [self rollDice];
                if (rollOfDice == 0) {
                    //Add to row.
                    newNode.indexPath = [NSIndexPath indexPathForRow:newNode.indexPath.row + positionModifier inSection:newNode.indexPath.section];
                } else {
                    //Add to column.
                    newNode.indexPath = [NSIndexPath indexPathForRow:newNode.indexPath.row inSection:newNode.indexPath.section + positionModifier];
                }
                if ([_HDHexaNode _isNodeValid:newNode withinMap:nodeMap]) {
                    [currentNode.nodes addObject:newNode];
                    currentNode = newNode;
                    [nodeMap setObject:newNode forKey:newNode.indexPath];
                    break;
                }
            } while (1);
        }
        
        NSMutableArray *gridArray = [NSMutableArray new];
        for (NSUInteger i = 0; i < 18; i++) {
            NSMutableArray *gridRow = [[NSMutableArray alloc] initWithCapacity:9];
            [gridArray addObject:gridRow];
            for (NSUInteger n = 0; n < 9; n++) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:n inSection:i];
                NSLog(@"PATH\t\t%@", indexPath);
                _HDHexaNode *hexaNode = nodeMap[indexPath];
                if (!hexaNode) {
                    NSLog(@"NOTHING\t%@", indexPath);
                    [gridRow addObject:@(0)];
                } else {
                    NSLog(@"FOUND\t%@", indexPath);
                    [gridRow addObject:@(hexaNode.numberOfHitsNeeded)];
                }
            }
        }
        
        NSMutableDictionary *grid = [NSMutableDictionary new];
        grid[@"grid"] = gridArray;
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(grid ,nil);
        });
    });
}

@end
