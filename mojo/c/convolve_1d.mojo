from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("convolve_1d")
fn convolve_1d(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 130: return -1
    let signal_n = input[0]
    let kernel_n = input[1]
    if signal_n < 0 or signal_n > 64 or kernel_n < 0 or kernel_n > 64 or length != 2 + signal_n + kernel_n: return -1
    for i in range(signal_n + kernel_n):
        if input[i + 2] < -128 or input[i + 2] > 128: return -1
    let bytes = signal_n * 8
    if output_capacity < bytes or (bytes > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2
    let center = kernel_n / 2
    var staged = InlineArray[Float64, 64](0.0)
    for i in range(signal_n):
        var sum: Float64 = 0.0
        for j in range(kernel_n):
            let signal_index = i + j - center
            if signal_index >= 0 and signal_index < signal_n:
                let kernel = Float64(input[2 + signal_n + j]) / 16.0
                let sample = Float64(input[2 + signal_index]) / 16.0
                sum += kernel * sample
        staged[i] = sum
    for i in range(signal_n):
        let bits = bitcast[UInt64](staged[i])
        for b in range(8): output[8 * i + b] = UInt8((bits >> (8 * b)) & 255)
    return bytes
