///  ContentView.swift
///  MuVis
///
/// The ContentView struct contains the code for the Graphical User Interface to the MuVis application.
///
///  Created by Keith Bromley on 20 Nov 2020.

import SwiftUI
import QuickLook

struct ContentView: View {
    @EnvironmentObject var audioManager: AudioManager
    @EnvironmentObject var settings: Settings

    @State private var visNum: Int = 0      // visualization number - used as an index into the visualizationList array
    @State private var enableSongFileSelection: Bool = false
    @State private var pauseButtonIsPaused: Bool = false
    
    @State var userGuideUrl: URL?
    @State var visualizationsGuideUrl: URL?
    // https://developer.apple.com/documentation/swiftui/view/quicklookpreview(_:in:)?language=objc_9
    // https://stackoverflow.com/questions/70341461/how-to-use-quicklookpreview-modifier-in-swiftui

    struct Visualization {
        var name: String        // The visualization's name is shown as text in the titlebar
        var location: AnyView   // A visualization's location is the View that renders it.
    }

    let visualizationList: [Visualization] =  [
            Visualization (name: "Spectrum",                        location: AnyView(Spectrum() ) ),
            Visualization (name: "Music Spectrum",                  location: AnyView(MusicSpectrum() ) ),
            Visualization (name: "MuSpectrum",                      location: AnyView(MuSpectrum() ) ),
            Visualization (name: "Spectrum Bars",                   location: AnyView(SpectrumBars() ) ),
            Visualization (name: "Linear OAS",                      location: AnyView(LinearOAS() ) ),
            Visualization (name: "Overlapped Octaves",              location: AnyView(OverlappedOctaves() ) ),
            Visualization (name: "Octave Aligned Spectrum",         location: AnyView(OctaveAlignedSpectrum() ) ),
            Visualization (name: "Octave Aligned Spectrum_both",    location: AnyView(OctaveAlignedSpectrum_both() ) ),
            Visualization (name: "Elliptical OAS",                  location: AnyView(EllipticalOAS() ) ),
            Visualization (name: "Spiral OAS",                      location: AnyView(SpiralOAS() ) ),
            Visualization (name: "Harmonic Alignment",              location: AnyView(HarmonicAlignment() ) ),
            Visualization (name: "Harmonic Alignment 2",            location: AnyView(HarmonicAlignment2() ) ),
            Visualization (name: "TriOct Spectrum",                 location: AnyView(TriOctSpectrum() ) ),
            Visualization (name: "TriOct MuSpectrum",               location: AnyView(TriOctMuSpectrum() ) ),
            Visualization (name: "Overlapped Harmonics",            location: AnyView(OverlappedHarmonics() ) ),
            Visualization (name: "Harmonograph",                    location: AnyView(Harmonograph() ) ),
            Visualization (name: "Cymbal",                          location: AnyView(Cymbal() ) ),
            Visualization (name: "Rainbow Spectrum",                location: AnyView(RainbowSpectrum() ) ),
            Visualization (name: "Rainbow Spectrum2",               location: AnyView(RainbowSpectrum2() ) ),
            Visualization (name: "Waterfall",                       location: AnyView(Waterfall() ) ),
            Visualization (name: "Rainbow OAS",                     location: AnyView(RainbowOAS() ) ),
            Visualization (name: "Rainbow Ellipse",                 location: AnyView(RainbowEllipse() ) ),
            Visualization (name: "Spinning Ellipse",                location: AnyView(SpinningEllipse() ) ),
            Visualization (name: "Out of the Rabbit Hole",          location: AnyView(OutOfTheRabbitHole() ) ),
            Visualization (name: "Down the Rabbit Hole",            location: AnyView(DownTheRabbitHole() ) ) ]



