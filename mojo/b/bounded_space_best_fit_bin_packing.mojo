from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn put_word(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    var bits = bitcast[UInt64](value)
    for j in range(8):
        output[offset+j] = UInt8(bits & UInt64(255))
        bits = bits >> 8

@export("bounded_space_best_fit_bin_packing")
fn bounded_space_best_fit_bin_packing(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
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
    var loads = List[Int64](capacity=64)
    var opened = List[Bool](capacity=64)
    var assignments = List[Int64](capacity=64)
    for _ in range(64):
        loads.append(0)
        opened.append(False)
        assignments.append(0)
    var bins = 0
    for i in range(n):
        let size = input[1+i]
        var selected = bins
        var smallest = Int64(1000001)
        for bin in range(bins):
            if opened[bin] and loads[bin]+size <= 1000000:
                let leftover = 1000000-loads[bin]-size
                if leftover < smallest:
                    smallest = leftover
                    selected = bin
        if selected == bins:
            loads[bins] = size
            opened[bins] = size < 1000000
            bins += 1
        else:
            loads[selected] += size
            if loads[selected] == 1000000: opened[selected] = False
        assignments[i] = Int64(selected)
        var count = 0
        for bin in range(bins):
            if opened[bin]: count += 1
        while count > 2:
            var weakest = bins
            for bin in range(bins):
                if opened[bin]:
                    if weakest == bins:
                        weakest = bin
                    elif loads[bin] < loads[weakest] or (loads[bin] == loads[weakest] and bin > weakest):
                        weakest = bin
            opened[weakest] = False
            count -= 1
    put_word(output, 0, Int64(bins))
    for i in range(n): put_word(output, 8*(i+1), assignments[i])
    return Int64(bytes)
