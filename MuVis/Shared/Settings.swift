///  Settings.swift
///  MuVis
///
///  From the spectrum of the audio signal, we are interested in the frequencies between note C1 (about 33 Hz) and note B8 (about 7,902 Hz).  These 96 notes
///  covers 8 octaves.  This file defines some constants and variables used in some of the classes and views.
///
///  Created by Keith Bromley on 16 Feb 20/21.


import Foundation
import SwiftUI


class Settings: ObservableObject {

    static let settings = Settings()  // This singleton instantiates the Settings class

    init() {
        self.calculateParameters()
    }

    let twelfthRoot2      : Float = pow(2.0, 1.0 / 12.0)     // twelfth root of two = 1.059463094359
    let twentyFourthRoot2 : Float = pow(2.0, 1.0 / 24.0)     // twenty-fourth root of two = 1.029302236643

    // User Settings:
    // The following are variables that the app's user gets to adjust - using the buttons and sliders provided in
    // the user interface within the ContentView struct.

    @Published var selectedColorScheme: ColorScheme = .light  // allows user to select light or dark mode
                                                // Changed in ContentView; Published to all visualizations

    @Published var optionOn: Bool = false       // allows user to view a variation on each visualization
                                                // Changed in ContentView; Published to all visualizations


    // Developer Settings:
    // The following are constants and variables that the app's developer has selected for optimum performance.
    // Sometimes variables need to be here for persistence between instantiantions of a visualization.

    var colorIndex: Int = 0     // used in Harmonograph, RainbowSpectrum2, Wormhole, OutOfTheRabbitHole, DownTheRabbitHole
    var hueOld: [Double] = [Double](repeating: 0.0, count: 64)  // used in RainbowEllipse, OutOfTheRabbitHole, DownTheRabbitHole

    var oldHorAngle: Double = 0.0  // old angle of horizontal waveform      used in Harmomograph
    var oldVerAngle: Double = 0.0  // old angle of vertical waveform        used in Harmonograph

    var oldAngleL0: Double = 0.0    // old angle of waveformL0      used in Harmomograph
    var oldAngleL1: Double = 0.0    // old angle of waveformL1      used in Harmomograph
    var oldAngleL2: Double = 0.0    // old angle of waveformL2      used in Harmomograph
    var oldAngleL3: Double = 0.0    // old angle of waveformL3      used in Harmomograph
    var oldAngleU0: Double = 0.0    // old angle of waveformU0      used in Harmomograph
    var oldAngleU1: Double = 0.0    // old angle of waveformU1      used in Harmomograph
    var oldAngleU2: Double = 0.0    // old angle of waveformU2      used in Harmomograph
    var oldAngleU3: Double = 0.0    // old angle of waveformU3      used in Harmomograph

    var previousAudioURL: URL = URL(string: "https://www.google.com")!
    

    // variables used to transform the spectrum into an "octave-aligned" spectrum:
    var freqC1: Float = 0.0         // The lowest note of interest is C1 (about 33 Hz Hz)
    var leftFreqC1: Float = 0.0
    var leftFreqC2: Float = 0.0
    var freqB8: Float = 0.0
    var rightFreqB8: Float = 0.0
    
    // The 8-octave spectrum covers the range from leftFreqC1=31.77 Hz to rightFreqB8=8133.84 Hz - that is from bin=12 to bin=3020
    // The FFT provides us with 8192 bins.  We will ignore the bin values above 3020.
    var leftOctFreq  = [Double](repeating: 0.0, count: 8) // frequency at the left window border for a given octave
    var rightOctFreq = [Double](repeating: 0.0, count: 8) // frequency at the right window border for a given octave
    var octBinCount  = [Int](repeating: 0, count: 8)   // number of spectral bins in each octave
    var octBottomBin = [Int](repeating: 0, count: 8)   // the bin number of the bottom spectral bin in each octave
    var octTopBin    = [Int](repeating: 0, count: 8)   // the bin number of the top spectral bin in each octave

    // This is an array of scaling factors to multiply the octaveWidth to get the x coordinate:
    var binXFactor = [Double](repeating: 0.0, count: AudioManager.binCount8)  // binCount8 = 3,022

