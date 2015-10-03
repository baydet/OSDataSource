//
// Created by Alexandr Evsyuchenya on 9/27/15.
// Copyright (c) 2015 baydet. All rights reserved.
//

import Foundation

public protocol Paginable {
    func loadMore() -> Bool
}

public typealias LoadingCompletionBlock = (ContentLoadingCompletionState) -> Void

public enum ContentLoadingCompletionState {
    case WithContent
    case NoContent
    case Error(error: ErrorType)
}

internal protocol DataProviderDelegate: class {
    func dataProvider(dataProvider: DataProvider, didChangeState state:DataProvider.LoadingState)
}

public class DataProvider {
    internal enum LoadingState {
        case Initial
        case LoadingContent
        case LoadingMoreContent
        case RefreshingContent
        case LoadedContent
        case NoContent
        case Error
    }
    internal weak var delegate: DataProviderDelegate?
    public var noContentMessage: String = ""

    private let possibleTransitions: [LoadingState : [LoadingState]] = [
            .Initial : [.LoadingContent],
            .LoadingContent : [.LoadedContent, .NoContent, .Error],
            .RefreshingContent : [.LoadedContent, .NoContent, .Error],
            .LoadedContent : [.LoadingContent, .RefreshingContent],
            .NoContent : [.LoadingContent, .RefreshingContent],
            .Error : [.LoadingContent, .RefreshingContent]
    ]

    internal private(set) var state: LoadingState = .Initial {
        willSet {
            assert(possibleTransitions[state]!.contains(newValue), "cannot perform transition from \(state) to \(newValue)")
        }
        didSet {
            delegate?.dataProvider(self, didChangeState: state)
        }
    }

    internal func beginLoading() {
        state = .LoadingContent
    }

    internal func endLoading(withState state: LoadingState) {
        self.state = state
    }

    public func numberOfSections() -> Int {
        return 0
    }

    public func numberOfItems(inSection section: Int) -> Int {
        return 0
    }

    public func loadContent(completionBlock:((LoadingCompletionBlock) -> Void)) {
        beginLoading()
        let finishBlock: LoadingCompletionBlock = {contentState in
            print(contentState)
        }
        completionBlock(finishBlock)
    }
}

public class DefaultDataProvider <T> : DataProvider {

    private var objects: [T]?

    required public init(objects: [T]?) {
        super.init()
        loadContent(objects)
    }

    override public func numberOfSections() -> Int {
        return objects == nil ? 0 : 1
    }

    override public func numberOfItems(inSection section: Int) -> Int {
        return objects?.count ?? 0
    }

    public func loadContent(objects: [T]?) {
        beginLoading()
        self.objects = objects
        let state = self.objects?.count > 0 ? LoadingState.LoadedContent : LoadingState.NoContent
        endLoading(withState: state)
    }


}