    var body: some View {

        VStack {

//----------------------------------------------------------------------------------------------------------------------
            // The following HStack constitutes the Top Toolbar:
            HStack {
            
                Text("Gain-")

                Slider(value: $audioManager.userGain, in: 0.0 ... 2.0)
                    .background(Capsule().stroke(Color.red, lineWidth: 2))
                    .onChange(of: audioManager.userGain, perform: {value in
                        audioManager.userGain = Float(value)
                })
                .help("This slider controls the gain of the visualization.")

                Slider(value: $audioManager.userSlope, in: 0.0 ... 0.03)
                    .background(Capsule().stroke(Color.red, lineWidth: 2))
                    .onChange(of: audioManager.userSlope, perform: {value in
                        audioManager.userSlope = Float(value)
                })
                .help("This slider controls the frequency slope of the visualization.")
                
                Text("-Treble")
                
            }  // end of HStack{}

//----------------------------------------------------------------------------------------------------------------------
            // The following ZStack consitutes the main "visualization rendering" pane:
            ZStack {
                ForEach(visualizationList.indices) {index in
                    ZStack{
                        if index == visNum {
                            visualizationList[index].location   // This is the main "visualization rendering" pane.
                            
                            // Use a dummy Path() to allow insertion of non-ViewBuilder code inside a View:
                            Path { path in
                                subtitle = visualizationList[index].name
                                path.move( to: CGPoint( x: 0.0, y: 0.0 ) )
                                path.addLine( to: CGPoint( x: 1.0, y: 1.0) )
                            }
                        }
                    }
                }
            }
            .drawingGroup()                     // improves graphics performance by utilizing off-screen buffers
            .colorScheme(settings.selectedColorScheme)  // sets the visualization pane's color scheme to either .dark or .light
            .background( (settings.selectedColorScheme == .light) ? Color.white : Color.darkGray )
            .navigationTitle("MuVis (Music Visualizer)  ")
            #if os(macOS)
                .navigationSubtitle("  \(subtitle)")  // 'navigationSubtitle' is unavailable in iOS
            #endif
            // https://developer.apple.com/documentation/swiftui/link/toolbar(content:)-8thcn
            

//----------------------------------------------------------------------------------------------------------------------
            // The following HStack constitutes the Bottom Toolbar:
            HStack {

                Group {
                    Button(action: {
                        visNum -= 1
                        if(visNum <= -1) {visNum = visualizationList.count - 1}
                        audioManager.onlyPeaks = false // Changing the visualization turns off the onlyPeaks variation.
                        settings.optionOn = false    // Changing the visualization turns off the optional visualization variation.
                    } ) {
                            Image(systemName: "chevron.left")
                    }
                    .keyboardShortcut(KeyEquivalent.leftArrow, modifiers: [])
                    .help("This button retreats to the previous visualization.")
                    .disabled(pauseButtonIsPaused)      // gray-out "Previous Vis" button if pauseButtonIsPaused is true
                    .padding(.trailing)



                    Button( action: {
                        visNum += 1
                        if(visNum >= visualizationList.count) {visNum = 0}
                        audioManager.onlyPeaks = false // Changing the visualization turns off the onlyPeaks variation.
                        settings.optionOn = false    // Changing the visualization turns off the optional visualization variation.
                    } ) {
                            Image(systemName: "chevron.right")
                    }
                    .keyboardShortcut(KeyEquivalent.rightArrow, modifiers: [])
                    .help("This button advances to the next visualization.")
                    .disabled(pauseButtonIsPaused)      // gray-out "Next Vis" button if pauseButtonIsPaused is true
                    .padding(.trailing)
                }


                Spacer()


                Button(action: {
                    if(audioManager.isPaused) { audioManager.startEngine() }    // User clicked on "Resume"
                    else { audioManager.pauseEngine() }                         // User clicked on "Pause"
                    audioManager.isPaused.toggle()
                    pauseButtonIsPaused.toggle()
                } ) {
                Text( (pauseButtonIsPaused) ? "Resume" : "Pause" )
                }
                .help("This button pauses or resumes the audio.")
                .padding(.trailing)



                Button( action: {
                    // It is crucial that micEnabled and filePlayEnabled are opposite - never both true or both false.
                    audioManager.micEnabled.toggle()         // This is the only place in the MuVis app that micEnabled is changed.
                    audioManager.filePlayEnabled.toggle()    // This is the only place in the MuVis app that filePlayEnabled is changed.
                    audioManager.setupAudio()
                    } ) {
                    Text( (audioManager.micEnabled) ? "Mic Off" : "Mic On")
                }
                .help("This button turns the microphone on and off.")
                .disabled(pauseButtonIsPaused)   // gray-out "Mic On/Off" button if pauseButtonIsPaused is true
                .padding(.trailing)



                Button( action: {
                    settings.previousAudioURL.stopAccessingSecurityScopedResource()
                    if(audioManager.filePlayEnabled) {enableSongFileSelection = true} } ) {
                    Text("Song")
                }
                .help("This button opens a pop-up pane to select a song file.")
                .disabled(audioManager.micEnabled)  // gray-out "Select Song" button if mic is enabled
                .disabled(pauseButtonIsPaused)      // gray-out "Select Song" button if pauseButtonIsPaused is true
                .fileImporter(
                    isPresented: $enableSongFileSelection,
                    allowedContentTypes: [.audio],
                    allowsMultipleSelection: false
                    ) { result in
                    if case .success = result {
                        do {
                            let audioURL: URL = try result.get().first!
                            settings.previousAudioURL = audioURL
                            if audioURL.startAccessingSecurityScopedResource() {
                                let path: String = audioURL.path
                                // path = /Users/JohnDoe/Music/Santana/Stormy.m4a
                                audioManager.selectedSongURL = URL(fileURLWithPath: path)
                                // URL = file:///Users/JohnDoe/Music/Santana/Stormy.m4a
                                if(audioManager.filePlayEnabled) {audioManager.setupAudio()}
                            }
                        } catch {
                            let nsError = error as NSError
                            fatalError("File Import Error \(nsError), \(nsError.userInfo)")
                        }
                    } else {
                            print("File Import Failed")
                    }
                }
                .padding(.trailing)



                Button(action: { audioManager.onlyPeaks.toggle() } ) {
                    Text( (audioManager.onlyPeaks == true) ? "Normal" : "Peaks")
                }
                .help("This button enhances the peaks by subtracting the background spectrum.")
                .disabled(pauseButtonIsPaused)   // gray-out "Peaks/Normal" button if pauseButtonIsPaused is true
                .padding(.trailing)



                Button(action: { settings.optionOn.toggle() } ) {
                    Text( (settings.optionOn == true) ? "Option Off" : "Option On")
                }
                .help("This button shows a variation of the visualization.")
                .keyboardShortcut(KeyEquivalent.downArrow, modifiers: []) // downArrow key toggles "Option On" button
                .padding(.trailing)


                
                Button( action: self.toggleColorScheme ) {
                    Text( (settings.selectedColorScheme == .dark) ? "Light" : "Dark")
                }
                .keyboardShortcut(KeyEquivalent.upArrow, modifiers: [])
                .help("This button chooses light- or dark-mode.")
                .padding(.trailing)



                Button(action: {
                    userGuideUrl = Bundle.main.url(forResource: "UserGuide", withExtension: "pdf", subdirectory: "Documentation")
                } ) {
                    Text("UserG")
                }
                .help("This button displays the User Guide.")
                .quickLookPreview($userGuideUrl)
                // https://developer.apple.com/documentation/swiftui/view/quicklookpreview(_:)?language=objc_9



                Button(action: {
                    visualizationsGuideUrl = Bundle.main.url(forResource: "Visualizations", withExtension: "pdf", subdirectory: "Documentation")
                } ) {
                    Text("VisG")
                }
                .help("This button displays the Visualizations Guide.")
                .quickLookPreview($visualizationsGuideUrl)
                // https://developer.apple.com/documentation/swiftui/view/quicklookpreview(_:)?language=objc_9

            }  // end of HStack{}

        }  // end of VStack{}

   }  // end of var body: some View
    


    // https://stackoverflow.com/questions/61912363/swiftui-how-to-implement-dark-mode-toggle-and-refresh-all-views
    func toggleColorScheme() {
        settings.selectedColorScheme = (settings.selectedColorScheme == .dark) ? .light : .dark
    }
    
}  // end of ContentView struct



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
