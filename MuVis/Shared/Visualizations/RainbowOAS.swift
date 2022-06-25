/// RainbowOAS.swift
/// MuVis
///
/// The RainbowOAS visualization uses the same Cartesian grid geometry as the OctaveAlignedSpectrum visualization.  However, instead of rendering just the
/// current muSpectrum, it also renders the most-recent 32 muSpectra history - so it shows how the envelope of each note varies with time.
/// Iterative scaling is used to make the older spectral values appear to drift into the background.
///
/// The 6 rows of the visualization cover 6 octaves.  Octave-wide spectra are rendered on rows 0, 1, 2 and on rows 4, 5, 6.  All iterate towards the vertical-midpoint
/// of the screen.  Octave 0 is rendered along row 0 at the bottom of the visualization pane.  Octave 5 is rendered along row 6 at the top of the visualization pane.
/// Using a resolution of 12 points per note, each row consists of 12 * 12 = 144 points covering 1 octave.  The 6 rows show a total of 6 * 144 = 864 points.
///
/// In addition to the current 864-point muSpectrum, we also render the previous 48 muSpectra.  Hence, the above figure shows a total of 864 * 48 =
/// 41,472 data points.  We use two for() loops.  The inner loop counts through the 6 octaves.  The outer loop counts through the 48 spectra stored in the
/// muSpecHistory[] buffer.
///
/// Again, for iPhones and iPads, the number 32 is reduced to 16 to lower the graphics load.
///
/// The different octaves are rendered in different vivid colors - hence the name RainbowOAS.
///
/// Created by Keith Bromley on 20 Dec 2020.  Significantly updated on 1 Nov 2021.


import SwiftUI


struct RainbowOAS: View {
    @EnvironmentObject var audioManager: AudioManager  // Observe the instance of AudioManager passed from ContentView
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        
        // Toggle between black and white as the Canvas's background color:
        let backgroundColor: Color = (settings.selectedColorScheme == .dark) ? Color.black : Color.white
        
