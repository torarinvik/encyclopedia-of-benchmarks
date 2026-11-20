from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

alias MAX_SEQUENCE_LENGTH = 16
alias MAX_PARSEABLE_LENGTH = 122

fn pair_input_index(n: Int, left: Int, right: Int) -> Int:
    let preceding = left * (2 * n - left - 1) // 2
    return 1 + preceding + (right - left - 1)

@export("rna_pair_activity_partition_function")
fn rna_pair_activity_partition_function(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_PARSEABLE_LENGTH:
        return -1
    let n_value = input[0]
    if n_value < 0 or n_value > MAX_SEQUENCE_LENGTH: return -1
    let n = Int(n_value)
    let expected_length = if n == 0 then 1 else 1 + n * (n - 1) // 2
    if Int(length) != expected_length: return -1
    for index in range(1, Int(length)):
        if input[index] < 0 or input[index] > 3: return -1
    if n == 0: return 1

    var table = InlineArray[Int64, 256](fill=0)
    for span in range(1, n + 1):
        for left in range(n - span + 1):
            let right = left + span - 1
            var total: Int64 = 1
            if left < right: total = table[left * MAX_SEQUENCE_LENGTH + right - 1]
            for partner in range(left, right):
                let activity = input[pair_input_index(n, partner, right)]
                let before: Int64 = if partner == left then 1 else table[left * MAX_SEQUENCE_LENGTH + partner - 1]
                let inside: Int64 = if partner + 1 >= right then 1 else table[(partner + 1) * MAX_SEQUENCE_LENGTH + right - 1]
                total += before * inside * activity
            table[left * MAX_SEQUENCE_LENGTH + right] = total
    return table[n - 1]
