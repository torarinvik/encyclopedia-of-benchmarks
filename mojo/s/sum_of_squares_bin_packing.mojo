# Online Sum-of-Squares bin packing with deterministic bin ties.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("sum_of_squares_bin_packing")
fn sum_of_squares_bin_packing(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                              output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 66: return -1
    let cv = input[0]; let nv = input[1]
    if cv < 1 or cv > 64 or nv < 0 or nv > 64 or length != c_size_t(2+nv): return -1
    let n = Int(nv)
    var sizes = List[Int](capacity=n)
    var loads = List[Int](capacity=n)
    var assignments = List[Int64](capacity=n)
    var histogram = List[Int64](capacity=65)
    for _ in range(65): histogram.append(0)
    for i in range(n):
        let size = input[2+i]
        if size < 1 or size > cv: return -1
        sizes.append(Int(size)); loads.append(0); assignments.append(0)
    let bin_capacity = Int(cv)
    var bins = 0
    var score = Int64(0)
    for item in range(n):
        let size = sizes[item]
        var selected = bins
        var best = Int64(1000000000)
        for bin in range(bins):
            let from_load = loads[bin]
            let to_load = from_load+size
            if to_load > bin_capacity: continue
            var candidate = score
            if from_load < bin_capacity: candidate += 1-2*histogram[from_load]
            if to_load < bin_capacity: candidate += 1+2*histogram[to_load]
            if candidate < best:
                best = candidate
                selected = bin
        var new_score = score
        if size < bin_capacity: new_score += 1+2*histogram[size]
        if new_score < best:
            best = new_score
            selected = bins
        if selected == bins:
            loads[bins] = size
            assignments[item] = Int64(bins)
            if size < bin_capacity: histogram[size] += 1
            bins += 1
        else:
            let from_load = loads[selected]
            let to_load = from_load+size
            if from_load < bin_capacity: histogram[from_load] -= 1
            if to_load < bin_capacity: histogram[to_load] += 1
            loads[selected] = to_load
            assignments[item] = Int64(selected)
        score = best
    let bytes = 8*(n+1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for byte in range(8): output[byte] = UInt8((Int64(bins) >> (8*byte)) & 255)
    for i in range(n):
        for byte in range(8): output[8*(i+1)+byte] = UInt8((assignments[i] >> (8*byte)) & 255)
    return Int64(bytes)
