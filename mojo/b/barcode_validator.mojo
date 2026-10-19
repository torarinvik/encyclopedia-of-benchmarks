from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn get_check_digit(input: Int64) -> Int64:
    var barcode = input / 10
    var checker = False
    var total: Int64 = 0
    while barcode != 0:
        let multiplier: Int64 = 1 if checker else 3
        total += multiplier * (barcode % 10)
        barcode /= 10
        checker = not checker
    return (10 - total % 10) % 10

fn decimal_length(value_input: Int64) -> Int:
    var value = value_input
    var digits = 1
    while value >= 10:
        value /= 10
        digits += 1
    return digits

@export("barcode_validator")
fn barcode_validator(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2:
        return -1
    let operation = input[0]
    let barcode = input[1]
    if (operation != 0 and operation != 1) or barcode < 0:
        return -1
    if operation == 0:
        return get_check_digit(barcode)
    return 1 if decimal_length(barcode) == 13 and get_check_digit(barcode) == barcode % 10 else 0
