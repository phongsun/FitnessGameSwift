//
//  ViewController.swift
//  FitnessGame
//
//  Created by Peter Sunon 10/16/2022.
//  Copyright © 2022 Peter Sun. All rights reserved.
//

import UIKit
import CoreMotion
import Charts

class ViewController: UIViewController {
    
    var defaults = UserDefaults.standard
    var userGoal: Int? {
            didSet{
                guard let goalValue = userGoal, goalValue > 0 else { return }
                // 1. update defaults
                defaults.set(userGoal!, forKey: "goal")
                // 2. update progress ring
                let percentOfGoal: Float =  Float(self.todaySteps) / Float(userGoal!)
                self.goalPercentage = percentOfGoal
            }
        }
    
    var goalPercentage: Float = 0.0 {
            didSet{
                if goalPercentage > 1.0 {
                    goalPercentage = 1.0
                }
                self.progressView.progress = goalPercentage
            }
        }
    
    lazy var barChartView: BarChartView = {
       let barChartView = BarChartView()
       barChartView.frame = view.frame
       return barChartView
    }()
    
    lazy var progressView = CircularProgressView(frame: CGRect(x: 0, y: 0, width: 150, height: 150), lineWidth: 15, rounded: false)
    
    // MARK: =====Class Variables=====
    let activityManager = CMMotionActivityManager()
    let pedometer = CMPedometer()
    var yesterdaySteps = 0
    var todaySteps = 0
    
    // MARK: =====UI Outlets=====
    @IBOutlet weak var goalStepper: UIStepper!
    @IBOutlet weak var goalLabel: UILabel!
    
    // MARK: =====UI Lifecycle=====
    @IBAction func stepperClicked(_ sender: UIStepper) {
        print("Daily Goal: \(Int(sender.value)) steps")
        userGoal = Int(sender.value)
        self.goalLabel.text =  "Daily Goal: \(Int(sender.value)) steps"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        barChartView.isUserInteractionEnabled = false
        progressView.isUserInteractionEnabled = false
        view.addSubview(barChartView)
        view.addSubview(progressView)
        
        progressView.progressColor = .blue
        progressView.trackColor = .lightGray
        progressView.center = view.center
        
        if defaults.integer(forKey: "goal") != 0 {
            self.userGoal = defaults.integer(forKey: "goal")
        } else {
            self.userGoal = Int(self.goalStepper.value)
        }
        self.goalLabel.text = "Daily Goal: \(Int(self.goalStepper.value)) steps"
        
        /** Get yesteray's steps **/
        let now = Calendar.current.dateComponents(in: .current, from: Date())
        let today = DateComponents(year: now.year, month: now.month, day: now.day)
        let dateToday = Calendar.current.date(from: today)!
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: dateToday)!
        let startOfToday = Calendar.current.startOfDay(for: .now)
        pedometer.queryPedometerData(from: yesterday, to: startOfToday)
        { pedoData, error in
            if let error = error {
                print("pedo meter error: \(error.localizedDescription)")
                return
            }
            
            if let pedoObj = pedoData {
                self.yesterdaySteps = pedoObj.numberOfSteps.intValue
                DispatchQueue.main.async {
                    
                    self.barChartView.dataEntries =
                    [
                        BarEntry(steps: self.todaySteps, title: "Today"),
                        BarEntry(steps: self.yesterdaySteps, title: "Yesterday"),
                    ]
                }
            }
        }
        
        // start monitoring
        self.startActivityMonitoring()
        self.startPedometerMonitoring()
    }


    // MARK: =====Motion Methods=====
    func startActivityMonitoring(){
        // is activity is available
        if CMMotionActivityManager.isActivityAvailable(){
            // update from this queue (should we use the MAIN queue here??.... )
            self.activityManager.startActivityUpdates(to: OperationQueue.main)
            {(activity:CMMotionActivity?)->Void in
                // unwrap the activity and display
                // using the real time pedometer influences how often we get activity updates...
                // so these updates can come through less often than we may want
                if let unwrappedActivity = activity {
                    // Print if we are walking or running
                    print("%@",unwrappedActivity.description)
                    //self.activityLabel.text =
                    print("🚶: \(unwrappedActivity.walking), 🏃: \(unwrappedActivity.running)")
                }
            }
        }
    }
    
    func startPedometerMonitoring(){
        // Create the start of the day in `DateComponents` by leaving off the time.
        let now = Calendar.current.dateComponents(in: .current, from: Date())
        let today = DateComponents(year: now.year, month: now.month, day: now.day)
        let dateToday = Calendar.current.date(from: today)!
        
        // check if pedometer is okay to use
        if CMPedometer.isStepCountingAvailable(){
            // start updating the pedometer from the current date and time
            pedometer.startUpdates(from: dateToday)
            {(pedData:CMPedometerData?, error:Error?)->Void in
                
                // if no errors, update the main UI
                if let data = pedData {
                    
                    // display the output directly on the phone
                    DispatchQueue.main.async {
                        // this goes into the large gray area on view
                        //self.debugLabel.text = "\(data.description)"
                        print("\(data.description)")
                        // this updates the slider with number of steps
                        //self.stepCounter.value = data.numberOfSteps.floatValue
                        print("\(data.numberOfSteps.floatValue)")
                        self.todaySteps = data.numberOfSteps.intValue
                        if let goalValue = self.userGoal {
                            self.goalPercentage = Float(self.todaySteps) / Float(goalValue)
                        }
                        self.barChartView.dataEntries =
                        [
                            BarEntry(steps: self.todaySteps, title: "Today"),
                            BarEntry(steps: self.yesterdaySteps, title: "Yesterday"),
                        ]
                    }
                }
            }
        }
    }


}