    var theta: Double = 0.0                                     // 0 <= theta < 1 is the angle around the ellipse
    let pointIncrement: Double = 1.0 / Double(sixOctPointCount)         // pointIncrement = 1 / 864
    var cos2PiTheta = [Double](repeating: 0.0, count: sixOctPointCount) // cos(2 * Pi * theta)
    var sin2PiTheta = [Double](repeating: 0.0, count: sixOctPointCount) // sin(2 * Pi * theta)
    
    
    // ----------------------------------------------------------------------------------------------------------------
    // Let's calculate a few frequency values and bin values common to many of the music visualizations:
    func calculateParameters() {

        // Calculate the lower bound of our frequencies-of-interest:
        freqC1 = 55.0 * pow(twelfthRoot2, -9.0)     // C1 = 32.7032 Hz
        leftFreqC1 = freqC1 / twentyFourthRoot2     // leftFreqC1 = 31.772186 Hz
        leftFreqC2 = 2.0 * leftFreqC1               // C1 = 32.7032 Hz    C2 = 65.4064 Hz
    
        // Calculate the upper bound of our frequencies-of-interest:
        freqB8  = 7040.0 * pow(twelfthRoot2, 2.0)   // B8 = 7,902.134 Hz
        rightFreqB8 = freqB8 * twentyFourthRoot2    // rightFreqB8 = 8,133.684 Hz

        // For each octave, calculate the left-most and right-most frequencies:
        for oct in 0 ..< 8 {    // 0 <= oct < 8
            let octD = Double(oct)
            let pow2oct: Double = pow( 2.0, octD )
            leftOctFreq[oct]  = pow2oct * Double( leftFreqC1 ) // 31.77  63.54 127.09 254.18  508.35 1016.71 2033.42 4066.84 Hz
            rightOctFreq[oct] = pow2oct * Double( leftFreqC2 ) // 63.54 127.09 254.18 508.35 1016.71 2033.42 4066.84 8133.68 Hz
        }

        let binFreqWidth = ( Double(AudioManager.sampleRate) / 2.0 ) / Double(AudioManager.binCount)     //  (44,100/2) / 8,192 = 2.69165 Hz

        // Calculate the number of bins in each octave:
        for oct in 0 ..< 8 {    // 0 <= oct < 8
            var bottomBin: Int = 0
            var topBin: Int = 0
            var startNewOct: Bool = true

            for bin in 0 ..< AudioManager.binCount {
                let binFreq: Double = Double(bin) * binFreqWidth
                if (binFreq < leftOctFreq[oct]) { continue } // For each row, ignore bins with frequency below the leftFreq.
                if (startNewOct) { bottomBin = bin; startNewOct = false }
                if (binFreq > rightOctFreq[oct]) {topBin = bin-1; break} // For each row, ignore bins with frequency above the rightFreq.
            }
            octBottomBin[oct] = bottomBin               // 12, 24, 48,  95, 189, 378,  756,  1511
            octTopBin[oct] = topBin                     // 23, 47, 94, 188, 377, 755, 1510,  3021
            octBinCount[oct] = topBin - bottomBin + 1   // 12, 24, 47,  94, 189, 378,  755,  1511
        }

        // Calculate the exponential x-coordinate scaling factor:
        for oct in 0 ..< 8 {    // 0 <= oct < 8
            for bin in octBottomBin[oct] ... octTopBin[oct] {
                let binFreq: Double = Double(bin) * binFreqWidth
                let binFraction: Double = (binFreq - leftOctFreq[oct]) / (rightOctFreq[oct] - leftOctFreq[oct]) // 0 < binFraction < 1.0
                let freqFraction: Double = pow(Double(twelfthRoot2), 12.0 * binFraction) // 1.0 < freqFraction < 2.0
                
                // This is an array of scaling factors to multiply the octaveWidth to get the x coordinate:
                binXFactor[bin] =  (2.0 - (2.0 / freqFraction))
                // If freqFraction = 1.0 then binXFactor = 0; If freqFraction = 2.0 then binXFactor = 1.0
                // print(oct,   bin,   binXFactor[bin])
            }
        }

        // Calculate the angle theta from dividing a circle into sixOctPointCount angular increments:
        for point in 0 ..< sixOctPointCount {           // sixOctPointCount = 72 * 12 = 864
            theta = Double(point) * pointIncrement
            cos2PiTheta[point] = cos(2.0 * Double.pi * theta)
            sin2PiTheta[point] = sin(2.0 * Double.pi * theta)
        }
        
    }  // end of calculateParameters() func
    
    
    
    
    // Performance Monitoring:
    var date = NSDate()
    var timePassed: Double = 0.0
    var displayedTimePassed: Double = 0.0
    var counter: Int = 0     // simple counter   0 <= counter < 5
    
    func monitorPerformance() -> (Int) {

        // Find the elapsed time since the last timer reset:
        let timePassed: Double = -date.timeIntervalSinceNow
        // print( lround( 1000.0 * timePassed ) )  // Gives frame-by-frame timing for debugging.
        // the global variable "counter" counts from 0 to 4 continuously (incrementing by one each frame):
        counter = (counter < 4) ? counter + 1 : 0
        // Every fifth frame update the "displayedTimePassed" and render it on the screen:
        if (counter == 4) {displayedTimePassed = timePassed}
        let mspFrame: Int = lround( 1000.0 * displayedTimePassed )
        date = NSDate() // Reset the timer to the current time.  <- Done just before start of visualization rendering.
        return mspFrame
    }  // end of monitorPerformance() func
    



