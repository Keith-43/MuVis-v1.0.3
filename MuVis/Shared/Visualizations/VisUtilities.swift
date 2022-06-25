//
//  VisUtilities.swift
//  MuVis
//
//  This file contains several utility structs that are used by some of the Visualizations.
//
//  Created by Keith Bromley on 10/21/21.
//

import Foundation
import SwiftUI



struct HorizontalLines: View {
    @EnvironmentObject var settings: Settings
    var rowCount: Int
    var offset: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            let width: CGFloat  = geometry.size.width   // The drawing origin is in the upper left corner.
            let height: CGFloat = geometry.size.height  // The drawing origin is in the upper left corner.
            let rowHeight : CGFloat = height / CGFloat(rowCount)
            
            //  Draw 8 horizontal lines across the pane (separating the 7 octaves):
            ForEach( 0 ..< rowCount+1, id: \.self) { row in        //  0 <= row < 7+1
            
                Path { path in
                path.move(   to: CGPoint(x: CGFloat(0.0), y: CGFloat(row) * rowHeight - offset * rowHeight) )
                path.addLine(to: CGPoint(x: width,        y: CGFloat(row) * rowHeight - offset * rowHeight) )
                }
                .stroke(lineWidth: 1.0)
                .foregroundColor( (settings.selectedColorScheme == .light) ? .white : .black )
            }
        }  // end of GeometryReader
    }  // end of var body: some View
}  // end of HorizontalLines struct



struct VerticalLines: View {
    @EnvironmentObject var settings: Settings
    var columnCount: Int

    var body: some View {
        GeometryReader { geometry in
            let width: CGFloat  = geometry.size.width   // The drawing origin is in the upper left corner.
            let height: CGFloat = geometry.size.height  // The drawing origin is in the upper left corner.
            let columnWidth : CGFloat = width / CGFloat(columnCount)
            
            //  Draw 12 vertical lines across the pane (separating the 12 notes):
            ForEach( 0 ..< columnCount+1, id: \.self) { column in        //  0 <= column < 11+1
            
                Path { path in
                    path.move(   to: CGPoint(x: CGFloat(column) * columnWidth, y: CGFloat(0.0)) )
                    path.addLine(to: CGPoint(x: CGFloat(column) * columnWidth, y: height) )
                }
                .stroke(lineWidth: 1.0)
                .foregroundColor( (settings.selectedColorScheme == .light) ? .white : .black )
            }
        }  // end of GeometryReader
    }  // end of var body: some View
}  // end of VerticalLines struct



struct GrayRectangles: View {
    @EnvironmentObject var settings: Settings
    var columnCount: Int

    var body: some View {
        GeometryReader { geometry in
            let width: CGFloat  = geometry.size.width   // The drawing origin is in the upper left corner.
            let height: CGFloat = geometry.size.height  // The drawing origin is in the upper left corner.
            let columnWidth : CGFloat = width / CGFloat(columnCount)

            //                               C      C#    D      D#     E     F      F#    G      G#    A      A#    B
            let accidentalNote: [Bool] = [  false, true, false, true, false, false, true, false, true, false, true, false,
                                            false, true, false, true, false, false, true, false, true, false, true, false,
                                            false, true, false, true, false, false, true, false, true, false, true, false,
                                            false, true, false, true, false, false, true, false, true, false, true, false,
                                            false, true, false, true, false, false, true, false, true, false, true, false,
                                            false, true, false, true, false, false, true, false, true, false, true, false,
                                            false, true, false, true, false, false, true, false, true, false, true, false,
                                            false, true, false, true, false, false, true, false, true, false, true, false ]
            
            ForEach( 0 ..< columnCount, id: \.self) { columnNum in        //  0 <= column < 12 or 36 or 72 or 96
                // For each octave, draw 5 rectangles across the pane (representing the 5 accidentals (i.e., sharp/flat notes):
                if(accidentalNote[columnNum] == true) {  // This condition selects the column values for the notes C#, D#, F#, G#, and A#
                    Rectangle()
                        .fill( (settings.selectedColorScheme == .light) ? Color.lightGray.opacity(0.25) : Color.black.opacity(0.25) )
                        .frame(width: columnWidth, height: height)
                        .offset(x: CGFloat(columnNum) * columnWidth, y: 0.0)
                }
            }
        }  // end of GeometryReader
    }  // end of var body: some View
}  // end of GrayRectangles struct



