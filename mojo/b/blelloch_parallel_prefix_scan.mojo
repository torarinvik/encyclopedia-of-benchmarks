from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("blelloch_parallel_prefix_scan")
fn blelloch_parallel_prefix_scan(
    input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin],
    output_capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 66:
        return -1
    let n64 = input[0]
    if n64 < 1 or n64 > 64:
        return -1
    let n = Int(n64)
    if length != c_size_t(n + 1):
        return -1

    var tree = InlineArray[Int64, 64](fill=0)
    var padded = 1
    while padded < n:
        padded = padded << 1
    for i in range(n):
        let value = input[i + 1]
        if value < -1_000_000 or value > 1_000_000:
            return -1
        tree[i] = value
    if (output == UnsafePointer[UInt8, MutAnyOrigin]()
        or output_capacity < c_size_t(n * 8)):
        return -2

    var stride = 2
    while stride <= padded:
        let half = stride >> 1
        var right = stride - 1
        while right < padded:
            tree[right] = tree[right] + tree[right - half]
            right += stride
        stride = stride << 1
    tree[padded - 1] = 0
    stride = padded
    while stride >= 2:
        let half = stride >> 1
        var right = stride - 1
        while right < padded:
            let left = right - half
            let partial = tree[left]
            tree[left] = tree[right]
            tree[right] = tree[right] + partial
            right += stride
        stride = stride >> 1

    for i in range(n):
        let bits = UInt64(tree[i])
        for byte in range(8):
            output[i * 8 + byte] = UInt8((bits >> (byte * 8)) & 255)
    return Int64(n * 8)
