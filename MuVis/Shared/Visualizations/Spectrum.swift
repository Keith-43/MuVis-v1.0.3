///  Spectrum.swift
///  MuVis
///
/// This view renders a visualization of the simple one-dimensional spectrum (using a mean-square amplitude scale) of the music.
///
/// We could render a full Spectrum - that is, rendering all of the 8,192 bins -  covering a frequency range from 0 Hz on the left to about 44,100 / 2 = 22,050 Hz
/// on the right . But instead, we will render the spectrum bins from 12 to 3021 - that is the 8 octaves from 32 Hz to 8,193 Hz.
///
/// In the lower plot, the horizontal axis is linear frequency (from 32 Hz on the left to 4,066 Hz on the right). The vertical axis shows (in red) the mean-square
/// amplitude of the instantaneous spectrum of the audio being played. The red peaks are spectral lines depicting the harmonics of the musical notes
/// being played. The blue curve is a smoothed average of the red curve (computed by the findMean function within the SpectralEnhancer class).
/// The blue curve typically represents percussive effects which smear spectral energy over a broad range.
///
/// The upper plot (in green) is the same as the lower plot except the vertical scale is decibels (over an 80 dB range) instead of the mean-square amplitude.
/// This more closely represents what the human ear actually hears.
///
/// Created by Keith Bromley on 20 Nov 2020.  Significantly updated on 28 Oct 2021.

import SwiftUI
import Accelerate


struct Spectrum: View {

    @EnvironmentObject var audioManager: AudioManager  // Observe the instance of AudioManager passed from ContentView
    @EnvironmentObject var settings: Settings
    var spectralEnhancer = SpectralEnhancer()
    
