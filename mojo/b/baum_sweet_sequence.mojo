from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer


fn baum_sweet_term(number: Int64) -> Int64:
    if number == 0: return 0
    var mask: Int64 = 1
    while mask <= number // 2:
        mask *= 2
    var odd_zero_run = False
    while mask > 0:
        if (number & mask) != 0:
            if odd_zero_run: return 0
            odd_zero_run = False
        else:
            odd_zero_run = not odd_zero_run
        mask //= 2
    return 0 if odd_zero_run else 1


@export("baum_sweet_sequence")
fn baum_sweet_sequence(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1: return -1
    let count = input[0]
    if count < 0 or count > 63: return -1
    var packed: Int64 = 0
    var bit: Int64 = 1
    for index in range(Int(count)):
        if baum_sweet_term(Int64(index)) != 0: packed += bit
        if index + 1 < Int(count): bit *= 2
    return packed
