from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

# Unverified deterministic planted 3-SAT generator draft.
@export("planted_3sat_clause_generator")
fn planted_3sat_clause_generator(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                 output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 83: return -1
    if input[0] < 3 or input[0] > 16 or input[1] < 0 or input[1] > 32: return -1
    let n = Int(input[0])
    let m = Int(input[1])
    if length != c_size_t(2+n+2*m): return -1
    for i in range(n):
        if input[2+i] != 0 and input[2+i] != 1: return -1
    let choices = n*(n-1)*(n-2)//6
    var literals = InlineArray[Int64, 96](fill=0)
    for clause in range(m):
        let raw = input[2+n+2*clause]
        let mask = input[3+n+2*clause]
        if raw < 0 or raw >= Int64(choices) or mask < 1 or mask > 7: return -1
        var rank = Int(raw)
        var next = 0
        for position in range(3):
            var variable = next
            while variable < n-(2-position):
                let remaining = n-variable-1
                var ways = 1
                if position == 0: ways = remaining*(remaining-1)//2
                elif position == 1: ways = remaining
                if rank >= ways:
                    rank -= ways
                    variable += 1
                    continue
                let value = Int64(variable+1)
                if input[2+variable] == ((mask >> UInt64(position)) & 1): literals[3*clause+position] = value
                else: literals[3*clause+position] = -value
                next = variable+1
                break
    let byte_count = 24*m
    if byte_count == 0: return 0
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(byte_count): return -2
    for i in range(3*m):
        let bits = bitcast[UInt64](literals[i])
        for b in range(8): output[8*i+b] = UInt8((bits >> UInt64(8*b)) & 255)
    return Int64(byte_count)
