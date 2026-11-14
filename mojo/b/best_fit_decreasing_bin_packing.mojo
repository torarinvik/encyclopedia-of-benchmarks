from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn put_word(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    var bits = bitcast[UInt64](value)
    for j in range(8):
        output[offset+j] = UInt8(bits & UInt64(255))
        bits = bits >> 8

@export("best_fit_decreasing_bin_packing")
fn best_fit_decreasing_bin_packing(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                   output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 65: return -1
    let nv = input[0]
    if nv < 0 or nv > 64: return -1
    let n = Int(nv)
    if length != c_size_t(1+n): return -1
    for i in range(n):
        if input[1+i] < 1 or input[1+i] > 1000000: return -1
    let bytes = 8*(n+1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var order = List[Int](capacity=64)
    var remaining = List[Int64](capacity=64)
    var assignments = List[Int64](capacity=64)
    for i in range(64):
        order.append(i)
        remaining.append(0)
        assignments.append(0)
    for i in range(1, n):
        let key = order[i]
        var j = i
        while j > 0 and input[1+order[j-1]] < input[1+key]:
            order[j] = order[j-1]
            j -= 1
        order[j] = key
    var bins = 0
    for pos in range(n):
        let item = order[pos]
        let size = input[1+item]
        var selected = bins
        var smallest = Int64(1000001)
        for bin in range(bins):
            if remaining[bin] >= size:
                let leftover = remaining[bin]-size
                if leftover < smallest:
                    smallest = leftover
                    selected = bin
        if selected == bins:
            remaining[bins] = 1000000-size
            bins += 1
        else:
            remaining[selected] -= size
        assignments[item] = Int64(selected)
    put_word(output, 0, Int64(bins))
    for i in range(n): put_word(output, 8*(i+1), assignments[i])
    return Int64(bytes)
