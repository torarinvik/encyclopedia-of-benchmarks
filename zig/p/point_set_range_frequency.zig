const MAX_N: usize = 64;
const MAX_Q: usize = 64;
const MAX_VALUES: usize = MAX_N + MAX_Q;
const STRIDE: usize = MAX_N + 1;
const MAX_TREE: usize = MAX_VALUES * STRIDE;
const MAX_PARSEABLE_INPUT: usize = 2 + MAX_N + 4 * MAX_Q + 1;
const MAX_VALUE: i64 = 1_000_000;

const Operation = struct { kind: i64 = 0, a: i64 = 0, b: i64 = 0, c: i64 = 0 };

fn lowbit(value: usize) usize { return value & (~value + 1); }

fn lowerBound(values: []const i64, target: i64) usize {
    var left: usize = 0;
    var right = values.len;
    while (left < right) {
        const middle = left + (right - left) / 2;
        if (values[middle] < target) left = middle + 1 else right = middle;
    }
    return left;
}

fn sortUnique(values: *[MAX_VALUES]i64, count: usize) usize {
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

fn fenwickAdd(tree: *[MAX_TREE]i64, value_id: usize, position: usize, n: usize, delta: i64) void {
    var index = position + 1;
    const row = value_id * STRIDE;
    while (index <= n) {
        tree[row + index] += delta;
        index += lowbit(index);
    }
}

fn fenwickPrefix(tree: *const [MAX_TREE]i64, value_id: usize, count: usize) i64 {
    var index = count;
    const row = value_id * STRIDE;
    var total: i64 = 0;
    while (index > 0) {
        total += tree[row + index];
        index -= lowbit(index);
    }
    return total;
}

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn point_set_range_frequency(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_PARSEABLE_INPUT) return -1;
    const packed = input[0..length];
    const n_value = packed[0];
    const q_value = packed[1];
    if (n_value < 1 or n_value > @as(i64, MAX_N) or q_value < 0 or q_value > @as(i64, MAX_Q)) return -1;
    const n: usize = @intCast(n_value);
    const q: usize = @intCast(q_value);
    if (2 + n > length) return -1;
    var values: [MAX_VALUES]i64 = @splat(0);
    var initial: [MAX_N]i64 = @splat(0);
    var operations: [MAX_Q]Operation = @splat(.{});
    var value_count: usize = 0;
    for (0..n) |index| {
        const value = packed[2 + index];
        if (value < 0 or value > MAX_VALUE) return -1;
        initial[index] = value;
        values[value_count] = value;
        value_count += 1;
    }
    var cursor: usize = 2 + n;
    var query_count: usize = 0;
    for (0..q) |index| {
        if (cursor >= length) return -1;
        const kind = packed[cursor];
        cursor += 1;
        if (kind == 0) {
            if (cursor + 2 > length) return -1;
            const position = packed[cursor];
            const value = packed[cursor + 1];
            cursor += 2;
            if (position < 0 or position >= n_value or value < 0 or value > MAX_VALUE) return -1;
            operations[index] = .{ .kind = kind, .a = position, .b = value };
            values[value_count] = value;
            value_count += 1;
        } else if (kind == 1) {
            if (cursor + 3 > length) return -1;
            const left = packed[cursor];
            const right = packed[cursor + 1];
            const value = packed[cursor + 2];
            cursor += 3;
            if (left < 0 or left > right or right > n_value or value < 0 or value > MAX_VALUE) return -1;
            operations[index] = .{ .kind = kind, .a = left, .b = right, .c = value };
            query_count += 1;
        } else return -1;
    }
    if (cursor != length) return -1;
    const output_bytes = 8 * query_count;
    if (output_bytes > 0 and (output == null or capacity < output_bytes)) return -2;

    const unique_count = sortUnique(&values, value_count);
    var tree: [MAX_TREE]i64 = @splat(0);
    var current: [MAX_N]usize = @splat(0);
    for (0..n) |index| {
        current[index] = lowerBound(values[0..unique_count], initial[index]);
        fenwickAdd(&tree, current[index], index, n, 1);
    }
    var answer: usize = 0;
    for (operations[0..q]) |operation| {
        if (operation.kind == 0) {
            const position: usize = @intCast(operation.a);
            const next = lowerBound(values[0..unique_count], operation.b);
            if (current[position] != next) {
                fenwickAdd(&tree, current[position], position, n, -1);
                fenwickAdd(&tree, next, position, n, 1);
                current[position] = next;
            }
        } else {
            const id = lowerBound(values[0..unique_count], operation.c);
            var count: i64 = 0;
            if (id < unique_count and values[id] == operation.c) {
                count = fenwickPrefix(&tree, id, @intCast(operation.b)) -
                        fenwickPrefix(&tree, id, @intCast(operation.a));
            }
            storeI64Le(output, 8 * answer, count);
            answer += 1;
        }
    }
    return @intCast(output_bytes);
}
