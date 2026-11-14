from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("next_fit_decreasing_bin_packing")
fn next_fit_decreasing_bin_packing(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 65: return -1
    let nv = input[0]
    if nv < 0 or nv > 64 or length != c_size_t(1+Int(nv)): return -1
    let n = Int(nv)
    var sizes = List[Int64](capacity=n)
    var order = List[Int](capacity=n)
    var assignment = List[Int](length=n, fill=0)
    for i in range(n):
        let size = input[i+1]
        if size < 1 or size > 1000000: return -1
        sizes.append(size); order.append(i)
    for i in range(1,n):
        let item = order[i]
        var j = i
        while j > 0 and sizes[order[j-1]] < sizes[item]:
            order[j] = order[j-1]
            j -= 1
        order[j] = item
    var bins = 0
    var load = Int64(0)
    for item in order:
        if bins == 0 or load+sizes[item] > 1000000:
            bins += 1
            load = 0
        load += sizes[item]
        assignment[item] = bins-1
    let bytes = 8*(n+1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(n+1):
        var value = Int64(bins)
        if i > 0: value = Int64(assignment[i-1])
        for j in range(8): output[8*i+j] = UInt8((value >> (8*j)) & 255)
    return Int64(bytes)
