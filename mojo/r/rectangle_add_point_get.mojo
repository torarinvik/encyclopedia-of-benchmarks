from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 32
comptime MAX_Q = 32
comptime MAX_RECTANGLES = MAX_N + MAX_Q
comptime MAX_COORDS = 2 * MAX_RECTANGLES
comptime MAX_CORNERS = 4 * MAX_RECTANGLES
comptime MAX_PARSEABLE_INPUT = 2 + 5 * MAX_N + 6 * MAX_Q + 1
comptime MAX_COORD = 1_000_000
comptime MAX_WEIGHT = 1_000_000

fn lowbit(value: Int) -> Int:
    return value & (-value)

fn lower_bound_i64(values: UnsafePointer[Int64, ImmutAnyOrigin], count: Int, target: Int64) -> Int:
    var left = 0
    var right = count
    while left < right:
        let middle = left + (right - left) // 2
        if values[middle] < target:
            left = middle + 1
        else:
            right = middle
    return left

fn upper_bound_i64(values: UnsafePointer[Int64, ImmutAnyOrigin], count: Int, target: Int64) -> Int:
    var left = 0
    var right = count
    while left < right:
        let middle = left + (right - left) // 2
        if values[middle] <= target:
            left = middle + 1
        else:
            right = middle
    return left

fn lower_bound_int(values: UnsafePointer[Int, ImmutAnyOrigin], count: Int, target: Int) -> Int:
    var left = 0
    var right = count
    while left < right:
        let middle = left + (right - left) // 2
        if values[middle] < target:
            left = middle + 1
        else:
            right = middle
    return left

fn sort_unique(values: UnsafePointer[Int64, MutAnyOrigin], count: Int) -> Int:
    for index in range(1, count):
        let value = values[index]
        var position = index
        while position > 0 and values[position - 1] > value:
            values[position] = values[position - 1]
            position -= 1
        values[position] = value
    var unique_count = 0
    for index in range(count):
        if unique_count == 0 or values[index] != values[unique_count - 1]:
            values[unique_count] = values[index]
            unique_count += 1
    return unique_count

fn register_event(xs: UnsafePointer[Int64, ImmutAnyOrigin], x_count: Int,
    ys: UnsafePointer[Int64, ImmutAnyOrigin], y_count: Int,
    present: UnsafePointer[Bool, MutAnyOrigin], x: Int64, y: Int64):
    var outer = lower_bound_i64(xs, x_count, x) + 1
    let rank = lower_bound_i64(ys, y_count, y)
    while outer <= x_count:
        present[outer * MAX_COORDS + rank] = True
        outer += lowbit(outer)

fn register_rectangle(xs: UnsafePointer[Int64, ImmutAnyOrigin], x_count: Int,
    ys: UnsafePointer[Int64, ImmutAnyOrigin], y_count: Int,
    present: UnsafePointer[Bool, MutAnyOrigin], left: Int64, down: Int64,
    right: Int64, up: Int64):
    register_event(xs, x_count, ys, y_count, present, left, down)
    register_event(xs, x_count, ys, y_count, present, right, down)
    register_event(xs, x_count, ys, y_count, present, left, up)
    register_event(xs, x_count, ys, y_count, present, right, up)

fn fenwick_add(tree: UnsafePointer[Int64, MutAnyOrigin],
    y_values: UnsafePointer[Int, ImmutAnyOrigin], y_counts: UnsafePointer[Int, ImmutAnyOrigin],
    xs: UnsafePointer[Int64, ImmutAnyOrigin], x_count: Int,
    ys: UnsafePointer[Int64, ImmutAnyOrigin], y_count: Int,
    x: Int64, y: Int64, weight: Int64):
    var outer = lower_bound_i64(xs, x_count, x) + 1
    let y_rank = lower_bound_i64(ys, y_count, y)
    while outer <= x_count:
        let row = outer * MAX_COORDS
        var inner = lower_bound_int(y_values + row, y_counts[outer], y_rank) + 1
        while inner <= y_counts[outer]:
            tree[outer * (MAX_COORDS + 1) + inner] += weight
            inner += lowbit(inner)
        outer += lowbit(outer)

