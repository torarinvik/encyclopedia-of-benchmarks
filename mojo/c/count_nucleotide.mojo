from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn nucleotide_digits(value: Int64) -> Int64:
    var n = value
    var count: Int64 = 1
    while n >= 10:
        n /= 10
        count += 1
    return count

@export("count_nucleotide")
fn count_nucleotide(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 1001: return -1
    let n = values[0]
    if n < 0 or n > 1000 or length != n + 1: return -1
    var counts = InlineArray[Int64, 4](0)
    for i in range(n):
        let code = values[1 + i]
        if code < 0 or code > 127: return -1
        if code == 65: counts[0] += 1
        elif code == 67: counts[1] += 1
        elif code == 71: counts[2] += 1
        elif code == 84: counts[3] += 1
    let needed = nucleotide_digits(counts[0]) + nucleotide_digits(counts[1]) + nucleotide_digits(counts[2]) + nucleotide_digits(counts[3]) + 3
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < needed: return -2
    var pos: Int64 = 0
    for i in range(4):
        var value = counts[i]
        var divisor: Int64 = 1
        while value / divisor >= 10: divisor *= 10
        while divisor > 0:
            output[pos] = UInt8(48 + value / divisor)
            pos += 1
            value %= divisor
            divisor /= 10
        if i < 3:
            output[pos] = 32
            pos += 1
    return pos
