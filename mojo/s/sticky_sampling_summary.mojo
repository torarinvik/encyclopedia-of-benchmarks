from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn put_word(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    var bits = bitcast[UInt64](value)
    for j in range(8):
        output[offset+j] = UInt8(bits & UInt64(255))
        bits = bits >> 8

@export("sticky_sampling_summary")
fn sticky_sampling_summary(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                           output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 323: return -1
    let tv = input[0]
    let nv = input[1]
    let kv = input[2]
    if tv < 1 or tv > 8 or nv < 0 or nv > 64 or kv < 0 or kv > 256: return -1
    let t = Int(tv)
    let n = Int(nv)
    let k = Int(kv)
    if length != c_size_t(3+n+k): return -1
    for i in range(n):
        if input[3+i] < 0 or input[3+i] > 15: return -1
    for i in range(k):
        if input[3+n+i] < 0 or input[3+n+i] > 255: return -1
    var counts = List[Int64](capacity=16)
    for _ in range(16): counts.append(0)
    var cursor = 0
    var rate = 1
    var phase_end = 2*t
    for i in range(n):
        if i == phase_end:
            rate *= 2
            phase_end += rate*t
            for item in range(16):
                while counts[item] != 0:
                    if cursor == k: return -1
                    let draw = input[3+n+cursor]
                    cursor += 1
                    if draw%2 == 1: break
                    counts[item] -= 1
        let item = Int(input[3+i])
        if counts[item] != 0: counts[item] += 1
        else:
            if cursor == k: return -1
            let draw = Int(input[3+n+cursor])
            cursor += 1
            if draw%rate == 0: counts[item] = 1
    if cursor != k: return -1
    var active = 0
    for item in range(16):
        if counts[item] != 0: active += 1
    let bytes = 8+16*active
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    put_word(output, 0, Int64(active))
    var offset = 8
    for item in range(16):
        if counts[item] != 0:
            put_word(output, offset, Int64(item))
            put_word(output, offset+8, counts[item])
            offset += 16
    return Int64(bytes)
