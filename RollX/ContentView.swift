//
//  ContentView.swift
//  RollX
//
//  Created by Gangulwar on 2/6/25.
//

import SwiftUI
import CoreMotion
import Network

class AccelerometerManager: ObservableObject {
    private let motionManager = CMMotionManager()
    private var connection: NWConnection?
    
    @Published var isConnected = false
    @Published var coordinates = (x: 0.0, y: 0.0, z: 0.0)
    @Published var errorMessage = ""
    
    func connect(to ip: String, port: UInt16) {
        disconnect()
        
        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(ip), port: NWEndpoint.Port(integerLiteral: port))
        connection = NWConnection(to: endpoint, using: .tcp)
        
        connection?.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    self?.isConnected = true
                    self?.errorMessage = ""
                    self?.startAccelerometer()
                case .failed(let error):
                    self?.errorMessage = "Connection failed: \(error.localizedDescription)"
                    self?.isConnected = false
                    self?.connection?.cancel()
                    self?.connection = nil
                case .waiting(let error):
                    self?.errorMessage = "Waiting: \(error.localizedDescription)"
                    self?.connection?.restart()
                default:
                    break
                }
            }
        }
        
        connection?.start(queue: .main)
    }
    
    func disconnect() {
        connection?.cancel()
        connection = nil
        stopAccelerometer()
        isConnected = false
    }
    
    private func startAccelerometer() {
        motionManager.stopAccelerometerUpdates()
        guard motionManager.isAccelerometerAvailable else {
            errorMessage = "Accelerometer not available"
            return
        }
        
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let data = data else { return }
            
            self?.coordinates = (data.acceleration.x, data.acceleration.y, data.acceleration.z)
            self?.sendCoordinates()
        }
    }
    
    private func stopAccelerometer() {
        motionManager.stopAccelerometerUpdates()
    }
    
    private func sendCoordinates() {
        let message = "\(coordinates.x),\(coordinates.y),\(coordinates.z)\n"
        guard let data = message.data(using: .utf8) else { return }
        
        connection?.send(content: data, completion: .contentProcessed { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = "Send error: \(error.localizedDescription)"
                }
            }
        })
    }
}

struct ContentView: View {
    @StateObject private var accelerometerManager = AccelerometerManager()
    @State private var ipAddress = ""
    @State private var port = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Accelerometer Data Sender")
                .font(.title)
                .padding()
            
            VStack(alignment: .leading) {
                TextField("IP Address", text: $ipAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                
                TextField("Port", text: $port)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
            }
            .padding(.horizontal)
            
            Button(action: {
                if accelerometerManager.isConnected {
                    accelerometerManager.disconnect()
                } else if let portNumber = UInt16(port) {
                    accelerometerManager.connect(to: ipAddress, port: portNumber)
                }
            }) {
                Text(accelerometerManager.isConnected ? "Disconnect" : "Connect")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(accelerometerManager.isConnected ? Color.red : Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            if accelerometerManager.isConnected {
                VStack(alignment: .leading, spacing: 10) {
                    Text("X: \(accelerometerManager.coordinates.x, specifier: "%.3f")")
                    Text("Y: \(accelerometerManager.coordinates.y, specifier: "%.3f")")
                    Text("Z: \(accelerometerManager.coordinates.z, specifier: "%.3f")")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            }
            
            if !accelerometerManager.errorMessage.isEmpty {
                Text(accelerometerManager.errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            Spacer()
        }
    }
}
