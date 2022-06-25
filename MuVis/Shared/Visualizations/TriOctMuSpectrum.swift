/// TriOctSpectrum.swift
/// MuVis
///
/// The TriOctMuSpectrum visualization is similar to the LinearOAS visualization in that it shows a muSpectrum of six octaves of the audio waveform -
/// however it renders it as two separate muSpectrum displays.
///
/// It has the format of a downward-facing muSpectrum in the lower half-screen covering the lower three octaves, and an upward-facing muSpectrum in the upper
/// half-screen covering the upper three octaves. Each half screen shows three octaves. (The name "bi- tri-octave muSpectrum" seemed unduly cumbersome,
/// so I abbreviated it to "tri-octave spectrum"). The specific note frequencies are:
///
/// *         262 Hz                                   523 Hz                                    1046 Hz                            1976 Hz
/// *          C4                                          C5                                           C6                                       B6
/// *           |                                               |                                               |                                          |
/// *          W B W B W W B W B W B W W B W B W W B W B W B W W B W B W W B W B W B W
/// *
/// *          W B W B W W B W B W B W W B W B W W B W B W B W W B W B W W B W B W B W
/// *           |                                               |                                               |                                          |
/// *          C1                                          C2                                            C3                                      B3
/// *          33Hz                                   65 Hz                                       130 Hz                               247 Hz
///
///
/// As with the LinearOAS visualization, the spectral peaks comprising each note are a separate color, and the colors of the grid are consistent across all octaves -
/// hence all octaves of a "C" note are red; all octaves of an "E" note are green, and all octaves of a "G" note are light blue, etc.
/// Also, we have added a piano-keyboard overlay to clearly differentiate the black notes (in gray) from the white notes (in white).
/// Also, we have added note names for the white notes at the top and bottom.
///
/// Created by Keith Bromley on 29  Nov 2020.  Improved on 4 Jan 2022.


import SwiftUI


struct TriOctMuSpectrum: View {
    var body: some View {
        ZStack {
            GrayRectangles(columnCount: 36)                             // struct code in VisUtilities file
            NoteNames(rowCount: 2, octavesPerRow: 3)                    // struct code in VisUtilities file
            DoubleMuSpectrum_Live()
            VerticalLines(columnCount: 36)                              // struct code in VisUtilities file
            HorizontalLines(rowCount: 2, offset: 0.0)                   // struct code in VisUtilities file
        }
    }
}




struct DoubleMuSpectrum_Live : View {
    @EnvironmentObject var audioManager: AudioManager  // We observe the instance of AudioManager passed from ContentView.
    @EnvironmentObject var settings: Settings
        
    var body: some View {
    
        // Toggle between black and white as the Canvas's background color:
        let backgroundColor: Color = (settings.selectedColorScheme == .dark) ? Color.black : Color.white
    
         Canvas { context, size in

            let width: Double  = size.width
            let height: Double = size.height
            let halfHeight : Double = height * 0.5
            var x : Double = 0.0       // The drawing origin is in the upper left corner.
            var y : Double = 0.0       // The drawing origin is in the upper left corner.
            var upRamp : Double = 0.0
            var magY: Double = 0.0     // used as a preliminary part of the "y" value
            let octavesPerRow : Int = 3
            let pointsPerRow : Int = pointsPerNote * notesPerOctave * octavesPerRow  //  12 * 12 * 3 = 432
            
            let colorSize: Int = 10_000    // This determines the frequency of the color change over time.
            settings.colorIndex = (settings.colorIndex >= colorSize) ? 0 : settings.colorIndex + 1
            let hue: Double = Double(settings.colorIndex) / Double(colorSize)          // 0.0 <= hue1 < 1.0
                
            // Bottom spectrum contains lower three octaves:
           var path = Path()
            path.move( to: CGPoint( x: 0.0,   y: halfHeight))    // left midpoint
            
            for point in 1 ..< pointsPerRow {
                upRamp =  Double(point) / Double(pointsPerRow)   // upRamp goes from 0.0 to 1.0 as point goes from 0 to pointsPerRow
                x = upRamp * width
                magY = Double(audioManager.muSpectrum[point]) * halfHeight
                magY = min(max(0.0, magY), halfHeight)
                y = halfHeight + magY
                path.addLine(to: CGPoint(x: x, y: y))
            }
            path.addLine( to: CGPoint( x: width, y: halfHeight ) )    // right midpoint
        
            // Top spectrum contains the upper three octaves:
            for point in (1 ..< pointsPerRow).reversed()  {
                upRamp =  Double(point) / Double(pointsPerRow)   // upRamp goes from 0.0 to 1.0 as point goes from 0 to pointsPerRow
                x = upRamp * width
                magY = Double(audioManager.muSpectrum[pointsPerRow + point]) * halfHeight
                magY = min(max(0.0, magY), halfHeight)
                y = halfHeight - magY
                path.addLine(to: CGPoint(x: x, y: y))
            }
            path.addLine( to: CGPoint( x: 0.0,   y: halfHeight))    // left midpoint
            path.closeSubpath()
            
            if(settings.optionOn) {
                context.fill(   path,
                                with: .linearGradient( settings.hue3Gradient,
                                       startPoint: CGPoint(x: 0.0, y: 0.0),
                                       endPoint: CGPoint(x: size.width, y: 0.0)) )
            }
            else {
                context.fill( path,
                              with: .color(Color(hue: hue, saturation: 1.0, brightness: 1.0) ) )
            }
            
            
            // Print on-screen the elapsed duration-per-frame (in milliseconds) (typically about 50)
            if(showMSPF == true) {
                let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                context.draw(Text("MSPF: \( settings.monitorPerformance() )"), in: frame )
            }
            
        }  // end of Canvas{}
        .background( (settings.optionOn) ? backgroundColor :  Color.clear )

    }  // end of var body: some View{}
}  // end of DoubleMuSpectrum_Live{} struct



struct TriOctMuSpectrum_Previews: PreviewProvider {
    static var previews: some View {
        TriOctMuSpectrum()
    }
}
