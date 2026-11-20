from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_UPDATES = 30
alias MAX_VALID_INPUT_VALUES = 1 + MAX_UPDATES
alias MAX_PARSEABLE_INPUT_VALUES = MAX_VALID_INPUT_VALUES + 1
alias DRAW_SPACE = UInt64(205891132094649)

fn morris_approximate_counter_base_three_store_i64(
    output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64
) -> None:
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("morris_approximate_counter_base_three")
fn morris_approximate_counter_base_three(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > c_size_t(MAX_PARSEABLE_INPUT_VALUES):
        return -1
    let updates_value = input[0]
    if updates_value < 0 or updates_value > MAX_UPDATES:
        return -1
    let updates = Int(updates_value)
    if length != c_size_t(1 + updates):
        return -1

    var state = 0
    var threshold = DRAW_SPACE
    var estimate: UInt64 = 0
    for event in range(updates):
        let draw_value = input[1 + event]
        if draw_value < 0 or UInt64(draw_value) >= DRAW_SPACE:
            return -1
        if UInt64(draw_value) < threshold:
            state += 1
            threshold //= 3
            estimate = 3 * estimate + 1

    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(16):
        return -2
    morris_approximate_counter_base_three_store_i64(output, 0, Int64(state))
    morris_approximate_counter_base_three_store_i64(output, 8, Int64(estimate))
    return 16
