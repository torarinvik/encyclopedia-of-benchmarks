from std.collections import InlineArray, List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("static_range_sum_with_upper_bound")
fn static_range_sum_with_upper_bound(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 258: return -1
    if input[0] < 1 or input[0] > 64 or input[1] < 1 or input[1] > 64: return -1
    let n = Int(input[0]); let q = Int(input[1])
    if length != c_size_t(2+n+3*q): return -1
    var current = InlineArray[Int, 64](fill=0)
    var scratch = InlineArray[Int, 64](fill=0)
    for i in range(n):
        if input[2+i] < 0 or input[2+i] > 1000000000: return -1
        current[i] = Int(input[2+i])
    for i in range(q):
        let base = 2+n+3*i
        if input[base] < 0 or input[base] > input[base+1] or input[base+1] > n: return -1
        if input[base+2] < 0 or input[base+2] > 1000000000: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(16*q): return -2
    var counts = List[Int](length=1950, fill=0)
    var sums = List[Int](length=1950, fill=0)
    var offsets = InlineArray[Int, 30](fill=0)
    for level in range(30):
        let mask = 1 << (29-level)
        for i in range(n):
            let zero = (current[i] & mask) == 0
            counts[65*level+i+1] = counts[65*level+i] + Int(zero)
            sums[65*level+i+1] = sums[65*level+i]
            if zero: sums[65*level+i+1] += current[i]
        offsets[level] = counts[65*level+n]
        var zero_pos = 0; var one_pos = offsets[level]
        for i in range(n):
            if (current[i] & mask) == 0:
                scratch[zero_pos] = current[i]; zero_pos += 1
            else:
                scratch[one_pos] = current[i]; one_pos += 1
        for i in range(n): current[i] = scratch[i]
    for i in range(q):
        let base = 2+n+3*i
        var l = Int(input[base]); var r = Int(input[base+1])
        let threshold = Int(input[base+2])+1
        var count = 0; var sum = 0
        for level in range(30):
            let zl = counts[65*level+l]; let zr = counts[65*level+r]
            if (threshold & (1 << (29-level))) != 0:
                count += zr-zl; sum += sums[65*level+r]-sums[65*level+l]
                l += offsets[level]-zl; r += offsets[level]-zr
            else: l = zl; r = zr
        for byte in range(8):
            output[16*i+byte] = UInt8((count >> (8*byte)) & 255)
            output[16*i+8+byte] = UInt8((sum >> (8*byte)) & 255)
    return Int64(16*q)
