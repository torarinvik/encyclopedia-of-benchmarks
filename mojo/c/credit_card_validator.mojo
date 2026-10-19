from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("credit_card_validator")
fn credit_card_validator(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 65: return -1
    let n = input[0]
    if n < 0 or n > 64 or length != n + 1: return -1
    var digits = True
    for i in range(n):
        let ch = input[i + 1]
        if ch < 0 or ch > 127: return -1
        if ch < 48 or ch > 57: digits = False
    if not digits or n < 13 or n > 16: return 0
    let first = input[1] - 48
    let second = input[2] - 48
    if not (first == 4 or first == 5 or first == 6 or (first == 3 and (second == 4 or second == 5 or second == 7))): return 0
    var sum: Int64 = 0
    for i in range(n):
        var digit = input[i + 1] - 48
        if i % 2 == n % 2:
            digit *= 2
            if digit > 9: digit -= 9
        sum += digit
    return 1 if sum % 10 == 0 else 0
