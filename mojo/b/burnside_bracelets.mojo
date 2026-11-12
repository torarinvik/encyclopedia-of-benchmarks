from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

alias MAX_N = 10
alias MAX_INPUT_VALUES = 3
alias OUTPUT_BYTES = 8

fn burnside_cycle_count(n: Int, shift: Int, reflection: Bool) -> Int:
    var seen = InlineArray[Bool, MAX_N](fill=False)
    var cycles = 0
    for start in range(n):
        if seen[start]:
            continue
        cycles += 1
        var position = start
        while not seen[position]:
            seen[position] = True
            if reflection:
                position = (shift + n - position) % n
            else:
                position = (position + shift) % n
    return cycles

fn burnside_fixed_colorings(n: Int, shift: Int, reflection: Bool,
    colors: Int64) -> Int64:
    let cycles = burnside_cycle_count(n, shift, reflection)
    var result: Int64 = 1
    for _ in range(cycles):
        result *= colors
    return result

fn burnside_store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(OUTPUT_BYTES):
        output[byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("burnside_bracelets")
fn burnside_bracelets(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(1) or length > c_size_t(MAX_INPUT_VALUES):
        return -1
    if length != c_size_t(2):
        return -1
    let n_value = input[0]
    let colors = input[1]
    if n_value < 1 or n_value > MAX_N or colors < 0 or colors > 3:
        return -1
    let n = Int(n_value)

    var fixed_sum: Int64 = 0
    for shift in range(n):
        fixed_sum += burnside_fixed_colorings(n, shift, False, colors)
        fixed_sum += burnside_fixed_colorings(n, shift, True, colors)
    let answer = fixed_sum // Int64(2 * n)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(OUTPUT_BYTES):
        return -2
    burnside_store_i64_le(output, answer)
    return Int64(OUTPUT_BYTES)
