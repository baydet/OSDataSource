//
// Created by Alexandr Evsyuchenya on 9/27/15.
// Copyright (c) 2015 baydet. All rights reserved.
//

import Foundation

class ComposedDataSource {
    public private(set) var dataSources: [DataSource]

    func addDataSource(dataSource: DataSource)
}
