from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import floor, isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_N = 10
alias MAX_INPUT_LENGTH = 13
alias MAX_ORDER = 6
alias ROW_COUNT = 7
alias TABLE_CELLS = ROW_COUNT * MAX_N

@export("wynn_epsilon_sequence_algorithm")
fn wynn_epsilon_sequence_algorithm(
    input: UnsafePointer[Float64, ImmutAnyOrigin], input_length: c_size_t,
    output: UnsafePointer[Float64, MutAnyOrigin], output_capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or input_length < 3 or input_length > MAX_INPUT_LENGTH:
        return -1
    for i in range(input_length):
        if not isfinite(input[i]):
            return -1
    let n_value = input[0]
    let k_value = input[1]
    if floor(n_value) != n_value or floor(k_value) != k_value:
        return -1
    if n_value < 5.0 or n_value > Float64(MAX_N) or k_value < 2.0 or k_value > 3.0:
        return -1
    let n = Int(n_value)
    let k = Int(k_value)
    if Float64(n) != n_value or Float64(k) != k_value or n < 2 * k + 1:
        return -1
    if input_length != c_size_t(n + 2):
        return -1
    for i in range(n):
        let sample = input[i + 2]
        let scaled = sample * 256.0
        if sample < -2.0 or sample > 2.0 or floor(scaled) != scaled:
            return -1

    var rows = InlineArray[Float64, TABLE_CELLS](fill=0.0)
    var valid = InlineArray[Bool, TABLE_CELLS](fill=False)
    for i in range(n):
        rows[i] = input[i + 2]
        valid[i] = True
    for order in range(2 * k):
        for i in range(n - order - 1):
            let cell = order * MAX_N + i
            var auxiliary_valid = True
            if order != 0:
                auxiliary_valid = valid[(order - 1) * MAX_N + i + 1]
            if not valid[cell] or not valid[cell + 1] or not auxiliary_valid:
                continue
            let denominator = rows[cell + 1] - rows[cell]
            if denominator == 0.0 or not isfinite(denominator):
                continue
            let reciprocal = 1.0 / denominator
            var auxiliary = 0.0
            if order != 0:
                auxiliary = rows[(order - 1) * MAX_N + i + 1]
            let value = auxiliary + reciprocal
            if not isfinite(reciprocal) or not isfinite(value):
                continue
            let next_cell = (order + 1) * MAX_N + i
            rows[next_cell] = value
            valid[next_cell] = True

    var needed = 0
    for order in range(2, 2 * k + 1, 2):
        needed += 2 * (n - order)
    if output == UnsafePointer[Float64, MutAnyOrigin]() or output_capacity < c_size_t(needed):
        return -2
    var cursor = 0
    for order in range(2, 2 * k + 1, 2):
        for i in range(n - order):
            let cell = order * MAX_N + i
            if valid[cell]:
                output[cursor] = 0.0
                output[cursor + 1] = rows[cell]
            else:
                output[cursor] = 1.0
                output[cursor + 1] = 0.0
            cursor += 2
    return Int64(needed)
