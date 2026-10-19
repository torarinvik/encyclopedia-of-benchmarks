from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("composite_lfsr_majority_clock")
fn composite_lfsr_majority_clock(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3: return -1
    if input[0] < 0 or input[0] > 524287 or input[1] < 0 or input[1] > 4194303 or input[2] < 0 or input[2] > 8388607: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < 32: return -2
    var s1 = UInt64(input[0])
    var s2 = UInt64(input[1])
    var s3 = UInt64(input[2])
    let c1 = (s1 >> 8) & 1
    let c2 = (s2 >> 10) & 1
    let c3 = (s3 >> 10) & 1
    let majority = 1 if c1 + c2 + c3 >= 2 else 0
    let emitted = ((s1 >> 18) ^ (s2 >> 21) ^ (s3 >> 22)) & 1
    if c1 == majority: s1 = ((s1 << 1) & 524287) | (((s1 >> 13) ^ (s1 >> 16) ^ (s1 >> 17) ^ (s1 >> 18)) & 1)
    if c2 == majority: s2 = ((s2 << 1) & 4194303) | (((s2 >> 20) ^ (s2 >> 21)) & 1)
    if c3 == majority: s3 = ((s3 << 1) & 8388607) | (((s3 >> 7) ^ (s3 >> 20) ^ (s3 >> 21) ^ (s3 >> 22)) & 1)
    var staged = InlineArray[UInt64, 4](0)
    staged[0] = emitted
    staged[1] = s1
    staged[2] = s2
    staged[3] = s3
    for i in range(4):
        for b in range(8): output[8 * i + b] = UInt8((staged[i] >> (8 * b)) & 255)
    return 32