fn apply_rectangle(tree: UnsafePointer[Int64, MutAnyOrigin],
    y_values: UnsafePointer[Int, ImmutAnyOrigin], y_counts: UnsafePointer[Int, ImmutAnyOrigin],
    xs: UnsafePointer[Int64, ImmutAnyOrigin], x_count: Int,
    ys: UnsafePointer[Int64, ImmutAnyOrigin], y_count: Int,
    left: Int64, down: Int64, right: Int64, up: Int64, weight: Int64):
    fenwick_add(tree, y_values, y_counts, xs, x_count, ys, y_count, left, down, weight)
    fenwick_add(tree, y_values, y_counts, xs, x_count, ys, y_count, right, down, -weight)
    fenwick_add(tree, y_values, y_counts, xs, x_count, ys, y_count, left, up, -weight)
    fenwick_add(tree, y_values, y_counts, xs, x_count, ys, y_count, right, up, weight)

fn prefix_sum(tree: UnsafePointer[Int64, ImmutAnyOrigin],
    y_values: UnsafePointer[Int, ImmutAnyOrigin], y_counts: UnsafePointer[Int, ImmutAnyOrigin],
    xs: UnsafePointer[Int64, ImmutAnyOrigin], x_count: Int,
    ys: UnsafePointer[Int64, ImmutAnyOrigin], y_count: Int,
    x_limit: Int64, y_limit: Int64) -> Int64:
    var outer = upper_bound_i64(xs, x_count, x_limit)
    let y_limit_rank = upper_bound_i64(ys, y_count, y_limit)
    var total: Int64 = 0
    while outer > 0:
        let row = outer * MAX_COORDS
        var inner = lower_bound_int(y_values + row, y_counts[outer], y_limit_rank)
        while inner > 0:
            total += tree[outer * (MAX_COORDS + 1) + inner]
            inner -= lowbit(inner)
        outer -= lowbit(outer)
    return total

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (byte * 8)) & UInt64(255))

