from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import log
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("hyperloglog_corrected_estimate")
fn hyperloglog_corrected_estimate(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 130: return -1
    if input[0] < 0 or input[0] > 128: return -1
    let n = Int(input[0])
    if length != c_size_t(n+1): return -1
    var registers = InlineArray[Int, 16](fill=0)
    for i in range(n):
        let value = input[i+1]
        if value < 0 or value > 4294967295: return -1
        let hash = UInt64(value)
        let bucket = Int(hash >> 28)
        let suffix = hash & UInt64(268435455)
        var mask = UInt64(1) << 27
        var rank = 1
        while mask != 0 and (suffix & mask) == 0:
            rank += 1
            mask >>= 1
        if rank > registers[bucket]: registers[bucket] = rank
    var total = UInt64(0)
    var zeros = 0
    for i in range(16):
        total += UInt64(1) << UInt(29-registers[i])
        if registers[i] == 0: zeros += 1
    var estimate = (Float64(673.0)*256.0*536870912.0)/(1000.0*Float64(total))
    let universe = Float64(4294967296.0)
    if estimate <= 40.0 and zeros != 0:
        estimate = 16.0*log(Float64(16.0)/Float64(zeros))
    elif estimate > universe/30.0:
        if estimate >= universe: return -3
        estimate = -universe*log(Float64(1.0)-estimate/universe)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8: return -2
    let bits = bitcast[UInt64](estimate)
    var staged = InlineArray[UInt8, 8](fill=0)
    for b in range(8): staged[b] = UInt8((bits >> UInt(8*b)) & 255)
    for b in range(8): output[b] = staged[b]
    return 8
