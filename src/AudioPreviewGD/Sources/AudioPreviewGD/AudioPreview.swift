import SwiftGodot

@Godot(.tool)
class AudioPreview: RefCounted {
    var samples: [(min: UInt8, max: UInt8)] = []
    var length: Double = 0
    var version: Int = 0
    
    required init() {
        super.init()
    }
    
    required init(nativeHandle: UnsafeRawPointer) {
        super.init(nativeHandle: nativeHandle)
    }
    
    init(samples: [(min: UInt8, max: UInt8)], length: Double) {
        super.init()
        self.samples = samples
        self.length = length
    }
    
    @Callable func get_length() -> Double {
        return length
    }

    @Callable func get_max(start: Double, end: Double) -> Double {
        if (length == 0 || samples.count == 0) {
            return 0
        }

        let slice_from = GD.clampi(value: Int64(start / length * Double(samples.count)), min: 0, max: Int64(samples.count - 1))
        let slice_to = GD.clampi(value: Int64(end / length * Double(samples.count)), min: slice_from + 1, max: Int64(samples.count - 1))

        var maxVal: UInt8 = samples[0].max

        for entry in samples {
            maxVal = max(maxVal, entry.max)
        }

        return (Double(maxVal) / 255.0) * 2.0 - 1.0
    }

    @Callable func get_min(start: Double, end: Double) -> Double {
        if (length == 0 || samples.count == 0) {
            return 0
        }

        let slice_from = GD.clampi(value: Int64(start / length * Double(samples.count)), min: 0, max: Int64(samples.count - 1))
        let slice_to = GD.clampi(value: Int64(end / length * Double(samples.count)), min: slice_from + 1, max: Int64(samples.count - 1))

        var minVal: UInt8 = samples[0].min

        for entry in samples {
            minVal = min(minVal, entry.min)
        }

        return (Double(minVal) / 255.0) * 2.0 - 1.0
    }
}
