/// HarmonicAlignment.swift
/// MuVis
///
/// The HarmonicAlignment visualization is an enhanced version of the OctaveAlignedMuSpectrum visualization - which renders a muSpectrum displaying the FFT
/// frequency bins of the live audio data on a two-dimensional Cartesian grid. Each row of this grid is a standard muSpectrum display covering one octave.
/// Each row is aligned one octave above the next-lower row to show the vertical alignment of octave-related frequencies in the music.
/// (Note that this requires compressing the frequency range by a factor of two for each octave.)
/// Hence the six rows of our displayed grid cover six octaves of musical frequency.
///
/// We have an audio sampling rate of 44,100 samples per second which means that the highest frequency we can observe is 44,100 / 2 = 22,050 Hz.
/// We will only consider notes up to B8 (freqB8 is about 7,902 Hz).  If C1 is considered as note = 0 then B8 is note = 95.
/// Thus the muSpectrum (generated from the spectrum computed by the FFT) covers a total of 96 notes ( 8 octaves ).
///
/// The bottom 6 octaves (the 72 notes from 0 to 71) will be displayed as possible fundamentals of the notes in the music, and the remaining 96 - 72 = 24 notes
/// will be used only for harmonic information. The rendered grid (shown in the above picture) has 6 rows and 12 columns - containing 6 * 12 = 72 boxes.
/// Each box represents one note. In the bottom row (octave 0), the leftmost box represents note 0 (C1 is 33 Hz) and the rightmost box represents note 11 (B1 is 61 Hz).
/// In the top row (octave 5), the leftmost box represents note 60 (C6 is 1046 Hz) and the rightmost box represents note 71 (B6 is 1975 Hz).
///
/// But the novel feature of the HarmonicAlignment visualization is the rendering of the harmonics beneath each note. We are rendering 6 harmonics of each note.
/// We will start counting from 1 - meaning that harm=1 refers to the fundamental. If the fundamental is note C1, then:
///
///	harm=1  is  C1  fundamental
///	harm=2  is  C2  octave                                               harm=3  is  G2
///	harm=4  is  C3  two octaves         harm=5  is  E3      harm=6  is  G3
/// So, harmonicCount = 6 and  harm = 1, 2, 3, 4, 5, 6.
/// The harmonic increment (harmIncrement) for our 6 rendered harmonics is 0, 12, 19, 24, 28, 31 notes.
///
/// The fundamental (harm=1) (the basic octave-aligned spectrum) is shown in red.  The first harmonic (harm=2) shows as orange; the second harmonic (harm=3) is yellow;
/// and the third harmonic harm=4) is green, and so on.  It is instructive to note the massive redundancy displayed here.  A fundamental note rendered as red in row 4
/// will also appear as orange in row 3 since it is the first harmonic of the note one-octave lower, and as orange in row 2 since it is the second harmonic of the note
/// two-octaves lower, and as yellow in row 1 since it is the fourth harmonic of the note three-octaves lower.
///
/// If the optionOn button is pressed, then: in order to decrease the visual clutter (and to be more musically meaningfull), we multiply the value of
/// the harmonics (harm = 2 through 6) by the value of the fundamental (harm = 1). So, if there is no meaningful amplitude for the fundamental, then its harmonics
/// are not shown (or at least only with low amplitude).
///
/// For each audio frame, we will render a total of 6 * 6 = 36 polygons - one for each harmonic of each octave.
///
/// totalPointCount =  96 * 12 = 1,152   // total number of points provided by the interpolator
/// sixOctPointCount = 72 * 12 =  864   // total number of points of the 72 possible fundamentals
///
/// Created by Keith Bromley on 20 Nov 2020.   Significantly updated on17 Nov 2021.


import SwiftUI


struct HarmonicAlignment: View {

    var body: some View {
        ZStack {
            GrayRectangles(columnCount: 12)             // struct code in VisUtilities file
            HorizontalLines(rowCount: 6, offset: 0.0)   // struct code in VisUtilities file
            VerticalLines(columnCount: 12)              // struct code in VisUtilities file
            NoteNames(rowCount: 2, octavesPerRow: 1)    // struct code in VisUtilities file
            HarmonicAlignment_Live()
        }
    }
}



