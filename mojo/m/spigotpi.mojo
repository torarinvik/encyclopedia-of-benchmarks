from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("spigotpi")
fn spigotpi(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
            output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1: return -1
    if input[0] < 0 or input[0] > 256: return -1
    let digits = Int(input[0])
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(digits): return -2
    if digits == 0: return 0
    let boxes = digits * 10 // 3
    var remainder = InlineArray[Int64, 854](fill=2)
    var staged = InlineArray[UInt8, 256](fill=0)
    var held = 0
    for index in range(digits):
        var carry: Int64 = 0
        var sum: Int64 = 0
        var cursor = boxes
        while cursor > 0:
            cursor -= 1
            sum = remainder[cursor] * 10 + carry
            let denominator = Int64(2 * cursor + 1)
            remainder[cursor] = sum % denominator
            carry = (sum // denominator) * Int64(cursor)
        remainder[0] = sum % 10
        var digit = sum // 10
        if digit == 9:
            held += 1
        elif digit == 10:
            digit = 0
            for offset in range(1, held + 1):
                let position = index - offset
                if staged[position] == 57:
                    staged[position] = 48
                else:
                    staged[position] += 1
            held = 1
        else:
            held = 1
        staged[index] = UInt8(48 + digit)
    for i in range(digits): output[i] = staged[i]
    return Int64(digits)
