import SwiftGodot

@Godot(.tool)
class AudioPreview: RefCounted {
    var samples: [(min: UInt8, max: UInt8)] = []
    var length: Double
    var version: Int

    @Callable func get_length() -> Double {
        return length
    }

    @Callable func get_max(start: Double, end: Double) -> Double {
        if (length == 0 || samples.count == 0) {
            return 0
        }

        let slice_from: Int = GD.clampi(value: start / length * samples.count, min: 0, max: samples.count - 1)
        let slice_to: Int = GD.clampi(value: end / length * samples.count, min: slice_from + 1, max: samples.count - 1)

        var max: UInt8 = samples[0].max

        for entry in samples {
            max = GD.maxi(max, entry.max)
        }

        return (max / 255.0) * 2.0 - 1.0
    }

    @Callable func get_min(start: Double, end: Double) -> Double {
        if (length == 0 || samples.count == 0) {
            return 0
        }

        let slice_from: Int = GD.clampi(value: start / length * samples.count, min: 0, max: samples.count - 1)
        let slice_to: Int = GD.clampi(value: end / length * samples.count, min: slice_from + 1, max: samples.count - 1)

        var min: UInt8 = samples[0].min

        for entry in samples {
            min = GD.maxi(min, entry.min)
        }

        return (min / 255.0) * 2.0 - 1.0
    }
}