# Independent bounded seam-carving profile; see package LICENSE.txt.
from std.ffi import c_size_t
from std.math import sqrt
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("seam_carving")
fn seam_carving(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 38: return -1
    let wv = input[0]; let hv = input[1]
    if wv < 2 or wv > 6 or hv < 1 or hv > 6 or length != c_size_t(2 + wv * hv): return -1
    let width = Int(wv); let height = Int(hv)
    var pixels = InlineArray[Int64, 36](fill=0)
    for i in range(width * height):
        let value = input[2 + i]
        if value < 0 or value > 255: return -1
        pixels[i] = value
    var costs = InlineArray[Float64, 36](fill=0.0)
    var previous = InlineArray[Int, 36](fill=0)
    for y in range(height):
        for x in range(width):
            let index = y * width + x
            var left: Float64 = 0.0
            var right: Float64 = 0.0
            if x > 0:
                let delta = Float64(pixels[index - 1] - pixels[index])
                left = delta * delta + delta * delta + delta * delta
            if x + 1 < width:
                let delta = Float64(pixels[index + 1] - pixels[index])
                right = delta * delta + delta * delta + delta * delta
            let energy = sqrt(left + right)
            if y == 0:
                costs[index] = energy
            else:
                let first = max(0, x - 1)
                let last = min(width - 1, x + 1)
                var best = first
                for candidate in range(first + 1, last + 1):
                    if costs[(y - 1) * width + candidate] < costs[(y - 1) * width + best]: best = candidate
                previous[index] = best
                costs[index] = costs[(y - 1) * width + best] + energy
    var last = 0
    for x in range(1, width):
        if costs[(height - 1) * width + x] < costs[(height - 1) * width + last]: last = x
    var seam = InlineArray[Int, 6](fill=0)
    seam[height - 1] = last
    var y = height - 1
    while y > 0:
        seam[y - 1] = previous[y * width + seam[y]]
        y -= 1
    let bytes = height * (width - 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var at = 0
    for row in range(height):
        for x in range(width):
            if x != seam[row]:
                output[at] = UInt8(pixels[row * width + x])
                at += 1
    return Int64(bytes)
