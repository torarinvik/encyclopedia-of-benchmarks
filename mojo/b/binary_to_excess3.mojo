from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

comptime MAX_MAGNITUDE: Int64 = 4_611_686_018_427_387_904
fn ascii_space(v: Int64) -> Bool: return v == 32 or (v >= 9 and v <= 13)
fn is_digit(v: Int64) -> Bool: return v == 48 or v == 49

@export("binary_to_excess3")
fn binary_to_excess3(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 128: return -1
    var start = 0; var end = Int(length)
    while start < end and ascii_space(input[start]): start += 1
    while end > start and ascii_space(input[end - 1]): end -= 1
    if start == end: return -1
    var negative = False
    if input[start] == 43 or input[start] == 45:
        negative = input[start] == 45; start += 1
        if start == end: return -1
    let prefixed = end - start >= 2 and input[start] == 48 and (input[start + 1] == 98 or input[start + 1] == 66)
    if prefixed: start += 2
    if start == end: return -1
    let digit_start = start
    var allow_prefix_underscore = prefixed; var have_digit = False; var last_was_digit = False
    var magnitude: Int64 = 0
    for index in range(start, end):
        let v = input[index]
        if is_digit(v):
            let digit = v - 48
            if magnitude > (MAX_MAGNITUDE - digit) // 2: return -1
            magnitude = magnitude * 2 + digit; have_digit = True; last_was_digit = True; allow_prefix_underscore = False
        elif v == 95:
            if last_was_digit and index + 1 < end and is_digit(input[index + 1]): last_was_digit = False
            elif allow_prefix_underscore and not have_digit and index == digit_start and index + 1 < end and is_digit(input[index + 1]): allow_prefix_underscore = False
            else: return -1
        else: return -1
    if not have_digit or not last_was_digit: return -1
    var result = (if negative: -magnitude else: magnitude) + 3
    let result_negative = result < 0
    if result_negative: result = -result
    var reversed = List[UInt8](capacity=64)
    while True:
        reversed.append(UInt8(48 + (result % 2))); result //= 2
        if result == 0: break
    let sign_len = 1 if result_negative else 0
    let needed = max(4, sign_len + len(reversed))
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(needed): return -2
    var bytes = List[UInt8](capacity=needed)
    if result_negative: bytes.append(45)
    let digit_width = needed - sign_len
    for _ in range(len(reversed), digit_width): bytes.append(48)
    for i in range(len(reversed) - 1, -1, -1): bytes.append(reversed[i])
    for i in range(needed): output[i] = bytes[i]
    return Int64(needed)