    // Convert HSB colors to RGB colors:
    // hue = 0 is red; 1/6 is yellow; 1/3 is green; 1/2 is cyan; 2/3 is blue; 5/6 is magenta; 1.0 is red
    // en.wikipedia.org/wiki/HSL_and_HSV
    // developer.apple.com/forums/thread/119289
    // simpleswiftguide.com/how-to-return-multiple-values-from-function-in-swift/
    func HSBtoRGB   ( hueValue: Double, saturationValue: Double, brightnessValue: Double) ->
                    ( redValue: Double, greenValue: Double,      blueValue: Double ) {
        var redH:   Double = 0.0
        var greenH: Double = 0.0
        var blueH:  Double = 0.0
        let hue:    Double = hueValue * 6.0

        if       (hue <= 1.0)   { redH = 1.0;       greenH = hue;       blueH = 0.0
        }else if (hue <  2.0)   { redH = 2.0 - hue; greenH = 1.0;       blueH = 0.0
        }else if (hue <  3.0)   { redH = 0.0;       greenH = 1.0;       blueH = hue - 2.0
        }else if (hue <  4.0)   { redH = 0.0;       greenH = 4.0 - hue; blueH = 1.0
        }else if (hue <  5.0)   { redH = hue - 4.0; greenH = 0.0;       blueH = 1.0
        }else                   { redH = 1.0;       greenH = 0.0;       blueH = 6.0 - hue
        }

        let tempDouble1: Double = (1.0 - saturationValue) * brightnessValue
        let tempDouble2: Double = saturationValue * brightnessValue

        let redValue: Double   = (tempDouble1 + tempDouble2 * redH  )
        let greenValue: Double = (tempDouble1 + tempDouble2 * greenH)
        let blueValue: Double  = (tempDouble1 + tempDouble2 * blueH )
        return (redValue, greenValue, blueValue)

    }  // end of HSBtoRGB() func


    // Array stating which notes are accidentals:
    //                               C      C#    D      D#     E     F      F#    G      G#    A      A#    B
    let accidentalNote: [Bool] = [  false, true, false, true, false, false, true, false, true, false, true, false,
                                    false, true, false, true, false, false, true, false, true, false, true, false,
                                    false, true, false, true, false, false, true, false, true, false, true, false,
                                    false, true, false, true, false, false, true, false, true, false, true, false,
                                    false, true, false, true, false, false, true, false, true, false, true, false,
                                    false, true, false, true, false, false, true, false, true, false, true, false,
                                    false, true, false, true, false, false, true, false, true, false, true, false ]


/*  Cycling through the 6 "hue" colors is a convenient representation for cycling through the 12 notes of an octave:
           red        yellow      green        cyan       blue       magenta       red
      hue = 0          1/6         2/6         3/6         4/6         5/6          1
            |-----------|-----------|-----------|-----------|-----------|-----------|
     note = 0     1     2     3     4     5     6     7     8     9    10    11     0
            C     C#    D     D#    E     F     F#    G     G#    A     A#    B     C
*/

    // Define a Gradient that cycles through the same color sequence as the standard "hue":
    // This is used in the OctaveAlignedSpectrum visualization.
    let hueGradient: Gradient = Gradient(colors: [Color(red: 1.0, green: 0.0, blue: 0.0),     // red
                                                  Color(red: 1.0, green: 1.0, blue: 0.0),     // yellow
                                                  Color(red: 0.0, green: 1.0, blue: 0.0),     // green
                                                  Color(red: 0.0, green: 1.0, blue: 1.0),     // cyan
                                                  Color(red: 0.0, green: 0.0, blue: 1.0),     // blue
                                                  Color(red: 1.0, green: 0.0, blue: 1.0),     // magenta
                                                  Color(red: 1.0, green: 0.0, blue: 0.0)])    // red