struct ColorRectangles: View {
    var columnCount: Int
    
    var body: some View {
        GeometryReader { geometry in
        
            let width: CGFloat  = geometry.size.width   // The drawing origin is in the upper left corner.
            let height: CGFloat = geometry.size.height  // The drawing origin is in the upper left corner.
            let columnWidth : CGFloat = width / CGFloat(columnCount)

            // Fill 36 colored rectangles across the pane.
            HStack(alignment: .center, spacing: 0.0) {
            
                ForEach( 0 ..< columnCount, id: \.self) { column in        //  0 <= rect < 36
                    let noteNum = column % notesPerOctave
                    Rectangle()
                        .fill(noteColor[noteNum])
                        .frame(width: columnWidth, height: height)
                }
            }
        }  // end of GeometryReader
    }  // end of var body: some View
}  // end of ColorRectangles struct



/*
struct ColorTriangles: View {
    var noteCount: Int

    var body: some View {
         Canvas { context, size in

            let width: Double  = size.width     // The drawing origin is in the upper left corner.
            let height: Double = size.height    // The drawing origin is in the upper left corner.
            let halfWidth: Double  = 0.5 * width
            let halfHeight: Double = 0.5 * height

            var x : Double = 0.0
            var y : Double = 0.0
            var theta: Double = 0.0
            let radius: Double = 0.8 * sqrt(halfWidth * halfWidth + halfHeight * halfHeight)
            let noteWedge : Double = 1.0 / Double(noteCount)    // noteWedge = 1 / 72

            // Fill 72 colored triangles around the circle:
            for note in 0 ..< noteCount {       //  0 <= note < 72
                var path = Path()
                path.move(to: CGPoint( x: halfWidth, y: halfHeight ) )  // the pane's center
            
                theta = Double(note) * noteWedge
                x = halfWidth  + radius * cos(2.0 * Double.pi * theta)
                y = halfHeight - radius * sin(2.0 * Double.pi * theta)
                path.addLine(to: CGPoint(x: x, y: y ))
                
                theta = Double(note+1) * noteWedge
                x = halfWidth  + radius * cos(2.0 * Double.pi * theta)
                y = halfHeight - radius * sin(2.0 * Double.pi * theta)
                path.addLine(to: CGPoint(x: x, y: y ))

                path.addLine(to: CGPoint(x: halfWidth, y: halfHeight ))  // Bring the triangle back to the pane's center
                path.closeSubpath()

                context.fill( path,
                              with: .color(noteColor[note % notesPerOctave] ) )
            }  // end of for() loop over note
        }  // end of Canvas{}
    }  // end of var body: some View{}
}  // end of ColorTriangles{} struct
*/



struct GradientRectangles: View {       // used in the SpectrumBars visualization
    @EnvironmentObject var settings: Settings
    var columnCount: Int
    
    var body: some View {
        Canvas { context, size in

            let width: Double  = size.width
            let height: Double = size.height
            let halfHeight: Double = 0.5 * height
            let columnWidth: Double = width / Double(columnCount)
            let gap: Double = 0.1 * columnWidth

            // First, paint the entire visualization pane with either white or black:
            var path = Path()
            path.move   ( to: CGPoint( x: 0.0,  y: 0.0   ) )        // top left
            path.addLine( to: CGPoint( x: width,y: 0.0   ) )        // top right
            path.addLine( to: CGPoint( x: width,y: height) )        // bottom right
            path.addLine( to: CGPoint( x: 0.0,  y: height) )        // bottom left
            path.addLine( to: CGPoint( x: 0.0,  y: 0.0   ) )        // top left
            path.closeSubpath()
            context.fill( path,
                          with: .color( (settings.selectedColorScheme == .light) ? Color.white : Color.black) )

            // Now paint the individual columns with the desired gradient colors:
            for column in 0 ..< columnCount {
                let leftX  = Double(column)   * columnWidth + gap
                let rightX = Double(column+1) * columnWidth - gap
                
                var path = Path()
                path.move(to:    CGPoint(x: leftX,  y: 0.0   ) )
                path.addLine(to: CGPoint(x: leftX,  y: height - gap) )  // This puts a white-or-black border at the pane bottom.
                path.addLine(to: CGPoint(x: rightX, y: height - gap) )  // This puts a white-or-black border at the pane bottom.
                path.addLine(to: CGPoint(x: rightX, y: 0.0   ) )
                path.closeSubpath()
                context.fill(   path,
                                with: .linearGradient(Gradient(colors: [.red, .yellow, .green]),
                                startPoint: CGPoint(x: 0.0, y: 0.0),
                                endPoint: CGPoint(x: 0.0, y: halfHeight)))
            }
        }
    }
}



