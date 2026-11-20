from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

const MAX_BITS = 64
const MAX_PARSEABLE = 131
const MAX_OUTPUT = 66

fn za_canonical(input: UnsafePointer[Int64, ImmutAnyOrigin], start: Int, length: Int) -> Bool:
    if length == 1 and input[start] == 0: return True
    if length == 0 or input[start] != 1: return False
    for i in range(length):
        if input[start + i] != 0 and input[start + i] != 1: return False
        if i + 1 < length and input[start + i] == 1 and input[start + i + 1] == 1: return False
    True

fn za_stage_one(inout d: InlineArray[UInt8, 66], n: Int) -> None:
    if n >= 4:
        for i in range(n - 3):
            if d[i] == 0 and d[i + 1] == 2 and d[i + 2] == 0:
                d[i] = 1; d[i + 1] = 0; d[i + 2] = 0; d[i + 3] = d[i + 3] + 1
            elif d[i] == 0 and d[i + 1] == 3 and d[i + 2] == 0:
                d[i] = 1; d[i + 1] = 1; d[i + 2] = 0; d[i + 3] = d[i + 3] + 1
            elif d[i] == 0 and d[i + 1] == 2 and d[i + 2] == 1:
                d[i] = 1; d[i + 1] = 1; d[i + 2] = 0
            elif d[i] == 0 and d[i + 1] == 1 and d[i + 2] == 2:
                d[i] = 1; d[i + 1] = 0; d[i + 2] = 1
    if n >= 3 and d[n - 3] == 0 and d[n - 2] == 3 and d[n - 1] == 0:
        d[n - 3] = 1; d[n - 2] = 1; d[n - 1] = 1
    elif n >= 3 and d[n - 3] == 0 and d[n - 2] == 2 and d[n - 1] == 0:
        d[n - 3] = 1; d[n - 2] = 0; d[n - 1] = 1
    elif n >= 4 and d[n - 4] == 0 and d[n - 3] == 1 and d[n - 2] == 2 and d[n - 1] == 0:
        d[n - 4] = 1; d[n - 3] = 0; d[n - 2] = 1; d[n - 1] = 0
    elif n >= 3 and d[n - 3] == 0 and d[n - 2] == 2 and d[n - 1] == 1:
        d[n - 3] = 1; d[n - 2] = 1; d[n - 1] = 0
    if n >= 2 and d[n - 2] == 0 and d[n - 1] == 3:
        d[n - 2] = 1; d[n - 1] = 1
    elif n >= 2 and d[n - 2] == 0 and d[n - 1] == 2:
        d[n - 2] = 1; d[n - 1] = 0
    elif n >= 3 and d[n - 3] == 0 and d[n - 2] == 1 and d[n - 1] == 2:
        d[n - 3] = 1; d[n - 2] = 0; d[n - 1] = 1

fn za_normalize(input: UnsafePointer[Int64, ImmutAnyOrigin], length: Int,
    inout staged: InlineArray[UInt8, 66]) -> Int64:
    if length < 4 or length > MAX_PARSEABLE: return -1
    let first_n_value = input[0]
    if first_n_value < 1 or first_n_value > MAX_BITS: return -1
    let first_n = Int(first_n_value)
    let second_n_index = first_n + 1
    if second_n_index >= length: return -1
    let second_n_value = input[second_n_index]
    if second_n_value < 1 or second_n_value > MAX_BITS: return -1
    let second_n = Int(second_n_value)
    if length != second_n_index + second_n + 1: return -1
    if not za_canonical(input, 1, first_n) or
        not za_canonical(input, second_n_index + 1, second_n): return -1

    let width = first_n if first_n > second_n else second_n
    let first_offset = width - first_n
    let second_offset = width - second_n
    var digit_count = width + 1
    staged[0] = 0
    for i in range(width):
        let a = 0 if i < first_offset else input[1 + i - first_offset]
        let b = 0 if i < second_offset else input[second_n_index + 1 + i - second_offset]
        staged[i + 1] = UInt8(a + b)
    za_stage_one(inout staged, digit_count)
    for i in range(digit_count, 0, -1): staged[i] = staged[i - 1]
    staged[0] = 0
    digit_count += 1
    for i in range(digit_count - 2, 0, -1):
        let start = i - 1
        if staged[start] == 0 and staged[start + 1] == 1 and staged[start + 2] == 1:
            staged[start] = 1; staged[start + 1] = 0; staged[start + 2] = 0
    for i in range(digit_count - 2):
        if staged[i] == 0 and staged[i + 1] == 1 and staged[i + 2] == 1:
            staged[i] = 1; staged[i + 1] = 0; staged[i + 2] = 0
    var first_output = 0
    while first_output + 1 < digit_count and staged[first_output] == 0:
        first_output += 1
    let required = digit_count - first_output
    for i in range(required): staged[i] = UInt8(48 + staged[first_output + i])
    Int64(required)

fn zeckendorf_addition_impl(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) -> Int64:
    if input.is_null() or length < 4 or length > MAX_PARSEABLE: return -1
    var staged = InlineArray[UInt8, 66](fill=0)
    let required = za_normalize(input, Int(length), inout staged)
    if required < 0: return required
    if output.is_null() or output_capacity < c_size_t(required): return -2
    for i in range(Int(required)): output[i] = staged[i]
    required

@export("zeckendorf_addition")
fn zeckendorf_addition(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    zeckendorf_addition_impl(input, length, output, output_capacity)
