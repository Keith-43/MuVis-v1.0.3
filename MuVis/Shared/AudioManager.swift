/// AudioManager.swift
/// MuVis
///
/// The AudioManager class handles the playing, capture, and processing of audio data in real time.  It uses the AVAudioEngine API to create a chain of
/// audio-procesing nodes.  If the variable micEnabled is true then the chain processes audio data from the microphone.
/// The chain comprises the following node architecture:
///
/// microphone  ------>   micMixer  ------>  mixer ------->  mixer2 ----------> main ------->   (to speakers)
///                 node                    node        |       node                     mixer
///                                     |                                    node
///                                     v
///                                 sampling tap
///
/// The micMixer node amplifies the audio signal from the device's microphone input.
/// The mixer node is used to convert the input audio stream to monophonic, and convert the sampling rate to 44,100 sps (if necessary).
/// The mixer2 node sets the volume to zero when using the microphone input (preventing audio feedback).
/// The mainMixerNode is implemented automatically by the AVAudioEngine and links to the audio output (speakers).
///
/// If the variable filePlayEnabled is true then the chain processes audio data from song files selected from the device's file structure.
/// The chain comprises the following node architecture:
///
/// (file)  ---------->  player  ---------> mixer  --------->   delay  ------->  main  -------->  (to speakers)
///             node                    node        |           node                mixer
///                                 |                                   node
///                                 v
///                             sampling tap
///
/// The player node plays the audio stream from the desired music file.
/// The mixer node is used to convert the input audio stream to monophonic, and convert the sampling rate to 44,100 sps (if necessary).
/// The delay node is used to introduce a delay into the audio stream (after our sampling tap) to synchronize the audio output with the on-screen renederd
/// visualizations.  It compensates for the latency of the sampling process and graphics rendering.
/// The mainMixerNode is implemented automatically by the AVAudioEngine and links to the audio output (speakers).
///
/// Using a sampleRate of 44,100 sps, the AVAudioEngine's sampling tap delivers blockSampleCount = 4,410 samples every 0.1 seconds.
/// We use the circBuffer array to store 4 * 4410 = 17,640 samples, and then read 16,384 samples from this array every 0.1 seconds.
///
/// Declared functions:
///     func setupAudio()
///     func startEngine()
///     func pauseEngine()
///     func captureOutput(buffer)
///     func readData()
///     func processData(inputArray)
///
/// Created by Keith Bromley in Aug 2020.  Improved in Dec 2021.



import AVFoundation
import Accelerate

class AudioManager: ObservableObject {

    static let audioManager = AudioManager() // This singleton instantiates the AudioManager class and runs the setupAudio() func
    let settings = Settings()
    let spectralEnhancer = SpectralEnhancer()

    static let sampleRate: Double = 44100.0     // We will process the audio data at 44,100 samples per second.
    static let fftLength: Int =  16384          // The number of audio samples inputted to the FFT operation each frame.
    static let binCount: Int = fftLength/2      // The number of frequency bins provided in the FFT output
                                                // binCount = 8,192 for fftLength = 16,384

    // To capture 6 octaves, the highest note is B6 = 1,976 Hz      rightFreqB6 = 2,033.42 Hz   topBin = 755
    static let binCount6: Int =  756        // binCount6 = octTopBin[5] + 1 =  755 + 1 = 756

    // To capture 8 octaves, the highest note is B8 = 7,902 Hz      rightFreqB8 = 8,133.68 Hz   topBin = 3,021
    static let binCount8: Int = 3022        // binCount8 = octTopBin[7] + 1 = 3021 + 1 = 3022

    init() { setupAudio() }

    var isPaused: Bool = false          // When paused, don't overwrite the previous rendering with all-zeroes:
    var micEnabled: Bool = false        // true means microphone is on and its audio is being captured.
    var filePlayEnabled: Bool = true    // Either micEnabled or filePlayEnabled is always true (but not both).

