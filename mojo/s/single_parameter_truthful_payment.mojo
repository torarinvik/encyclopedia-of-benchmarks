from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("single_parameter_truthful_payment")
fn single_parameter_truthful_payment(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 18: return -1
    let bid = input[0]; let kv = input[1]
    if bid < 0 or bid > 16 or kv < 1 or kv > 8 or length != c_size_t(2+2*Int(kv)): return -1
    let k = Int(kv)
    var breaks = List[Int64](capacity=k)
    var loads = List[Int64](capacity=k)
    for i in range(k):
        let point = input[2+2*i]; let load = input[3+2*i]
        if point < 0 or point >= 16 or load < 0 or load > 16: return -1
        if i == 0 and point != 0: return -1
        if i > 0 and (point <= breaks[i-1] or load > loads[i-1]): return -1
        breaks.append(point); loads.append(load)
    var allocation = Int64(0)
    if bid < 16:
        for i in range(k):
            if breaks[i] <= bid: allocation = loads[i]
    var area = Int64(0)
    for i in range(k):
        var end = Int64(16)
        if i+1 < k: end = breaks[i+1]
        var left = breaks[i]
        if bid > left: left = bid
        if end > left: area += (end-left)*loads[i]
    let payment = bid*allocation+area
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 16: return -2
    for j in range(8):
        output[j] = UInt8((allocation >> (8*j)) & 255)
        output[8+j] = UInt8((payment >> (8*j)) & 255)
    return 16
