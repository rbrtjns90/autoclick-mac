//
//  ContentView.swift
//  autoclicker2
//
//  Created by Robert Jones on 1/28/25.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @State private var recordedPoints: [CGPoint] = [] // Store multiple click locations
    @State private var clickTimer: Timer? = nil       // Timer for autoclicking
    @State private var isRecording: Bool = false     // Tracks if we're recording clicks
    @State private var eventMonitor: Any? = nil      // Global event monitor reference
    @State private var intervalText: String = "0.2"  // User input for interval (default 0.2 seconds)
    @State private var interval: Double = 0.2        // Parsed interval as a Double

    var body: some View {
        VStack(spacing: 20) {
            Text("Multi-Click Autoclicker")
                .font(.headline)
                .padding(.top, 10)

            if recordedPoints.isEmpty {
                Text("No clicks recorded yet.")
                    .foregroundColor(.red)
            } else {
                Text("Recorded \(recordedPoints.count) locations:")
                    .foregroundColor(.green)
                ForEach(recordedPoints.indices, id: \.self) { index in
                    Text("\(index + 1): (\(Int(recordedPoints[index].x)), \(Int(recordedPoints[index].y)))")
                }
            }

            Button(isRecording ? "Stop Recording Clicks" : "Record Clicks") {
                toggleRecording()
            }
            .padding()

            HStack {
                Text("Interval (seconds):")
                TextField("Enter interval", text: $intervalText)
                    .frame(width: 60)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: intervalText) { newValue in
                        validateIntervalInput()
                    }
            }
            .padding()

            Button("Start Autoclick") {
                startAutoclicking()
            }
            .padding()

            Button("Stop Autoclick") {
                stopAutoclicking()
            }
            .padding()

            Button("Exit Program") {
                exitProgram()
            }
            .padding()

            Spacer()
        }
        .frame(width: 400, height: 350)
        .padding()
        .onAppear {
            setupEmergencyStop()
        }
    }

    // MARK: - Toggle Recording State
    func toggleRecording() {
        if isRecording {
            // Stop recording
            isRecording = false
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
            print("Stopped recording clicks.")
        } else {
            // Start recording
            isRecording = true
            recordedPoints.removeAll() // Clear previous points
            eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { event in
                if let cgEvent = event.cgEvent {
                    let point = cgEvent.location
                    recordedPoints.append(point)
                    print("Recorded click at: \(point)")
                }
            }
            print("Started recording clicks. Click anywhere to record.")
        }
    }

    // MARK: - Start Autoclicking
    func startAutoclicking() {
        guard !recordedPoints.isEmpty else {
            print("No recorded points to click.")
            return
        }

        guard interval > 0 else {
            print("Invalid interval: \(interval). Must be greater than 0.")
            return
        }

        // Stop any existing timer
        clickTimer?.invalidate()

        // Create a new repeating timer that cycles through the recorded points
        var currentIndex = 0
        clickTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            click(at: recordedPoints[currentIndex])
            currentIndex = (currentIndex + 1) % recordedPoints.count // Cycle through points
        }

        print("Started autoclicking at recorded locations with interval \(interval) seconds.")
    }

    // MARK: - Stop Autoclicking
    func stopAutoclicking() {
        clickTimer?.invalidate()
        clickTimer = nil
        print("Autoclicker stopped.")
    }

    // MARK: - Exit Program
    func exitProgram() {
        stopAutoclicking()
        print("Exiting program.")
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Perform a single click at a point
    func click(at point: CGPoint) {
        // (Optional) Move the mouse cursor visually
        let moveEvent = CGEvent(mouseEventSource: nil,
                                mouseType: .mouseMoved,
                                mouseCursorPosition: point,
                                mouseButton: .left)
        moveEvent?.post(tap: .cghidEventTap)

        // Mouse down
        let clickDown = CGEvent(mouseEventSource: nil,
                                mouseType: .leftMouseDown,
                                mouseCursorPosition: point,
                                mouseButton: .left)
        clickDown?.post(tap: .cghidEventTap)

        // Mouse up
        let clickUp = CGEvent(mouseEventSource: nil,
                              mouseType: .leftMouseUp,
                              mouseCursorPosition: point,
                              mouseButton: .left)
        clickUp?.post(tap: .cghidEventTap)
    }

    // MARK: - Validate Interval Input
    func validateIntervalInput() {
        if let newInterval = Double(intervalText), newInterval > 0 {
            interval = newInterval
        } else {
            print("Invalid interval input: \(intervalText). Defaulting to \(interval).")
        }
    }

    // MARK: - Emergency Stop Setup
    func setupEmergencyStop() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // Escape key
                stopAutoclicking()
                print("Emergency stop triggered by Escape key.")
            }
        }
    }
}
