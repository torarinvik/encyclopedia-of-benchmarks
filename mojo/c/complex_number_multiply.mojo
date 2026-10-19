from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn parse_complex_component(input: UnsafePointer[Int64, ImmutAnyOrigin], start: Int64, end: Int64) -> Int64:
    var pos = start
    var negative = False
    if pos < end and input[pos] == 45:
        negative = True
        pos += 1
    if pos >= end: return -32768
    var magnitude: Int64 = 0
    while pos < end:
        if input[pos] < 48 or input[pos] > 57: return -32768
        let digit = input[pos] - 48
        if magnitude > (32767 - digit) / 10: return -32768
        magnitude = magnitude * 10 + digit
        pos += 1
    return -magnitude if negative else magnitude

fn parse_complex_number(input: UnsafePointer[Int64, ImmutAnyOrigin], start: Int64, n: Int64) -> Int64:
    if n < 4 or n > 64 or input[start + n - 1] != 105: return -1
    var separator = n
    for i in range(n - 1):
        if input[start + i] == 43:
            if separator != n: return -1
            separator = i
    if separator == n: return -1
    let real = parse_complex_component(input, start, start + separator)
    let imag = parse_complex_component(input, start + separator + 1, start + n - 1)
    if real == -32768 or imag == -32768: return -1
    return ((real + 32768) << 16) | (imag + 32768)

fn complex_decimal_length(value: Int64) -> Int64:
    var n = value
    var digits: Int64 = 1
    if n < 0:
        digits = 2
        n = -n
    while n >= 10:
        n /= 10
        digits += 1
    return digits

fn complex_append_decimal(staged: UnsafePointer[UInt8, MutAnyOrigin], start: Int64, value: Int64) -> Int64:
    var pos = start
    var magnitude = value
    if magnitude < 0:
        staged[pos] = 45
        pos += 1
        magnitude = -magnitude
    let digits_start = pos
    if magnitude == 0:
        staged[pos] = 48
        return pos + 1
    while magnitude != 0:
        staged[pos] = UInt8(48 + magnitude % 10)
        pos += 1
        magnitude /= 10
    var left = digits_start
    var right = pos - 1
    while left < right:
        let temp = staged[left]
        staged[left] = staged[right]
        staged[right] = temp
        left += 1
        right -= 1
    return pos

@export("complex_number_multiply")
fn complex_number_multiply(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 130: return -1
    let left_n = input[0]
    let right_n = input[1]
    if left_n < 4 or left_n > 64 or right_n < 4 or right_n > 64 or length != 2 + left_n + right_n: return -1
    for i in range(2, length):
        if input[i] < 0 or input[i] > 127: return -1
    let left_packed = parse_complex_number(input, 2, left_n)
    let right_packed = parse_complex_number(input, 2 + left_n, right_n)
    if left_packed < 0 or right_packed < 0: return -1
    let left_real = (left_packed >> 16) - 32768
    let left_imag = (left_packed & 65535) - 32768
    let right_real = (right_packed >> 16) - 32768
    let right_imag = (right_packed & 65535) - 32768
    let real = left_real * right_real - left_imag * right_imag
    let imag = left_real * right_imag + left_imag * right_real
    let needed = complex_decimal_length(real) + complex_decimal_length(imag) + 2
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < needed: return -2
    var pos = complex_append_decimal(output, 0, real)
    output[pos] = 43
    pos += 1
    pos = complex_append_decimal(output, pos, imag)
    output[pos] = 105
    pos += 1
    return pos
