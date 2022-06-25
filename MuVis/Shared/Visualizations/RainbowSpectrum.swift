/// RainbowSpectrum.swift
/// MuVis
///
/// The RainbowSpectrum is the first of the MuVis visualizations that depict the time-history of the muSpectra. That is, instead of rendering just the current
/// muSpectrum, they also render the most-recent 48 muSpectra - so they show how the envelope of each note varies with time. With a frame-rate of 0.1 seconds
/// per frame, these 48 muSpectra cover the last 4.8 seconds of the music we are hearing.
///
/// The RainbowSpectrum visualization uses a similar geometry to the TriOctSpectrum visualization wherein the lower three octaves of muSpectrum audio information
/// are rendered in the lower half-screen and the upper three octaves are rendered in the upper half-screen. The current muSpectrum is shown in the bottom and
/// top rows. And the muSpectrum history is shown as drifting (and shrinking) to the vertical mid-screen.
///
/// For variety, the colors of the upper half-screen and lower half-screen change over time.  If the optionOn button is selected, then a color gradient is applied to
/// the muSpectrum such that the notes within an octave are colored similarly to the standard "hue" color cycle.
///
/// Created by Keith Bromley on 16 Dec 2020.  Significantly updated on 1 Nov 2021.


import SwiftUI


struct RainbowSpectrum: View {
    @EnvironmentObject var audioManager: AudioManager  // Observe the instance of AudioManager passed from ContentView
    @EnvironmentObject var settings: Settings

    var body: some View {
        
        // Toggle between black and white as the Canvas's background color:
        let backgroundColor: Color = (settings.selectedColorScheme == .dark) ? Color.black : Color.white
        
        Canvas { context, size in

            let width: Double           = size.width
            let height: Double          = size.height
            let halfHeight: Double      = height * 0.5
            let quarterHeight: Double   = height * 0.25
            
            var x : Double = 0.0       // The drawing origin is in the upper left corner.
            var y : Double = 0.0       // The drawing origin is in the upper left corner.

            let lineCount: Int = 48     // lineCount must be <= historyCount
            let octavesPerLine: Int = 3
            let pointsPerLine: Int = pointsPerNote * notesPerOctave * octavesPerLine  // pointsPerLine = 12 * 12 * 3 = 432
            var lineRampUp: Double = 0.0
            var lineRampDown: Double = 0.0
            
            var hue: Double = 0.0               // 0 <= hue < 1.0
            var hueLower: Double = 0.0          // 0 <= hueLower < 1.0
            var hueUpper: Double = 0.0          // 0 <= hueUpper < 1.0
            let colorSize: Int = 10_000         // This determines the frequency of the color change over time.
                
//---------------------------------------------------------------------------------------------------------------------
            
            for lineNum in 0 ..< lineCount {       //  0 <= lineNum < 48
            
                let lineOffset: Int = (lineCount-1 - lineNum) * sixOctPointCount  // lineNum = 0 is the oldest spectrum
                
                // As lineNum goes from 0 to lineCount, lineNumRampUp goes from 0.0 to 1.0:
                lineRampUp = Double(lineNum) / Double(lineCount)

                // As lineNum goes from 0 to lineCount, lineNumRampDown goes from 1.0 to 0.0:
                lineRampDown =  Double(lineCount - lineNum ) / Double(lineCount)
                
                // Each spectrum is rendered along a horizontal line extending from startX to endX.
                let startX: Double = 0.0   + lineRampUp * (0.33 * width)
                let endX: Double   = width - lineRampUp * (0.33 * width)
                let spectrumWidth: Double = endX - startX
                let pointWidth: Double = spectrumWidth / Double(pointsPerLine)  // pointsPerLine = 12 * 12 * 3 = 432

                let ValY: Double = lineRampUp * halfHeight
                
                settings.colorIndex = (settings.colorIndex >= colorSize) ? 0 : settings.colorIndex + 1
                hueLower = Double(settings.colorIndex) / Double(colorSize)      // 0.0 <= hue < 1.0
                hueUpper = hueLower + 0.5
                if (hueUpper > 1.0) { hueUpper -= 1.0 }

                // Render the lower and upper triOct spectra:
                for triOct in 0 ..< 2 {		// triOct = 0, 1 denote lower and upper half-panes respectively

                    let startY: Double = (triOct == 0) ? height - ValY : ValY
                    let endY: Double = startY
 
                    var path = Path()
                    path.move( to: CGPoint( x: startX, y: startY ) )

                    // We will render a total of sixOctPointCount points where sixOctPointCount = 72 * 12 = 864
                    // The lower triOct spectrum and the upper triOct spectrum each contain 432 points.
                    for point in 0 ..< pointsPerLine{     // 0 <= point < 432
                        x = startX + ( Double(point) * pointWidth )
                        x = min(max(startX, x), endX)
                        let tempIndex = (triOct == 0) ? lineOffset + point : (pointsPerLine + lineOffset + point)
                        let mag: Double = 0.5 * Double(audioManager.muSpecHistory[tempIndex])
                        let magY = ValY + ( mag * lineRampDown * quarterHeight )
                        y = (triOct == 0) ? height - magY : magY
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    path.addLine( to: CGPoint( x: endX, y: endY ) )
                    
                    hue = (triOct == 0) ? hueLower : hueUpper
                    
                    if(settings.optionOn) {
                        context.stroke( path,
                                        with: .linearGradient( settings.hue3Gradient,
                                                               startPoint: CGPoint(x: startX, y: startY),
                                                               endPoint: CGPoint(x: endX, y: endY)),
                                        lineWidth: 0.3 + lineRampDown * 3.0 )
                    }
                    else {
                        context.stroke( path,
                                        with: .color(Color(hue: hue, saturation: 1.0, brightness: 1.0)),
                                        lineWidth: 0.3 + (lineRampDown * 3.0) )
                    }
                    
                }  // end of for() loop over triOct
            }  // end of for() loop over hist
            

            // Print on-screen the elapsed duration-per-frame (in milliseconds) (typically about 50)
            if(showMSPF == true) {
                context.draw(Text("MSPF: \( settings.monitorPerformance() )"), at: CGPoint(x: 0.04*width, y: 0.5*height) )
            }
   

        }  // end of Canvas{}
        .background(backgroundColor)  // Toggle between black and white background color.

    }  //end of var body: some View{}
}  // end of RainbowSpectrum{} struct



struct RainbowSpectrum_Previews: PreviewProvider {
    static var previews: some View {
        RainbowSpectrum()
    }
}
