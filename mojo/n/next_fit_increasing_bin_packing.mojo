# Stable increasing-order Next Fit bin packing.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("next_fit_increasing_bin_packing")
fn next_fit_increasing_bin_packing(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                   output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 65: return -1
    let nv = input[0]
    if nv < 0 or nv > 64 or length != c_size_t(1+nv): return -1
    let n = Int(nv)
    var sizes = List[Int64](capacity=n)
    var order = List[Int](capacity=n)
    var assignments = List[Int64](capacity=n)
    for i in range(n):
        let size = input[1+i]
        if size < 1 or size > 1000000: return -1
        sizes.append(size)
        order.append(i)
        assignments.append(0)
    for i in range(1,n):
        let item = order[i]
        var j = i
        while j > 0 and sizes[order[j-1]] > sizes[item]:
            order[j] = order[j-1]
            j -= 1
        order[j] = item
    var bins = Int64(0)
    var remaining = Int64(0)
    for rank in range(n):
        let item = order[rank]
        let size = sizes[item]
        if bins == 0 or size > remaining:
            assignments[item] = bins
            bins += 1
            remaining = 1000000-size
        else:
            assignments[item] = bins-1
            remaining -= size
    let bytes = 8*(n+1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for byte in range(8): output[byte] = UInt8((bins >> (8*byte)) & 255)
    for i in range(n):
        for byte in range(8): output[8*(i+1)+byte] = UInt8((assignments[i] >> (8*byte)) & 255)
    return Int64(bytes)
