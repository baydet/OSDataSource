//
// Created by Alexander Evsyuchenya on 12/9/15.
// Copyright (c) 2015 Engaged Mobility. All rights reserved.
//

import Foundation
import CoreData

@objc class FetchedResultsSection: NSObject, Section, NSFetchedResultsControllerDelegate {
    weak var updater: SectionItemsUpdatesDelegate?
    let fetchedResultsController: NSFetchedResultsController
    
    init(fetchedResultsController: NSFetchedResultsController) {
        self.fetchedResultsController = fetchedResultsController
        super.init()
        self.fetchedResultsController.delegate = self
        let _ = try? self.fetchedResultsController.performFetch()
    }
    
    func numberOfItems(inSection section: Int) -> Int {
        guard let sectionInfo = fetchedResultsController.sections?[section] else {
            return 0
        }
        return sectionInfo.numberOfObjects
    }
    
    func numberOfSubSections() -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    subscript(indexPath: IndexPath) -> RowInfo {
        get {
            return fetchedResultsController.objectAtIndexPath(NSIndexPath(forItem: indexPath.index, inSection: indexPath.section)) as! RowInfo
        }
        set {
            fatalError("unimplemented")
        }
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        updater?.notifyBeginUpdates(self)
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?)
    {
        switch(type) {
            
        case .Update:
            if let indexPath = indexPath {
                updater?.notifyUpdateRowAtIndexPath(self, indexPath: indexPath.tuple)
            }
            
        case .Insert:
            if let newIndexPath = newIndexPath {
                updater?.notifyInsertRowsAtIndexPaths(self, paths: [newIndexPath.tuple])
            }
            
        case .Delete:
            if let indexPath = indexPath {
                updater?.notifyDeleteRowsAtIndexPaths(self, paths: [indexPath.tuple])
            }
            
        case .Move:
            if let indexPath = indexPath, newIndexPath = newIndexPath where indexPath != newIndexPath {
                updater?.notifyDeleteRowsAtIndexPaths(self, paths: [indexPath.tuple])
                updater?.notifyInsertRowsAtIndexPaths(self, paths: [newIndexPath.tuple])
            }
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch(type) {
        case .Insert:
            updater?.notifyInsertSections(self, sectionIndex: sectionIndex)
        case .Delete:
            updater?.notifyDeleteSections(self, sectionIndex: sectionIndex)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        updater?.notifyEndUpdates(self)
    }


}