    var body: some View {
    
        // Toggle between black and white as the Canvas's background color:
        let backgroundColor: Color = (settings.selectedColorScheme == .dark) ? Color.black : Color.white
        
         Canvas { context, size in

            let width: Double  = size.width
            let height: Double = size.height
            let halfHeight: Double = height * 0.5

            let lowerBin = 12           // render the spectrum bins from 12 to 3021
            let upperBin = 3021         // render the spectrum bins from 12 to 3021
            var x: Double = 0.0         // The drawing origin is in the upper left corner.
            var y: Double = 0.0         // The drawing origin is in the upper left corner.
            var upRamp: Double = 0.0
            var dB: Float = 0.0
            let dBmin: Float =  1.0 + 0.0125 * 20.0 * log10(0.001)
            var amplitude: Float = 0.0
            var magY: Double = 0.0             // used as a preliminary part of the "y" value
            
            // Declare the array of mean spectrum values of the current frame of audio samples:
            var meanSpectrum: [Float] = [Float](repeating: 0.0, count: AudioManager.binCount)
            // Declare the array of dB-scale spectrum values of the current frame of audio samples:
            var dB_Spectrum:  [Float] = [Float](repeating: 0.0, count: AudioManager.binCount)
            // Declare the array of mean dB-scale spectrum values of the current frame of audio samples:
            var mean_dB_Spectrum: [Float] = [Float](repeating: 0.0, count: AudioManager.binCount)
            
            
// ---------------------------------------------------------------------------------------------------------------------
            // Optionally, for each octave, render gray rectangles depicting each of the 7 accidental notes:

            if(settings.optionOn) {
                //                               C      C#    D      D#     E     F      F#    G      G#    A      A#    B
                let accidentalNote: [Bool] = [  false, true, false, true, false, false, true, false, true, false, true, false,
                                                false, true, false, true, false, false, true, false, true, false, true, false,
                                                false, true, false, true, false, false, true, false, true, false, true, false,
                                                false, true, false, true, false, false, true, false, true, false, true, false,
                                                false, true, false, true, false, false, true, false, true, false, true, false,
                                                false, true, false, true, false, false, true, false, true, false, true, false,
                                                false, true, false, true, false, false, true, false, true, false, true, false,
                                                false, true, false, true, false, false, true, false, true, false, true, false ]
                let octaveCount = 8
                for oct in 0 ..< octaveCount {              //  0 <= oct < 8
                    for note in 0 ..< notesPerOctave {      // notesPerOctave = 12
                    
                        let cumulativeNotes: Int = oct * notesPerOctave + note  // cumulativeNotes = 0, 1, 2, 3, ... 95
                        
                        if(accidentalNote[cumulativeNotes] == true) {  // This condition selects the column values for the notes C#, D#, F#, G#, and A#
                    
                            let leftNoteFreq: Float  = settings.leftFreqC1  * pow(settings.twelfthRoot2, Float(cumulativeNotes) )
                            let rightFreqC1: Float   = settings.freqC1 * settings.twentyFourthRoot2
                            let rightNoteFreq: Float = rightFreqC1 * pow(settings.twelfthRoot2, Float(cumulativeNotes) )
                            
                            // The x-axis is frequency (in Hz) and covers the 7 octaves from 32 Hz to 4,066 Hz.
                            x = width * ( ( Double(leftNoteFreq) - 32.0 ) / (4066.0 - 32.0) )
                    
                            var path = Path()
                            path.move(   to: CGPoint( x: x, y: height ) )
                            path.addLine(to: CGPoint( x: x, y: 0.0))
                            
                            x = width * ( ( Double(rightNoteFreq) - 32.0 ) / (4066.0 - 32.0) )
                            
                            path.addLine(to: CGPoint( x: x, y: 0.0))
                            path.addLine(to: CGPoint( x: x, y: height))
                            path.closeSubpath()
                        
                            context.fill( path,
                                          with: .color( (settings.selectedColorScheme == .light) ?
                                                        Color.lightGray.opacity(0.25) :
                                                        Color.black.opacity(0.25) ) )

                            // context.stroke( path,
                            //                 with: .color( Color.black),
                            //                 lineWidth: 1.0 )
                        }
                    }  // end of for() loop over note
                }  // end of for() loop over oct
            }  // end of if(optionOn) conditional


// ---------------------------------------------------------------------------------------------------------------------
            // First, render the rms amplitude spectrum in red in the lower half pane:
            // We will render the spectrum bins from 12 to 3021 - that is the 8 octaves from 32 Hz to 8,133 Hz.

            var path = Path()
            path.move(to: CGPoint( x: Double(0.0), y: height - Double(audioManager.spectrum[lowerBin]) * halfHeight ) )

            for bin in lowerBin ... upperBin {
                // upRamp goes from 0.0 to 1.0 as bin goes from lowerBin to upperBin:
                upRamp =  Double(bin - lowerBin) / Double(upperBin - lowerBin)
                x = upRamp * width
                
                magY = Double(audioManager.spectrum[bin]) * halfHeight  // index out of range
                magY = min(max(0.0, magY), halfHeight)
                y = height - magY
                path.addLine(to: CGPoint(x: x, y: y))
            }

            context.stroke( path,
                            with: .color( Color(red: 1.0, green: 0.0, blue: 0.0) ),
                            lineWidth: 2.0 )


// ---------------------------------------------------------------------------------------------------------------------
            // Second, render the mean of the rms amplitude spectrum in blue:
            // We will render the spectrum bins from 12 to 3021 - that is the 8 octaves from 32 Hz to 8,133 Hz.
            
            if(audioManager.onlyPeaks == false) {
                meanSpectrum = spectralEnhancer.findMean(inputArray: audioManager.spectrum)
                
                path = Path()
                path.move(to: CGPoint(x: Double(0.0), y: height - Double(meanSpectrum[lowerBin]) * halfHeight) )
                    
                for bin in lowerBin ... upperBin {
                    // upRamp goes from 0.0 to 1.0 as bin goes from lowerBin to upperBin:
                    upRamp =  Double(bin - lowerBin) / Double(upperBin - lowerBin)
                    x = upRamp * width
                    
                    magY = Double(meanSpectrum[bin] ) * halfHeight
                    magY = min(max(0.0, magY), halfHeight)
                    y = height - magY
                    path.addLine(to: CGPoint(x: x, y: y))
                }

                context.stroke( path,
                                with: .color( Color(red: 0.0, green: 0.0, blue: 1.0) ),
                                lineWidth: 2.0 )
            }

// ---------------------------------------------------------------------------------------------------------------------
            // Third, render the decibel-scale spectrum in green in the upper half pane:
            // We will render the spectrum bins from 12 to 3021 - that is the 8 octaves from 32 Hz to 8,133 Hz.

            /*
            vDSP.convert( amplitude: audioManager.spectrum,
                          toDecibels: &dB_Spectrum,
                          zeroReference: Float(AudioManager.binCount))
            y = Double( 0.01 * -dB_Spectrum[bin] ) * halfHeight - quarterHeight
            */
            
            path = Path()
            path.move( to: CGPoint( x: 0.0, y: halfHeight - Double( audioManager.spectrum[lowerBin] ) * halfHeight ) )

            for bin in lowerBin ... upperBin {
                // upRamp goes from 0.0 to 1.0 as bin goes from lowerBin to upperBin:
                upRamp =  Double(bin - lowerBin) / Double(upperBin - lowerBin)
                x = upRamp * width

                // I must raise 10 to the power of -4 to get my lowest dB value (0.001) to 20*(-4) = 80 dB
                amplitude = audioManager.spectrum[bin]
                if(amplitude < 0.001) { amplitude = 0.001 }
                dB = 20.0 * log10(amplitude)    // As 0.001  < spectrum < 1 then  -80 < dB < 0
                dB = 1.0 + 0.0125 * dB          // As 0.001  < spectrum < 1 then    0 < dB < 1
                dB = dB - dBmin
                dB = min(max(0.0, dB), 1.0)
                dB_Spectrum[bin] = dB           // We use this array below in creating the mean spectrum
                magY = Double(dB) * halfHeight
                y = halfHeight - magY
                path.addLine(to: CGPoint(x: x, y: y))
            }

            context.stroke( path,
                            with: .color( Color(red: 0.0, green: 1.0, blue: 0.0) ),
                            lineWidth: 2.0 )

            
            
// ---------------------------------------------------------------------------------------------------------------------
            // Fourth, render the mean of the decibel-scale spectrum in blue:
            // We will render the spectrum bins from 12 to 3021 - that is the 8 octaves from 32 Hz to 8,133 Hz.

            if(audioManager.onlyPeaks == false) {
                mean_dB_Spectrum = spectralEnhancer.findMean(inputArray: dB_Spectrum)

                path = Path()
                path.move( to: CGPoint( x: Double(0.0), y: halfHeight - Double(mean_dB_Spectrum[lowerBin]) * halfHeight) )

                for bin in lowerBin ... upperBin {
                    // upRamp goes from 0.0 to 1.0 as bin goes from lowerBin to upperBin:
                    upRamp =  Double(bin - lowerBin) / Double(upperBin - lowerBin)
                    x = upRamp * width
                    magY = Double( mean_dB_Spectrum[bin] ) * halfHeight
                    magY = min(max(0.0, magY), halfHeight)
                    y = halfHeight - magY
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                context.stroke( path,
                                with: .color( Color(red: 0.0, green: 0.0, blue: 1.0) ),
                                lineWidth: 2.0 )
            }
            
            

            // Print on-screen the elapsed duration-per-frame (in milliseconds) (typically about 50)
            if(showMSPF == true) {
                let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                context.draw(Text("MSPF: \( settings.monitorPerformance() )"), in: frame )
            }

        }  // end of Canvas{}
        .background( (settings.optionOn) ? Color.clear : backgroundColor )

    }  // end of var body: some View{}
}  // end of Spectrum_EightOctaves{} struct



struct Spectrum_Previews: PreviewProvider {
    static var previews: some View {
        Spectrum()
    }
}
