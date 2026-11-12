const MAX_N: usize = 32;
const MAX_Q: usize = 32;
const MAX_POINTS: usize = MAX_N + MAX_Q;
const MAX_PARSEABLE_INPUT: usize = 2 + 3 * MAX_N + 5 * MAX_Q + 1;
const MAX_COORD: i64 = 1_000_000;
const MAX_WEIGHT: i64 = 1_000_000;

const Point = struct { x: i64, y: i64, weight: i64 };
const Operation = struct { kind: i64, a: i64, b: i64, c: i64, d: i64 };

fn lowbit(value: usize) usize {
    return value & (~value + 1);
}

fn lowerBoundI64(values: []const i64, target: i64) usize {
    var left: usize = 0;
    var right = values.len;
    while (left < right) {
        const middle = left + (right - left) / 2;
        if (values[middle] < target) left = middle + 1 else right = middle;
    }
    return left;
}

fn lowerBoundUsize(values: []const usize, target: usize) usize {
    var left: usize = 0;
    var right = values.len;
    while (left < right) {
        const middle = left + (right - left) / 2;
        if (values[middle] < target) left = middle + 1 else right = middle;
    }
    return left;
}

fn sortUnique(values: *[MAX_POINTS]i64, count: usize) usize {
    for (1..count) |index| {
        const value = values[index];
        var position = index;
        while (position > 0 and values[position - 1] > value) {
            values[position] = values[position - 1];
            position -= 1;
        }
        values[position] = value;
    }
    var unique_count: usize = 0;
    for (0..count) |index| {
        if (unique_count == 0 or values[index] != values[unique_count - 1]) {
            values[unique_count] = values[index];
            unique_count += 1;
        }
    }
    return unique_count;
}

fn registerCoordinate(xs: *const [MAX_POINTS]i64, x_count: usize,
    ys: *const [MAX_POINTS]i64, y_count: usize,
    present: *[ (MAX_POINTS + 1) * MAX_POINTS ]bool, x: i64, y: i64) void {
    var outer = lowerBoundI64(xs[0..x_count], x) + 1;
    const rank = lowerBoundI64(ys[0..y_count], y);
    while (outer <= x_count) {
        present[outer * MAX_POINTS + rank] = true;
        outer += lowbit(outer);
    }
}

fn fenwickAdd(tree: *[ (MAX_POINTS + 1) * (MAX_POINTS + 1) ]i64,
    y_values: *const [ (MAX_POINTS + 1) * MAX_POINTS ]usize,
    y_counts: *const [MAX_POINTS + 1]usize,
    xs: *const [MAX_POINTS]i64, x_count: usize,
    ys: *const [MAX_POINTS]i64, y_count: usize,
    x: i64, y: i64, weight: i64) void {
    var outer = lowerBoundI64(xs[0..x_count], x) + 1;
    const y_rank = lowerBoundI64(ys[0..y_count], y);
    while (outer <= x_count) {
        const row = outer * MAX_POINTS;
        const row_values = y_values[row .. row + y_counts[outer]];
        var inner = lowerBoundUsize(row_values, y_rank) + 1;
        while (inner <= y_counts[outer]) {
            tree[outer * (MAX_POINTS + 1) + inner] += weight;
            inner += lowbit(inner);
        }
        outer += lowbit(outer);
    }
}

