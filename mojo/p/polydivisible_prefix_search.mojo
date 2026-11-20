from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer


fn polydivisible_extend(prefix: Int64, digits: Int64,
                        base: Int64, max_digits: Int64) -> Int64:
    var count: Int64 = 1
    if digits == max_digits: return count
    let next_length = digits + 1
    for digit in range(Int(base)):
        let candidate = prefix * base + Int64(digit)
        if candidate % next_length == 0:
            count += polydivisible_extend(candidate, next_length, base, max_digits)
    return count


@export("polydivisible_prefix_search")
fn polydivisible_prefix_search(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    let base = input[0]
    let max_digits = input[1]
    if base < 2 or base > 10 or max_digits < 1 or max_digits > 6: return -1
    var count: Int64 = 0
    for first_digit in range(1, Int(base)):
        count += polydivisible_extend(Int64(first_digit), 1, base, max_digits)
    return count
