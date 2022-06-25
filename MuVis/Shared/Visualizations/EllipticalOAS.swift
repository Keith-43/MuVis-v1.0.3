/// EllipticalOAS.swift
/// MuVis
///
/// This visualization generates the same FFT spectral information as the OctaveAlignedSpectrum, but displays it as a series of concentric ellipses instead of as
/// rows in a Cartesian grid. Each ellipse of this set is a standard muSpectrum display covering one octave of frequency. Each ellipse is scaled and aligned
/// one octave above the next-inner ellipse to show the radial alignment of octave-related frequencies in the music.
///
/// The parametric equations for a circle are
/// x = r sin (2 * PI * theta)
/// y = r cos (2 * PI * theta)
/// where the angle theta (in radians) is measured clockwise from the vertical axis. Since our rendering pane is rectangular, we should generalize this to be an ellipse
/// in order to maximally fill the rendering pane.
///
/// The parametric equations for an ellipse are
/// x = A sin (2 * PI * theta)
/// y = B cos (2 * PI * theta)
/// where A and B are the major- and minor-radii respectively.  (Strictly speaking, theta is no longer the desired geometric angle, but the approximation
/// becomes more accurate as A = B.)
///
/// In the render() method, for each of the 7 ellipses (i.e., for each octave of spectral data) we:
/// 1.) Start defining a multi-segmented line with a starting point at the twelve o'clock position on the appropriate ellipse,
/// 2.) Add points to the line as we navigate counter-clockwise around the ellipse,
/// 3.) When we get all the way around to the twelve o'clock position again, we reverse direction and add more points as we move clockwise around the ellipse,
/// 4.) During this latter path, we add the spectral bin value to the radius of the ellipse so that the curve has outward bumps representing the spectral peaks,
/// 5.) When we get all the way around to the original starting point, we close the line segments to create an enclosed "blob",
/// 6.) Finally, we fill this blob with a desired fill color.
///
/// Created by Keith Bromley on 21 Feb 2021 (adapted from his previous java version in the Polaris app).


import SwiftUI


struct EllipticalOAS: View {
    var body: some View {
        ZStack {
            GrayTriangles()
            Ellipses()
            EllipticalOAS_Live()
            CenterEllipse()
        }
    }



    struct Ellipses: View {
        var body: some View {
            GeometryReader { geometry in
            
                let octaveCount: Int = 8  // The FFT provides 8 octaves.
                let width: CGFloat  = geometry.size.width   // The drawing origin is in the upper left corner.
                let height: CGFloat = geometry.size.height  // The drawing origin is in the upper left corner.
                
                ZStack(alignment: .center) {
                    // Render the  9 ellipses corresponding to the 8 rows of the OAS plus 1.
                    ForEach( 0 ..< octaveCount+1, id: \.self) { row in      //  0 <= row < 8+1
                        Ellipse()
                            .stroke(lineWidth: 1.0)
                            .foregroundColor(.black)
                            .frame(width: width * CGFloat(row+1) / CGFloat(octaveCount+1), height: height * CGFloat(row+1) / CGFloat(octaveCount+1))
                    }  // end of ForEach(row)
                }  // end of ZStack
            }  // end of GeometryReader
        }  // end of var body: some View
    }  // end of Ellipses struct



    struct CenterEllipse: View {
        @EnvironmentObject var settings: Settings
        var body: some View {
            GeometryReader { geometry in
                let octaveCount: Int = 8  // The FFT provides 8 octaves.
                let width: CGFloat  = geometry.size.width   // The drawing origin is in the upper left corner.
                let height: CGFloat = geometry.size.height  // The drawing origin is in the upper left corner.
                
                Ellipse()   // Fill the smallest ellipse
                    .foregroundColor( (settings.selectedColorScheme == .light) ? Color.white : Color.darkGray )
                    .frame(width: width / CGFloat(octaveCount+1), height: height / CGFloat(octaveCount+1))
                    .offset(x: width*8.0/18.0, y: height*8.0/18.0)
            }  // end of GeometryReader
        }  // end of var body: some View
    }  // end of CenterEllipse struct
    


