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
        var generating: Bool = false
        var id: UInt = 0
        
        init(preview: AudioPreview, baseStream: AudioStream, playback: AudioStreamPlayback, generating: Bool, id: UInt) {
            self.preview = preview
            self.baseStream = baseStream
            self.playback = playback
            self.generating = generating
            self.id = id
        }
    }

    #signal("preview_updated", arguments: ["audio_stream": AudioStream.self])

    static var previews: [UInt: Preview] = [:]

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
        
        var preview = Preview(preview: audioPreview, baseStream: baseStream, playback: playback, generating: true, id: id)

        AudioPreviewGenerator.previews[streamId] = preview

        return preview.preview
    }
}
