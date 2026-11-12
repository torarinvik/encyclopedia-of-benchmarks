const MAX_N: usize = 256;
const MAX_Q: usize = 256;
const MAX_BASE: usize = 256;
const MAX_TREE: usize = 2 * MAX_BASE;
const MAX_PARSEABLE_INPUT: usize = 2 + MAX_N + 5 * MAX_Q + 1;
const MOD: i64 = 998244353;

const Operation = struct { kind: i64 = 0, left: i64 = 0, right: i64 = 0, multiplier: i64 = 0, offset: i64 = 0 };

fn applyTag(mul: *[MAX_TREE]i64, add: *[MAX_TREE]i64, node: usize, multiplier: i64, offset: i64) void {
    add[node] = @mod(multiplier * add[node] + offset, MOD);
    mul[node] = @mod(multiplier * mul[node], MOD);
}

fn push(mul: *[MAX_TREE]i64, add: *[MAX_TREE]i64, node: usize) void {
    if (mul[node] != 1 or add[node] != 0) {
        const multiplier = mul[node];
        const offset = add[node];
        applyTag(mul, add, 2 * node, multiplier, offset);
        applyTag(mul, add, 2 * node + 1, multiplier, offset);
        mul[node] = 1;
        add[node] = 0;
    }
}

fn rangeApply(mul: *[MAX_TREE]i64, add: *[MAX_TREE]i64, node: usize,
    segment_left: usize, segment_right: usize, left: usize, right: usize,
    multiplier: i64, offset: i64) void {
    if (right <= segment_left or segment_right <= left) return;
    if (left <= segment_left and segment_right <= right) {
        applyTag(mul, add, node, multiplier, offset);
        return;
    }
    push(mul, add, node);
    const middle = segment_left + (segment_right - segment_left) / 2;
    rangeApply(mul, add, 2 * node, segment_left, middle, left, right, multiplier, offset);
    rangeApply(mul, add, 2 * node + 1, middle, segment_right, left, right, multiplier, offset);
}

fn pointGet(mul: *[MAX_TREE]i64, add: *[MAX_TREE]i64, initial: *const [MAX_N]i64,
    node: usize, segment_left: usize, segment_right: usize, index: usize) i64 {
    if (segment_right - segment_left == 1)
        return @mod(mul[node] * initial[index] + add[node], MOD);
    push(mul, add, node);
    const middle = segment_left + (segment_right - segment_left) / 2;
    if (index < middle)
        return pointGet(mul, add, initial, 2 * node, segment_left, middle, index);
    return pointGet(mul, add, initial, 2 * node + 1, middle, segment_right, index);
}

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn range_affine_point_get(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_PARSEABLE_INPUT) return -1;
    const packed = input[0..length];
    const n_value = packed[0];
    const q_value = packed[1];
    if (n_value < 1 or n_value > @as(i64, MAX_N) or q_value < 0 or q_value > @as(i64, MAX_Q)) return -1;
    const n: usize = @intCast(n_value);
    const q: usize = @intCast(q_value);
    if (2 + n > length) return -1;
    var initial: [MAX_N]i64 = @splat(0);
    var operations: [MAX_Q]Operation = @splat(.{});
    for (0..n) |index| {
        initial[index] = packed[2 + index];
        if (initial[index] < 0 or initial[index] >= MOD) return -1;
    }
    var cursor: usize = 2 + n;
    var query_count: usize = 0;
    for (0..q) |index| {
        if (cursor >= length) return -1;
        const kind = packed[cursor];
        cursor += 1;
        if (kind == 0) {
            if (cursor + 4 > length) return -1;
            const left = packed[cursor];
            const right = packed[cursor + 1];
            const multiplier = packed[cursor + 2];
            const offset = packed[cursor + 3];
            cursor += 4;
            if (left < 0 or left >= right or right > n_value or multiplier < 1 or multiplier >= MOD or offset < 0 or offset >= MOD) return -1;
            operations[index] = .{ .kind = kind, .left = left, .right = right, .multiplier = multiplier, .offset = offset };
        } else if (kind == 1) {
            if (cursor >= length) return -1;
            const point = packed[cursor];
            cursor += 1;
            if (point < 0 or point >= n_value) return -1;
            operations[index] = .{ .kind = kind, .left = point };
            query_count += 1;
        } else return -1;
    }
    if (cursor != length) return -1;
    const output_bytes = 8 * query_count;
    if (output_bytes > 0 and (output == null or capacity < output_bytes)) return -2;

    var base: usize = 1;
    while (base < n) base *= 2;
    var mul: [MAX_TREE]i64 = @splat(1);
    var add: [MAX_TREE]i64 = @splat(0);
    var answer: usize = 0;
    for (operations[0..q]) |operation| {
        if (operation.kind == 0) {
            rangeApply(&mul, &add, 1, 0, base, @intCast(operation.left),
                @intCast(operation.right), operation.multiplier, operation.offset);
        } else {
            const value = pointGet(&mul, &add, &initial, 1, 0, base, @intCast(operation.left));
            storeI64Le(output, 8 * answer, value);
            answer += 1;
        }
    }
    return @intCast(output_bytes);
}