    private let serialQueue = DispatchQueue(label: "...")
    // https://www.raywenderlich.com/books/concurrency-by-tutorials/v2.0/chapters/5-concurrency-problems

    private var tempUserGain: Float = 1.0
    
    public var userGain: Float {    // the user's choice for "gain"  (0.0  <= userGain  <= 2.0 ) Changed in ContentView
        get { return serialQueue.sync { tempUserGain }
        }
        set { serialQueue.sync { tempUserGain = newValue }
        }
    }
    
    private var tempUserSlope: Float = 0.015
    
    public var userSlope: Float {   // the user's choice for "slope" (0.00 <= userSlope <= 0.03) Changed in ContentView
        get { return serialQueue.sync { tempUserSlope }
        }
        set { serialQueue.sync { tempUserSlope = newValue }
        }
    }

    // Allow the user to choose to see normal spectrum or only peaks (with percussive noises removed).
    private var tempOnlyPeaks = false
    
    public var onlyPeaks: Bool {
        get { return serialQueue.sync { tempOnlyPeaks }
        }
        set { serialQueue.sync { tempOnlyPeaks = newValue }
        }
    }

    var selectedSongURL = Bundle.main.url(forResource: "music", withExtension: "mp3")  // Play this song when MuVis app starts.
   
    var engine: AVAudioEngine!
    var player = AVAudioPlayerNode()    // player will read and play our song file

    // Declare a dispatchSemaphore for syncronizing processing between frames:
    let dispatchSemaphore = DispatchSemaphore(value: 1)

    let desiredBlockSampleCount: Int = 4410
    var actualBlockSampleCount: Int = 0  // will be set to the number of audio samples actually captured per block

    static let circBufferLength: Int = 17640  // Must be >= 16384     I chose 4 * 4410 = 17,640
    var circBuffer : [Float] = [Float] (repeating: 0.0, count: circBufferLength)  // Store the most recent 17,640 samples in circBuffer.

    var sampleValues: [Float] = [Float] (repeating: 0.0, count: AudioManager.fftLength)

    // Declare a circular buffer to store the past 48 blocks of the first six octaves of muSpectrum[]. It stores 48*72*12=41,472 points
    var pointHistoryBuffer: [Float] = [Float](repeating: 0.0, count: historyCount * sixOctPointCount)

    // Declare arrays of the final values (for this frame) that we will publish to the various visualizations:
    @Published var spectrum = [Float](repeating: 0.0, count: binCount8)             // binCount8 = 3021+1 = 3022
    @Published var muSpectrum = [Float](repeating: 0.0, count: totalPointCount)     // totalPointCount = 96*12 = 1,152

    // Declare a circular array to store the past 48 blocks of the first six octaves of muSpectrum[]. It stores 48*72*12=41,472 points
    @Published var muSpecHistory: [Float] = [Float](repeating: 0.0, count: historyCount * sixOctPointCount)