    // Define a Gradient that cycles 3 times through the same color sequence as the standard "hue":
    // This is used in the TriOctMuSpectrum visualization.
    let hue3Gradient: Gradient = Gradient(colors: [Color(red: 1.0, green: 0.0, blue: 0.0),     // red
                                                   Color(red: 1.0, green: 1.0, blue: 0.0),     // yellow
                                                   Color(red: 0.0, green: 1.0, blue: 0.0),     // green
                                                   Color(red: 0.0, green: 1.0, blue: 1.0),     // cyan
                                                   Color(red: 0.0, green: 0.0, blue: 1.0),     // blue
                                                   Color(red: 1.0, green: 0.0, blue: 1.0),     // magenta
                                                   Color(red: 1.0, green: 0.0, blue: 0.0),     // red
                                                   Color(red: 1.0, green: 1.0, blue: 0.0),     // yellow
                                                   Color(red: 0.0, green: 1.0, blue: 0.0),     // green
                                                   Color(red: 0.0, green: 1.0, blue: 1.0),     // cyan
                                                   Color(red: 0.0, green: 0.0, blue: 1.0),     // blue
                                                   Color(red: 1.0, green: 0.0, blue: 1.0),     // magenta
                                                   Color(red: 1.0, green: 0.0, blue: 0.0),     // red
                                                   Color(red: 1.0, green: 1.0, blue: 0.0),     // yellow
                                                   Color(red: 0.0, green: 1.0, blue: 0.0),     // green
                                                   Color(red: 0.0, green: 1.0, blue: 1.0),     // cyan
                                                   Color(red: 0.0, green: 0.0, blue: 1.0),     // blue
                                                   Color(red: 1.0, green: 0.0, blue: 1.0),     // magenta
                                                   Color(red: 1.0, green: 0.0, blue: 0.0)])    // red
                                                  
                                                  
    // Define a Gradient that cycles 6 times through the same color sequence as the standard "hue":
    // This is used in the Wormhole visualization.
    let hue6Gradient: Gradient = Gradient(colors: [Color(red: 1.0, green: 0.0, blue: 0.0),     // red
                                                   Color(red: 1.0, green: 1.0, blue: 0.0),     // yellow
                                                   Color(red: 0.0, green: 1.0, blue: 0.0),     // green
                                                   Color(red: 0.0, green: 1.0, blue: 1.0),     // cyan
                                                   Color(red: 0.0, green: 0.0, blue: 1.0),     // blue
                                                   Color(red: 1.0, green: 0.0, blue: 1.0),     // magenta
                                                   Color(red: 1.0, green: 0.0, blue: 0.0),     // red
                                                   Color(red: 1.0, green: 1.0, blue: 0.0),     // yellow
                                                   Color(red: 0.0, green: 1.0, blue: 0.0),     // green
                                                   Color(red: 0.0, green: 1.0, blue: 1.0),     // cyan
                                                   Color(red: 0.0, green: 0.0, blue: 1.0),     // blue
                                                   Color(red: 1.0, green: 0.0, blue: 1.0),     // magenta
                                                   Color(red: 1.0, green: 0.0, blue: 0.0),     // red
                                                   Color(red: 1.0, green: 1.0, blue: 0.0),     // yellow
                                                   Color(red: 0.0, green: 1.0, blue: 0.0),     // green
                                                   Color(red: 0.0, green: 1.0, blue: 1.0),     // cyan
                                                   Color(red: 0.0, green: 0.0, blue: 1.0),     // blue
                                                   Color(red: 1.0, green: 0.0, blue: 1.0),     // magenta
                                                   Color(red: 1.0, green: 0.0, blue: 0.0),     // red
                                                   Color(red: 1.0, green: 1.0, blue: 0.0),     // yellow
                                                   Color(red: 0.0, green: 1.0, blue: 0.0),     // green
                                                   Color(red: 0.0, green: 1.0, blue: 1.0),     // cyan
                                                   Color(red: 0.0, green: 0.0, blue: 1.0),     // blue
                                                   Color(red: 1.0, green: 0.0, blue: 1.0),     // magenta
                                                   Color(red: 1.0, green: 0.0, blue: 0.0),     // red
                                                   Color(red: 1.0, green: 1.0, blue: 0.0),     // yellow
                                                   Color(red: 0.0, green: 1.0, blue: 0.0),     // green
                                                   Color(red: 0.0, green: 1.0, blue: 1.0),     // cyan
                                                   Color(red: 0.0, green: 0.0, blue: 1.0),     // blue
                                                   Color(red: 1.0, green: 0.0, blue: 1.0),     // magenta
                                                   Color(red: 1.0, green: 0.0, blue: 0.0),     // red
                                                   Color(red: 1.0, green: 1.0, blue: 0.0),     // yellow
                                                   Color(red: 0.0, green: 1.0, blue: 0.0),     // green
                                                   Color(red: 0.0, green: 1.0, blue: 1.0),     // cyan
                                                   Color(red: 0.0, green: 0.0, blue: 1.0),     // blue
                                                   Color(red: 1.0, green: 0.0, blue: 1.0),     // magenta
                                                   Color(red: 1.0, green: 0.0, blue: 0.0)])    // red



}  // end of Settings{} class
