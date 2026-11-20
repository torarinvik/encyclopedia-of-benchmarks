from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_DRAWS = 256
alias MAX_INPUT_LENGTH = MAX_DRAWS + 2

@export("seven_sided_dice_from_five_sided_dice")
fn seven_sided_dice_from_five_sided_dice(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_INPUT_LENGTH:
        return -1
    let draw_count_value = input[0]
    if draw_count_value < 0 or draw_count_value > MAX_DRAWS:
        return -1
    let draw_count = Int(draw_count_value)
    if length != c_size_t(draw_count + 1):
        return -1
    for index in range(draw_count):
        let draw = input[index + 1]
        if draw < 0 or draw > 4:
            return -1

    var staged = InlineArray[UInt8, MAX_DRAWS]()
    var written = 0
    var value: Int64 = 0
    var state_range: Int64 = 1
    for index in range(draw_count):
        value = 5 * value + input[index + 1]
        state_range *= 5
        while state_range >= 7:
            let accepted = state_range - state_range % 7
            if value < accepted:
                staged[written] = UInt8(value % 7 + 1)
                written += 1
                value /= 7
                state_range = accepted / 7
            else:
                value -= accepted
                state_range -= accepted

    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(written):
        return -2
    for index in range(written):
        output[index] = staged[index]
    return Int64(written)