/*
struct ColorPane: View {       // used in the Harmomograph and Harmonograph2 visualizations
    @EnvironmentObject var settings: Settings
    var colorSize: Int
    
    var body: some View {
        Canvas { context, size in
        
            // Before rendering any live data, let's paint the underlying graphics layer with a time-varying color:
            let width: Double  = size.width
            let height: Double = size.height
            // let colorSize: Int = 500    // This determines the frequency of the color change over time.
            var hue:  Double = 0.0
            
            var path = Path()
            path.move   ( to: CGPoint( x: 0.0,  y: 0.0   ) )        // top left
            path.addLine( to: CGPoint( x: width,y: 0.0   ) )        // top right
            path.addLine( to: CGPoint( x: width,y: height) )        // bottom right
            path.addLine( to: CGPoint( x: 0.0,  y: height) )        // bottom left
            path.addLine( to: CGPoint( x: 0.0,  y: 0.0   ) )        // top left
            path.closeSubpath()
            
            settings.colorIndex = (settings.colorIndex >= colorSize) ? 0 : settings.colorIndex + 1
            hue = Double(settings.colorIndex) / Double(colorSize)          // 0.0 <= hue < 1.0

            context.fill( path,
                          with: .color(Color(hue: hue, saturation: 1.0, brightness: 0.9) ) )
                          // Deliberately slightly dim to serve as background
        }
    }
}
*/



struct NoteNames: View {
    var rowCount: Int
    var octavesPerRow: Int
    
    var body: some View {
        GeometryReader { geometry in
            let width: CGFloat  = geometry.size.width   // The drawing origin is in the upper left corner.
            let height: CGFloat = geometry.size.height  // The drawing origin is in the upper left corner.
            let octaveWidth: CGFloat = width / CGFloat(octavesPerRow)
            let noteWidth: CGFloat = width / CGFloat(octavesPerRow * notesPerOctave)
            
            ForEach(0 ..< rowCount) { rows in
                let row = CGFloat(rows)
                
                  ForEach(0 ..< octavesPerRow) { octave in
                    let oct = CGFloat(octave)
                    
                    Text("C")
                        .frame(width: noteWidth, height: 0.05*height)
                        .offset(x: oct * octaveWidth + 0 * noteWidth, y: 0.95 * row * height)
                    Text("D")
                        .frame(width: noteWidth, height: 0.05*height)
                        .offset(x: oct * octaveWidth + 2 * noteWidth, y: 0.95 * row * height)
                    Text("E")
                        .frame(width: noteWidth, height: 0.05*height)
                        .offset(x: oct * octaveWidth + 4 * noteWidth, y: 0.95 * row * height)
                    Text("F")
                        .frame(width: noteWidth, height: 0.05*height)
                        .offset(x: oct * octaveWidth + 5 * noteWidth, y: 0.95 * row * height)
                    Text("G")
                        .frame(width: noteWidth, height: 0.05*height)
                        .offset(x: oct * octaveWidth + 7 * noteWidth, y: 0.95 * row * height)
                    Text("A")
                        .frame(width: noteWidth, height: 0.05*height)
                        .offset(x: oct * octaveWidth + 9 * noteWidth, y: 0.95 * row * height)
                    Text("B")
                        .frame(width: noteWidth, height: 0.05*height)
                        .offset(x: oct * octaveWidth + 11 * noteWidth, y: 0.95 * row * height)
                }
            }
        }
    }
}
