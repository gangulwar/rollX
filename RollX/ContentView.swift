//
//  ContentView.swift
//  RollX
//
//  Created by Gangulwar on 2/6/25.
//

import SwiftUI
import CoreMotion

struct ContentView: View {
    @State private var xAcceleration: Double = 0.0
    @State private var yAcceleration: Double = 0.0
    @State private var zAcceleration: Double = 0.0
    
    private let motionManager = CMMotionManager()
    
    func startAccelerometerUpdates() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: OperationQueue.main) { (data, error) in
                if let accelerometerData = data {
                    self.xAcceleration = accelerometerData.acceleration.x
                    self.yAcceleration = accelerometerData.acceleration.y
                    self.zAcceleration = accelerometerData.acceleration.z
                }
            }
        }
    }
    
    var body: some View {
        VStack {
            Text("Device Acceleration (XYZ):")
                .font(.title)
                .padding()
            
            Text("X: \(xAcceleration, specifier: "%.2f")")
                .font(.title2)
            
            Text("Y: \(yAcceleration, specifier: "%.2f")")
                .font(.title2)
            
            Text("Z: \(zAcceleration, specifier: "%.2f")")
                .font(.title2)
            
        }
        .onAppear {
            startAccelerometerUpdates()
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
