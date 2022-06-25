/// OctaveAlignedSpectrum.swift
/// MuVis
///
/// The OctaveAlignedSpectrumB visualization uses the spectrum[] values directly.  This achieves higher resolution than the muSpectrum[].
///
/// The OctaveAlignedSpectrum (OAS) visualization is one of the bedrock visualizations of this app. It is similar to the LinearOAS visualization except that the
/// octaves are laid out one above the other. This is ideal for examining the harmonic structure.
///
/// The graphical structure depicted is a grid of 7 rows by 12 columns. Each of the 7 rows contains all 12 notes within that one octave.
/// Each of the 12 columns contains 7 octaves of that particular note. If we render with a resolution of 12 points per note,
/// then each row contains 12 * 12 = 144 points, and the entire grid contains 144 * 7 = 1008 points.
///
/// Each octave is a standard spectrum display (converted from linear to exponential frequency) covering one octave. Each octave is overlaid one octave above the
/// next-lower octave. (Note that this requires compressing the frequency range by a factor of two for each octave.)
///
/// We typically use the muSpectrum array to render it. But we could render it directly from the Spectrum array. The top row would show half of the spectral bins
/// (but over an exponential axis). The next-to-the-top row would show half of the remaining bins (but stretched by a factor of 2 to occupy the same length as the
/// top row). The next-lower-row would show half of the remaining bins (but stretched by a factor of 4 to occupy the same length as the top row). And so on.
/// Observe that the bottom row might contain only a small number of bins (perhaps 12) whereas the top row might contain a very large number of bins (perhaps
/// 12 times two-raised-to-the-sixth-power). The resultant increased resolution at the higher octaves might prove very useful in determining when a vocalist
/// is on- or off-pitch.
///
/// In the default Core Graphics coordinate space, the origin is located in the lower-left corner of the rectangle and the rectangle extends towards the upper-right corner.
///
/// Created by Keith Bromley on 20 Nov 2020.   Significantly updated on 3 Nov 2021.

import SwiftUI


struct OctaveAlignedSpectrum: View {

    var body: some View {
        ZStack {
            GrayRectangles(columnCount: 12)                                 // struct code in VisUtilities file
            HorizontalLines(rowCount: 8, offset: 0.0)                       // struct code in VisUtilities file
            VerticalLines(columnCount: 12)                                  // struct code in VisUtilities file
            NoteNames(rowCount: 2, octavesPerRow: 1)                        // struct code in VisUtilities file
            OctaveAlignedSpectrum_Live()
        }
    }
}



struct OctaveAlignedSpectrum_Live: View {
    @EnvironmentObject var audioManager: AudioManager  // Observe the instance of AudioManager passed from ContentView
    @EnvironmentObject var settings: Settings
        
    var body: some View {
        
         Canvas { context, size in

            let width: Double  = size.width
            let height: Double = size.height
            var x : Double = 0.0       // The drawing origin is in the upper left corner.
            var y : Double = 0.0       // The drawing origin is in the upper left corner.
            
            let octaveCount : Int = 8  // The FFT provides 8 octaves.
            let rowHeight : Double = height / Double(octaveCount)
            var magY:  Double = 0.0        // used as a preliminary part of the "y" value
            var rowD:  Double = 0.0        // the integer "row" cast as a Double

//----------------------------------------------------------------------------------------------------------------------
            // Fill seven paths representing the spectrum:
            
            for oct in 0 ..< octaveCount {    // 0 <= row < 8
                rowD = Double(oct)
                var path = Path()
                    path.move(to: CGPoint( x: 0.0, y: height - rowD * rowHeight ) )  // left-hand pane border
                    
                for bin in settings.octBottomBin[oct] ... settings.octTopBin[oct] {
                    x = settings.binXFactor[bin] * width
                    magY = Double(audioManager.spectrum[bin]) * rowHeight
                    magY = min(max(0.0, magY), rowHeight)
                    y = height - rowD * rowHeight - magY
                    path.addLine(to: CGPoint(x: x, y: y))
                }

                path.addLine(to: CGPoint(x: width, y: height - rowD * rowHeight ))  // right-hand pane border
                path.addLine(to: CGPoint(x: 0.0, y: height - rowD * rowHeight ))    // left-hand pane border
                path.closeSubpath()

                if(settings.optionOn == false) {
                context.fill(   path,
                                with: .color(red: 192.0/255.0, green: 57.0/255.0, blue: 43.0/255.0) ) // pomegranate red
                }
                else {
                context.fill(   path,
                                with: .linearGradient( settings.hueGradient,
                                                       startPoint: CGPoint(x: 0.0, y: 1.0),
                                                       endPoint: CGPoint(x: size.width, y: 1.0)) )
                }

            }  // end of for() loop over oct


            // Print on-screen the elapsed duration-per-frame (in milliseconds) (typically about 50)
            if(showMSPF == true) {
                let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                context.draw(Text("MSPF: \( settings.monitorPerformance() )"), in: frame )
            }

        }  // end of Canvas{}
        
    }  // end of var body: some View
}  // end of OctaveAlignedSpectrum_Live struct




struct OctaveAlignedSpectrum_Previews: PreviewProvider {
    static var previews: some View {
        OctaveAlignedSpectrum()
    }
}
