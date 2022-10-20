//
//  CircularProgressView.swift
//  FitnessGame
//
//  Created by The Peter Sun on 10/16/22.
//  Copyright © 2022 Peter Sun. All rights reserved.
//
import UIKit

class CircularProgressView: UIView {
    
    fileprivate var progressLayer = CAShapeLayer()
    fileprivate var trackLayer = CAShapeLayer()
    fileprivate var didConfigureLabel = false
    fileprivate var rounded: Bool
    fileprivate var filled: Bool
    var label: UILabel
    fileprivate let lineWidth: CGFloat?
    
    var timeToFill = 1.0
    
    var progressColor = UIColor.white {
        didSet{
            progressLayer.strokeColor = progressColor.cgColor
        }
    }
    
    var trackColor = UIColor.white {
        didSet{
            trackLayer.strokeColor = trackColor.cgColor
        }
    }
    
    var progress: Float {
        didSet{
            var pathMoved = progress - oldValue
            if pathMoved < 0{
                pathMoved = 0 - pathMoved
            }
            
            setProgress(duration: timeToFill * Double(pathMoved), to: progress)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        //label.sizeToFit()
        label.center = self.convert(self.center, from: self.superview)
        label.isEnabled = true
        label.textColor = .blue
    }
    
    fileprivate func createProgressView(){
        
        self.backgroundColor = .clear
        self.layer.cornerRadius = frame.size.width / 2
        let circularPath = UIBezierPath(arcCenter: center, radius: frame.width / 2, startAngle: CGFloat(-0.5 * .pi), endAngle: CGFloat(1.5 * .pi), clockwise: true)
        trackLayer.fillColor = UIColor.blue.cgColor
        
        trackLayer.path = circularPath.cgPath
        trackLayer.fillColor = .none
        trackLayer.strokeColor = trackColor.cgColor
        if filled {
            trackLayer.lineCap = .butt
            trackLayer.lineWidth = frame.width
        }else{
            trackLayer.lineWidth = lineWidth!
        }
        trackLayer.strokeEnd = 1
        layer.addSublayer(trackLayer)
        
        progressLayer.path = circularPath.cgPath
        progressLayer.fillColor = .none
        progressLayer.strokeColor = progressColor.cgColor
        if filled {
            progressLayer.lineCap = .butt
            progressLayer.lineWidth = frame.width
        }else{
            progressLayer.lineWidth = lineWidth!
        }
        progressLayer.strokeEnd = 0
        if rounded{
            progressLayer.lineCap = .round
        }
        
        layer.addSublayer(progressLayer)
        
    }
    
    func trackColorToProgressColor() -> Void{
        trackColor = progressColor
        trackColor = UIColor(red: progressColor.cgColor.components![0], green: progressColor.cgColor.components![1], blue: progressColor.cgColor.components![2], alpha: 0.2)
    }
    
    func setProgress(duration: TimeInterval = 3, to newProgress: Float) -> Void{
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.duration = duration
        
        animation.fromValue = progressLayer.strokeEnd
        animation.toValue = newProgress
        
        progressLayer.strokeEnd = CGFloat(newProgress)
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
                formatter.maximumFractionDigits = 2

        let formattedValue = formatter.string(from: NSNumber(value:newProgress))!

        self.label.text = String(formattedValue)
        progressLayer.add(animation, forKey: "animationProgress")
        
    }
    
    override init(frame: CGRect){
        progress = 0
        rounded = true
        filled = false
        lineWidth = 15
        label = UILabel(frame: CGRect(x: 0, y: 0, width: 80, height: 21))
        label.textAlignment = .center
        super.init(frame: frame)
        filled = false
        createProgressView()
        self.addSubview(label)
    }
    
    required init?(coder: NSCoder) {
        progress = 0
        rounded = true
        filled = false
        label = UILabel(frame: CGRect(x: 0, y: 0, width: 80, height: 21))
        label.textAlignment = .center
        lineWidth = 15
        super.init(coder: coder)
        createProgressView()
        self.addSubview(label)
    }
    
    init(frame: CGRect, lineWidth: CGFloat?, rounded: Bool) {
        progress = 0
        
        if lineWidth == nil{
            self.filled = true
            self.rounded = false
        }else{
            if rounded{
                self.rounded = true
            }else{
                self.rounded = false
            }
            self.filled = false
        }
        self.lineWidth = lineWidth
        label = UILabel(frame: CGRect(x: 0, y: 0, width: 80, height: 21))
        label.textAlignment = .center
        super.init(frame: frame)
        createProgressView()
        self.addSubview(label)
    }
}
