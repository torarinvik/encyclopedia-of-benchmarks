from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import exp, pow
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("deriche")
fn deriche(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3: return -1.0e300
    if input[0] < 1 or input[0] > 32 or input[1] < 1 or input[1] > 32 or input[2] < 1 or input[2] > 4: return -1.0e300
    let width = Int(input[0])
    let height = Int(input[1])
    let passes = Int(input[2])
    let alpha = Float32(0.25)
    let e = exp(-alpha)
    let k = ((Float32(1.0) - e) * (Float32(1.0) - e)) / (Float32(1.0) + Float32(2.0) * alpha * e - exp(Float32(2.0) * alpha))
    let a1 = k
    let a2 = k * e * (alpha - Float32(1.0))
    let a3 = k * e * (alpha + Float32(1.0))
    let a4 = -k * exp(-Float32(2.0) * alpha)
    let b1 = pow(Float32(2.0), -alpha)
    let b2 = -exp(-Float32(2.0) * alpha)
    var image = InlineArray[Float32, 1024](fill=0.0)
    var filtered = InlineArray[Float32, 1024](fill=0.0)
    var forward = InlineArray[Float32, 1024](fill=0.0)
    var reverse = InlineArray[Float32, 1024](fill=0.0)
    for i in range(width):
        for j in range(height):
            image[i * height + j] = Float32((313 * i + 991 * j) % 65536) / Float32(65535.0)
    for _ in range(passes):
        for i in range(width):
            var prev: Float32 = 0.0
            var prior: Float32 = 0.0
            var last_input: Float32 = 0.0
            for j in range(height):
                let at = i * height + j
                var value = a1 * image[at] + a2 * last_input
                value = value + b1 * prev
                value = value + b2 * prior
                forward[at] = value
                last_input = image[at]
                prior = prev
                prev = value
            var next1: Float32 = 0.0
            var next2: Float32 = 0.0
            var input1: Float32 = 0.0
            var input2: Float32 = 0.0
            var j = height
            while j > 0:
                j -= 1
                let at = i * height + j
                var value = a3 * input1 + a4 * input2
                value = value + b1 * next1
                value = value + b2 * next2
                reverse[at] = value
                input2 = input1
                input1 = image[at]
                next2 = next1
                next1 = value
        for at in range(width * height): filtered[at] = forward[at] + reverse[at]
        for j in range(height):
            var prev: Float32 = 0.0
            var prior: Float32 = 0.0
            var last_input: Float32 = 0.0
            for i in range(width):
                let at = i * height + j
                var value = a1 * filtered[at] + a2 * last_input
                value = value + b1 * prev
                value = value + b2 * prior
                forward[at] = value
                last_input = filtered[at]
                prior = prev
                prev = value
            var next1: Float32 = 0.0
            var next2: Float32 = 0.0
            var input1: Float32 = 0.0
            var input2: Float32 = 0.0
            var i = width
            while i > 0:
                i -= 1
                let at = i * height + j
                var value = a3 * input1 + a4 * input2
                value = value + b1 * next1
                value = value + b2 * next2
                reverse[at] = value
                input2 = input1
                input1 = filtered[at]
                next2 = next1
                next1 = value
        for at in range(width * height): image[at] = forward[at] + reverse[at]
    var checksum: Float64 = 0.0
    for at in range(width * height): checksum += Float64(image[at])
    return checksum
