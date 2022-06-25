///  Spectrum.swift
///  MuVis
///
/// This view renders a visualization of the simple one-dimensional spectrum (using a mean-square amplitude scale) of the music. However, the horizontal scale is
/// rendered logarithmically to account for the logarithmic relationship between spectrum bins and musical octaves.  The spectrum covers 8 octaves from
/// leftFreqC1 = 31.77 Hz to rightFreqB8 = 8133.68 Hz -  that is from bin = 12 to bin = 3021.
///
/// In the lower plot, the vertical axis shows (in red) the mean-square amplitude of the instantaneous spectrum of the audio being played. The red peaks are spectral
/// lines depicting the harmonics of the musical notes being played. The blue curve is a smoothed average of the red curve (computed by the findMean function
/// within the SpectralEnhancer class).  The blue curve typically represents percussive effects which smear spectral energy over a broad range.
///
/// The upper plot (in green) is the same as the lower plot except the vertical scale is decibels (over an 80 dB range) instead of the mean-square amplitude.
/// This more closely represents what the human ear actually hears.
///
/// Created by Keith Bromley on 4 Nov 2021.

import SwiftUI


struct MusicSpectrum: View {

    var body: some View {
        ZStack {
            GrayRectangles(columnCount: 84) // struct code in VisUtilities file  Canvas.background toggles this on/off
            MusicSpectrum_Live()
        }
    }
}



struct MusicSpectrum_Live: View {

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
            let octaveCount: Int = 8
            let octaveWidth: Double = width / Double(octaveCount)
            var x: Double = 0.0       // The drawing origin is in the upper left corner.
            var y: Double = 0.0       // The drawing origin is in the upper left corner.
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
            // First, render the rms amplitude spectrum in red in the lower half pane:
            // We will render the spectrum bins from 12 to 3021 - that is the 8 octaves from 32 Hz to 8,133 Hz.
            
            var path = Path()
            path.move(to: CGPoint( x: 0.0, y: height - Double(audioManager.spectrum[12]) * halfHeight ) )

            for oct in 0 ..< octaveCount {  // 0 <= oct < 8
            
                for bin in settings.octBottomBin[oct] ... settings.octTopBin[oct] {
                    x = ( Double(oct) * octaveWidth ) + ( settings.binXFactor[bin] * octaveWidth )

                    magY = Double( audioManager.spectrum[bin] ) * halfHeight
                    magY = min(max(0.0, magY), halfHeight)
                    y = height - magY
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }

            context.stroke( path,
                            with: .color(red: 1.0, green: 0.0, blue: 0.0, opacity: 1.0),
                            lineWidth: 2.0 )
                            
            
// ---------------------------------------------------------------------------------------------------------------------
            // Second, render the mean of the rms amplitude spectrum in blue:
            
            if(audioManager.onlyPeaks == false) {
                meanSpectrum = spectralEnhancer.findMean(inputArray: audioManager.spectrum)
                
                path = Path()
                path.move(to: CGPoint(x: 0.0, y:height - Double(meanSpectrum[12]) * halfHeight) )
                    
                for oct in 0 ..< octaveCount {  // 0 <= oct < 8
                    for bin in settings.octBottomBin[oct] ... settings.octTopBin[oct] {
                        x = ( Double(oct) * octaveWidth ) + ( settings.binXFactor[bin] * octaveWidth )
                        magY = Double( meanSpectrum[bin] ) * halfHeight
                        magY = min(max(0.0, magY), halfHeight)
                        y = height - magY
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                
                context.stroke( path,
                                with: .color(red: 0.0, green: 0.0, blue: 1.0, opacity: 1.0),
                                lineWidth: 2.0 )
            }

// ---------------------------------------------------------------------------------------------------------------------
            // Third, render the decibel-scale spectrum in green in the upper half pane:

            path = Path()
            path.move( to: CGPoint( x: 0.0, y: halfHeight - Double( audioManager.spectrum[0]) * halfHeight) )

            for oct in 0 ..< octaveCount {  // 0 <= oct < 8
            
                for bin in settings.octBottomBin[oct] ... settings.octTopBin[oct] {
                    x = ( Double(oct) * octaveWidth ) + ( settings.binXFactor[bin] * octaveWidth )

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
            }
                    
            context.stroke( path,
                            with: .color(red: 0.0, green: 1.0, blue: 0.0, opacity: 1.0),
                            lineWidth: 2.0 )

            
            
// ---------------------------------------------------------------------------------------------------------------------
            // Fourth, render the mean of the decibel-scale spectrum in blue:
            
            if(audioManager.onlyPeaks == false) {
                mean_dB_Spectrum = spectralEnhancer.findMean(inputArray: dB_Spectrum)
                                
                path = Path()
                path.move( to: CGPoint( x: 0.0, y: halfHeight - Double(mean_dB_Spectrum[12]) * halfHeight) )
                
                for oct in 0 ..< octaveCount {  // 0 <= oct < 8
                    for bin in settings.octBottomBin[oct] ... settings.octTopBin[oct] {
                        x = ( Double(oct) * octaveWidth ) + ( settings.binXFactor[bin] * octaveWidth )
                        magY = Double( mean_dB_Spectrum[bin] ) * halfHeight
                        magY = min(max(0.0, magY), halfHeight)
                        y = halfHeight - magY
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                context.stroke( path,
                                with: .color(red: 0.0, green: 0.0, blue: 1.0, opacity: 1.0),
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
}  // end of MusicSpectrum_Live struct



struct MusicSpectrum_Previews: PreviewProvider {
    static var previews: some View {
        MusicSpectrum()
    }
}