    struct GrayTriangles: View {
        @EnvironmentObject var settings: Settings
        var body: some View {
            GeometryReader { geometry in
            
                let columnCount : Int = 12  // There are 12 notes in an octave
                let width: CGFloat  = geometry.size.width   // The drawing origin is in the upper left corner.
                let height: CGFloat = geometry.size.height  // The drawing origin is in the upper left corner.
                let X0: CGFloat = width  / 2.0  // the origin of the ellipses
                let Y0: CGFloat = height / 2.0  // the origin of the ellipses
                let A0: CGFloat = width  / 2.0  // the horizontal radius of the largest ellipse
                let B0: CGFloat = height / 2.0  // the vertical   radius of the largest ellipse
                var theta:  Double = 0.0
                var theta1: Double = 0.0
                var theta2: Double = 0.0
                var x: CGFloat = 0.0
                var y: CGFloat = 0.0
                let accidentalLine: [Int] = [1, 3, 6, 8, 10]  // line value preceding notes C#, D#, F#, G#, and A#
                
                // Draw 5 triangles (representing the 5 accidentals (i.e., sharp/flat notes)):
                ForEach( 0 ..< accidentalLine.count, id: \.self) { line in  // line = 0,1,2,3,4   accidentalLine = 1, 3, 6, 8, 10

                    Path { path in
                        // First, do a triangle side from the outer ellipse to the center:
                        theta1 = Double(accidentalLine[line]) / Double(columnCount)  // fraction goes from 0.0 to 1.0
                        x = X0 + A0 * CGFloat( sin(2.0 * Double.pi * theta1) )       // 0 <= theta1 <= 1
                        y = Y0 - B0 * CGFloat( cos(2.0 * Double.pi * theta1) )       // 0 <= theta1 <= 1
                        path.move(   to: CGPoint(x: x,  y: y  ) )   // from outer ellipse
                        path.addLine(to: CGPoint(x: X0, y: Y0 ) )   // to the center
                        
                        // Second, do the subsequent triangle side from the center to the outer ellipse:
                        theta2 = Double(accidentalLine[line] + 1) / Double(columnCount) // fraction goes from 0.0 to 1.0
                        x = X0 + A0 * CGFloat( sin(2.0 * Double.pi * theta2) )         // 0 <= theta2 <= 1
                        y = Y0 - B0 * CGFloat( cos(2.0 * Double.pi * theta2) )         // 0 <= theta2 <= 1
                        path.addLine(to: CGPoint(x: x,  y: y ) )    // to the outer ellipse

                        // Third, add a line to a point on the outside ellipse that is halfway between these two angles:
                        theta = (theta1 + theta2) * 0.5
                        x = X0 + A0 * CGFloat( sin(2.0 * Double.pi * theta) )         // 0 <= theta <= 1
                        y = Y0 - B0 * CGFloat( cos(2.0 * Double.pi * theta) )         // 0 <= theta <= 1
                        path.addLine(to: CGPoint(x: x,  y: y ) )
                        path.closeSubpath()
                    }
                    // .fill(Color.accidentalNoteColor)
                    .fill( (settings.selectedColorScheme == .light) ? Color.lightGray.opacity(0.25) : Color.black.opacity(0.25) )
                    
                }  // end of ForEach(accidentalLine)
                
                // Calculate the x,y coordinate where the 12 radial lines meet the outermost ellipse
                // and render the radial gridlines dividing each ellipse into 12 increments.
                // Each center between consecutive radial lines represents the center frequency of a musical note.
                // The angles will only be correct if we make the rendering pane square (i.e., make the ellipses into circles).
                ForEach( 0 ..< notesPerOctave, id: \.self) { note in      //  0 <= note < 12

                    Path { path in
                        theta = Double(note) / Double(notesPerOctave)  // fraction goes from 0.0 to 1.0
                        theta = min(max(0.0, theta), 1.0);                      // Limit over and under saturation.
                        x = X0 + A0 * CGFloat( sin(2.0 * Double.pi * theta) )       // 0 <= theta <= 1
                        y = Y0 - B0 * CGFloat( cos(2.0 * Double.pi * theta) )       // 0 <= theta <= 1
                    
                        path.move(   to: CGPoint(x: X0, y: Y0 ) )
                        path.addLine(to: CGPoint(x: x,  y: y ) )
                    }
                    .stroke(lineWidth: 1.0)
                    .foregroundColor(.black)

                }  // end of ForEach(line)
                
            }  // end of GeometryReader
        }  // end of var body: some View
    }  // end of GrayTriangles struct
    


    struct EllipticalOAS_Live: View {
        @EnvironmentObject var audioManager: AudioManager  // Observe the instance of AudioManager passed from ContentView
        @EnvironmentObject var settings: Settings
        
