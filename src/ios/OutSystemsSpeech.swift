//
//  OutSystemsSpeech.swift
//  OSSpeech
//
//  Created by Andre Grillo on 25/08/2020.
//  Copyright © 2020 Andre Grillo. All rights reserved.
//

import UIKit
import AVFoundation
import Speech

@objc(OSSpeech) class OSSpeech : CDVPlugin, AVAudioRecorderDelegate {
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var cdvCommand: CDVInvokedUrlCommand!
    var pluginResult: CDVPluginResult!
    
    @objc(speak:)
    func speak(command: CDVInvokedUrlCommand) {
        
        pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR
        )
        
        if let textToBeSpoken = command.arguments[0] as? String {
            if let language = command.arguments[1] as? String {
                let utterance = AVSpeechUtterance(string: textToBeSpoken)
                utterance.voice = AVSpeechSynthesisVoice(language: language)
                utterance.rate = 0.5
                let synthesizer = AVSpeechSynthesizer()
                synthesizer.speak(utterance)
                
                pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_OK,
                    messageAs: "\(textToBeSpoken)"
                )
            } else {
                print("Missing language argument")
                pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Missing language argument")
            }
            
        } else {
            print("Missing text argument")
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Missing text argument")
        }
        
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc(listen:)
    func listen(command: CDVInvokedUrlCommand) {
        cdvCommand = command
//        pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR)
        requestAudioRecordingPermission()
        requestTranscribePermissions()
        
        recordTapped()
    }
    
    @objc func recordTapped() {
        if audioRecorder == nil {
            startRecording()
        } else {
            finishRecording(success: true)
        }
    }
    
    func requestAudioRecordingPermission() {
        recordingSession = AVAudioSession.sharedInstance()

        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { allowed in
                DispatchQueue.main.async {
                    if allowed {
                        print("Recording permission granted")
                    } else {
                        // failed to record!
                        print("Recording permission denied")
                        let pluginResult: CDVPluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Recording permission denied")
                        self.commandDelegate!.send(pluginResult, callbackId: self.cdvCommand.callbackId)
                    }
                }
            }
        } catch {
            print("Failed to record!")
            let pluginResult: CDVPluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Failed to record")
            self.commandDelegate!.send(pluginResult, callbackId: self.cdvCommand.callbackId)
        }
    }
    
    func requestTranscribePermissions() {
        SFSpeechRecognizer.requestAuthorization { authStatus in//[unowned self] authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    print("Good to go!")
                } else {
                    print("Transcription permission was declined.")
                    let pluginResult: CDVPluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Transcription permission was declined")
                    self.commandDelegate!.send(pluginResult, callbackId: self.cdvCommand.callbackId)
                }
            }
        }
    }


    func transcribeAudio(url: URL) {
        if let language = cdvCommand.arguments[0] as? String {
            // create a new recognizer and point it at our audio
            var recognizer = SFSpeechRecognizer()
            recognizer = SFSpeechRecognizer(locale: Locale.init(identifier: language))

            let request = SFSpeechURLRecognitionRequest(url: url)

            // start recognition!
            recognizer?.recognitionTask(with: request) { [unowned self] (result, error) in
                // abort if we didn't get any transcription back
                guard let result = result else {
                    print("There was an error: \(error!)")
                    let pluginResult: CDVPluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Error: \(error!)")
                    self.commandDelegate!.send(pluginResult, callbackId: self.cdvCommand.callbackId)
                    return
                }

                // we got the final transcription back, say it!
                if result.isFinal {
                    // the best transcription...
                    print("Transcription: \(result.bestTranscription.formattedString)")
                    let sentence = result.bestTranscription.formattedString
                    
                    // *** REMOVER - SOMENTE PARA TESTES ***
                    self.outsystemsTalks(sentence: sentence, language: language)
                    //
                    
                    let pluginResult: CDVPluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "Transcribed text: \(sentence)")
                    self.commandDelegate!.send(pluginResult, callbackId: self.cdvCommand.callbackId)
                    
                }
            }
        } else {
            print("Error: Language not set")
            let pluginResult: CDVPluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Error: Language not set")
            self.commandDelegate!.send(pluginResult, callbackId: self.cdvCommand.callbackId)
        }
        
    }


    func startRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()

        } catch {
            finishRecording(success: false)
            let pluginResult: CDVPluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Error: Failed to record")
            self.commandDelegate!.send(pluginResult, callbackId: self.cdvCommand.callbackId)
            
        }
    }

    func finishRecording(success: Bool) {
        audioRecorder.stop()
        audioRecorder = nil

        if success {
            print("recording succeded!")
        } else {
            print("recording failed :(")
        }
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    // Delegate method in case the recording finishes out of our control (ie: phone call)
    // If the recording is successful, will call the transcription method
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        } else {
            //recording successfull - request transcription
            let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
            transcribeAudio(url: audioFilename)
        }
    }
    
    //REMOVER - SOMENTE PARA TESTES
    func outsystemsTalks(sentence: String, language: String) {
        let utterance = AVSpeechUtterance(string: sentence)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.5
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
    
    
}
