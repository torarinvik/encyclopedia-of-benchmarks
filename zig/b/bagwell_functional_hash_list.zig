const Starts = [_]usize{ 0, 8, 24 };
const Sides = [_]usize{ 8, 16, 32 };

fn putI64Le(output: [*c]u8, at: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| output[at + b] = @truncate(bits >> @intCast(8 * b));
}

pub export fn bagwell_functional_hash_list(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 131) return -1;
    const nv = input[0];
    if (nv < 0 or nv > 32) return -1;
    const n: usize = @intCast(nv);
    const q_at = 1 + 2 * n;
    if (q_at >= length) return -1;
    const qv = input[q_at];
    if (qv < 1 or qv > 32) return -1;
    const q: usize = @intCast(qv);
    const query_at = q_at + 1;
    if (length != 2 + 2 * n + 2 * q) return -1;
    for (0..n) |i| {
        if (input[1+2*i] < -2147483648 or input[1+2*i] > 2147483647 or
            input[2+2*i] < -2147483648 or input[2+2*i] > 2147483647) return -1;
    }
    for (0..q) |j| {
        const root = input[query_at+2*j];
        const key = input[query_at+2*j+1];
        if (root < 0 or root > nv or key < -2147483648 or key > 2147483647) return -1;
    }
    const output_bytes = 8 * q;
    if (output == null or capacity < output_bytes) return -2;

    var keys: [56]i64 = @splat(0);
    var values: [56]i64 = @splat(0);
    var next: [56]i32 = @splat(-1);
    var heads: [56]i32 = @splat(-1);
    var prev: [3]i32 = @splat(-1);
    var root_block: [33]i32 = @splat(-1);
    var root_offset: [33]i32 = @splat(-1);
    var current: usize = 0;
    for (0..n) |i| {
        if (i == 8 or i == 24) { prev[current+1] = @intCast(current); current += 1; }
        const offset = i - Starts[current];
        const slot = Starts[current] + offset;
        const hash: u32 = @truncate(@as(u64, @bitCast(input[1+2*i])));
        const bucket_slot = Starts[current] + @as(usize, hash & @as(u32, @intCast(Sides[current]-1)));
        keys[slot] = input[1+2*i];
        values[slot] = input[2+2*i];
        next[slot] = heads[bucket_slot];
        heads[bucket_slot] = @intCast(offset);
        root_block[i+1] = @intCast(current);
        root_offset[i+1] = @intCast(offset);
    }
    for (0..q) |j| {
        const root: usize = @intCast(input[query_at+2*j]);
        const key = input[query_at+2*j+1];
        var block = root_block[root];
        const limit = root_offset[root];
        var answer: i64 = -9223372036854775807 - 1;
        if (block >= 0) {
            const hash: u32 = @truncate(@as(u64, @bitCast(key)));
            var first = true;
            while (block >= 0 and answer == -9223372036854775807 - 1) {
                const b: usize = @intCast(block);
                const bucket_slot = Starts[b] + @as(usize, hash & @as(u32, @intCast(Sides[b]-1)));
                var chain = heads[bucket_slot];
                while (chain >= 0) {
                    const slot = Starts[b] + @as(usize, @intCast(chain));
                    if ((!first or chain <= limit) and keys[slot] == key) { answer = values[slot]; break; }
                    chain = next[slot];
                }
                block = prev[b];
                first = false;
            }
        }
        putI64Le(output, 8*j, answer);
    }
    return @intCast(output_bytes);
}
