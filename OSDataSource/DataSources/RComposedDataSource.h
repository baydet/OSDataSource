/*
 Abstract:
 
  A subclass of AAPLDataSource with multiple child data sources. Child data sources may have multiple sections. Load content messages will be sent to all child data sources.
  
 */

#import "OSDataSource.h"

/// A data source that is composed of other data sources.
@interface RComposedDataSource : OSDataSource

/// Add a data source to the data source.
- (void)addDataSource:(OSDataSource *)dataSource;

/// Remove the specified data source from this data source.
- (void)removeDataSource:(OSDataSource *)dataSource;

@end
