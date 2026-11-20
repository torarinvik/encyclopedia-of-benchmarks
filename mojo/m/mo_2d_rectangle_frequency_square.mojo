from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_N = 8
comptime MAX_Q = 32
comptime MAX_CELLS = 64
comptime MAX_INPUT = 194
comptime MAX_PARSEABLE = 195

fn query_before(a: Int, b: Int, tops: InlineArray[Int, MAX_Q],
                lefts: InlineArray[Int, MAX_Q], bottoms: InlineArray[Int, MAX_Q],
                rights: InlineArray[Int, MAX_Q], block_size: Int) -> Bool:
    let a_tb = tops[a] // block_size
    let b_tb = tops[b] // block_size
    if a_tb != b_tb: return a_tb < b_tb
    let a_lb = lefts[a] // block_size
    let b_lb = lefts[b] // block_size
    if a_lb != b_lb: return a_lb < b_lb
    let a_bb = bottoms[a] // block_size
    let b_bb = bottoms[b] // block_size
    if a_bb != b_bb: return a_bb < b_bb
    let a_rb = rights[a] // block_size
    let b_rb = rights[b] // block_size
    if a_rb != b_rb: return a_rb < b_rb
    if tops[a] != tops[b]: return tops[a] < tops[b]
    if lefts[a] != lefts[b]: return lefts[a] < lefts[b]
    if bottoms[a] != bottoms[b]: return bottoms[a] < bottoms[b]
    if rights[a] != rights[b]: return rights[a] < rights[b]
    return a < b

fn add_value(value: Int, mut frequencies: InlineArray[Int, 8], mut square_sum: Int):
    let old_frequency = frequencies[value]
    square_sum += 2 * old_frequency + 1
    frequencies[value] = old_frequency + 1

fn remove_value(value: Int, mut frequencies: InlineArray[Int, 8], mut square_sum: Int):
    let old_frequency = frequencies[value]
    square_sum += 1 - 2 * old_frequency
    frequencies[value] = old_frequency - 1

@export("mo_2d_rectangle_frequency_square")
fn mo_2d_rectangle_frequency_square(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(2) or length > c_size_t(MAX_PARSEABLE):
        return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 1 or n_value > MAX_N or q_value < 0 or q_value > MAX_Q: return -1
    let n = Int(n_value)
    let q = Int(q_value)
    if length != c_size_t(2 + n * n + 4 * q) or length > c_size_t(MAX_INPUT): return -1

    var matrix = InlineArray[Int, MAX_CELLS](fill=0)
    for cell in range(n * n):
        let value = input[2 + cell]
        if value < 0 or value > 7: return -1
        matrix[cell] = Int(value)

    var tops = InlineArray[Int, MAX_Q](fill=0)
    var lefts = InlineArray[Int, MAX_Q](fill=0)
    var bottoms = InlineArray[Int, MAX_Q](fill=0)
    var rights = InlineArray[Int, MAX_Q](fill=0)
    var order = InlineArray[Int, MAX_Q](fill=0)
    var cursor = 2 + n * n
    for query in range(q):
        let top_value = input[cursor]
        let left_value = input[cursor + 1]
        let bottom_value = input[cursor + 2]
        let right_value = input[cursor + 3]
        if top_value < 0 or top_value >= n_value or bottom_value < top_value or bottom_value >= n_value:
            return -1
        if left_value < 0 or left_value >= n_value or right_value < left_value or right_value >= n_value:
            return -1
        tops[query] = Int(top_value)
        lefts[query] = Int(left_value)
        bottoms[query] = Int(bottom_value)
        rights[query] = Int(right_value)
        order[query] = query
        cursor += 4

    if q == 0: return 0
    var block_size = 1
    let n_fourth = n * n * n * n
    while block_size < n:
        let candidate = block_size + 1
        if q * candidate * candidate * candidate * candidate <= n_fourth:
            block_size = candidate
        else:
            break
    for query in range(1, q):
        let item = order[query]
        var position = query
        while position > 0 and query_before(item, order[position - 1], tops, lefts, bottoms, rights, block_size):
            order[position] = order[position - 1]
            position -= 1
        order[position] = item

    var answers = InlineArray[Int64, MAX_Q](fill=0)
    var frequencies = InlineArray[Int, 8](fill=0)
    var square_sum = 0
    let first_query = order[0]
    var current_top = tops[first_query]
    var current_bottom = bottoms[first_query]
    var current_left = lefts[first_query]
    var current_right = rights[first_query]
    for row in range(current_top, current_bottom + 1):
        for column in range(current_left, current_right + 1):
            add_value(matrix[row * n + column], mut frequencies, mut square_sum)
    answers[first_query] = Int64(square_sum)

    for sorted_position in range(1, q):
        let query = order[sorted_position]
        let target_top = tops[query]
        let target_bottom = bottoms[query]
        let target_left = lefts[query]
        let target_right = rights[query]
        while current_top > target_top:
            current_top -= 1
            for column in range(current_left, current_right + 1):
                add_value(matrix[current_top * n + column], mut frequencies, mut square_sum)
        while current_bottom < target_bottom:
            current_bottom += 1
            for column in range(current_left, current_right + 1):
                add_value(matrix[current_bottom * n + column], mut frequencies, mut square_sum)
        while current_left > target_left:
            current_left -= 1
            for row in range(current_top, current_bottom + 1):
                add_value(matrix[row * n + current_left], mut frequencies, mut square_sum)
        while current_right < target_right:
            current_right += 1
            for row in range(current_top, current_bottom + 1):
                add_value(matrix[row * n + current_right], mut frequencies, mut square_sum)
        while current_top < target_top:
            for column in range(current_left, current_right + 1):
                remove_value(matrix[current_top * n + column], mut frequencies, mut square_sum)
            current_top += 1
        while current_bottom > target_bottom:
            for column in range(current_left, current_right + 1):
                remove_value(matrix[current_bottom * n + column], mut frequencies, mut square_sum)
            current_bottom -= 1
        while current_left < target_left:
            for row in range(current_top, current_bottom + 1):
                remove_value(matrix[row * n + current_left], mut frequencies, mut square_sum)
            current_left += 1
        while current_right > target_right:
            for row in range(current_top, current_bottom + 1):
                remove_value(matrix[row * n + current_right], mut frequencies, mut square_sum)
            current_right -= 1
        answers[query] = Int64(square_sum)

    var checksum: Int64 = 0
    for index in range(q): checksum += Int64(index + 1) * answers[index]
    return checksum
