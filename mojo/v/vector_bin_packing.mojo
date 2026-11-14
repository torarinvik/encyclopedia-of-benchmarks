from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("vector_bin_packing")
fn vector_bin_packing(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 130: return -1
    let nv = input[0]; let dv = input[1]
    if nv < 1 or nv > 32 or dv < 1 or dv > 4: return -1
    let n = Int(nv); let d = Int(dv)
    if length != c_size_t(2+n*d): return -1
    var items = List[Int64](capacity=n*d)
    for i in range(n*d):
        let value = input[2+i]
        if value < 0 or value > 1000: return -1
        items.append(value)
    var loads = List[Int64](capacity=n*d)
    var assignment = List[Int](capacity=n)
    for _ in range(n*d): loads.append(0)
    var bins = 0
    for item in range(n):
        var selected = bins
        for b in range(bins):
            var fits = True
            for q in range(d):
                if loads[b*d+q]+items[item*d+q] > 1000:
                    fits = False
                    break
            if fits:
                selected = b
                break
        if selected == bins: bins += 1
        assignment.append(selected)
        for q in range(d): loads[selected*d+q] += items[item*d+q]
    let words = 1+n+bins*d
    let bytes = 8*words
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(words):
        var value = Int64(bins)
        if i > 0 and i <= n: value = Int64(assignment[i-1])
        elif i > n: value = loads[i-1-n]
        for j in range(8): output[8*i+j] = UInt8((value >> (8*j)) & 255)
    return Int64(bytes)
