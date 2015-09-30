//
// Created by Alexandr Evsyuchenya on 9/27/15.
// Copyright (c) 2015 baydet. All rights reserved.
//

import Foundation

public protocol Paginable {
    var page: Int {get}
    func loadNextPage() -> Bool
}

public class DataProvider {
    private enum LoadingState: Int {
        case Initial
        case LoadingContent
        case RefreshingContent
        case LoadedContent
        case NoContent
        case Error
    }

    private let possibleTransitions: [LoadingState : [LoadingState]] = [
            .Initial : [.LoadingContent],
            .LoadingContent : [.LoadedContent, .NoContent, .Error],
            .RefreshingContent : [.LoadedContent, .NoContent, .Error],
            .LoadedContent : [.LoadingContent, .RefreshingContent],
            .NoContent : [.LoadingContent, .RefreshingContent],
            .Error : [.LoadingContent, .RefreshingContent]
    ]

    private var state: LoadingState = .Initial {
        willSet {
            assert(possibleTransitions[state]!.contains(newValue), "cannot perform transition from \(state) to \(newValue)")
        }
    }

    func numberOfSections() -> Int {
        return 0
    }

    func numberOfItems(inSection section: Int) -> Int {
        return 0
    }

    func loadContent() throws {

    }
}

public class DefaultDataProvider: DataProvider {

    override func numberOfSections() -> Int {
        return 0
    }

    override func numberOfItems(inSection section: Int) -> Int {
        return 0
    }


}
