# Clean-room Parboil histogram profile; see package LICENSE.txt.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("parboil_histo")
fn parboil_histo(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 1027: return -1
    let iterations = input[0]; let bins = input[1]; let samples = input[2]
    if iterations < 0 or iterations > 8 or bins < 1 or bins > 256 or samples < 0 or samples > 1024: return -1
    if length != c_size_t(3+Int(samples)): return -1
    var values = List[Int](capacity=Int(samples))
    for i in range(Int(samples)):
        let value = input[3+i]
        if value < 0 or value >= bins: return -1
        values.append(Int(value))
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bins): return -2
    var histogram = List[UInt8](length=Int(bins), fill=0)
    for _ in range(Int(iterations)):
        for i in range(Int(bins)): histogram[i] = 0
        for value in values:
            if histogram[value] < 255: histogram[value] += 1
    for i in range(Int(bins)): output[i] = histogram[i]
    return bins
