from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("walker_vose_alias_sampling")
fn walker_vose_alias_sampling(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 83: return -1
    if input[0] < 1 or input[0] > 16 or input[1] < 0 or input[1] > 32: return -1
    let n = Int(input[0])
    let q = Int(input[1])
    if length != c_size_t(2+n+2*q): return -1
    var total = 0
    for i in range(n):
        if input[2+i] < 0 or input[2+i] > 100: return -1
        total += Int(input[2+i])
    if total == 0: return -1
    for i in range(q):
        if input[2+n+2*i] < 0 or input[2+n+2*i] >= Int64(n): return -1
        if input[3+n+2*i] < 0 or input[3+n+2*i] >= Int64(total): return -1
    if q == 0: return 0
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8*q): return -2
    var mass = InlineArray[Int, 16](fill=0)
    var threshold = InlineArray[Int, 16](fill=0)
    var aliases = InlineArray[Int, 16](fill=0)
    var small = InlineArray[Int, 16](fill=0)
    var large = InlineArray[Int, 16](fill=0)
    var ns = 0
    var nl = 0
    for i in range(n):
        mass[i] = n*Int(input[2+i])
        threshold[i] = total
        aliases[i] = i
        if mass[i] < total:
            small[ns] = i
            ns += 1
        else:
            large[nl] = i
            nl += 1
    while ns > 0 and nl > 0:
        ns -= 1
        nl -= 1
        let low = small[ns]
        let high = large[nl]
        threshold[low] = mass[low]
        aliases[low] = high
        mass[high] -= total-mass[low]
        if mass[high] < total:
            small[ns] = high
            ns += 1
        else:
            large[nl] = high
            nl += 1
    var staged = InlineArray[UInt8, 256](fill=0)
    for i in range(q):
        let col = Int(input[2+n+2*i])
        var chosen = aliases[col]
        if input[3+n+2*i] < Int64(threshold[col]): chosen = col
        let bits = UInt64(chosen)
        for b in range(8): staged[8*i+b] = UInt8((bits >> UInt(8*b)) & 255)
    for i in range(8*q): output[i] = staged[i]
    return Int64(8*q)
