//
// Created by Alexandr Evsyuchenya on 9/27/15.
// Copyright (c) 2015 baydet. All rights reserved.
//

import Foundation

public protocol Paginable {
    var page: Int {get}
    func loadNextPage() -> Bool
}

public protocol DataProvider {
    func numberOfSections() -> Int
    func numberOfItems(inSection section: Int) -> Int
    func loadContent() throws
}


