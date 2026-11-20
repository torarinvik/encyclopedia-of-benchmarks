from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias MAX_VALUES = 64
alias MAX_INPUT_LENGTH = 66
alias MAX_FUNCTION_VALUE = Int64(1000000)

fn sum_over_subsets_zeta_transform_run(
        inout values: InlineArray[Int64, MAX_VALUES],
        bit_count: Int, state_count: Int) -> Int64:
    for bit_index in range(bit_count):
        let bit_mask = 1 << bit_index
        for mask in range(state_count):
            if (mask & bit_mask) != 0:
                values[mask] += values[mask ^ bit_mask]
    var checksum: Int64 = 0
    for mask in range(state_count):
        checksum += Int64(mask + 1) * values[mask]
    return checksum

@export("sum_over_subsets_zeta_transform")
fn sum_over_subsets_zeta_transform(
        input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or
            length < 1 or length > MAX_INPUT_LENGTH:
        return -1
    let raw_bit_count = input[0]
    if raw_bit_count < 0 or raw_bit_count > 6:
        return -1
    let bit_count = Int(raw_bit_count)
    let state_count = 1 << bit_count
    if length != c_size_t(state_count + 1):
        return -1

    var values = InlineArray[Int64, MAX_VALUES](fill=0)
    for mask in range(state_count):
        let value = input[mask + 1]
        if value < 0 or value > MAX_FUNCTION_VALUE:
            return -1
        values[mask] = value
    return sum_over_subsets_zeta_transform_run(inout values, bit_count, state_count)
