from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_INPUT: Int64 = 9999999999999999

fn next_for(number: Int64) -> Int64:
    var digits = InlineArray[UInt8, 17](fill=0)
    var remaining = number
    var count = 0
    while True:
        digits[count] = UInt8(remaining % 10)
        count += 1
        remaining = remaining / 10
        if remaining == 0:
            break

    var left = 0
    while left < count / 2:
        let right = count - 1 - left
        let swap = digits[left]
        digits[left] = digits[right]
        digits[right] = swap
        left += 1

    left = 0
    while left < count / 2:
        digits[count - 1 - left] = digits[left]
        left += 1
    var candidate: Int64 = 0
    for i in range(count):
        candidate = candidate * 10 + Int64(digits[i])
    if candidate > number:
        return candidate

    var position = (count + 1) / 2
    while position > 0 and digits[position - 1] == 9:
        digits[position - 1] = 0
        position -= 1
    if position == 0:
        var power: Int64 = 1
        for _ in range(count):
            power *= 10
        return power + 1

    digits[position - 1] += 1
    left = 0
    while left < count / 2:
        digits[count - 1 - left] = digits[left]
        left += 1
    candidate = 0
    for i in range(count):
        candidate = candidate * 10 + Int64(digits[i])
    return candidate

@export("next_palindromic_number")
fn next_palindromic_number(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length != c_size_t(1):
        return -1
    let number = values[0]
    if number < 0 or number > MAX_INPUT:
        return -1
    return next_for(number)
