from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("cusum_detector")
fn cusum_detector(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 133: return -1
    let n = input[0]
    if n < 0 or n > 128 or length != n + 5: return -1
    let target = input[1]
    let sigma = input[2]
    let allowance = input[3]
    let threshold = input[4]
    if target < -1000 or target > 1000 or sigma < 1 or sigma > 1000 or allowance < 0 or allowance > 1000 or threshold < 1 or threshold > 1000: return -1
    for i in range(n):
        if input[5 + i] < -1000 or input[5 + i] > 1000: return -1
    let bytes = n * 8
    if capacity < bytes or (n > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2
    var stage = InlineArray[Int64, 128](0)
    var upper = 0.0
    var lower = 0.0
    for i in range(n):
        let z = (Float64(input[5 + i]) - Float64(target)) / Float64(sigma)
        upper += z - Float64(allowance)
        if upper < 0.0: upper = 0.0
        lower += -z - Float64(allowance)
        if lower < 0.0: lower = 0.0
        var signal: Int64 = 0
        if upper > Float64(threshold): signal = 1
        elif lower > Float64(threshold): signal = -1
        if signal != 0: upper = 0.0; lower = 0.0
        stage[i] = signal
    for i in range(n):
        let bits = UInt64(stage[i])
        for b in range(8): output[i * 8 + b] = UInt8((bits >> (8 * b)) & 255)
    return bytes
