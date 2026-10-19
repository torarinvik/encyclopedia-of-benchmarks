from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn conway_digits(value_arg: Int64) -> Int64:
    var value = value_arg
    var digits: Int64 = 1
    while value >= 10:
        value /= 10
        digits += 1
    return digits

@export("conway")
fn conway(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 129: return -1
    let n = input[0]
    if n < 1 or n > 128 or length != n + 1: return -1
    for i in range(n):
        if input[i + 1] < 0 or input[i + 1] > 127: return -1
    var needed: Int64 = 0
    var i: Int64 = 0
    while i < n:
        var j = i + 1
        while j < n and (input[j] == input[j + 1] or input[j] == 10 or input[j] == 13): j += 1
        needed += conway_digits(j - i) + 1
        i = j
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < needed: return -2
    var pos: Int64 = 0
    i = 0
    while i < n:
        var j = i + 1
        while j < n and (input[j] == input[j + 1] or input[j] == 10 or input[j] == 13): j += 1
        var run = j - i
        var digits = InlineArray[UInt8, 3](0)
        var count: Int64 = 0
        while True:
            digits[count] = UInt8(48 + run % 10)
            count += 1
            run /= 10
            if run == 0: break
        while count > 0:
            count -= 1
            output[pos] = digits[count]
            pos += 1
        output[pos] = UInt8(input[i + 1])
        pos += 1
        i = j
    return pos
