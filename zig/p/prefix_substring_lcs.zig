const MAX_M: usize = 32;
const MAX_N: usize = 32;
const MAX_Q: usize = 64;
const STRIDE: usize = MAX_N + 1;
const MAX_INPUT: usize = 3 + MAX_M + MAX_N + 3 * MAX_Q;

const Query = struct { a: usize = 0, b: usize = 0, c: usize = 0 };

fn lowbit(value: usize) usize { return value & (0 -% value); }

fn fenwickAdd(tree: *[STRIDE + 1]i32, position: usize, count: usize) void {
    var index = position + 1;
    while (index <= count) {
        tree[index] += 1;
        index += lowbit(index);
    }
}

fn fenwickPrefix(tree: *const [STRIDE + 1]i32, exclusive: usize) i32 {
    var total: i32 = 0;
    var index = exclusive;
    while (index > 0) {
        total += tree[index];
        index -= lowbit(index);
    }
    return total;
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @as(u6, @intCast(byte * 8)));
}

export fn prefix_substring_lcs(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT) return -1;
    const packed = input.?[0..length];
    const m_value, const n_value, const q_value = .{ packed[0], packed[1], packed[2] };
    if (m_value < 1 or m_value > 32 or n_value < 1 or n_value > 32 or q_value < 1 or q_value > 64) return -1;
    const m: usize = @intCast(m_value);
    const n: usize = @intCast(n_value);
    const q: usize = @intCast(q_value);
    if (length != 3 + m + n + 3 * q) return -1;

    var s: [MAX_M]i32 = @splat(0);
    var t: [MAX_N]i32 = @splat(0);
    var offset: usize = 3;
    for (0..m) |index| {
        const code = packed[offset];
        if (code < 97 or code > 122) return -1;
        s[index] = @intCast(code);
        offset += 1;
    }
    for (0..n) |index| {
        const code = packed[offset];
        if (code < 97 or code > 122) return -1;
        t[index] = @intCast(code);
        offset += 1;
    }
    var queries: [MAX_Q]Query = @splat(.{});
    var query_head: [STRIDE * STRIDE]i32 = @splat(-1);
    var query_next: [MAX_Q]i32 = @splat(0);
    for (0..q) |index| {
        const a_value, const b_value, const c_value = .{ packed[offset], packed[offset + 1], packed[offset + 2] };
        if (a_value < 0 or a_value > m_value or b_value < 0 or b_value > c_value or c_value > n_value) return -1;
        queries[index] = .{ .a = @intCast(a_value), .b = @intCast(b_value), .c = @intCast(c_value) };
        const key = queries[index].a * STRIDE + queries[index].b;
        query_next[index] = query_head[key];
        query_head[key] = @intCast(index);
        offset += 3;
    }
    const output_bytes = 8 * q;
    if (output == null or capacity < output_bytes) return -2;

    var horizontal: [STRIDE * STRIDE]i32 = @splat(0);
    var vertical: [STRIDE * STRIDE]i32 = @splat(0);
    for (0..n + 1) |j| horizontal[j] = @intCast(j);
    var i: usize = 1;
    while (i <= m) : (i += 1) {
        var j: usize = 1;
        while (j <= n) : (j += 1) {
            const above = horizontal[(i - 1) * STRIDE + j];
            const left = vertical[i * STRIDE + j - 1];
            if (s[i - 1] == t[j - 1]) {
                horizontal[i * STRIDE + j] = left;
                vertical[i * STRIDE + j] = above;
            } else {
                horizontal[i * STRIDE + j] = @max(above, left);
                vertical[i * STRIDE + j] = @min(above, left);
            }
        }
    }

    var answers: [MAX_Q]i32 = @splat(0);
    var a: usize = 0;
    while (a <= m) : (a += 1) {
        var value_head: [STRIDE]i32 = @splat(-1);
        var value_next: [STRIDE]i32 = @splat(0);
        for (0..n + 1) |position| {
            const value: usize = @intCast(horizontal[a * STRIDE + position]);
            value_next[position] = value_head[value];
            value_head[value] = @intCast(position);
        }
        var fenwick: [STRIDE + 1]i32 = @splat(0);
        var b: usize = 0;
        while (b <= n) : (b += 1) {
            var position = value_head[b];
            while (position >= 0) {
                fenwickAdd(&fenwick, @intCast(position), n + 1);
                position = value_next[@intCast(position)];
            }
            var query_index = query_head[a * STRIDE + b];
            while (query_index >= 0) {
                const qi: usize = @intCast(query_index);
                const query = queries[qi];
                answers[qi] = fenwickPrefix(&fenwick, query.c + 1) - fenwickPrefix(&fenwick, query.b + 1);
                query_index = query_next[qi];
            }
        }
    }
    for (0..q) |index| storeI64Le(output.?, 8 * index, @intCast(answers[index]));
    return @intCast(output_bytes);
}
