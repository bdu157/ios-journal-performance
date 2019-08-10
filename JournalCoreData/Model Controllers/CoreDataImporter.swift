//
//  CoreDataImporter.swift
//  JournalCoreData
//
//  Created by Andrew R Madsen on 9/10/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import Foundation
import CoreData

class CoreDataImporter {
    init(context: NSManagedObjectContext) {
        self.context = context   //newBackgroundContext()
    }
    
    func sync(entries: [EntryRepresentation], completion: @escaping (Error?) -> Void = { _ in }) {
        
        //why is this so slow??
        self.context.performAndWait {
            print("syncing starts : \(self.checkCurrentTime(for: Date()))")
                //guard let identifier = entryRep.identifier else { continue }
                    let entriesFromCoreData = self.fetchEntriesFromPersistentStore(with: entries, in: self.context)
                    for entryRep in entries {
                        if let entry = entryDictionary[entryRep.identifier!], entry != entryRep {
                            self.update(entry: entry, with: entryRep)
                        } else {
                            _ = Entry(entryRepresentation: entryRep, context: self.context)
                        }
                    }
            completion(nil)
            print("syncing ends : \(self.checkCurrentTime(for: Date()))")
        }
    }
    
    private func update(entry: Entry, with entryRep: EntryRepresentation) {
        entry.title = entryRep.title
        entry.bodyText = entryRep.bodyText
        entry.mood = entryRep.mood
        entry.timestamp = entryRep.timestamp
        entry.identifier = entryRep.identifier
    }
    
    //change it to get one entry based on an array of identifiers through Predicate because you are either creating or updaing
     func fetchEntriesFromPersistentStore(with entries: [EntryRepresentation], in context: NSManagedObjectContext) -> [Entry]? {
        
        var identifiers: [String] = []
        identifiers = entries.map {$0.identifier!}
        
        //to make the performance better for syncing, change NSPredicate to have an array instead of having to check one by one
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiers) //"identifier IN %@", arrayOfIdentifiers
        
        var entries: [Entry]?
        self.context.performAndWait {
            do {
                entries = try context.fetch(fetchRequest)
            } catch {
                NSLog("Error fetching single entry: \(error)")
            }
        }
        
        //cache dictionary
        
        for entry in entries! {
            self.entryDictionary[entry.identifier!] = entry
        }
        return entries
    }
    
    var entryDictionary = [String : Entry]()
    
    let context: NSManagedObjectContext
    
    private func checkCurrentTime(for currentTime : Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "PST")
        return formatter.string(from: currentTime)
    }
}
//dictionary is not needed
//looping through firebase elemenets
