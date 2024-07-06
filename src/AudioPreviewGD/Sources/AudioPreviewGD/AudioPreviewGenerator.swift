import SwiftGodot

//TODO: this should be good for testing!
@Godot(.tool)
class AudioPreviewGenerator : Node {
    //TODO: can I expose this to Godot with current SwiftGodot? not sure I can so I just make all other generators a stub rn
    static var shared: AudioPreviewGenerator = AudioPreviewGenerator()
    
    private var signal_callable: Callable = Callable(signal_propagate as! ([Variant]) -> Variant?)
    
    class Preview {
        var preview: AudioPreview
        var baseStream: AudioStream
        var playback: AudioStreamPlayback
        var generating: Bool //TODO: atomic boolean probably
        var id: UInt
        var thread: Thread
        
        init(preview: AudioPreview, baseStream: AudioStream, playback: AudioStreamPlayback, generating: Bool, id: UInt, thread: Thread) {
            self.preview = preview
            self.baseStream = baseStream
            self.playback = playback
            self.generating = generating
            self.id = id
            self.thread = thread
        }
    }
    
    override func _ready() {
        if (self != AudioPreviewGenerator.shared) {
            AudioPreviewGenerator.shared.connect(signal: "preview_updated", callable: signal_callable)
        }
    }
    
    deinit {
        if (self != AudioPreviewGenerator.shared) {
            AudioPreviewGenerator.shared.disconnect(signal: "preview_updated", callable: signal_callable)
        }
    }
    
    #signal("preview_updated", arguments: ["audio_stream": AudioStream.self])

    static var previews: [UInt: Preview] = [:]
    
    func process_generation(preview: Preview) {
        let mixbuffChunkSeconds = 0.25
        let mixbuffChunkFrames: UInt = UInt(AudioServer.getMixRate() * mixbuffChunkSeconds)
        var buffer: UnsafeMutableBufferPointer<AudioFrame> = UnsafeMutableBufferPointer.allocate(capacity: Int(mixbuffChunkFrames))
        
        let framesTotal: UInt = UInt(AudioServer.getMixRate() * preview.preview.length)
        var framesTodo: UInt = framesTotal
        
        preview.playback._start(fromPos: 0)
        
        while (framesTodo > 0) {
            let writeOffset: UInt = (framesTotal-framesTodo) * UInt(preview.preview.samples.count) / framesTotal
            let toRead: UInt = min(framesTodo, mixbuffChunkFrames)
            var toWrite: UInt = toRead * UInt(preview.preview.samples.count) / framesTotal
            toWrite = min(toWrite, UInt(preview.preview.samples.count) - writeOffset)
            
            preview.playback._mix(buffer: OpaquePointer(buffer.baseAddress), rateScale: 1.0, frames: Int32(toRead))
            
            for i in 0...toWrite {
                var maxVal: Double = -1000
                var minVal: Double = 1000
                var from = UInt(i * toRead / toWrite)
                var to = UInt((i + 1) * toRead / toWrite)
                to = min(to, toRead)
                from = min(from, toRead - 1)
                
                if (to == from) {
                    to = from + 1
                }
                
                for j in from...to {
                    let frame: AudioFrame = buffer[Int(j)]
                    
                    maxVal = max(maxVal, Double(frame.left))
                    maxVal = max(maxVal, Double(frame.right))
                    
                    minVal = min(minVal, Double(frame.left))
                    minVal = min(minVal, Double(frame.right))
                }
                
                let minByte: UInt8 = UInt8(GD.clamp(value: Variant((minVal * 0.5 + 0.5) * 255), min: Variant(0), max: Variant(255)))!
                let maxByte: UInt8 = UInt8(GD.clamp(value: Variant((maxVal * 0.5 + 0.5) * 255), min: Variant(0), max: Variant(255)))!
                
                preview.preview.samples[Int(writeOffset+i)] = (min: minByte, max: maxByte)
            }
            
            framesTodo -= toRead
            callDeferred(method: "deferredSignal", Variant(preview.baseStream))
        }
        
        preview.preview.version += 1
        preview.playback._stop()
        preview.generating = false
    }
    
    //awful gross type signature for Callable, don't worry about it it's fine
    func thread_command(args: [Variant]) -> Variant? {
        AudioPreviewGenerator.shared.process_generation(preview: AudioPreviewGenerator.previews[UInt(String(args[0])!)!]!)
        return nil
    }
    
    func deferredSignal(stream: AudioStream) {
        emit(signal: SignalWith1Argument("preview_updated", argument1Name: "audio_stream"), stream)
    }
    
    func signal_propagate(args: [Variant]) -> Variant? {
        emit(signal: SignalWith1Argument("preview_updated", argument1Name: "audio_stream"), args[0].asObject(AudioStream.self)!)
        return nil
    }
    
    //TODO: @Callable doesn't work for static funcs yet, so just leave it like this and access static previews dict
    @Callable func generate_preview(stream: AudioStream) -> AudioPreview {
        var streamId = stream.getInstanceId()
        
        if AudioPreviewGenerator.previews.keys.contains(streamId) {
            // ! is here because we just checked existence
            return AudioPreviewGenerator.previews[streamId]!.preview
        }
        
        var baseStream = stream
        var id = streamId
        var playback = stream.instantiatePlayback()!
        
        var length = stream.getLength()
        if (length == 0) {
            length = 60 * 5 //5 minutes default
        }
        
        var frames: Int = Int(AudioServer.getMixRate() * length) / 20
        
        var samples: [(min: UInt8, max: UInt8)] = []
        
        for i in 0...frames {
            samples[i] = (0, 255) //this is 127 in the original C++, even though it's an unsigned int??
        }
        
        var audioPreview = AudioPreview(samples: samples, length: length)
        audioPreview.samples = samples
        audioPreview.length = length
        
        var thread = Thread()
        
        var preview = Preview(preview: audioPreview, baseStream: baseStream, playback: playback, generating: true, id: id, thread: thread)
        
        AudioPreviewGenerator.previews[streamId] = preview
        
        //pass the id as a String because we can't trust the UInt id can fit inside an I64 for variant
        preview.thread.start(callable: Callable(thread_command).bind(Variant(String(id))))
        
        return preview.preview
    }
}