fn prefixSum(tree: *const [ (MAX_POINTS + 1) * (MAX_POINTS + 1) ]i64,
    y_values: *const [ (MAX_POINTS + 1) * MAX_POINTS ]usize,
    y_counts: *const [MAX_POINTS + 1]usize,
    xs: *const [MAX_POINTS]i64, x_count: usize,
    ys: *const [MAX_POINTS]i64, y_count: usize,
    x_limit: i64, y_limit: i64) i64 {
    var outer = lowerBoundI64(xs[0..x_count], x_limit);
    const y_limit_rank = lowerBoundI64(ys[0..y_count], y_limit);
    var total: i64 = 0;
    while (outer > 0) {
        const row = outer * MAX_POINTS;
        const row_values = y_values[row .. row + y_counts[outer]];
        var inner = lowerBoundUsize(row_values, y_limit_rank);
        while (inner > 0) {
            total += tree[outer * (MAX_POINTS + 1) + inner];
            inner -= lowbit(inner);
        }
        outer -= lowbit(outer);
    }
    return total;
}

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn point_add_rectangle_sum(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_PARSEABLE_INPUT) return -1;
    const packed = input[0..length];
    const n_value = packed[0];
    const q_value = packed[1];
    if (n_value < 1 or n_value > MAX_N or q_value < 0 or q_value > MAX_Q) return -1;
    const n: usize = @intCast(n_value);
    const q: usize = @intCast(q_value);

    var initial: [MAX_N]Point = @splat(.{ .x = 0, .y = 0, .weight = 0 });
    var operations: [MAX_Q]Operation = @splat(.{ .kind = 0, .a = 0, .b = 0, .c = 0, .d = 0 });
    var all_x: [MAX_POINTS]i64 = @splat(0);
    var all_y: [MAX_POINTS]i64 = @splat(0);
    var point_count: usize = 0;
    var cursor: usize = 2;
    for (0..n) |index| {
        if (cursor + 3 > length) return -1;
        const x = packed[cursor];
        const y = packed[cursor + 1];
        const weight = packed[cursor + 2];
        cursor += 3;
        if (x < 0 or x > MAX_COORD or y < 0 or y > MAX_COORD or weight < 0 or weight > MAX_WEIGHT) return -1;
        initial[index] = .{ .x = x, .y = y, .weight = weight };
        all_x[point_count] = x;
        all_y[point_count] = y;
        point_count += 1;
    }

    var query_count: usize = 0;
    for (0..q) |index| {
        if (cursor >= length) return -1;
        const kind = packed[cursor];
        cursor += 1;
        if (kind == 0) {
            if (cursor + 3 > length) return -1;
            const x = packed[cursor];
            const y = packed[cursor + 1];
            const weight = packed[cursor + 2];
            cursor += 3;
            if (x < 0 or x > MAX_COORD or y < 0 or y > MAX_COORD or weight < 0 or weight > MAX_WEIGHT) return -1;
            operations[index] = .{ .kind = 0, .a = x, .b = y, .c = weight, .d = 0 };
            all_x[point_count] = x;
            all_y[point_count] = y;
            point_count += 1;
        } else if (kind == 1) {
            if (cursor + 4 > length) return -1;
            const left = packed[cursor];
            const down = packed[cursor + 1];
            const right = packed[cursor + 2];
            const up = packed[cursor + 3];
            cursor += 4;
            if (left < 0 or left >= right or right > MAX_COORD or down < 0 or down >= up or up > MAX_COORD) return -1;
            operations[index] = .{ .kind = 1, .a = left, .b = down, .c = right, .d = up };
            query_count += 1;
        } else return -1;
    }
    if (cursor != length) return -1;

    const x_count = sortUnique(&all_x, point_count);
    const y_count = sortUnique(&all_y, point_count);
    var present: [ (MAX_POINTS + 1) * MAX_POINTS ]bool = @splat(false);
    for (initial[0..n]) |point| registerCoordinate(&all_x, x_count, &all_y, y_count, &present, point.x, point.y);
    for (operations[0..q]) |op| {
        if (op.kind == 0) registerCoordinate(&all_x, x_count, &all_y, y_count, &present, op.a, op.b);
    }

    var y_values: [ (MAX_POINTS + 1) * MAX_POINTS ]usize = @splat(0);
    var y_counts: [MAX_POINTS + 1]usize = @splat(0);
    for (1..x_count + 1) |outer| {
        for (0..y_count) |rank| {
            if (present[outer * MAX_POINTS + rank]) {
                y_values[outer * MAX_POINTS + y_counts[outer]] = rank;
                y_counts[outer] += 1;
            }
        }
    }

    var tree: [ (MAX_POINTS + 1) * (MAX_POINTS + 1) ]i64 = @splat(0);
    for (initial[0..n]) |point| fenwickAdd(&tree, &y_values, &y_counts, &all_x, x_count,
        &all_y, y_count, point.x, point.y, point.weight);
    var answers: [MAX_Q]i64 = @splat(0);
    var answer_count: usize = 0;
    for (operations[0..q]) |op| {
        if (op.kind == 0) {
            fenwickAdd(&tree, &y_values, &y_counts, &all_x, x_count, &all_y, y_count, op.a, op.b, op.c);
        } else {
            answers[answer_count] =
                prefixSum(&tree, &y_values, &y_counts, &all_x, x_count, &all_y, y_count, op.c, op.d) -
                prefixSum(&tree, &y_values, &y_counts, &all_x, x_count, &all_y, y_count, op.a, op.d) -
                prefixSum(&tree, &y_values, &y_counts, &all_x, x_count, &all_y, y_count, op.c, op.b) +
                prefixSum(&tree, &y_values, &y_counts, &all_x, x_count, &all_y, y_count, op.a, op.b);
            answer_count += 1;
        }
    }

    const output_bytes = 8 * answer_count;
    if (output_bytes > 0 and (output == null or capacity < output_bytes)) return -2;
    for (0..answer_count) |index| storeI64Le(output, 8 * index, answers[index]);
    return @intCast(output_bytes);
}