@export("rectangle_add_point_get")
fn rectangle_add_point_get(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(MAX_PARSEABLE_INPUT):
        return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 1 or n_value > MAX_N or q_value < 1 or q_value > MAX_Q:
        return -1
    let n = Int(n_value)
    let q = Int(q_value)

    var initial = InlineArray[Int64, 5 * MAX_N](fill=0)
    var kinds = InlineArray[Int64, MAX_Q](fill=0)
    var op_a = InlineArray[Int64, MAX_Q](fill=0)
    var op_b = InlineArray[Int64, MAX_Q](fill=0)
    var op_c = InlineArray[Int64, MAX_Q](fill=0)
    var op_d = InlineArray[Int64, MAX_Q](fill=0)
    var op_e = InlineArray[Int64, MAX_Q](fill=0)
    var all_x = InlineArray[Int64, MAX_CORNERS](fill=0)
    var all_y = InlineArray[Int64, MAX_CORNERS](fill=0)
    var rectangle_count = 0
    var cursor = 2
    for index in range(n):
        if cursor + 5 > length: return -1
        let left = input[cursor]
        let down = input[cursor + 1]
        let right = input[cursor + 2]
        let up = input[cursor + 3]
        let weight = input[cursor + 4]
        cursor += 5
        if left < 0 or left >= right or right > MAX_COORD or down < 0 or down >= up or up > MAX_COORD or weight < 0 or weight > MAX_WEIGHT:
            return -1
        let base = 5 * index
        initial[base] = left
        initial[base + 1] = down
        initial[base + 2] = right
        initial[base + 3] = up
        initial[base + 4] = weight
        all_x[4 * rectangle_count] = left
        all_y[4 * rectangle_count] = down
        all_x[4 * rectangle_count + 1] = right
        all_y[4 * rectangle_count + 1] = down
        all_x[4 * rectangle_count + 2] = left
        all_y[4 * rectangle_count + 2] = up
        all_x[4 * rectangle_count + 3] = right
        all_y[4 * rectangle_count + 3] = up
        rectangle_count += 1

    for index in range(q):
        if cursor >= length: return -1
        let kind = input[cursor]
        cursor += 1
        kinds[index] = kind
        if kind == 0:
            if cursor + 5 > length: return -1
            let left = input[cursor]
            let down = input[cursor + 1]
            let right = input[cursor + 2]
            let up = input[cursor + 3]
            let weight = input[cursor + 4]
            cursor += 5
            if left < 0 or left >= right or right > MAX_COORD or down < 0 or down >= up or up > MAX_COORD or weight < 0 or weight > MAX_WEIGHT:
                return -1
            op_a[index] = left
            op_b[index] = down
            op_c[index] = right
            op_d[index] = up
            op_e[index] = weight
            all_x[4 * rectangle_count] = left
            all_y[4 * rectangle_count] = down
            all_x[4 * rectangle_count + 1] = right
            all_y[4 * rectangle_count + 1] = down
            all_x[4 * rectangle_count + 2] = left
            all_y[4 * rectangle_count + 2] = up
            all_x[4 * rectangle_count + 3] = right
            all_y[4 * rectangle_count + 3] = up
            rectangle_count += 1
        elif kind == 1:
            if cursor + 2 > length: return -1
            let x = input[cursor]
            let y = input[cursor + 1]
            cursor += 2
            if x < 0 or x > MAX_COORD or y < 0 or y > MAX_COORD: return -1
            op_a[index] = x
            op_b[index] = y
        else:
            return -1
    if cursor != length: return -1

    let corner_count = rectangle_count * 4
    let x_count = sort_unique(all_x.unsafe_ptr(), corner_count)
    let y_count = sort_unique(all_y.unsafe_ptr(), corner_count)
    var present = InlineArray[Bool, (MAX_COORDS + 1) * MAX_COORDS](fill=False)
    for index in range(n):
        let base = 5 * index
        register_rectangle(all_x.unsafe_ptr(), x_count, all_y.unsafe_ptr(), y_count,
            present.unsafe_ptr(), initial[base], initial[base + 1], initial[base + 2], initial[base + 3])
    for index in range(q):
        if kinds[index] == 0:
            register_rectangle(all_x.unsafe_ptr(), x_count, all_y.unsafe_ptr(), y_count,
                present.unsafe_ptr(), op_a[index], op_b[index], op_c[index], op_d[index])

    var y_values = InlineArray[Int, (MAX_COORDS + 1) * MAX_COORDS](fill=0)
    var y_counts = InlineArray[Int, MAX_COORDS + 1](fill=0)
    for outer in range(1, x_count + 1):
        for rank in range(y_count):
            if present[outer * MAX_COORDS + rank]:
                y_values[outer * MAX_COORDS + y_counts[outer]] = rank
                y_counts[outer] += 1
    var tree = InlineArray[Int64, (MAX_COORDS + 1) * (MAX_COORDS + 1)](fill=0)
    for index in range(n):
        let base = 5 * index
        apply_rectangle(tree.unsafe_ptr(), y_values.unsafe_ptr(), y_counts.unsafe_ptr(),
            all_x.unsafe_ptr(), x_count, all_y.unsafe_ptr(), y_count,
            initial[base], initial[base + 1], initial[base + 2], initial[base + 3], initial[base + 4])
    var answers = InlineArray[Int64, MAX_Q](fill=0)
    var answer_count = 0
    for index in range(q):
        if kinds[index] == 0:
            apply_rectangle(tree.unsafe_ptr(), y_values.unsafe_ptr(), y_counts.unsafe_ptr(),
                all_x.unsafe_ptr(), x_count, all_y.unsafe_ptr(), y_count,
                op_a[index], op_b[index], op_c[index], op_d[index], op_e[index])
        else:
            answers[answer_count] = prefix_sum(tree.unsafe_ptr(), y_values.unsafe_ptr(), y_counts.unsafe_ptr(),
                all_x.unsafe_ptr(), x_count, all_y.unsafe_ptr(), y_count, op_a[index], op_b[index])
            answer_count += 1

    let output_bytes = 8 * answer_count
    if output_bytes > 0 and (output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes)):
        return -2
    for index in range(answer_count): store_i64_le(output, index * 8, answers[index])
    return Int64(output_bytes)
