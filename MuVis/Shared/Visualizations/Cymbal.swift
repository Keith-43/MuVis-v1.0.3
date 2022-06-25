/// Cymbal.swift
/// MuVis
///
/// The Cymbal visualization is a different way of depicting the current muSpectrum. It was inspired by contemplating the vibrational patterns of a cymbal.
/// It is purely an aesthetic depiction (with no attempt at real-world modeling).
///
/// On a Mac, we render 6 octaves of the muSpectrum at 12 notes/octave and 2 points/note. Thus, each muSpectrum contains 6 * 12 * 2 = 144 points.
/// This Cymbal visualization renders 144 concentric circles (all with their origin at the pane center) with their radius proportional to these 144 musical-frequency points.
/// 72 of these are note centers, and 72 are the interspersed inter-note midpoints. We dynamically change the line width of these circles to denote the muSpectrum
/// amplitude.
///
/// On an iPhone or iPad, we decrease the circleCount from 144 to 36 to reduce the graphics load (to avoid freezes and crashes when the app runs on more-limited
/// devices).
///
/// For aesthetic effect, we overlay a green plot of the current muSpectrum (replicated from mid-screen to the right edge and from mid-screen to the left edge)
/// on top of the circles.
///
/// A toggle is provided to the developer to render either ovals (wherein all of the shapes are within the visualization pane) or circles (wherein the top and bottom
/// are clipped as outside of the visualization pane)
///
/// My iPad4 could not keep up with the graphics load of rendering 144 circles, so I reduced the circleCount to 36 for iOS devices.
///
/// If the optionOn button is pressed, then this visualization shows oval shapes instead of circle shapes.  This only becomes obvious in short wide panes or tall thin panes.
///
/// Created by Keith Bromley in June 2021. (adapted from his previous java version in the Polaris app).   Significantly updated on 17 Nov 2021.


import SwiftUI


struct Cymbal: View {

    // We observe the instances of the AudioProcessing and Settings classes passed to us from ContentView:
    @EnvironmentObject var audioManager: AudioManager  // Observe the instance of AudioManager passed from ContentView
    @EnvironmentObject var settings: Settings
    
    var body: some View {
    
        // Toggle between black and white as the visualization's background color:
        let backgroundColor: Color = (settings.selectedColorScheme == .dark) ? Color.black : Color.white
        
        Canvas { context, size in

            let width: Double  = size.width
            let height: Double = size.height
            let halfWidth:  Double =  0.5 * width
            let halfHeight: Double =  0.5 * height
            var x : Double = 0.0       // The drawing origin is in the upper left corner.
            var y : Double = 0.0       // The drawing origin is in the upper left corner.
            var mag: Double = 0.0          // used as a preliminary part of the audio amplitude value
            var thisLineWidth: Double = 0.0
            let circleCount: Int = 144
            
// ---------------------------------------------------------------------------------------------------------------------
   
            context.withCGContext { cgContext in
                
                let center = CGPoint(x: halfWidth, y: halfHeight)

                // Render the 144 concentric circle/ovals:
                for circleNum in 0 ..< circleCount {

                    // As circleNum goes from 0 to circleCount, rampUp goes from 0.0 to 1.0:
                    let rampUp: Double = Double(circleNum) / Double(circleCount)

                    let circleNum2 = 6 * circleNum  // 6 * 144 = 864
                    let hue: Double = Double( circleNum%12 ) / 12.0
                    let result = settings.HSBtoRGB(hueValue: hue, saturationValue: 1.0, brightnessValue: 1.0)
                    let red = result.redValue
                    let green = result.greenValue
                    let blue = result.blueValue

                    thisLineWidth = Double( audioManager.muSpectrum[circleNum2] )
                    thisLineWidth = max(0.0, thisLineWidth)     // ensures that thisLineWidth is greater than zero.
                    cgContext.setLineWidth(thisLineWidth)

                    let radiusX = rampUp * halfWidth
                    let radiusY = rampUp * halfHeight

                    if(settings.optionOn ==  true) {        // Show oval shape instead of circle shape.
                        // https://betterprogramming.pub/implementing-swiftui-canvas-view-in-ios-15-b7909eac207
                        let rect = CGRect(
                            x: halfWidth - radiusX,
                            y: halfHeight - radiusY,
                            width: 2.0 * radiusX,
                            height: 2.0 * radiusY )

                        let path = CGPath( ellipseIn: rect, transform: nil)

                        cgContext.addPath(path)
                        cgContext.setLineWidth(thisLineWidth)
                        cgContext.setStrokeColor(CGColor.init(red: red, green: green, blue: blue, alpha: 1.0))
                        cgContext.strokePath()
                    }
                    else {
                        cgContext.addArc(center: center, radius: radiusX, startAngle: 0.0, endAngle: .pi * 2.0, clockwise: true)
                        cgContext.setStrokeColor(CGColor.init(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0))
                        cgContext.strokePath()
                    }

                }  // end of for() loop over circleNum


// ---------------------------------------------------------------------------------------------------------------------
                // Now render a four-fold muSpectrum[] across the middle of the pane:
                
                for row in 0 ..< 2 {            // We have a lower and an upper row.
                    for column in 0 ..< 2 {     // We have a left and a right column.
                    
                        let spectrumHeight = (row == 0) ? -0.1 * height : 0.1 * height // makes spectrum negative for lower row
                        let spectrumWidth = (column == 0) ? -halfWidth : halfWidth     // makes spectrum go to left for left column
                            
                            cgContext.move(to: CGPoint( x: halfWidth, y: halfHeight ) )
                            
                            for point in 0 ..< sixOctPointCount {
                                let upRamp =  Double(point) / Double(sixOctPointCount)
                                x = halfWidth + upRamp * spectrumWidth
                                mag = Double(audioManager.muSpectrum[point]) * spectrumHeight
                                y = halfHeight + mag
                                cgContext.addLine(to: CGPoint(x: x, y: y))
                            }
                            
                            if(settings.optionOn == true) {      // render four-fold muSpectrum in red
                                cgContext.setStrokeColor(CGColor.init(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0))
                            }else {                     // render four-fold muSpectrum in green
                                cgContext.setStrokeColor(CGColor.init(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0))
                            }

                            cgContext.setLineWidth(1.0)
                            cgContext.drawPath(using: CGPathDrawingMode.stroke)
                        
                    }  // end of for() loop over column
                }  // end of for() loop over row
            
            }  // end of context.withCGContext
            
            // Print on-screen the elapsed duration-per-frame (in milliseconds) (typically about 50)
            if(showMSPF == true) {
                let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                context.draw(Text("MSPF: \( settings.monitorPerformance() )"), in: frame )
            }
            
        }  // end of Canvas{}
        .background(backgroundColor)  // Toggle between black and white background color.
        
    }  // end of var body: some View{}
}  // end of Cymbal{} struct



struct Cymbal_Previews: PreviewProvider {
    static var previews: some View {
        Cymbal()
    }
}
