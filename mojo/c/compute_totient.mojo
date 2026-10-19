from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

fn totient_digits(value: Int64) -> Int64:
    var n = value
    var count: Int64 = 1
    while n >= 10:
        n /= 10
        count += 1
    return count

@export("compute_totient")
fn compute_totient(n: Int64, output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if n < 1 or n > 80: return -1
    var phi = InlineArray[Int64, 80](0)
    for i in range(1, n + 1): phi[i - 1] = i
    for p in range(2, n + 1):
        if phi[p - 1] != p: continue
        phi[p - 1] = p - 1
        var i = 2 * p
        while i <= n:
            phi[i - 1] = (phi[i - 1] / p) * (p - 1)
            i += p
    var required = n - 1
    for i in range(n): required += totient_digits(phi[i])
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < required: return -2
    var staged = InlineArray[UInt8, 240](0)
    var pos: Int64 = 0
    for i in range(n):
        if i != 0:
            staged[pos] = 44
            pos += 1
        var value = phi[i]
        var digits = InlineArray[UInt8, 3](0)
        var digit_count: Int64 = 0
        while True:
            digits[digit_count] = UInt8(value % 10)
            digit_count += 1
            value /= 10
            if value == 0: break
        while digit_count > 0:
            digit_count -= 1
            staged[pos] = UInt8(48 + digits[digit_count])
            pos += 1
    for i in range(pos): output[i] = staged[i]
    return pos
