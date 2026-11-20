from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_LIMIT: Int64 = 100000
const MAX_PARSEABLE_LENGTH = 2

fn digit_sum10(value: Int64) -> Int64:
    var remaining = value
    var total: Int64 = 0
    while remaining > 0:
        total += remaining % 10
        remaining = remaining // 10
    return total

@export("self_number_count_sieve")
fn self_number_count_sieve(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > c_size_t(MAX_PARSEABLE_LENGTH):
        return -1
    let limit = input[0]
    if length != 1 or limit < 1 or limit > MAX_LIMIT:
        return -1

    var generated = InlineArray[UInt64, 1563](fill=0)
    for source in range(1, Int(limit) + 1):
        let target = Int64(source) + digit_sum10(Int64(source))
        if target <= limit:
            let word = Int(target // 64)
            let bit = UInt64(target % 64)
            generated[word] |= UInt64(1) << bit
    var count: Int64 = 0
    for value in range(1, Int(limit) + 1):
        let word = Int(value // 64)
        let bit = UInt64(value % 64)
        if generated[word] & (UInt64(1) << bit) == 0:
            count += 1
    return count
