const MAX_N: usize = 256;
const MAX_Q: usize = 256;
const MAX_INPUT_LENGTH: usize = 4 + MAX_N + 3 * MAX_Q + 1;
const FNV_OFFSET: u64 = 0xcbf29ce484222325;
const FNV_PRIME: u64 = 0x100000001b3;

fn queryBefore(a: usize, b: usize, lefts: *const [MAX_Q]i32, rights: *const [MAX_Q]i32, block_size: usize) bool {
    const block_a = @divTrunc(lefts[a], @as(i32, @intCast(block_size)));
    const block_b = @divTrunc(lefts[b], @as(i32, @intCast(block_size)));
    if (block_a != block_b) return block_a < block_b;
    if (@as(u32, @bitCast(block_a)) & 1 != 0) return rights[a] < rights[b];
    return rights[a] > rights[b];
}

fn hashResults(operation: u8, count: usize, results: []const i32) i64 {
    var hash = FNV_OFFSET;
    const q: u16 = @intCast(count);
    hash = (hash ^ operation) *% FNV_PRIME;
    hash = (hash ^ @as(u64, @truncate(q))) *% FNV_PRIME;
    hash = (hash ^ @as(u64, @truncate(q >> 8))) *% FNV_PRIME;
    for (results) |result| {
        const bits: u32 = @bitCast(result);
        for (0..4) |byte_index| hash = (hash ^ @as(u64, @truncate(bits >> @intCast(byte_index * 8)))) *% FNV_PRIME;
    }
    return @intCast(hash & 0x7fff_ffff_ffff_ffff);
}

fn execute(input: []const i64) ?i64 {
    if (input.len < 4 or input.len > MAX_INPUT_LENGTH) return null;
    const operation = input[0];
    const n64 = input[1];
    const q64 = input[2];
    const target64 = input[3];
    if ((operation != 0 and operation != 1) or n64 < 1 or n64 > @as(i64, MAX_N)
        or q64 < 0 or q64 > @as(i64, MAX_Q) or target64 < -1_000_000 or target64 > 1_000_000
        or input.len != 4 + @as(usize, @intCast(n64)) + 3 * @as(usize, @intCast(q64))) return null;
    const n: usize = @intCast(n64);
    const q: usize = @intCast(q64);
    const target: i32 = @intCast(target64);
    var values: [MAX_N]i32 = [_]i32{0} ** MAX_N;
    for (0..n) |index| {
        if (input[4 + index] < -1_000_000 or input[4 + index] > 1_000_000) return null;
        values[index] = @intCast(input[4 + index]);
    }

    var lefts: [MAX_Q]i32 = [_]i32{0} ** MAX_Q;
    var rights: [MAX_Q]i32 = [_]i32{0} ** MAX_Q;
    var indices: [MAX_Q]i32 = [_]i32{0} ** MAX_Q;
    var order: [MAX_Q]usize = [_]usize{0} ** MAX_Q;
    var seen: [MAX_Q]bool = [_]bool{false} ** MAX_Q;
    const offset = 4 + n;
    for (0..q) |query| {
        const left = input[offset + 3 * query];
        const right = input[offset + 3 * query + 1];
        const index = input[offset + 3 * query + 2];
        if (left < 0 or right < left or right >= n64 or index < 0 or index >= q64) return null;
        const index_usize: usize = @intCast(index);
        if (seen[index_usize]) return null;
        lefts[query] = @intCast(left);
        rights[query] = @intCast(right);
        indices[query] = @intCast(index);
        seen[index_usize] = true;
        order[query] = query;
    }

    var block_size: usize = 1;
    while ((block_size + 1) * (block_size + 1) <= n) block_size += 1;
    for (1..q) |query| {
        const current = order[query];
        var position = query;
        while (position > 0 and queryBefore(current, order[position - 1], &lefts, &rights, block_size)) {
            order[position] = order[position - 1];
            position -= 1;
        }
        order[position] = current;
    }

    var results: [MAX_Q]i32 = [_]i32{0} ** MAX_Q;
    var current_left: i32 = 0;
    var current_right: i32 = -1;
    var aggregate: i32 = 0;
    for (0..q) |sorted| {
        const query = order[sorted];
        const left = lefts[query];
        const right = rights[query];
        if (operation == 0) {
            while (current_right < right) { current_right += 1; aggregate += values[@intCast(current_right)]; }
            while (current_right > right) { aggregate -= values[@intCast(current_right)]; current_right -= 1; }
            while (current_left < left) { aggregate -= values[@intCast(current_left)]; current_left += 1; }
            while (current_left > left) { current_left -= 1; aggregate += values[@intCast(current_left)]; }
        } else {
            while (current_right < right) { current_right += 1; if (values[@intCast(current_right)] == target) aggregate += 1; }
            while (current_right > right) { if (values[@intCast(current_right)] == target) aggregate -= 1; current_right -= 1; }
            while (current_left < left) { if (values[@intCast(current_left)] == target) aggregate -= 1; current_left += 1; }
            while (current_left > left) { current_left -= 1; if (values[@intCast(current_left)] == target) aggregate += 1; }
        }
        results[@intCast(indices[query])] = aggregate;
    }
    return hashResults(@intCast(operation), q, results[0..q]);
}

export fn mos_algorithm(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 4 or length > MAX_INPUT_LENGTH) return -1;
    return execute(input[0..length]) orelse -1;
}
