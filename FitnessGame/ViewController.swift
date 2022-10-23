//
//  ViewController.swift
//  FitnessGame
//
//  Created by Peter Sun on 10/16/2022.
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
    
    @IBOutlet weak var currentActivityLabel: UILabel!
    // MARK: =====UI Lifecycle=====
    @IBAction func stepperClicked(_ sender: UIStepper) {
        print("Daily Goal: \(Int(sender.value)) steps")
        userGoal = Int(sender.value)
        let stepsB4Goal = userGoal! - todaySteps
        if stepsB4Goal > 0 {
            self.goalLabel.text =  "\(stepsB4Goal) more steps to goal:\(Int(sender.value))"
        } else {
            self.goalLabel.text =  "exceeded goal:\(Int(sender.value)) by \(-1*stepsB4Goal) steps"
        }
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
            self.goalStepper.value = Double(self.userGoal!)
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
                    DispatchQueue.main.async {
                        
                        if unwrappedActivity.walking {
                            self.currentActivityLabel.text = "You are walking! 🚶"
                        } else if unwrappedActivity.running {
                            self.currentActivityLabel.text = "You are running! 🏃"
                        } else if unwrappedActivity.cycling {
                            self.currentActivityLabel.text = "You are biking! 🚲"
                        } else if unwrappedActivity.automotive {
                            self.currentActivityLabel.text = "You are in a car! 🚗"
                        } else if unwrappedActivity.stationary {
                            self.currentActivityLabel.text = "Move fat man! 🐷"
                        } else if unwrappedActivity.unknown{
                            self.currentActivityLabel.text = "You have evaded Apple! Don't let them see this to avoid a lawsuit 🎉"
                        }
                    }
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
    
    
    @IBAction func gameButtonClicked(_ sender: UIButton) {
        performSegue(withIdentifier: "NextView", sender: sender)
    }
    

}

