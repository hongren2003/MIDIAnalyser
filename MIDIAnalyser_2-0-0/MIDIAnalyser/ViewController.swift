//
//  ViewController.swift
//  MIDIAnalyser
//
//  Created by Tim Brewis on 05/04/2020.
//  Copyright © 2020 Tim Brewis. All rights reserved.
//

import Cocoa
import AudioKit

class ViewController: NSViewController, AKMIDIListener {
    
    // GUI
    @IBOutlet var chordNameLabel: NSTextField!
    @IBOutlet var possibleChordNamesLabel: NSTextField!
    @IBOutlet var accidentalsDisplayType: NSSegmentedControl!
    @IBOutlet var sourcePopUpButton: NSPopUpButton!
    
    
    // preference
    
    let defaults = UserDefaults.standard
    
    // MIDI handling
    var MIDI = AudioKit.midi
    var keyboard: Keyboard = Keyboard.init()
    var analyser: ChordAnalyser = ChordAnalyser.init()
    
    // callbacks for key presses http://blog.ericd.net/2016/10/10/ios-to-macos-reading-keyboard-input/
    override var acceptsFirstResponder: Bool { return true }
    override func becomeFirstResponder() -> Bool { return true }
    override func resignFirstResponder() -> Bool { return true }
    
    // initialisation
    override func viewDidLoad() {
        
        // view loaded
        super.viewDidLoad()
        chordNameLabel.stringValue = "-"
        
        // MIDI initialisation
        MIDI.openInput("(default)")
        MIDI.addListener(self)
        
        sourcePopUpButton.removeAllItems()
        sourcePopUpButton.addItem(withTitle: "(select input)")
        sourcePopUpButton.addItems(withTitles: MIDI.inputNames)
        
        // keypress detection
        NSEvent.addLocalMonitorForEvents(matching: .keyUp) { (aEvent) -> NSEvent? in
            self.keyUp(with: aEvent)
            return aEvent
        }

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { (aEvent) -> NSEvent? in
            self.keyDown(with: aEvent)
            return aEvent
        }
        
        /*
        if let name = defaults.string(forKey: "testKey") {
            print(name)
        }
        else {
            print("none")
        }*/
        
    }
    
    
    @IBAction func sourceChanged(_ sender: NSPopUpButton) {

        if sender.indexOfSelectedItem > 0 {
            MIDI.closeAllInputs()
            MIDI.openInput(MIDI.inputNames[sender.indexOfSelectedItem - 1])
        }
    }
    
    
//    @IBAction func sourceChanged(_ sender: NSPopUpButton) {
//
//        print("source changed")
//
//        if sender.indexOfSelectedItem > 0 {
//            MIDI.closeAllInputs()
//            MIDI.openInput(MIDI.inputNames[sender.indexOfSelectedItem - 1])
//        }
//    }
    
    
    // something default
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    
    // MIDI event handlers

    func receivedMIDINoteOn(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel) {
        
        // update controls
        pollUI();
        
        // update the keyboard state
        keyboard.setKeyState(MIDINumber: Int(noteNumber), state: true)
        analyser.analyse(keyStates: keyboard.keyStates)
        updateChordLabels()
        
        // set preferences
        // defaults.set(analyser.chordName, forKey: "testKey")
        
    }

    
    func receivedMIDINoteOff(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel) {
       
        // update controls
        pollUI()
        
        // update the keyboard state
        keyboard.setKeyState(MIDINumber: Int(noteNumber), state: false)
        analyser.analyse(keyStates: keyboard.keyStates)
        updateChordLabels()
        
    }

    func receivedMIDIController(_ controller: MIDIByte, value: MIDIByte, channel: MIDIChannel) {
        
        pollUI()
        
        // check for sustain pedal
        if controller.magnitude == 64 {
            
            if value == 127 {
                keyboard.sustainPressed()
            } else {
                keyboard.sustainReleased()
                // if wanting chord to go away when sustain released, add these lines
                //analyser.analyse(keyStates: keyboard.keyStates)
                //updateChordLabels()
            }
            
        }
        
    }
     
     /*other functions to be implemented:
    func receivedMIDIPitchWheel(_ pitchWheelValue: MIDIWord, channel: MIDIChannel, portID: MIDIUniqueID? = nil, offset: MIDITimeStamp = 0) {
    }
    func receivedMIDIAftertouch(noteNumber: MIDINoteNumber, pressure: MIDIByte, channel: MIDIChannel, portID: MIDIUniqueID? = nil, offset: MIDITimeStamp = 0) {
    }
    func receivedMIDIAftertouch(_ pressure: MIDIByte, channel: MIDIChannel, portID: MIDIUniqueID? = nil, offset: MIDITimeStamp = 0) {
    }
    func receivedMIDIPitchWheel(_ pitchWheelValue: MIDIByte, channel: MIDIChannel, portID: MIDIUniqueID? = nil, offset: MIDITimeStamp = 0) {
    }
    func receivedMIDIProgramChange(_ program: MIDIByte, channel: MIDIChannel, portID: MIDIUniqueID? = nil, offset: MIDITimeStamp = 0) {
    }
    func receivedMIDISystemCommand(_ data: [MIDIByte], portID: MIDIUniqueID? = nil, offset: MIDITimeStamp = 0) {
    }*/

    // key press events
    override func keyDown(with event: NSEvent) {
        
        super.keyDown(with: event)
        
        let MIDINumber = Keyboard.keycodeToMIDINumber(Int(event.keyCode))
        
        if MIDINumber != 0 {
            keyboard.setKeyState(MIDINumber: MIDINumber, state: true)
            pollUI();
            analyser.analyse(keyStates: keyboard.keyStates)
            updateChordLabels()
        }
        
    }
    
    override func keyUp(with event: NSEvent) {
        
        super.keyUp(with: event)
        
        let MIDINumber = Keyboard.keycodeToMIDINumber(Int(event.keyCode))
        
        if MIDINumber != 0 {
            keyboard.setKeyState(MIDINumber: MIDINumber, state: false)
            pollUI()
            analyser.analyse(keyStates: keyboard.keyStates)
            updateChordLabels()
        }
        
    }
    
    
    // update the chord labels
    func updateChordLabels() {
        DispatchQueue.main.async(execute: {
            
            // main chord label
            self.chordNameLabel.stringValue = "\(self.analyser.chordName)"
            
            // possible chords
            var multiLineChordLabel =  ""
            //analyser.possibleChords.sort(by: descending)
            
            if(self.analyser.possibleChords.count != 0) {
                
                for i in 0 ..< self.analyser.possibleChords.count {
                    multiLineChordLabel += "\(self.analyser.possibleChordNames[i])\n"
                }
                
            }
            
            self.possibleChordNamesLabel.stringValue = "\(multiLineChordLabel)"
            
        })
    }
    
    
    // UI update checks
    func pollUI() {
        pollAccidentalsSegmentedControl()
    }

    
    // check for changes to accidentals
    func pollAccidentalsSegmentedControl() {
        
        DispatchQueue.main.async(execute: {
            
            switch self.accidentalsDisplayType.selectedSegment {
            
            case 0:
                self.analyser.accidentals = Keyboard.Accidentals.sharps
            case 1:
                self.analyser.accidentals = Keyboard.Accidentals.flats
            case 2:
                self.analyser.accidentals = Keyboard.Accidentals.mixed
            default:
                break
                
            }
            
        })
        
    }

    

}

