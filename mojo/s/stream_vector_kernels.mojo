# Bounded integer STREAM-kernel variant; see package README and upstream notice.
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("stream_vector_kernels")
fn stream_vector_kernels(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 259: return -1
    let mode = input[0]
    let count = input[1]
    if mode < 0 or mode > 3 or count < 0 or count > 128: return -1
    let n = Int(count)
    let has_alpha = mode == 1 or mode == 3
    let arrays = if mode < 2: 1 else: 2
    let start = if has_alpha: 3 else: 2
    if length != c_size_t(start + arrays * n): return -1
    var alpha: Int64 = 0
    if has_alpha:
        alpha = input[2]
        if alpha < -1000 or alpha > 1000: return -1
    for i in range(arrays * n):
        if input[start + i] < -1000 or input[start + i] > 1000: return -1
    var result = InlineArray[Int64, 128](fill=0)
    for i in range(n):
        let a = input[start + i]
        if mode == 0: result[i] = a
        elif mode == 1: result[i] = alpha * a
        elif mode == 2: result[i] = a + input[start + n + i]
        else: result[i] = a + alpha * input[start + n + i]
    let bytes = 8 * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(n):
        var bits = bitcast[UInt64](result[i])
        for byte in range(8):
            output[8 * i + byte] = UInt8(bits & 255)
            bits >>= 8
    return Int64(bytes)
