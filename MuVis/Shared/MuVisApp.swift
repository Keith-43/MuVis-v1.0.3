///  MuVisApp.swift
///  MuVis
///
///  This file defines some global constants and variables, and then launches the MuVis app's ContentView.
///
///  Created by Keith Bromley on 17 Nov 2020.


import SwiftUI

// Declare and intialize global constants and variables:
var showMSPF: Bool = false			// display the Performance Monitor's "milliseconds per frame"
var subtitle: String = "hello"      // needed in ContentView()

let notesPerOctave   = 12   // An octave contains 12 musical notes.
let pointsPerNote    = 12   // The number of frequency samples within one musical note.
let pointsPerOctave  = notesPerOctave * pointsPerNote  // 12 * 12 = 144

let totalNoteCount   = 96   // from C1 to B8 is 96 notes  (  0 <= note < 96 ) (This covers 8 octaves.)
let totalPointCount  = totalNoteCount * pointsPerNote  // 96 * 12 = 1,152  // total number of points provided by the interpolator

let sixOctNoteCount  = 72	// the number of notes within six octaves
let sixOctPointCount = sixOctNoteCount * pointsPerNote  // 72 * 12 = 864   // number of points within six octaves

var historyCount: Int = 48  // Keep the 48 most-recent values of muSpectrum[point] in a circular buffer


// Declare and defined:
extension Color {
    static let lightGray        = Color(red: 0.7, green: 0.7, blue: 0.7)    // denotes accidental notes in keyboard overlay in light mode
    static let darkGray         = Color(red: 0.3, green: 0.3, blue: 0.3)    // denotes natural notes in keyboard overlay in dark mode
    
    static let noteC_Color      = Color(red: 1.0, green: 0.0, blue: 0.0)    // red
    static let noteCsharp_Color = Color(red: 1.0, green: 0.5, blue: 0.0)
    static let noteD_Color      = Color(red: 1.0, green: 1.0, blue: 0.0)    // yellow
    static let noteDsharp_Color = Color(red: 0.1, green: 1.0, blue: 0.0)
    static let noteE_Color      = Color(red: 0.0, green: 1.0, blue: 0.0)    // green
    static let noteF_Color      = Color(red: 0.0, green: 1.0, blue: 0.7)
    static let noteFsharp_Color = Color(red: 0.0, green: 1.0, blue: 1.0)    // cyan
    static let noteG_Color      = Color(red: 0.0, green: 0.5, blue: 1.0)
    static let noteGsharp_Color = Color(red: 0.0, green: 0.0, blue: 1.0)	// blue
    static let noteA_Color      = Color(red: 0.5, green: 0.0, blue: 1.0)
    static let noteAsharp_Color = Color(red: 1.0, green: 0.0, blue: 1.0)    // magenta
    static let noteB_Color      = Color(red: 1.0, green: 0.0, blue: 0.7)
}

let noteColor: [Color] = [  Color.noteC_Color, Color.noteCsharp_Color, Color.noteD_Color, Color.noteDsharp_Color,
                            Color.noteE_Color, Color.noteF_Color, Color.noteFsharp_Color, Color.noteG_Color,
                            Color.noteGsharp_Color, Color.noteA_Color, Color.noteAsharp_Color, Color.noteB_Color ]
// These colors are used in VisUtilities and then in the LinearOAS, TriOctSpectrum, and OverlappedHarmonics visualizations.



@main
struct MuVisApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                    .environmentObject(AudioManager.audioManager)
                    .environmentObject(Settings.settings)
                    .frame( minWidth:  100.0, idealWidth:  800.0, maxWidth:  .infinity,
                            minHeight: 100.0, idealHeight: 800.0, maxHeight: .infinity, alignment: .center)
                    // .ignoresSafeArea()
        }
    }
}
