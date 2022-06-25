/// OctaveAlignedSpectrum_both.swift
/// MuVis
///
/// The OctaveAlignedSpectrum_both visualization adds a line represeting the spectrum[] values - in addition to the muSpectrum[] values already there.
/// The muSpectrum paths are filled with a pomegranite red color, and the spectrum paths are stroked with a green color.  Clicking the "Option" button reverses these two.
/// This visualization allows direct side-by-side comparison between the spectrum and the muSpectrum.
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


struct OctaveAlignedSpectrum_both: View {

    var body: some View {
        ZStack {
            GrayRectangles(columnCount: 12)                                 // struct code in VisUtilities file
            HorizontalLines(rowCount: 8, offset: 0.0)                       // struct code in VisUtilities file
            VerticalLines(columnCount: 12)                                  // struct code in VisUtilities file
            NoteNames(rowCount: 2, octavesPerRow: 1)                        // struct code in VisUtilities file
            LiveSpectraA()
        }
    }
}



struct LiveSpectraA: View {
    @EnvironmentObject var audioManager: AudioManager  // Observe the instance of AudioManager passed from ContentView
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        
         Canvas { context, size in

            let width: Double  = size.width
            let height: Double = size.height
    
            var x : Double = 0.0       // The drawing origin is in the upper left corner.
            var y : Double = 0.0       // The drawing origin is in the upper left corner.
            var upRamp : Double = 0.0

            let octaveCount: Int = 8        // The FFT provides 8 octaves.
            let rowCount: Int = octaveCount // We will render 8 rows.
            let rowHeight: Double = height / Double(rowCount)
            var magY:  Double = 0.0        // used as a preliminary part of the "y" value
            var rowD:  Double = 0.0        // the integer row cast as a Double
            
            
//----------------------------------------------------------------------------------------------------------------------
            // Fill eight paths representing the spectrum or the muSpectrum:
            for row in 0 ..< rowCount {
                rowD = Double(row)
                
                var path = Path()
                path.move(to: CGPoint( x: Double(0.0), y: height - rowD * rowHeight ) )
                
                if (settings.optionOn == false) {                        // fill using the muSpectrum
                    for point in 0 ..< pointsPerOctave {
                        // upRamp goes from 0.0 to 1.0 as point goes from 0 to pointsPerOctave:
                        upRamp =  Double(point) / Double(pointsPerOctave)
                        x = upRamp * width
                        magY = Double(audioManager.muSpectrum[row * pointsPerOctave + point]) * rowHeight
                        magY = min(max(0.0, magY), rowHeight)
                        y = height - rowD * rowHeight - magY
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                else {                                          // fill using the spectrum
                    let oct = row       // 0 <= oct < 8
                
                    for bin in settings.octBottomBin[oct] ... settings.octTopBin[oct] {
                        x = settings.binXFactor[bin] * width
                        magY = Double( audioManager.spectrum[bin] ) * rowHeight
                        magY = min(max(0.0, magY), rowHeight)
                        y = height - rowD * rowHeight - magY
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                
                path.addLine(to: CGPoint(x: width, y: height - rowD * rowHeight ))
                path.addLine(to: CGPoint(x: 0.0, y: height - rowD * rowHeight ))
                path.closeSubpath()
                
                // Fill the 8 paths with a pomegranate-red color:
                context.fill(   path,
                                with: .color(red: 192.0/255.0, green: 57.0/255.0, blue: 43.0/255.0) )
                
            }  // end of for() loop over row

//----------------------------------------------------------------------------------------------------------------------

            // Stroke eight paths representing the spectrum or the muSpectrum:
             for row in 0 ..< rowCount {
                rowD = Double(row)
                
                var path = Path()
                path.move(to: CGPoint( x: Double(0.0), y: height - rowD * rowHeight ) )
                
                if (settings.optionOn == true) {                        // stroke using the muSpectrum
                    for point in 0 ..< pointsPerOctave {
                        // upRamp goes from 0.0 to 1.0 as point goes from 0 to pointsPerOctave:
                        upRamp =  Double(point) / Double(pointsPerOctave)
                        x = upRamp * width
                        magY = Double(audioManager.muSpectrum[row * pointsPerOctave + point]) * rowHeight
                        magY = min(max(0.0, magY), rowHeight)
                        y = height - rowD * rowHeight - magY
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                else {                                          // stroke using the spectrum
                    let oct = row       // 0 <= oct < 8
                
                    for bin in settings.octBottomBin[oct] ... settings.octTopBin[oct] {
                        x = settings.binXFactor[bin] * width
                        magY = Double( audioManager.spectrum[bin] ) * rowHeight
                        magY = min(max(0.0, magY), rowHeight)
                        y = height - rowD * rowHeight - magY
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                
                path.addLine(to: CGPoint(x: width, y: height - rowD * rowHeight ))
                
                // Stroke the 8 paths with a green color:
                context.stroke( path,
                                with: .color(Color.green),
                                lineWidth: 2.0 )
                
            }  // end of for() loop over row

            
            // Print on-screen the elapsed duration-per-frame (in milliseconds) (typically about 50)
            if(showMSPF == true) {
                let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                context.draw(Text("MSPF: \( settings.monitorPerformance() )"), in: frame )
            }

        }  // end of Canvas{}
        
    }  // end of var body: some View{}
}  // end of LiveSpectra{} struct




struct OctaveAlignedSpectrum_both_Previews: PreviewProvider {
    static var previews: some View {
        OctaveAlignedSpectrum_both()
    }
}
