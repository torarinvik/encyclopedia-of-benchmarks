from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("exponential_histogram_window")
fn exponential_histogram_window(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 130: return -1
    let wv = input[0]
    let nv = input[1]
    if wv < 1 or wv > 64 or nv < 0 or nv > 128: return -1
    let window = Int(wv)
    let n = Int(nv)
    if length != c_size_t(2+n): return -1
    for i in range(n):
        if input[2+i] != 0 and input[2+i] != 1: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8*n): return -2
    var ends = List[Int](capacity=128)
    var sizes = List[Int](capacity=128)
    for _ in range(128):
        ends.append(0)
        sizes.append(0)
    var used = 0
    for time in range(n):
        while used != 0 and time >= window and ends[0] <= time-window:
            for j in range(1, used):
                ends[j-1] = ends[j]
                sizes[j-1] = sizes[j]
            used -= 1
        if input[2+time] == 1:
            ends[used] = time
            sizes[used] = 1
            used += 1
        var size = 1
        while size <= 128:
            var first = used
            var second = used
            var found = 0
            for j in range(used):
                if sizes[j] == size:
                    if found == 0: first = j
                    elif found == 1: second = j
                    found += 1
            if found > 2:
                sizes[second] = 2*size
                for j in range(first+1, used):
                    ends[j-1] = ends[j]
                    sizes[j-1] = sizes[j]
                used -= 1
            size *= 2
        var total = 0
        for j in range(used): total += sizes[j]
        var oldest = 0
        if used != 0: oldest = sizes[0]
        var bits = UInt64(2*total-oldest)
        for j in range(8):
            output[8*time+j] = UInt8(bits & UInt64(255))
            bits = bits >> 8
    return Int64(8*n)
