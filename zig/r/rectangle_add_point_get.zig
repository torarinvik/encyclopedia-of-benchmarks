const MAX_N: usize = 32;
const MAX_Q: usize = 32;
const MAX_RECTANGLES: usize = MAX_N + MAX_Q;
const MAX_COORDS: usize = 2 * MAX_RECTANGLES;
const MAX_CORNERS: usize = 4 * MAX_RECTANGLES;
const MAX_PARSEABLE_INPUT: usize = 2 + 5 * MAX_N + 6 * MAX_Q + 1;
const MAX_COORD: i64 = 1_000_000;
const MAX_WEIGHT: i64 = 1_000_000;

const Rectangle = struct { left: i64, down: i64, right: i64, up: i64, weight: i64 };
const Operation = struct { kind: i64, a: i64, b: i64, c: i64, d: i64, e: i64 };
const Presence = [ (MAX_COORDS + 1) * MAX_COORDS ]bool;
const NestedValues = [ (MAX_COORDS + 1) * MAX_COORDS ]usize;
const NestedTree = [ (MAX_COORDS + 1) * (MAX_COORDS + 1) ]i64;

fn lowbit(value: usize) usize { return value & (~value + 1); }

fn lowerBoundI64(values: []const i64, target: i64) usize {
    var left: usize = 0;
    var right = values.len;
    while (left < right) {
        const middle = left + (right - left) / 2;
        if (values[middle] < target) left = middle + 1 else right = middle;
    }
    return left;
}

