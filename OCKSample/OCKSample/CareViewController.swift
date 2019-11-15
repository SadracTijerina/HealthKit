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

import Foundation
import UIKit
import CareKit

class CareViewController: OCKDailyPageViewController<OCKStore> {

        override func viewDidLoad() {
            super.viewDidLoad()
            
        //This is creating the care team button and calls presentContactsListViewController when clicked
            navigationItem.rightBarButtonItem =
                UIBarButtonItem(title: "Care Team", style: .plain, target: self,
                                action: #selector(presentContactsListViewController))
        }

        //This is how we are displaying the contacts
        @objc private func presentContactsListViewController() {
            //OCKContactsListViewController is what displays the contacts we just need to pass the store manager
            let viewController = OCKContactsListViewController(storeManager: storeManager)
            viewController.title = "Care Team"
            viewController.navigationItem.rightBarButtonItem =
                UIBarButtonItem(title: "Done", style: .plain, target: self,
                                action: #selector(dismissContactsListViewController))

            let navigationController = UINavigationController(rootViewController: viewController)
            present(navigationController, animated: true, completion: nil)
        }

        @objc private func dismissContactsListViewController() {
            dismiss(animated: true, completion: nil)
        }

    // This will be called each time the selected date changes.
    // Use this as an opportunity to rebuild the content shown to the user.
    override func dailyPageViewController<S>(
        _ dailyPageViewController: OCKDailyPageViewController<S>,
        prepare listViewController: OCKListViewController,
        for date: Date) where S: OCKStoreProtocol {

        //What we want to display is put in the anchor variable
        let identifiers = ["depakene", "absenceSeizure", "gym"]
        let anchor = OCKTaskAnchor.taskIdentifiers(identifiers)
        var query = OCKTaskQuery(for: date)
        query.excludesTasksWithNoEvents = true

        storeManager.store.fetchTasks(anchor, query: query) { result in
            switch result {
            case .failure(let error): print("Error: \(error)")
            case .success(let tasks):

                // Add a non-CareKit view into the list
                let tipTitle = "Benefits of exercising"
                let tipText = "Going to the gym is the wave"

                // Only show the tip view on the current date
                //This is basicallychecking if the date is current and if it is, display the tipview
                //Tipview is arbituary data and isn't related to Carekit
                if Calendar.current.isDate(date, inSameDayAs: Date()) {
                    let tipView = TipView()
                
                    //Setting the card title and detail label to display the text from the top variables
                    tipView.headerView.titleLabel.text = tipTitle
                    tipView.headerView.detailLabel.text = tipText
                    
                    //This is to set a background image to the card
                    tipView.imageView.image = UIImage(named: "gym.png")
                    
                    //This is adding the card to the screen
                    listViewController.appendView(tipView, animated: false)
                }

                // Since the tylenol task is only sheduled every other day, there will be cases
                // where it is not contained in the tasks array returned from the query.
                if let gymTask = tasks.first(where: { $0.identifier == "gym" }) {
                    //There are different types of ViewControllers and we can change all of them without worry since they all have the same initializers
                    let gymCard = OCKSimpleTaskViewController(
                        storeManager: self.storeManager, //passing it to the store
                        task: gymTask,//this is basically the identifer, what task are we trying to display data for
                        eventQuery: OCKEventQuery(for: date)) //This displays only events for today
                    listViewController.appendViewController(gymCard, animated: false)
                }
            
                
                // Create a card for the tylenol task if there are events for it on this day.
                if let depakeneTask = tasks.first(where: { $0.identifier == "depakene" }) {
                    let depakeneCard = OCKChecklistTaskViewController(
                        storeManager: self.storeManager,
                        task: depakeneTask,
                        eventQuery: OCKEventQuery(for: date))
                    
                   // depakeneTask.asset = "meds.png"
                    listViewController.appendViewController(depakeneCard, animated: false)
                }

                // Create a card for the nausea task if there are events for it on this day.
                // Its OCKSchedule was defined to have daily events, so this task should be
                // found in `tasks` every day after the task start date.
                if let absenceSeizureTask = tasks.first(where: { $0.identifier == "absenceSeizure" }) {
                    // dynamic gradient colors
                    let absenceSeizureGradientStart = UIColor { traitCollection -> UIColor in
                        return traitCollection.userInterfaceStyle == .light ? #colorLiteral(red: 0.9960784314, green: 0.3725490196, blue: 0.368627451, alpha: 1) : #colorLiteral(red: 0.8627432641, green: 0.2630574384, blue: 0.2592858295, alpha: 1)
                    }
                    let absenceSeizureGradientEnd = UIColor { traitCollection -> UIColor in
                        return traitCollection.userInterfaceStyle == .light ? #colorLiteral(red: 0.9960784314, green: 0.4732026144, blue: 0.368627451, alpha: 1) : #colorLiteral(red: 0.8627432641, green: 0.3598620686, blue: 0.2592858295, alpha: 1)
                    }

                    // Create a plot comparing nausea to medication adherence.
                    let absenceSeizureDataSeries = OCKDataSeriesConfiguration<OCKStore>(
                        taskIdentifier: "absenceSeizure",
                        legendTitle: "Absence Seizure",
                        gradientStartColor: absenceSeizureGradientStart,
                        gradientEndColor: absenceSeizureGradientEnd,
                        markerSize: 10,
                        eventAggregator: OCKEventAggregator.countOutcomeValues)

                    //This is creating a plot for tylenol
                    let depakeneDataSeries = OCKDataSeriesConfiguration<OCKStore>(
                        taskIdentifier: "depakene",
                        legendTitle: "Depakene",
                        gradientStartColor: .systemGray2,
                        gradientEndColor: .systemGray,
                        markerSize: 10,
                        eventAggregator: OCKEventAggregator.countOutcomeValues)

                    //This is creating the chart
                    let insightsCard = OCKCartesianChartViewController(
                        storeManager: self.storeManager, //This is for sychronization
                        type: .bar,
                        dataSeriesConfigurations: [absenceSeizureDataSeries, depakeneDataSeries], //displaying each data series
                        date: date)
                    
                    insightsCard.synchronizedView.headerView.titleLabel.text = "Absence Seizure & Depakene Intake"
                    insightsCard.synchronizedView.headerView.detailLabel.text = "This Week"

                    //we are adding the chart to the screen
                    listViewController.appendViewController(insightsCard, animated: false)

 
                    let absenceSeizureCard = OCKButtonLogTaskViewController(
                        storeManager: self.storeManager,
                        task: absenceSeizureTask,
                        eventQuery: OCKEventQuery(for: date))

                    //we are adding the nausea tracker to the screen
                    listViewController.appendViewController(absenceSeizureCard, animated: true)
                }
            }
        }
    }
}
