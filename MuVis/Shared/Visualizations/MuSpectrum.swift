/// MuSpectrum.swift
/// MuVis
///
/// This view renders a visualization of the muSpectrum (using a mean-square amplitude scale) of the music. I have coined the name muSpectrum for the
/// exponentially-resampled version of the spectrum to more closely represent the notes of the musical scale.
///
/// In the lower plot, the horizontal axis is exponential frequency - from the note C1 (about 33 Hz) on the left to the note B6 (about 1,976 Hz) on the right.
/// The vertical axis shows (in red) the mean-square amplitude of the instantaneous muSpectrum of the audio being played. The red peaks are spectral lines
/// depicting the harmonics of the musical notes being played - and cover six octaves. The blue curve is a smoothed average of the red curve (computed by the
/// findMean function within the SpectralEnhancer class). The blue curve typically represents percussive effects which smear spectral energy over a broad range.
///
/// In the upper plot, the green curve is simply the red curve after subtracting the blue curve. This green curve would be a good starting point for analyzing the
/// harmonic structure of an ensemble of notes being played to facilitate automated note detection.
///
/// Created by Keith Bromley on 20 Nov 2020.  Significantly updated on 30 Oct 2021.

import SwiftUI

struct MuSpectrum: View {

    var body: some View {
        ZStack {
            GrayRectangles(columnCount: 72)                                 // struct code in VisUtilities file
            VerticalLines(columnCount: 72)                                  // struct code in VisUtilities file
            MuSpectrum_Live()
        }
    }
}

struct MuSpectrum_Live: View {

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

            var x: Double = 0.0       // The drawing origin is in the upper left corner.
            var y: Double = 0.0       // The drawing origin is in the upper left corner.
            var upRamp: Double = 0.0
            var magY: Double = 0.0         // used as a preliminary part of the "y" value
            
            // Declare the array of muSpectrum values of the current frame of audio samples:
            var meanMuSpectrum: [Float] = [Float](repeating: 0.0, count: totalPointCount)
            
            // Declare the array of enhancedMuSpectrum values of the current frame of audio samples:
            var enhancedMuSpectrum: [Float] = [Float](repeating: 0.0, count: totalPointCount)
            
// ---------------------------------------------------------------------------------------------------------------------
            // First, render the muSpectrum in red in the lower half pane:
            context.withCGContext { cgContext in

                cgContext.move(to: CGPoint( x: Double(0.0), y: height ) )
                
                for point in 0 ..< sixOctPointCount {
                    // upRamp goes from 0.0 to 1.0 as point goes from 0 to sixOctPointCount:
                    upRamp =  Double(point) / Double(sixOctPointCount)
                    x = upRamp * width
                    
                    magY = Double(audioManager.muSpectrum[point]) * halfHeight
                    magY = min(max(0.0, magY), halfHeight)
                    y = height - magY
                    cgContext.addLine(to: CGPoint(x: x, y: y))
                }
                
                cgContext.setStrokeColor(CGColor.init(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0))
                cgContext.setLineWidth(2.0)
                cgContext.drawPath(using: CGPathDrawingMode.stroke)
            }


// ---------------------------------------------------------------------------------------------------------------------
            // Second, render the mean of the muSpectrum in blue:
            
            meanMuSpectrum = spectralEnhancer.findMean(inputArray: audioManager.muSpectrum)
                            
            context.withCGContext { cgContext in
                cgContext.move(to: CGPoint(x:Double(0.0), y: height - Double(meanMuSpectrum[0]) * height ) )
                
                for point in 1 ..< sixOctPointCount {
                    // upRamp goes from 0.0 to 1.0 as point goes from 0 to sixOctPointCount:
                    upRamp =  Double(point) / Double(sixOctPointCount)
                    x = upRamp * width
                    
                    magY = Double(meanMuSpectrum[point]) * halfHeight
                    magY = min(max(0.0, magY), height)
                    y = height - magY
                    cgContext.addLine(to: CGPoint(x: x, y: y))
                }

                cgContext.setStrokeColor(CGColor.init(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0))
                cgContext.setLineWidth(2.0)
                cgContext.drawPath(using: CGPathDrawingMode.stroke)
            }
            
            
// ---------------------------------------------------------------------------------------------------------------------
            // Third, render the enhanced muSpectrum in green in the upper half pane:
            // The enhancedMuSpectrum is just the muSpectrum with the meanMuSpectrum subtracted from it.
                
            enhancedMuSpectrum = spectralEnhancer.enhance(inputArray: audioManager.muSpectrum)
                
            context.withCGContext { cgContext in
                cgContext.move( to: CGPoint( x: Double(0.0), y: halfHeight - Double(enhancedMuSpectrum[0]) * height ) )

                for point in 0 ..< sixOctPointCount {
                    // upRamp goes from 0.0 to 1.0 as point goes from 0 to sixOctPointCount:
                    upRamp =  Double(point) / Double(sixOctPointCount)
                    x = upRamp * width
                    
                    magY = Double(enhancedMuSpectrum[point]) * halfHeight
                    magY = min(max(0.0, magY), halfHeight)
                    y = halfHeight - magY
                    cgContext.addLine(to: CGPoint(x: x, y: y))
                }
                
                cgContext.setStrokeColor(CGColor.init(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0))
                cgContext.setLineWidth(2.0)
                cgContext.drawPath(using: CGPathDrawingMode.stroke)
            }

            // Print on-screen the elapsed duration-per-frame (in milliseconds) (typically about 50)
            if(showMSPF == true) {
                let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                context.draw(Text("MSPF: \( settings.monitorPerformance() )"), in: frame )
            }


        }  // end of Canvas{}
        .background( (settings.optionOn) ? Color.clear : backgroundColor )
        
    }  // end of var body: some View
}  // end of MuSpectrum_Live struct



struct MuSpectrum_Previews: PreviewProvider {
    static var previews: some View {
        MuSpectrum()
    }
}