fn upperBoundI64(values: []const i64, target: i64) usize {
    var left: usize = 0;
    var right = values.len;
    while (left < right) {
        const middle = left + (right - left) / 2;
        if (values[middle] <= target) left = middle + 1 else right = middle;
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

fn sortUnique(values: *[MAX_CORNERS]i64, count: usize) usize {
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

fn registerEvent(xs: *const [MAX_CORNERS]i64, x_count: usize,
    ys: *const [MAX_CORNERS]i64, y_count: usize,
    present: *Presence, x: i64, y: i64) void {
    var outer = lowerBoundI64(xs[0..x_count], x) + 1;
    const rank = lowerBoundI64(ys[0..y_count], y);
    while (outer <= x_count) {
        present[outer * MAX_COORDS + rank] = true;
        outer += lowbit(outer);
    }
}

fn registerRectangle(xs: *const [MAX_CORNERS]i64, x_count: usize,
    ys: *const [MAX_CORNERS]i64, y_count: usize,
    present: *Presence, rectangle: Rectangle) void {
    registerEvent(xs, x_count, ys, y_count, present, rectangle.left, rectangle.down);
    registerEvent(xs, x_count, ys, y_count, present, rectangle.right, rectangle.down);
    registerEvent(xs, x_count, ys, y_count, present, rectangle.left, rectangle.up);
    registerEvent(xs, x_count, ys, y_count, present, rectangle.right, rectangle.up);
}

fn fenwickAdd(tree: *NestedTree, y_values: *const NestedValues,
    y_counts: *const [MAX_COORDS + 1]usize,
    xs: *const [MAX_CORNERS]i64, x_count: usize,
    ys: *const [MAX_CORNERS]i64, y_count: usize,
    x: i64, y: i64, weight: i64) void {
    var outer = lowerBoundI64(xs[0..x_count], x) + 1;
    const y_rank = lowerBoundI64(ys[0..y_count], y);
    while (outer <= x_count) {
        const row = outer * MAX_COORDS;
        const row_values = y_values[row .. row + y_counts[outer]];
        var inner = lowerBoundUsize(row_values, y_rank) + 1;
        while (inner <= y_counts[outer]) {
            tree[outer * (MAX_COORDS + 1) + inner] += weight;
            inner += lowbit(inner);
        }
        outer += lowbit(outer);
    }
}

fn applyRectangle(tree: *NestedTree, y_values: *const NestedValues,
    y_counts: *const [MAX_COORDS + 1]usize,
    xs: *const [MAX_CORNERS]i64, x_count: usize,
    ys: *const [MAX_CORNERS]i64, y_count: usize, rectangle: Rectangle) void {
    fenwickAdd(tree, y_values, y_counts, xs, x_count, ys, y_count,
        rectangle.left, rectangle.down, rectangle.weight);
    fenwickAdd(tree, y_values, y_counts, xs, x_count, ys, y_count,
        rectangle.right, rectangle.down, -rectangle.weight);
    fenwickAdd(tree, y_values, y_counts, xs, x_count, ys, y_count,
        rectangle.left, rectangle.up, -rectangle.weight);
    fenwickAdd(tree, y_values, y_counts, xs, x_count, ys, y_count,
        rectangle.right, rectangle.up, rectangle.weight);
}

fn prefixSum(tree: *const NestedTree, y_values: *const NestedValues,
    y_counts: *const [MAX_COORDS + 1]usize,
    xs: *const [MAX_CORNERS]i64, x_count: usize,
    ys: *const [MAX_CORNERS]i64, y_count: usize,
    x_limit: i64, y_limit: i64) i64 {
    var outer = upperBoundI64(xs[0..x_count], x_limit);
    const y_limit_rank = upperBoundI64(ys[0..y_count], y_limit);
    var total: i64 = 0;
    while (outer > 0) {
        const row = outer * MAX_COORDS;
        const row_values = y_values[row .. row + y_counts[outer]];
        var inner = lowerBoundUsize(row_values, y_limit_rank);
        while (inner > 0) {
            total += tree[outer * (MAX_COORDS + 1) + inner];
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

export fn rectangle_add_point_get(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_PARSEABLE_INPUT) return -1;
    const packed = input[0..length];
    const n_value = packed[0];
    const q_value = packed[1];
    if (n_value < 1 or n_value > MAX_N or q_value < 1 or q_value > MAX_Q) return -1;
    const n: usize = @intCast(n_value);
    const q: usize = @intCast(q_value);
    var initial: [MAX_N]Rectangle = @splat(.{ .left = 0, .down = 0, .right = 0, .up = 0, .weight = 0 });
    var operations: [MAX_Q]Operation = @splat(.{ .kind = 0, .a = 0, .b = 0, .c = 0, .d = 0, .e = 0 });
    var all_x: [MAX_CORNERS]i64 = @splat(0);
    var all_y: [MAX_CORNERS]i64 = @splat(0);
    var rectangle_count: usize = 0;
    var cursor: usize = 2;
    for (0..n) |index| {
        if (cursor + 5 > length) return -1;
        const rectangle = Rectangle{ .left = packed[cursor], .down = packed[cursor + 1],
            .right = packed[cursor + 2], .up = packed[cursor + 3], .weight = packed[cursor + 4] };
        cursor += 5;
        if (rectangle.left < 0 or rectangle.left >= rectangle.right or rectangle.right > MAX_COORD or
            rectangle.down < 0 or rectangle.down >= rectangle.up or rectangle.up > MAX_COORD or
            rectangle.weight < 0 or rectangle.weight > MAX_WEIGHT) return -1;
        initial[index] = rectangle;
        const corner_x = [_]i64{ rectangle.left, rectangle.right, rectangle.left, rectangle.right };
        const corner_y = [_]i64{ rectangle.down, rectangle.down, rectangle.up, rectangle.up };
        for (0..4) |corner| {
            all_x[rectangle_count * 4 + corner] = corner_x[corner];
            all_y[rectangle_count * 4 + corner] = corner_y[corner];
        }
        rectangle_count += 1;
    }
    for (0..q) |index| {
        if (cursor >= length) return -1;
        const kind = packed[cursor];
        cursor += 1;
        if (kind == 0) {
            if (cursor + 5 > length) return -1;
            const rectangle = Rectangle{ .left = packed[cursor], .down = packed[cursor + 1],
                .right = packed[cursor + 2], .up = packed[cursor + 3], .weight = packed[cursor + 4] };
            cursor += 5;
            if (rectangle.left < 0 or rectangle.left >= rectangle.right or rectangle.right > MAX_COORD or
                rectangle.down < 0 or rectangle.down >= rectangle.up or rectangle.up > MAX_COORD or
                rectangle.weight < 0 or rectangle.weight > MAX_WEIGHT) return -1;
            operations[index] = .{ .kind = 0, .a = rectangle.left, .b = rectangle.down,
                .c = rectangle.right, .d = rectangle.up, .e = rectangle.weight };
            const corner_x = [_]i64{ rectangle.left, rectangle.right, rectangle.left, rectangle.right };
            const corner_y = [_]i64{ rectangle.down, rectangle.down, rectangle.up, rectangle.up };
            for (0..4) |corner| {
                all_x[rectangle_count * 4 + corner] = corner_x[corner];
                all_y[rectangle_count * 4 + corner] = corner_y[corner];
            }
            rectangle_count += 1;
        } else if (kind == 1) {
            if (cursor + 2 > length) return -1;
            const x = packed[cursor];
            const y = packed[cursor + 1];
            cursor += 2;
            if (x < 0 or x > MAX_COORD or y < 0 or y > MAX_COORD) return -1;
            operations[index] = .{ .kind = 1, .a = x, .b = y, .c = 0, .d = 0, .e = 0 };
        } else return -1;
    }
    if (cursor != length) return -1;

    const corner_count = rectangle_count * 4;
    const x_count = sortUnique(&all_x, corner_count);
    const y_count = sortUnique(&all_y, corner_count);
    var present: Presence = @splat(false);
    for (initial[0..n]) |rectangle| registerRectangle(&all_x, x_count, &all_y, y_count, &present, rectangle);
    for (operations[0..q]) |operation| {
        if (operation.kind == 0) registerRectangle(&all_x, x_count, &all_y, y_count, &present,
            Rectangle{ .left = operation.a, .down = operation.b, .right = operation.c,
                .up = operation.d, .weight = operation.e });
    }
    var y_values: NestedValues = @splat(0);
    var y_counts: [MAX_COORDS + 1]usize = @splat(0);
    for (1..x_count + 1) |outer| {
        for (0..y_count) |rank| {
            if (present[outer * MAX_COORDS + rank]) {
                y_values[outer * MAX_COORDS + y_counts[outer]] = rank;
                y_counts[outer] += 1;
            }
        }
    }
    var tree: NestedTree = @splat(0);
    for (initial[0..n]) |rectangle| applyRectangle(&tree, &y_values, &y_counts,
        &all_x, x_count, &all_y, y_count, rectangle);
    var answers: [MAX_Q]i64 = @splat(0);
    var answer_count: usize = 0;
    for (operations[0..q]) |operation| {
        if (operation.kind == 0) {
            applyRectangle(&tree, &y_values, &y_counts, &all_x, x_count, &all_y, y_count,
                Rectangle{ .left = operation.a, .down = operation.b, .right = operation.c,
                    .up = operation.d, .weight = operation.e });
        } else {
            answers[answer_count] = prefixSum(&tree, &y_values, &y_counts,
                &all_x, x_count, &all_y, y_count, operation.a, operation.b);
            answer_count += 1;
        }
    }
    const output_bytes = 8 * answer_count;
    if (output_bytes > 0 and (output == null or capacity < output_bytes)) return -2;
    for (0..answer_count) |index| storeI64Le(output, 8 * index, answers[index]);
    return @intCast(output_bytes);
}