        var body: some View {
            Canvas { context, size in
                
                let width: Double  = size.width
                let height: Double = size.height
                var x : Double = 0.0       // The drawing origin is in the upper left corner.
                var y : Double = 0.0       // The drawing origin is in the upper left corner.
                var theta:  Double = 0.0
                
                let X0: Double = width  / 2.0  // the origin of the ellipses
                let Y0: Double = height / 2.0  // the origin of the ellipses
                let A0: Double = width  / 2.0  // the horizontal radius of the largest ellipse
                let B0: Double = height / 2.0  // the vertical   radius of the largest ellipse
                
                let octaveCount: Int = 8  // The FFT provides 8 octaves.
                            
                let radInc: Double = 1.0 / Double(octaveCount+1) // radInc = radial increment = 1/9
                var radFrac: Double = 0.0                      // radFrac = radial fraction
                let horBinRad:  Double = A0 * radInc           // horizontal bin radius = A0 / 9
                let vertBinRad: Double = B0 * radInc           // vertical bin radius   = B0 / 9

                var mag:   Double = 0.0         // used as a preliminary part of the audio amplitude value
                
                // Render 8 concentric ellipses (one for each spectral octave) about the pane's center:
                for oct in 0 ..< octaveCount {  //  0 <= oct < 8

                    // We divide the radius into octaveCount+1 equal parts.  We don't use the innermost part for data.
                    radFrac = Double(oct + 1) * radInc     // radFrac = 1/9, 2/9, 3/9, 4/9, 5/9, 6/9, 7/9, 8/9
                    
                    // Initialize the start of each spectral row to the appropriate ellipse:
                    x = X0 - 1              // slightly to the left of the 12 o'clock position.
                    y = Y0 - B0 * radFrac
                    
                    var path = Path()
                    path.move( to: CGPoint(x: x, y: y) )
                    
                    // For each spectral octave, generate the inside-part of the ellipse.  That is, start defining a multi-segmented
                    // line with a starting point at the twelve o'clock position on the appropriate ellipse.  Then add points to
                    // the line as we navigate counter-clockwise around the ellipse.  Use pointsPerOctave points along each ellipse.
                    for point in (0 ..< pointsPerOctave).reversed() {
                        theta = Double(point) / Double(pointsPerOctave)    // 0.0 < theta < 1.0
                        x = X0 + A0 * radFrac * Double( sin(2.0 * Double.pi * theta) )
                        y = Y0 - B0 * radFrac * Double( cos(2.0 * Double.pi * theta) )
                        path.addLine(to: CGPoint(x: x,  y: y ) )
                    }
                    
                    // Connect the end of the inside-part to the start of the outside-part:
                    x = X0 + 1  // slightly to the right of the twelve o'clock position.
                    y = Y0 - B0 * radFrac
                    path.addLine(to: CGPoint(x: x,  y: y ) )
                          
                    
                    // Render the "live" spectra generated by the FFT processing.  That is, we reverse direction and
                    // add more points to the line as we move clockwise around the ellipse.  During this path, we
                    // add the spectral bin value to the radius of the ellipse so that the curve has outward bumps
                    // representing the spectral peaks. This curve is the "ellipse plus spectral data".
                    for bin in settings.octBottomBin[oct] ... settings.octTopBin[oct] {
                        theta = settings.binXFactor[bin]    // 0.0 < theta < 1.0
                        
                        mag = Double( audioManager.spectrum[bin] )
                        mag = min(max(0.0, mag), 1.0);  // Limit over- and under-saturation.
                        
                        x = X0 + (A0 * radFrac + (mag * horBinRad )) * Double( sin(2.0 * Double.pi * theta) )
                        y = Y0 - (B0 * radFrac + (mag * vertBinRad)) * Double( cos(2.0 * Double.pi * theta) )
                        path.addLine(to: CGPoint(x: x, y: y))

                    }
                    path.closeSubpath()

                    if(settings.optionOn == false) {
                        // fill the 8 paths with a Pomegranate color:
                        context.fill( path,
                                      with: .color(red: 192.0/255.0, green: 57.0/255.0, blue: 43.0/255.0) ) // pomegranate red
                    }
                    else {
                        // Fill the 8 paths with an angular gradient cycling through the "hue" colors:
                        context.fill( path,
                                      with: .conicGradient( settings.hueGradient,
                                                            center: CGPoint( x: 0.5*size.width, y: 0.5*size.height ),
                                                            angle: Angle(degrees: 270.0) ) )
                        // https://devtechie.medium.com/new-in-swiftui-3-canvas-269c64ef5efc
                        // https://swiftui-lab.com/swiftui-animations-part5/
                    }
                    
                }  // end of for() loop over oct


            // Print on-screen the elapsed duration-per-frame (in milliseconds) (typically about 50)
            if(showMSPF == true) {
                let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                context.draw(Text("MSPF: \( settings.monitorPerformance() )"), in: frame )
            }
                       
            }  // end of Canvas{}
        }  // end of var body: some View
    }  // end of EllipticalOAS_Live struct
}  // end of EllipticalOAS struct



struct EllipticalOAS_Previews: PreviewProvider {
    static var previews: some View {
        EllipticalOAS()
    }
}

