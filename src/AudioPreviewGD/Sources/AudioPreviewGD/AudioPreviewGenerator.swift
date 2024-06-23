import SwiftGodot

//TODO: this is single-threaded for now, I might look into multithreading later but Oh God The Perils
//TODO: actually generate previews, not there quite yet wheeee
@Godot(.tool)
class AudioPreviewGenerator : Node {
    class Preview {
        var preview: AudioPreview
        var baseStream: AudioStream
        var playback: AudioPlayback
        var generating: Bool
        var id: UInt
    }

    #signal("preview_updated", argument: ["audio_stream": AudioStream.self])

    static var previews: [UInt: Preview] = [:]

    @Callable static func generate_preview(stream: AudioStream) -> AudioPreview {
        var streamId = stream.getInstanceId()

        if previews.keys.contains(streamId) {
            return previews[streamId].preview
        }

        var preview = Preview()
        preview.baseStream = stream
        preview.id = streamId
        preview.playback = stream.instantiatePlayback()
        preview.generating = true

        var length = stream.getLength()
        if (length == 0) {
            length = 60 * 5 //5 minutes default
        }

        var frames: Int = (AudioServer.GetMixRate() * length) / 20

        var samples: [(min: UInt8, max: UInt8)] = []

        for i in 0..frames {
            samples[i] = (0, 255) //this is 127 in the original C++, even though it's an unsigned int??
        }

        var audioPreview = AudioPreview()
        audioPreview.samples = samples
        audioPreview.length = length
        preview.preview = audioPreview

        previews[streamId] = preview

        return preview
    }
}