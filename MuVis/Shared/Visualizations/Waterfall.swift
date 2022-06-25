//
//  Waterfall.swift
//  MuVis
//
//  Created by Keith Bromley on 24 Aug 2021.  Improved on 1 Jan 2022.
//

import SwiftUI

struct Waterfall: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                GrayRectangles(columnCount: 72)
                VerticalLines(columnCount: 72)
                NoteNames(rowCount: 2, octavesPerRow: 6)
                Waterfall_Live()
            }
        }
    }
}


struct Waterfall_Live: View {

    @EnvironmentObject var audioManager: AudioManager  // We observe the instance of AudioManager passed to us from ContentView.
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        
        // Toggle between black and white as the Canvas's background color:
        let backgroundColor: Color = (settings.selectedColorScheme == .dark) ? Color.black : Color.white
        
        Canvas { context, size in

            let width: Double  = size.width
            let height: Double = size.height
            let quarterHeight: Double  = height * 0.25
            let threeQuartersHeight: Double  = height * 0.75
            
            var x : Double = 0.0       // The drawing origin is in the upper left corner.
            var y : Double = 0.0       // The drawing origin is in the upper left corner.

            let lineCount: Int = 48         // lineCount must be <= historyCount
            var lineRampUp: Double = 0.0
            
            let colorSize: Int = 20_000    // This determines the frequency of the color change over time.
            var hue: Double = 0.0



//---------------------------------------------------------------------------------------------------------------------
            for lineNum in 0 ..< lineCount {       //  0 <= lineNum < 48
            
                let lineOffset: Int = (lineCount-1 - lineNum) * sixOctPointCount  // lineNum = 0 is the oldest spectrum
            
                // As lineNum goes from 0 to lineCount, lineRampUp goes from 0.0 to 1.0:
                lineRampUp = Double(lineNum) / Double(lineCount)
                
                // Each spectrum is rendered along a horizontal line extending from startX to endX.
                let startX: Double = 0.0
                let endX: Double   = width
                let spectrumWidth: Double = endX - startX
                let pointWidth: Double = spectrumWidth / Double(sixOctPointCount)  // pointsPerRow= 3*12*8 = 288
                
                let ValY: Double = lineRampUp * threeQuartersHeight
                    
                var path = Path()
                path.move( to: CGPoint( x: startX, y: quarterHeight + ValY ) )
                
                // For each historical spectrum, render sixOctPointCount (72 * 12 = 864) points:
                for point in 0 ..< sixOctPointCount{     // 0 <= point < 864
                    
                    x = startX + ( Double(point) * pointWidth )
                    x = min(max(startX, x), endX);
                    
                    let tempIndex = lineOffset + point
                    let mag: Double = 0.1 * Double( audioManager.muSpecHistory[tempIndex] )
                    let magY = mag * quarterHeight
                    y = quarterHeight + ValY - magY
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                path.addLine( to: CGPoint( x: endX, y:  quarterHeight + ValY))
                
                settings.colorIndex = (settings.colorIndex >= colorSize) ? 0 : settings.colorIndex + 1
                hue = Double(settings.colorIndex) / Double(colorSize)      // 0.0 <= hue < 1.0

                if(settings.optionOn) {
                    context.stroke( path,
                                    with: .color(Color(hue: hue, saturation: 1.0, brightness: 1.0)),
                                    lineWidth: 2.0 )
                } else {
                    context.stroke( path,
                                    with: .linearGradient( settings.hue6Gradient,
                                                           startPoint: CGPoint(x: 0.0, y: 1.0),
                                                           endPoint: CGPoint(x: size.width, y: 1.0)),
                                    lineWidth: 2.0 )
                }

            }  // end of for() loop over lineNum


            // Print on-screen the elapsed duration-per-frame (in milliseconds) (typically about 50)
            if(showMSPF == true) {
                let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                context.draw(Text("MSPF: \( settings.monitorPerformance() )"), in: frame )
            }


        }  // end of Canvas{}
        .background( (settings.optionOn) ? Color.clear : backgroundColor )  // Toggle between keyboard overlay and background color.
        
    }  //end of var body: some View
}  // end of Waterfall_Live struct



struct Waterfall_Previews: PreviewProvider {
    static var previews: some View {
        Waterfall()
    }
}