        Canvas { context, size in

            let width: Double  = size.width
            let height: Double = size.height
                
            var x: Double = 0.0       // The drawing origin is in the upper left corner.
            var y: Double = 0.0       // The drawing origin is in the upper left corner.
            var startX: Double = 0.0
            var endX: Double = width
            var spectrumWidth: Double = 0.0
            var lineRampUp: Double = 0.0
            var lineRampDown: Double = 0.0
            var pointWidth: Double = 0.0
            
            let octaveCount: Int = 6
            let rowCount = octaveCount  // row = 0,1,2,3,4,5
            let lineCount: Int = 48     // lineCount must be <= historyCount
            let rowHeight: Double = height    / Double(rowCount)
            let lineHeight: Double = rowHeight / Double(lineCount)
            
            var magY: Double  = 0.0    // used as a preliminary part of the "y" value
            var rowY: Double  = 0.0    // used as a preliminary part of the "y" value
            var lineY: Double = 0.0    // used as a preliminary part of the "y" value
            
            var octaveColor: Color = Color.white
            
            for lineNum in (0 ..< lineCount) {   // lineNum = 0, 1, 2, 3 ... 45, 46, 47
            
                let lineOffset: Int = (lineCount-1 - lineNum) * sixOctPointCount
                
                // lineRampUp goes from 0.0 to 1.0 as lineNum goes from 0 to lineCount
                lineRampUp   =  Double(lineNum) / Double(lineCount)
                // lineRampDown goes from 1.0 to 0.0 as lineNum goes from 0 to lineCount
                lineRampDown =  Double(lineCount - lineNum) / Double(lineCount)
                
                // Each spectrum is rendered along a horizontal line extending from startX to endX.
                startX = 0.0   + lineRampUp * (0.33 * width);
                endX   = width - lineRampUp * (0.33 * width);
                spectrumWidth = endX - startX;
                pointWidth = spectrumWidth / Double(pointsPerOctave)
                        
                for oct in 0 ..< octaveCount {     //  0 <= oct < 6
                    // Idea: Render octaves 0 and 5, then octaves 1 and 4, and then octaves 2 and 3
                    
                    let octOffset: Int  = oct * pointsPerOctave
                    
                    rowY = (oct < 3) ? height - (Double(oct) * rowHeight) : Double((5-oct)) * rowHeight

                    switch oct {
                        case 0: lineY = rowY - Double(lineNum) * 3.0 * lineHeight
                        case 1: lineY = rowY - Double(lineNum) * 2.0 * lineHeight
                        case 2: lineY = rowY - Double(lineNum) *       lineHeight
                        case 3: lineY = rowY + Double(lineNum) *       lineHeight
                        case 4: lineY = rowY + Double(lineNum) * 2.0 * lineHeight
                        case 5: lineY = rowY + Double(lineNum) * 3.0 * lineHeight
                        default: lineY = 0.0
                    }
                        
                    var path = Path()
                    path.move( to: CGPoint( x: startX, y: lineY ) )

                    for point in 1 ..< pointsPerOctave {
                        x = startX + ( Double(point) * pointWidth )
                        x = min(max(startX, x), endX)
                        
                        let tempIndex = lineOffset + octOffset + point
                        magY = 0.3 * Double(audioManager.muSpecHistory[tempIndex]) * lineRampDown * rowHeight

                        switch oct {
                            case 0: y = rowY - Double(lineNum) * 3.0 * lineHeight - magY
                            case 1: y = rowY - Double(lineNum) * 2.0 * lineHeight - magY
                            case 2: y = rowY - Double(lineNum) *       lineHeight - magY
                            case 3: y = rowY + Double(lineNum) *       lineHeight + magY
                            case 4: y = rowY + Double(lineNum) * 2.0 * lineHeight + magY
                            case 5: y = rowY + Double(lineNum) * 3.0 * lineHeight + magY
                            default: y = 0.0
                        }
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    path.addLine(to: CGPoint(x: endX, y: lineY))
                    
                    if(settings.optionOn) {
                        context.stroke( path,
                                        with: .linearGradient( settings.hueGradient,
                                                               startPoint: CGPoint(x: startX, y: lineY),
                                                               endPoint: CGPoint(x: endX, y: lineY)),
                                        lineWidth: 0.3 + lineRampDown * 3.0 )
                    }
                    else {
 
                        switch oct {
                            case 0:  octaveColor = Color(red: 1.0, green: 0.0, blue: 0.0)  // red
                            case 1:  octaveColor = Color(red: 0.0, green: 1.0, blue: 0.0)  // green
                            case 2:  octaveColor = Color(red: 0.0, green: 0.0, blue: 1.0)  // blue
                            case 3:  octaveColor = Color(red: 0.0, green: 1.0, blue: 1.0)  // cyan
                            case 4:  octaveColor = Color(red: 1.0, green: 0.7, blue: 0.0)  // orange
                            case 5:  octaveColor = Color(red: 1.0, green: 0.0, blue: 1.0)  // magenta
                            default: octaveColor = Color.black
                        }

                        context.stroke( path,
                                        with: .color(octaveColor),
                                        // Vary the line thickness to enhance the three-dimensional effect:
                                        lineWidth: 0.2 + (lineRampDown*4.0) )
                    }
                    
                }  // end of for() loop over oct
            }  // end of for() loop over lineNum


            // Print on-screen the elapsed duration-per-frame (in milliseconds) (typically about 50)
            if(showMSPF == true) {
                context.draw(Text("MSPF: \( settings.monitorPerformance() )"), at: CGPoint(x: 0.04*width, y: 0.5*height) )
            }


        }  // end of Canvas{}
        .background(backgroundColor)  // Toggle between black and white background color.
        
    }  //end of var body: some View{}
}  // end of RainbowOAS struct



struct RainbowOAS_Previews: PreviewProvider {
    static var previews: some View {
        RainbowOAS()
    }
}