struct HarmonicAlignment_Live: View {
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
            let harmOffset: Double = 1.0 / ( Double(harmonicCount) ) // harmOffset = 1/6
            let width: Double  = size.width
            let height: Double = size.height
            var x: Double = 0.0       // The drawing origin is in the upper left corner.
            var y: Double = 0.0       // The drawing origin is in the upper left corner.
            var upRamp: Double = 0.0
            let rowCount: Int = 6
            let rowHeight: Double = height / Double(rowCount)
            var harmAmp: Double = 0.0   // harmonic amplitude is a scale factor to decrease the rendered value of harmonics
            
            let harmIncrement: [Int]  = [ 0, 12, 19, 24, 28, 31 ]      // The increment (in notes) for the six harmonics:
            //                           C1  C2  G2  C3  E3  G3

            // Render each of the six harmonics:
            for har in 0 ..< harmonicCount {            // har  = 0,1,2,3,4,5      harm = 1,2,3,4,5,6

                let hueIndex: Double = Double(har) * harmOffset          // hueIndex = 0, 1/6, 2/6, 3/6, 4/6, 5/6

                for row in 0 ..< rowCount {
                    let rowD: Double = Double(row)

                    var path = Path()
                    path.move( to: CGPoint( x: 0.0, y: height - rowD * rowHeight ) )

                    for point in 0 ..< pointsPerOctave {
                        // upRamp goes from 0.0 to 1.0 as point goes from 0 to pointsPerOctave
                        upRamp =  Double(point) / Double(pointsPerOctave)
                        x = upRamp * width

                        /*
                        In order to decrease the visual clutter (and to be more musically meaningfull), we multiply the
                        value of the harmonics (harm = 2 through 6) by the value of the fundamental (harm = 1).
                        So, if there is no meaningful amplitude for the fundamental, then its harmonics are not shown
                        (or at least shown only with low amplitude).
                        */
                        
                        if(settings.optionOn == true) {
                            harmAmp = (har == 0) ? 1.0 : Double(audioManager.muSpectrum[row * pointsPerOctave + point])
                        }
                        else {
                            harmAmp = 1.0
                        }
                        var cumulativePoints: Int = row * pointsPerOctave + pointsPerNote*harmIncrement[har] + point
                        if(cumulativePoints >= totalPointCount) { cumulativePoints = totalPointCount-1 }

                        var magY: Double = Double(audioManager.muSpectrum[cumulativePoints]) * rowHeight * harmAmp
                        if( cumulativePoints == totalPointCount-1 ) { magY = 0 }
                        magY = min(max(0.0, magY), rowHeight)  // Limit over- and under-saturation.
                        y = height - rowD * rowHeight - magY
                        path.addLine(to: CGPoint(x: x, y: y))
                    }

                    path.addLine( to: CGPoint( x: width, y: height - rowD * rowHeight ) )
                    path.addLine( to: CGPoint( x: 0.0,   y: height - rowD * rowHeight ) )
                    path.closeSubpath()

                    context.fill( path,
                                  with: .color(Color(hue: hueIndex, saturation: 1.0, brightness: 1.0) ) )

                    context.stroke( path,
                        with: .color( (settings.selectedColorScheme == .dark) ? Color.black : Color.white ),
                        lineWidth: 1.0 )
                }

            }  // end of for() loop over harm


            // Print on-screen the elapsed duration-per-frame (in milliseconds) (typically about 50)
            if(showMSPF == true) {
                let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                context.draw(Text("MSPF: \( settings.monitorPerformance() )"), in: frame )
            }


        }  // end of Canvas{}
    }  // end of var body: some View{}
}  // end of HarmonicAlignment_Live{} struct



struct HarmonicAlignment_Previews: PreviewProvider {
    static var previews: some View {
        HarmonicAlignment()
    }
}
