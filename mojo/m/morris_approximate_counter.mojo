from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_UPDATES = 53
alias DRAW_BITS = 53
alias MAX_INPUT_VALUES = 1 + MAX_UPDATES
alias DRAW_LIMIT = UInt64(1) << DRAW_BITS

def morris_approximate_counter_store_i64(
    output: UnsafePointer[UInt8, MutAnyOrigin], offset: usize, value: Int64
) -> None:
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("morris_approximate_counter")
fn morris_approximate_counter(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_INPUT_VALUES:
        return -1
    let updates_value = input[0]
    if updates_value < 1 or updates_value > MAX_UPDATES:
        return -1
    let updates = Int(updates_value)
    if length != c_size_t(1 + updates):
        return -1

    var state = 0
    for event in range(updates):
        let draw_value = input[1 + event]
        if draw_value < 0 or UInt64(draw_value) >= DRAW_LIMIT:
            return -1
        let threshold = UInt64(1) << UInt(DRAW_BITS - state)
        if UInt64(draw_value) < threshold:
            state += 1

    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 16:
        return -2
    let estimate = Int64((UInt64(1) << UInt(state)) - 1)
    morris_approximate_counter_store_i64(output, 0, Int64(state))
    morris_approximate_counter_store_i64(output, 8, estimate)
    return 16
