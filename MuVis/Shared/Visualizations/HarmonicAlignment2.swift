/// HarmonicAlignment2.swift
/// MuVis
///
/// The HarmonicAlignment2 visualization depicts the same information as the HarmonicAlignment visualization but rendered in a slightly different form.
/// (This is purely for aesthetic effect - which you may find pleasing or annoying.) The muSpectrum for each of the six octaves (and for each of the six harmonics
/// within each octave) is rendered twice - one upward stretching muSpectrum and one downward stretching muSpectrum.
///
/// The OAS of the fundamental notes (in red) is rendered first. Then the OAS of the first harmonic notes (in yellow) are rendered over it.
/// Then the OAS of the second harmonic notes (in green) are rendered over it, and so on - until all 6 harmonics are depicted.
///
/// If the optionOn button is pressed, we multiply the value of the harmonics (harm = 2 through 6) by the value of the fundamental (harm = 1).
/// So, the harmonics are shown if-and-only-if there is meaningful energy in the fundamental.
///
/// Created by Keith Bromley on 20 Nov 2020.   Significantly updated on 17 Nov 2021.


import SwiftUI


struct HarmonicAlignment2: View {

    // @Environment(\.colorScheme) var colorScheme
    var body: some View {
        ZStack {
            GrayRectangles(columnCount: 12)                             // struct code in VisUtilities file
            HorizontalLines(rowCount: 6, offset: 0.5)                   // struct code in VisUtilities file
            VerticalLines(columnCount: 12)                              // struct code in VisUtilities file
            NoteNames(rowCount: 2, octavesPerRow: 1)                    // struct code in VisUtilities file
            HarmonicAlignment2_Live()
        }
    }
}



struct HarmonicAlignment2_Live: View {
    @EnvironmentObject var audioManager: AudioManager  // Observe the instance of AudioManager passed from ContentView
    @EnvironmentObject var settings: Settings
    
    var body: some View {
    
        Canvas { context, size in
        
            /*
            This is a two-dimensional grid containing 6 row and 12 columns.
            Each of the 6 rows contains 1 octave or 12 notes or 12*12 = 144 points.
            Each of the 12 columns contains 6 octaves of that particular note.
            The entire grid renders 6 octaves or 6*12 = 72 notes or 6*144 = 864 points
            */

            let harmonicCount: Int = 6  // The total number of harmonics rendered.    0 <= har <= 5     1 <= harm <= 6
            let width: Double  = size.width
            let height: Double = size.height
            
            var x: Double = 0.0       // The drawing origin is in the upper left corner.
            var y: Double = 0.0       // The drawing origin is in the upper left corner.
            var upRamp: Double = 0.0

            let rowCount: Int = 6  // The FFT provides 7 octaves (plus 5 unrendered notes)
            let rowHeight: Double = height / Double(rowCount)
            let halfRowHeight: Double = 0.5 * rowHeight
            
            var magY:  Double = 0.0        // used as a preliminary part of the "y" value
            var cumulativePoints: Int = 0
            var harmAmp: Double = 0.0   // harmonic amplitude is a scale factor to decrease the rendered value of harmonics
            
            let harmIncrement: [Int]  = [ 0, 12, 19, 24, 28, 31 ]      // The increment (in notes) for the six harmonics:
            //                           C1  C2  G2  C3  E3  G3
            
            // Render each of the six harmonics:
            for har in 0 ..< harmonicCount {            // har  = 0,1,2,3,4,5      harm = 1,2,3,4,5,6

                let hueHarmOffset: Double = 1.0 / ( Double(harmonicCount) ) // hueHarmOffset = 1/6
                let hueIndex: Double = Double(har) * hueHarmOffset         // hueIndex = 0, 1/6, 2/6, 3/6, 4/6, 5/6
                    
                for row in 0 ..< rowCount {
                    let rowD: Double = Double(row)
            
                    var path = Path()
                    path.move( to: CGPoint( x: 0.0, y: height - rowD * rowHeight - halfRowHeight ) )

                    for point in 0 ..< pointsPerOctave {
                        // upRamp goes from 0.0 to 1.0 as point goes from 0 to pointsPerOctave
                        upRamp =  Double(point) / Double(pointsPerOctave)
                        x = upRamp * width

                        cumulativePoints = row * pointsPerOctave + point
                        magY = Double(audioManager.muSpectrum[cumulativePoints])
                        
                        if(settings.optionOn == true) {
                            harmAmp = (har==0) ? 1.0 : magY  // This gracefully reduces the harmonic spectra for weak fundamentals
                        } else {
                            harmAmp = 1.0
                        }
                        cumulativePoints = row * pointsPerOctave + pointsPerNote*harmIncrement[har] + point
                        if(cumulativePoints >= totalPointCount) { cumulativePoints = totalPointCount-1 }
                        magY = 0.2 * Double(audioManager.muSpectrum[cumulativePoints]) * rowHeight * harmAmp
                        
                        if( cumulativePoints == totalPointCount-1 ) { magY = 0 }
                        magY = min(max(0.0, magY), rowHeight)  // Limit over- and under-saturation.
                        y = height - rowD * rowHeight - halfRowHeight - magY
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    
                    path.addLine( to: CGPoint( x: width, y: height - rowD * rowHeight - halfRowHeight ) )
                    
                    for point in (0 ..< pointsPerOctave).reversed() {
                        upRamp =  Double(point) / Double(pointsPerOctave)
                        x = upRamp * width
                        
                        cumulativePoints = row * pointsPerOctave + point
                        magY = Double(audioManager.muSpectrum[cumulativePoints])
                        
                        if(settings.optionOn == true) {
                            harmAmp = (har==0) ? 1.0 : magY  // This gracefully reduces the harmonic spectra for weak fundamentals
                        } else {
                            harmAmp = 1.0
                        }
                        cumulativePoints = row * pointsPerOctave + pointsPerNote*harmIncrement[har] + point
                        if(cumulativePoints >= totalPointCount) { cumulativePoints = totalPointCount-1 }
                        magY = 0.2 * Double(audioManager.muSpectrum[cumulativePoints]) * rowHeight * harmAmp
                        
                        if( cumulativePoints == totalPointCount-1 ) { magY = 0 }
                        magY = min(max(0.0, magY), rowHeight)  // Limit over- and under-saturation.
                        y = height - rowD * rowHeight - halfRowHeight + magY
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                       
                    path.addLine( to: CGPoint( x: 0.0,   y: height - rowD * rowHeight - halfRowHeight ) )
                    path.closeSubpath()
                    
                    context.fill( path,
                                  with: .color(Color(hue: hueIndex, saturation: 1.0, brightness: 1.0) ) )
                                  
                    context.stroke( path,
                        with: .color( (settings.selectedColorScheme == .dark) ? Color.black : Color.white ),
                        lineWidth: 1.0 )
                }
                    
            }  // end of ForEach(harm)


            // Print on-screen the elapsed duration-per-frame (in milliseconds) (typically about 50)
            if(showMSPF == true) {
                let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                context.draw(Text("MSPF: \( settings.monitorPerformance() )"), in: frame )
            }
            
            
        }  // end of Canvas{}
    }  // end of var body: some View{}
}  // end of HarmonicAlignment2_Live{} struct



struct HarmonicAlignment2_Previews: PreviewProvider {
    static var previews: some View {
        HarmonicAlignment2()
    }
}
