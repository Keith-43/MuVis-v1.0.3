/// LinearOAS.swift
/// MuVis
///
/// The LinearOAS visualization is similar to the Music Spectrum visualization in that it shows an amplitude vs. exponential-frequency spectrum of the audio waveform.
/// The horizontal axis covers a total of 6 octaves  (from bin = 12 to bin = 755).  This 6-octave range covers the notes from C1 (about 33 Hz) to B6 (about 1,976 Hz).
///
/// For a pleasing effect, the vertical axis shows both an upward-extending spectrum in the upper-half screen and a downward-extending spectrum in the lower-half screen.
///
/// We have added a piano-keyboard overlay to clearly differentiate the black notes (in gray) from the white notes (in white).
/// Also, we have added note names for the white notes at the top and bottom.
///
/// The spectral peaks comprising each note are a separate color. The colors of the grid are consistent across all octaves - hence all octaves of a "C" note are red;
/// all octaves of an "E" note are green, and all octaves of a "G" note are light blue, etc. Many of the subsequent visualizations use this same note coloring scheme.
/// I have subjectively selected these to provide high color difference between adjacent notes.
///
/// The visual appearance of this spectrum is of each note being rendered as a small blob of a different color. However, in fact, we implement this effect by having
/// static vertical blocks depicting the note colors and then having the non-spectrum rendered as one big white /dark-gray blob covering the non-spectrum portion
/// of the spectrum display. The static colored vertical blocks are rendered first; then the dynamic white / dark-gray big blob; then the gray "black notes";
/// and finally the note names.
///
/// Created by Keith Bromley on 29 Nov 2020.  Significantly updated on 17 Nov 2021.

import SwiftUI


struct LinearOAS: View {
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        ZStack {
            ColorRectangles(columnCount: 96)                // struct code in VisUtilities file
            LiveSpectrum()
            if(settings.optionOn) {
                GrayRectangles(columnCount: 96)             // struct code in VisUtilities file
                VerticalLines(columnCount: 96)              // struct code in VisUtilities file
                NoteNames(rowCount: 2, octavesPerRow: 8)    // struct code in VisUtilities file
            }
        }
    }
}



struct LiveSpectrum : View {
    @EnvironmentObject var audioManager: AudioManager  // Observe the instance of AudioManager passed from ContentView
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        
        // Toggle between black and white as the Canvas's background color:
        // let backgroundColor: Color = (settings.selectedColorScheme == .dark) ? Color.black : Color.white
        
         Canvas { context, size in

            let width: Double  = size.width
            let height: Double = size.height
            let halfHeight : Double = height * 0.5
            let octaveCount: Int = 8
            let octaveWidth: Double = width / Double(octaveCount)
            
            var x : Double = 0.0       // The drawing origin is in the upper left corner.
            var y : Double = 0.0       // The drawing origin is in the upper left corner.
            var magY: Double = 0.0     // used as a preliminary part of the "y" value


            // Render white / darkGray blob from bottom of pane:
            var path = Path()
            path.move   ( to: CGPoint( x: width, y: halfHeight) )   // right midpoint
            path.addLine( to: CGPoint( x: width, y: height))        // right bottom
            path.addLine( to: CGPoint( x: 0.0,   y: height))        // left bottom
            path.addLine( to: CGPoint( x: 0.0,   y: halfHeight))    // left midpoint

            for oct in 0 ..< octaveCount {  // 0 <= oct < 6
                for bin in settings.octBottomBin[oct] ... settings.octTopBin[oct] {
                    x = ( Double(oct) * octaveWidth ) + ( settings.binXFactor[bin] * octaveWidth )
                
                    magY = Double( audioManager.spectrum[bin] ) * halfHeight
                    magY = min(max(0.0, magY), halfHeight)
                    y = halfHeight + magY
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            path.addLine( to: CGPoint( x: width, y: halfHeight ) )
            path.closeSubpath()
            
            context.fill( path,
                          with: .color( (settings.selectedColorScheme == .light) ? Color.white : Color.darkGray ) )
        
        
            // Render white / darkGray blob from top of pane:
            path = Path()
            path.move   ( to: CGPoint( x: width, y: halfHeight) )   // right midpoint
            path.addLine( to: CGPoint( x: width, y: 0.0))           // right top
            path.addLine( to: CGPoint( x: 0.0,   y: 0.0))           // left top
            path.addLine( to: CGPoint( x: 0.0,   y: halfHeight))    // left midpoint
            
            for oct in 0 ..< octaveCount {  // 0 <= oct < 6
                for bin in settings.octBottomBin[oct] ... settings.octTopBin[oct] {
                    x = ( Double(oct) * octaveWidth ) + ( settings.binXFactor[bin] * octaveWidth )
            
                    magY = Double( audioManager.spectrum[bin] ) * halfHeight
                    magY = min(max(0.0, magY), halfHeight)
                    y = halfHeight - magY
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            path.addLine( to: CGPoint( x: width, y: halfHeight ) )
            path.closeSubpath()
            
            context.fill( path,
                          with: .color( (settings.selectedColorScheme == .light) ? Color.white : Color.darkGray ) )


            // Print on-screen the elapsed duration-per-frame (in milliseconds) (typically about 50)
            if(showMSPF == true) {
                let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                context.draw(Text("MSPF: \( settings.monitorPerformance() )"), in: frame )
            }
            
        }  // end of Canvas{}
        // .background( (optionOn) ? Color.clear : backgroundColor )
        
    }  // end of var body: some View {}
}  // end of LiveSpectrum{} struct



struct LinearOAS_Previews: PreviewProvider {
    static var previews: some View {
        LinearOAS()
    }
}
