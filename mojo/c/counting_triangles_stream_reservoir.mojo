from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("counting_triangles_stream_reservoir")
fn counting_triangles_stream_reservoir(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                       output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 6 or length > 114: return -1
    let n = input[0]
    let mv = input[1]
    if n < 2 or n > 8 or mv < 1 or mv > 28: return -1
    let m = Int(mv)
    if length != c_size_t(2 + 4 * m): return -1
    var seen = List[Bool](capacity=64)
    for _ in range(64): seen.append(False)
    for i in range(m):
        let u = input[2 + 2 * i]
        let v = input[3 + 2 * i]
        if u < 0 or v <= u or v >= n: return -1
        let index = Int(8 * u + v)
        if seen[index]: return -1
        seen[index] = True
    let draws = 2 + 2 * m
    for t in range(m):
        for slot in range(2):
            let draw = input[draws + 2 * t + slot]
            if draw < 0 or draw > Int64(t): return -1
    let required = 32 * m
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2
    var slots = List[Int64](capacity=4)
    for _ in range(4): slots.append(0)
    var staged = List[Int64](capacity=4 * m)
    for t in range(m):
        for slot in range(2):
            if input[draws + 2 * t + slot] == 0:
                slots[2 * slot] = input[2 + 2 * t]
                slots[2 * slot + 1] = input[3 + 2 * t]
        for i in range(4): staged.append(slots[i])
    for i in range(4 * m):
        for byte in range(8):
            output[8 * i + byte] = UInt8((staged[i] >> (8 * byte)) & 255)
    return Int64(required)
