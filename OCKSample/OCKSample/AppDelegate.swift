/*
Copyright (c) 2019, Apple Inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1.  Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

2.  Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

3. Neither the name of the copyright holder(s) nor the names of any contributors
may be used to endorse or promote products derived from this software without
specific prior written permission. No license is granted to the trademarks of
the copyright holders even if such marks are included in this software.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


/* This file is basically in charge of creating and adding data to the store. The store is an on-device database
 We can use other databases which here is where we would add the data*/
import UIKit
import CareKit
import Contacts

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    // Manages synchronization of a CoreData store
    lazy var manager: OCKSynchronizedStoreManager<OCKStore> = {
        
        //OCKStore is basically just a on-device database, here we are creating it
        //We can use any other data base as well as long as it works with OCKStore protocol
        let store = OCKStore(name: "sadracTijerina3")
        
        //OCKSynchronizedStoreManager is what makes it possible to use another database
        let manager = OCKSynchronizedStoreManager(wrapping: store)
        
        //We are calling the function to populate the data
        manager.populateSampleData()
        
        return manager
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        //We are calling our CareViewController which is what we use to display the data in this file. The way we are displaying the data is by passing the storeManager which has all the data
        let careViewController = CareViewController(storeManager: manager)

        //This sets our view controller as our rootview, so basically where we are going to start
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UINavigationController(rootViewController: careViewController)
        
        //This changes the interface colors according to the theme they have selected on their iPhone
        window?.tintColor = UIColor { traitCollection -> UIColor in
            return traitCollection.userInterfaceStyle == .light ? #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1) : #colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1)
        }
        
        window?.tintColor = UIColor { traitCollection -> UIColor in
            return traitCollection.userInterfaceStyle == .dark ? #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1) : #colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1)
        }
        window?.makeKeyAndVisible()

        return true
    }
}

//This creates the cards, doesnt display it though its careViewController that does using the identifiers.
//This is basically populating the store
private extension OCKSynchronizedStoreManager where Store == OCKStore {

    // Adds tasks and contacts into the store
    func populateSampleData() {

        let thisMorning = Calendar.current.startOfDay(for: Date())
        let aFewDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: thisMorning)!
        let firstPill = Calendar.current.date(byAdding: .hour, value: 10, to: aFewDaysAgo)!
        let secondPill = Calendar.current.date(byAdding: .hour, value: 22, to: aFewDaysAgo)!
        
        let tuesdayWorkout = DateComponents(calendar: Calendar.current, year: 2019, month: 10, day: 8, weekday: 3)
        let thursdayWorkout = DateComponents(calendar: Calendar.current, year: 2019, month: 10, day: 10, weekday: 5)
        let saturdayWorkout = DateComponents(calendar: Calendar.current, year: 2019, month: 10, day: 12, weekday: 7)
        
        //This is setting a schedule for my pills
        let pillSchedule = OCKSchedule(composing: [
            //Every day in the morning
            OCKScheduleElement(start: firstPill, end: nil,
                               interval: DateComponents(day: 1)),

            //Every other day in the afternoon; every 2 days
            OCKScheduleElement(start: secondPill, end: nil,
                               interval: DateComponents(day: 1))
        ])

        var depakene = OCKTask(identifier: "depakene", title: "Take Depakene",
                             carePlanID: nil, schedule: pillSchedule)
        depakene.instructions = "Take two pills of depakene every 12 hours"
        depakene.impactsAdherence = true
        
        
        //This is the nasueaSchedule which is going to run everyday all day since its not something you can predict
        let absenceSeizureSchedule = OCKSchedule(composing: [
            OCKScheduleElement(start: firstPill, end: nil,
                               interval: DateComponents(day: 1),
                               text: "Anytime throughout the day", targetValues: [], isAllDay: true)
            ])

        //This is creating the task
        var absenceSeizures = OCKTask(identifier: "absenceSeizure", title: "Track your absence seizure",
                             carePlanID: nil, schedule: absenceSeizureSchedule)
        //impactsAdherence basically means does this impact those completion rings up top? Having nausea doesnt.
        absenceSeizures.impactsAdherence = false
        absenceSeizures.instructions = "Tap the button below anytime you experience an absence seizure."

        //This is creating the gym schedule
        let gymSchedule = OCKSchedule(composing: [
            
            OCKScheduleElement(start: tuesdayWorkout, end: nil, interval: DateComponents(day: 7)),
            
            OCKScheduleElement(start: thursdayWorkout, end: nil, interval: DateComponents(day:7)),
            
            OCKScheduleElement(start: saturdayWorkout, end: nil, interval: DateComponents(day:7)),
                ])
                
        //This is creating the task
        var gym = OCKTask(identifier: "gym", title: "Gym", carePlanID: nil, schedule: gymSchedule)
        gym.impactsAdherence = true
        gym.instructions = "Go to the gym"

        //Now that we have task created we have to add them to the store/database
        store.addTasks([absenceSeizures, depakene, gym])


        var contact1 = OCKContact(identifier: "gomez", givenName: "Arnulfo",
                                  familyName: "Gomez", carePlanID: nil)
        contact1.asset = nil
        contact1.title = "My Doctor from Monterrey"
        contact1.role = "He is a neurologist from Doctors Hospital in Monterrey"
        contact1.emailAddresses = [OCKLabeledValue(label: CNLabelEmailiCloud, value: "gomezarnulfo@hotmail.com")]
        contact1.phoneNumbers = [OCKLabeledValue(label: CNLabelWork, value: "011 52 18182591540")]
        contact1.messagingNumbers = [OCKLabeledValue(label: CNLabelWork, value: "011 52 18182591540")]
        
        //Calle Ecuador 2331, Balcones de Galerías, 64620 Monterrey, N.L., Mexico
        
        contact1.address = {
            let address = OCKPostalAddress()
            address.street = "Calle Ecuador 2331"
            address.city = "Monterrey"
            address.state = "Nuevo Leon, Mexico"
            address.postalCode = "64620"
            return address
        }()

        
        //add both contacts to store/database
        store.addContacts([contact1])
    }
}
