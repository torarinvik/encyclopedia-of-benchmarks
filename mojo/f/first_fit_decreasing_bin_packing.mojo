# Independent bounded first-fit-decreasing profile; see package attribution.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("first_fit_decreasing_bin_packing")
fn first_fit_decreasing_bin_packing(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                     output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 65: return -1
    let nv = input[0]
    if nv < 0 or nv > 64 or length != c_size_t(1+nv): return -1
    let n = Int(nv)
    var order = List[Int](capacity=n)
    var owners = List[Int64](capacity=n)
    for i in range(n):
        if input[1+i] < 1 or input[1+i] > 1000000: return -1
        order.append(i)
        owners.append(0)
    for i in range(1,n):
        let item = order[i]
        var j = i
        while j > 0 and input[1+order[j-1]] < input[1+item]:
            order[j] = order[j-1]
            j -= 1
        order[j] = item
    var loads = List[Int64](capacity=n)
    for i in range(n):
        let item = order[i]
        let size = input[1+item]
        var b = 0
        while b < len(loads) and loads[b]+size > 1000000: b += 1
        if b == len(loads): loads.append(0)
        loads[b] += size
        owners[item] = Int64(b)
    let required = 8*(n+1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2
    let bins = Int64(len(loads))
    for byte in range(8): output[byte] = UInt8((bins >> (8*byte)) & 255)
    for i in range(n):
        for byte in range(8): output[8*(i+1)+byte] = UInt8((owners[i] >> (8*byte)) & 255)
    return Int64(required)
