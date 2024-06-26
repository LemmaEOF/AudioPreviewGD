import SwiftGodot

//TODO: this is single-threaded for now, I might look into multithreading later but Oh God The Perils
//TODO: actually generate previews, not there quite yet wheeee
@Godot(.tool)
class AudioPreviewGenerator : Node {
    //TODO: can I expose this to Godot with current SwiftGodot? not sure I can, but it's here just in case
    static var shared: AudioPreviewGenerator = AudioPreviewGenerator()
    
    class Preview {
        var preview: AudioPreview
        var baseStream: AudioStream
        var playback: AudioStreamPlayback
        var generating: Bool = false //TODO: atomic integer probably
        var id: UInt = 0
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

    #signal("preview_updated", arguments: ["audio_stream": AudioStream.self])

    static var previews: [UInt: Preview] = [:]
    
    func process_generation(previewId: UInt) {
        //TODO: impl
    }
    
    //awful gross type signature for Callable, don't worry about it it's fine
    //TODO: should this happen on the shared or the instance? still gotta figure that stuff out for singleton stuff...
    func thread_command(args: [SwiftGodot.Variant]) -> SwiftGodot.Variant? {
        AudioPreviewGenerator.shared.process_generation(previewId: UInt(String(args[0])!)!)
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
