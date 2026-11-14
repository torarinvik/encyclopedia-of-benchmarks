from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn hll_gcd(a0: UInt64, b0: UInt64) -> UInt64:
    var a = a0
    var b = b0
    while b != 0:
        let r = a % b
        a = b
        b = r
    return a

@export("hyperloglog_raw_estimate")
fn hyperloglog_raw_estimate(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
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
    for i in range(16): total += UInt64(1) << UInt(29-registers[i])
    var numerator = UInt64(673)*256*(UInt64(1)<<29)
    var denominator = UInt64(1000)*total
    let factor = hll_gcd(numerator,denominator)
    numerator //= factor
    denominator //= factor
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 144: return -2
    var words = InlineArray[UInt64, 18](fill=0)
    words[0] = numerator
    words[1] = denominator
    for i in range(16): words[i+2] = UInt64(registers[i])
    var staged = InlineArray[UInt8, 144](fill=0)
    for i in range(18):
        for b in range(8): staged[8*i+b] = UInt8((words[i] >> UInt(8*b)) & 255)
    for i in range(144): output[i] = staged[i]
    return 144
