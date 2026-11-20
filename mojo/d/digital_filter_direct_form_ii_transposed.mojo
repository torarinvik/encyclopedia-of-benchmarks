from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_SAMPLES = 32
alias MAX_ORDER = 4
alias MAX_INPUT_WORDS = 45

@export("digital_filter_direct_form_ii_transposed")
fn digital_filter_direct_form_ii_transposed(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(MAX_INPUT_WORDS): return -1
    let count_word = input[0]
    let order_word = input[1]
    if count_word < 0 or count_word > MAX_SAMPLES or order_word < 0 or order_word > MAX_ORDER: return -1
    let count = Int(count_word)
    let order = Int(order_word)
    if length != c_size_t(count + 2 * order + 4): return -1
    let a_start = 2
    let b_start = order + 3
    let x_start = 2 * order + 4
    if input[a_start] != 1: return -1
    for index in range(1, order + 1):
        if input[a_start + index] < -1 or input[a_start + index] > 1: return -1
    for index in range(order + 1):
        if input[b_start + index] < -1 or input[b_start + index] > 1: return -1
    for index in range(count):
        if input[x_start + index] < -16 or input[x_start + index] > 16: return -1
    let bytes = count * 8
    if bytes > 0 and (output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes)): return -2
    if count == 0: return 0

    var state = InlineArray[Int64, 4](fill=0)
    for sample_index in range(count):
        let sample = input[x_start + sample_index]
        let value = input[b_start] * sample + (state[0] if order > 0 else 0)
        for stage in range(order):
            let next_state = state[stage + 1] if stage + 1 < order else 0
            state[stage] = next_state + input[b_start + stage + 1] * sample - input[a_start + stage + 1] * value
        let bits = bitcast[UInt64](value)
        for byte in range(8):
            output[sample_index * 8 + byte] = UInt8((bits >> (byte * 8)) & 255)
    Int64(bytes)