    // ----------------------------------------------------------------------------------------------------------------
    //  Setup and start our audio engine:
    func setupAudio(){
    
        #if os(iOS)
            // For iOS devices, set the audioSession category, mode, and options:
            let session = AVAudioSession.sharedInstance()  // Get the singleton instance of an AVAudioSession.
            do {
                if(filePlayEnabled) {
                    // This is required by iOS to prevent output audio from only going to the iPhones's rear speaker.
                    try session.setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.default, options: [.defaultToSpeaker])
                }
                else {
                    try session.setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.default, options: [])
                }
                do {
                    try session.setActive(true, options: .notifyOthersOnDeactivation)
                }
                catch  {
                    print("ERROR: Failed to set audio record session active")
                }
            } catch { print("Failed to set audioSession category.") }
        #endif
        
        // Create our player, mixer, and delay nodes.  (The mainMixerNode is created automatically.)
        engine = AVAudioEngine()            // Initialize our audio engine.
        let mic = engine.inputNode          // mic inputs audio from the default microphone
        let micMixer = AVAudioMixerNode()   // micMixer converts the microphone input to compatible signal
        player = AVAudioPlayerNode()        // player will read and play our song file  // needed here for Mic On/Mic Off to work properly iniOS
        let mixer = AVAudioMixerNode()      // mixer will convert channelCount to mono, and sampleRate to 11,025
        let mixer2 = AVAudioMixerNode()     // mixer2 sets volume to 0 when using microphone (preventing feedback)
        let delay = AVAudioUnitDelay()      // delay will add a 0.1 seconds delay to the audio output

        // Before connecting nodes we need to attach them to the engine:
        engine.attach(micMixer) // mic provides audio input from the microphone
        engine.attach(player)   // player will read and play our song file
        engine.attach(mixer)    // mixer will convert channelCount to mono, and sampleRate to 11,025
        engine.attach(mixer2)   // mixer2 sets volume to 0 when using microphone (preventing audio feedback)
        engine.attach(delay)    // delay will add a 0.1 seconds delay to the audio output

        do {
            
            let micFormat = mic.inputFormat(forBus: 0)

            // Player nodes have a few ways to play music, the easiest way is from an AVAudioFile
            let audioFile = try AVAudioFile(forReading: selectedSongURL!)

            // Capture the AVAudioFormat of our player node (It should be that of the music file.)
            let playerOutputFormat = player.outputFormat(forBus: 0)

            // Define a monophonic (1 ch) and 11025 sps AVAudioFormat for the desired output of our mixer node.
            let mixerOutputFormat =  AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: AudioManager.sampleRate, channels: 1, interleaved: false)

            // Connect our nodes in the desired order:
            if(micEnabled) {
                engine.connect(mic,      to: micMixer, format: micFormat)           // Connect microphone to mixer
                engine.connect(micMixer, to: mixer, format: micFormat)              // Connect micMixer to mixer
                engine.connect(mixer,    to: mixer2, format: mixerOutputFormat)     // Connect mixer to mixer2
                engine.connect(mixer2,   to: engine.mainMixerNode, format:mixerOutputFormat) // Connect mixer2 to mainMixerNode
                mixer2.volume = 0.0 // Zeroing mixer2.volume effectively shuts off the speakers when using the microphone (but not for FilePlay).
            }
            else {
                engine.connect(player,  to: mixer, format: playerOutputFormat)      // Connect player to mixer
                engine.connect(mixer,   to: delay, format: mixerOutputFormat)       // Connect mixer to delay
                engine.connect(delay,   to: engine.mainMixerNode, format:mixerOutputFormat) // Connect delay to mainMixerNode

                player.scheduleFile(audioFile, at: nil, completionHandler: nil)     // Play the file.
            }

        }   catch let error { print(error.localizedDescription) }
        
        // Install a tap on the mixerNode to get the buffer data to use for rendering visualizations:
        // Even when I request 1024 samples, the app consistently gives me 4410 samples every 0.1 seconds.
        mixer.installTap(onBus:0, bufferSize: 4410, format: nil) { (buffer, time) in
            self.captureOutput(buffer: buffer)  // This runs the capturOutput() func using the buffer created by the installTap() operation.
            // print("actual frameLength: \(buffer.frameLength)")  // 4410 for SR=44100
        }
    
        engine.prepare()        // Prepare and start our audio engine:
        startEngine()           // When user clicks "Resume", MuVis runs the startEngine() func
    
        // Set the parameters for our delay node:
        delay.delayTime = 0.3   // The delay is specified in seconds. Default is 1. Valid range of values is 0 to 2 seconds.
        delay.feedback = 0.0    // Percentage of the output signal fed back. Default is 50%. Valid range of values is -100% to 100%.
        delay.lowPassCutoff = 5512  // The default value is 15000 Hz. The valid range of values is 10 Hz through (sampleRate/2).
        delay.wetDryMix = 100     // Blend is specified as a percentage. Default value is 100%. Valid range is 0% (all dry) through 100% (all wet).
        
        if(filePlayEnabled) { player.play() }   // Start playing the music.
        
    }  // end of setupAudio() func



    // ----------------------------------------------------------------------------------------------------------------
    func startEngine() {
        do { try engine.start()
        } catch { print("Unable to start AVAudioEngine: \(error.localizedDescription)") }
    }



    // ----------------------------------------------------------------------------------------------------------------
    func pauseEngine() {
        engine.pause()       // Pause the music
        // developer.apple.com/documentation/avfaudio/avaudioengine/1387076-pause
    }



    // ----------------------------------------------------------------------------------------------------------------
    func captureOutput(buffer: AVAudioPCMBuffer) {

        actualBlockSampleCount = Int(buffer.frameLength)  // number of audio samples actually captured per block (typically 4410)
        
        var blockSampleValues: [Float] = [Float](repeating: 0.0, count: desiredBlockSampleCount)  // one block of 4410 audio sample values
        
        // Extract the most-recent block of audio samples from the AVAudioPCMBuffer created by the AVAudioEngine:
        blockSampleValues  = Array(UnsafeBufferPointer(start: buffer.floatChannelData?[0], count: actualBlockSampleCount))

        // We will only readData, processData, and publishData for those audio frames which contain exactly 4410 audio samples:
        if(actualBlockSampleCount == desiredBlockSampleCount) {
            // Store the most recent 4 * 4410 audio samples in our circular buffer:
            // Each frame, write the new blockSampleValues array into the recirculating circBuffer array:
            // The circBuffer array always has the oldest values at the beginning and the newest values at the end.
            // We do NOT have to worry about writePointers, readPointers, or wrap-around.
            
            if( (actualBlockSampleCount >= 0) && (actualBlockSampleCount <= circBuffer.count) ) {
                circBuffer.removeFirst(actualBlockSampleCount)        // requires that  0 <= blockSampleCount <= circBuffer.count
                circBuffer.append(contentsOf: blockSampleValues)
            }
            
            readData()
        }

    }  // end of captureOutput() func



    // ----------------------------------------------------------------------------------------------------------------
    // After the first 4 frames of audio data, the AudioManager has filled the circBuffer with the most-recent 4 * 4410
    // = 17,640 audio samples. Now we can read the data out of this circular buffer into the 16,384-element sampleValues array.

    func readData() {

        // Fill the sampleValues array with the oldest 16,384 audio sample values still in the circBuffer:
        sampleValues = Array ( circBuffer[0 ..< AudioManager.fftLength] )   // samples 0 ..< 16384
        processData(inputArray: sampleValues)
        
    }  // end of readData() func



    // ----------------------------------------------------------------------------------------------------------------
    // Now we can start processing and rendering this audio data:
    func processData(inputArray: [Float]) {
    
        let inputArray: [Float] = inputArray
        
        // Declare an FFT setup object for fftLength values going forward (time domain -> frequency domain):
        let fftSetup = vDSP_DFT_zop_CreateSetup(nil, UInt(AudioManager.fftLength), vDSP_DFT_Direction.FORWARD)
        
        // Setup the FFT output variables:
        var realIn  = [Float](repeating: 0.0, count: AudioManager.fftLength)
        var imagIn  = [Float](repeating: 0.0, count: AudioManager.fftLength)
        var realOut = [Float](repeating: 0.0, count: AudioManager.fftLength)
        var imagOut = [Float](repeating: 0.0, count: AudioManager.fftLength)
        
        // Calculate a Hann window function of length fftLength:
        var hannWindow = [Float](repeating: 0, count: AudioManager.fftLength)

        vDSP_hann_window(&hannWindow, vDSP_Length(AudioManager.fftLength), Int32(vDSP_HANN_NORM))

        // Fill the real input part (&realIn) with audio data from the AudioManager (multiplied by the Hann window):
        vDSP_vmul(inputArray, 1, hannWindow, vDSP_Stride(1), &realIn, vDSP_Stride(1), vDSP_Length(AudioManager.fftLength))

        // Execute the FFT.  The results are now inside the realOut[] and imagOut[] arrays:
        vDSP_DFT_Execute(fftSetup!, &realIn, &imagIn, &realOut, &imagOut)

        realOut.withUnsafeMutableBufferPointer { realOutBuffer in
            imagOut.withUnsafeMutableBufferPointer { imagOutBuffer in
                
                // Package the FFT results inside a complex vector representation used in the vDSP framework:
                var complex = DSPSplitComplex(realp: realOutBuffer.baseAddress!, imagp: imagOutBuffer.baseAddress!)

                // Declare an array to hold the rms amplitude FFT output:
                var amplitudes = [Float](repeating: 0.0, count: AudioManager.binCount)  // This covers all 8,192 frequency bins.
                
                // Calculate the rms amplitude FFT results:
                vDSP_zvabs( &complex, vDSP_Stride(1), &amplitudes, vDSP_Stride(1),  vDSP_Length(AudioManager.binCount) )

                // Declare an array to contain the first 3,022 binValues of the current window of audio spectral data:
                var binBuffer = [Float](repeating: 0.0, count: AudioManager.binCount)

                // Normalize the rms amplitudes to be loosely within the range 0.0 to 1.0:
                for bin in 0 ..< AudioManager.binCount8 {
                    let scalingFactor: Float = 0.001 * ( userGain + userSlope * Float(bin) )  // The 0.001 is adhoc to look best.
                    binBuffer[bin] = scalingFactor * amplitudes[bin]
                }
                
                if(onlyPeaks == true) {binBuffer = spectralEnhancer.enhance(inputArray: binBuffer) }

                let binWidth = (Float(AudioManager.sampleRate)/2.0) / Float(AudioManager.binCount) // (44,100/2) / 8,192 = 2.69165 Hz

                // Prepare to enhance the spectrum to the muSpectrum:
                var outputIndices   = [Float] (repeating: 0.0, count: totalPointCount)  // totalPointCount = 96 * 12 = 1,152
                var pointBuffer     = [Float] (repeating: 0.0, count: totalPointCount)  // totalPointCount = 96 * 12 = 1,152

                // Compute the pointBuffer[] (precursor to the muSpectrum[]):
                // This uses pointsPerNote = 12, so the pointBuffer has size totalPointCount = 96 * 12 = 1,152
                for point in 0 ..< totalPointCount {
                    outputIndices[point] = (settings.leftFreqC1 * pow(2.0, Float(point) / Float(notesPerOctave * pointsPerNote))) / binWidth
                }

                vDSP_vqint( binBuffer,
                            &outputIndices,
                            vDSP_Stride(1),
                            &pointBuffer,
                            vDSP_Stride(1),
                            vDSP_Length(totalPointCount),
                            vDSP_Length(AudioManager.binCount8))

                let muSpectrum6  = Array( pointBuffer[0 ..< sixOctPointCount] )  // Reduce pointCount from 1152 to 864
                
                DispatchQueue.main.async { [self] in
                    // Store the current muSpectrum6 array (72*12 points) into the pointHistoryBuffer array (48*72*12 points):
                    pointHistoryBuffer.removeFirst(sixOctPointCount)    // requires that  0 <= sixOctPointCount <= pointHistoryBuffer.count
                    pointHistoryBuffer.append(contentsOf: muSpectrum6)
                    // Note that the newest data is at the end of the pointHistoryBuffer (and also of the muSpecHistory array)
                }
                
                DispatchQueue.main.async { [self] in
                    spectrum    = binBuffer                 // <- 8,192 bins
                    muSpectrum  = pointBuffer               // <- 96 * 12 = 1,152 points
                    muSpecHistory = pointHistoryBuffer      // <- 48 * 72 * 12 = 48 * 864 = 41,472 points
                }
            }
        }

    } // end of processData() func
    
}  // end of AudioManager class
