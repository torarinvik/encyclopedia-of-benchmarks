from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MODULUS: Int64 = 998244353
comptime MAX_STATES = 7
comptime MATRIX_WIDTH = MAX_STATES + 1

fn pow_mod(base_value: Int64, exponent_value: Int64) -> Int64:
    var result: Int64 = 1
    var base = base_value
    var exponent = exponent_value
    while exponent > 0:
        if (exponent & 1) != 0:
            result = result * base % MODULUS
        base = base * base % MODULUS
        exponent >>= 1
    return result

fn find_state(codes: InlineArray[Int64, MAX_STATES], lengths: InlineArray[Int, MAX_STATES],
              count: Int, code: Int64, state_length: Int) -> Int:
    for index in range(count):
        if codes[index] == code and lengths[index] == state_length:
            return index
    return -1

fn solve(word_length: Int, first: Int64, second: Int64) -> Int64:
    var codes = InlineArray[Int64, MAX_STATES](fill=0)
    var lengths = InlineArray[Int, MAX_STATES](fill=0)
    var state_count = 1
    for prefix_length in range(1, word_length):
        for which in range(2):
            let pattern = first if which == 0 else second
            let code = pattern >> (word_length - prefix_length)
            if find_state(codes, lengths, state_count, code, prefix_length) < 0:
                codes[state_count] = code
                lengths[state_count] = prefix_length
                state_count += 1

    var matrix = InlineArray[Int64, MAX_STATES * MATRIX_WIDTH](fill=0)
    for row in range(state_count):
        for column in range(state_count):
            matrix[row * MATRIX_WIDTH + column] = 2 if row == column else 0
        for bit in range(2):
            let candidate = (codes[row] << 1) | Int64(bit)
            let candidate_length = lengths[row] + 1
            if candidate_length == word_length and candidate == first:
                matrix[row * MATRIX_WIDTH + state_count] += 1
                continue
            if candidate_length == word_length and candidate == second:
                continue

            var suffix_length = min(candidate_length, word_length - 1)
            var destination = -1
            while suffix_length >= 0 and destination < 0:
                let suffix_mask = (Int64(1) << suffix_length) - 1
                destination = find_state(codes, lengths, state_count,
                    candidate & suffix_mask, suffix_length)
                suffix_length -= 1
            if destination < 0:
                destination = 0
            let target = row * MATRIX_WIDTH + destination
            matrix[target] = (matrix[target] - 1 + MODULUS) % MODULUS

    for column in range(state_count):
        var pivot = column
        while pivot < state_count and matrix[pivot * MATRIX_WIDTH + column] == 0:
            pivot += 1
        if pivot == state_count:
            return -1
        if pivot != column:
            for j in range(state_count + 1):
                let left = column * MATRIX_WIDTH + j
                let right = pivot * MATRIX_WIDTH + j
                let temporary = matrix[left]
                matrix[left] = matrix[right]
                matrix[right] = temporary
        let inverse = pow_mod(matrix[column * MATRIX_WIDTH + column], MODULUS - 2)
        for j in range(column, state_count + 1):
            let index = column * MATRIX_WIDTH + j
            matrix[index] = matrix[index] * inverse % MODULUS
        for row in range(state_count):
            if row == column:
                continue
            let factor = matrix[row * MATRIX_WIDTH + column]
            for j in range(column, state_count + 1):
                let row_index = row * MATRIX_WIDTH + j
                let pivot_index = column * MATRIX_WIDTH + j
                let product = factor * matrix[pivot_index] % MODULUS
                matrix[row_index] = (matrix[row_index] - product + MODULUS) % MODULUS
    return matrix[state_count]

@export("penney_game_pattern_probability")
fn penney_game_pattern_probability(input: UnsafePointer[Int64, ImmutAnyOrigin],
                                   length: c_size_t) -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3:
        return -1
    let word_length = input[0]
    if word_length < 1 or word_length > 4:
        return -1
    let limit = Int64(1) << Int(word_length)
    let first = input[1]
    let second = input[2]
    if first < 0 or second < 0 or first >= limit or second >= limit or first == second:
        return -1
    return solve(Int(word_length), first, second)
