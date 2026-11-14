# Independent bounded Fibonacci universal code; see package attribution.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("fibonacci_integer_code")
fn fibonacci_integer_code(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                           output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 33: return -1
    let nv = input[0]
    if nv < 1 or nv > 32 or length != c_size_t(1+nv): return -1
    let n = Int(nv)
    for i in range(n):
        if input[1+i] < 0 or input[1+i] > 1000000: return -1
    var weights = List[Int64](capacity=30)
    weights.append(1)
    weights.append(2)
    while len(weights) < 30:
        let next = weights[len(weights)-1] + weights[len(weights)-2]
        if next > 1000001: break
        weights.append(next)
    var staged = List[UInt8](capacity=960)
    for i in range(n):
        var remaining = input[1+i]+1
        var top = 0
        while top+1 < len(weights) and weights[top+1] <= remaining: top += 1
        var bits = List[UInt8](capacity=top+1)
        for _ in range(top+1): bits.append(UInt8(48))
        var j = top
        while j >= 0:
            if weights[j] <= remaining:
                bits[j] = UInt8(49)
                remaining -= weights[j]
            j -= 1
        for k in range(top+1): staged.append(bits[k])
        staged.append(UInt8(49))
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(len(staged)): return -2
    for i in range(len(staged)): output[i] = staged[i]
    return Int64(len(staged))
