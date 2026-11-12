const max_n: usize = 64;
const max_q: usize = 64;
const max_levels: usize = 6;
const max_input_values: usize = 2 + max_n + 3 * max_q;
const modulus: i64 = 998244353;
const Layers = [max_levels][max_n]usize;

fn normalize(value: i64) i64 {
    const reduced = @rem(value, modulus);
    return if (reduced < 0) reduced + modulus else reduced;
}

fn findRoot(parent: *Layers, level: usize, item: usize) usize {
    if (parent[level][item] != item) {
        parent[level][item] = findRoot(parent, level, parent[level][item]);
    }
    return parent[level][item];
}

fn mergeInner(level: usize, left: usize, right: usize, parent: *Layers,
    set_size: *Layers, weight: *[max_n]i64, pair_sum: *i64) void {
    var root_left = findRoot(parent, level, left);
    var root_right = findRoot(parent, level, right);
    if (root_left == root_right) return;
    if (set_size[level][root_left] < set_size[level][root_right]) {
        const temporary = root_left;
        root_left = root_right;
        root_right = temporary;
    }
    parent[level][root_right] = root_left;
    set_size[level][root_left] += set_size[level][root_right];
    if (level == 0) {
        pair_sum.* = normalize(pair_sum.* + weight[root_left] * weight[root_right]);
        weight[root_left] = normalize(weight[root_left] + weight[root_right]);
        return;
    }
    const half = @as(usize, 1) << @intCast(level - 1);
    mergeInner(level - 1, left, right, parent, set_size, weight, pair_sum);
    mergeInner(level - 1, left + half, right + half, parent, set_size, weight, pair_sum);
}

fn floorLog2(value: usize) usize {
    var remaining = value;
    var level: usize = 0;
    while (remaining > 1) : (level += 1) remaining >>= 1;
    return level;
}

fn mergeRanges(length: usize, left: usize, right: usize, parent: *Layers,
    set_size: *Layers, weight: *[max_n]i64, pair_sum: *i64) void {
    if (length == 0) return;
    const level = floorLog2(length - 1);
    const block = @as(usize, 1) << @intCast(level);
    mergeInner(level, left, right, parent, set_size, weight, pair_sum);
    mergeInner(level, left + length - block, right + length - block,
        parent, set_size, weight, pair_sum);
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn range_parallel_unionfind(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 6 or length > max_input_values) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    const q_value = input[1];
    if (n_value < 1 or n_value > @as(i64, @intCast(max_n)) or
        q_value < 1 or q_value > @as(i64, @intCast(max_q))) return -1;
    const n: usize = @intCast(n_value);
    const q: usize = @intCast(q_value);
    if (length != 2 + n + 3 * q) return -1;
    for (0..n) |item| {
        if (input[2 + item] < 0 or input[2 + item] >= modulus) return -1;
    }
    const operations_at = 2 + n;
    for (0..q) |operation| {
        const position = operations_at + 3 * operation;
        const span = input[position];
        const left = input[position + 1];
        const right = input[position + 2];
        if (span < 0 or span > n_value or left < 0 or right < 0 or
            left > n_value - span or right > n_value - span) return -1;
    }
    const required = 8 * q;
    if (output_opt == null or capacity < required) return -2;

    var parent: Layers = undefined;
    var set_size: Layers = undefined;
    var weight: [max_n]i64 = undefined;
    for (0..max_levels) |level| {
        const block = @as(usize, 1) << @intCast(level);
        if (block > n) break;
        for (0..n - block + 1) |start| {
            parent[level][start] = start;
            set_size[level][start] = 1;
        }
    }
    for (0..n) |item| weight[item] = input[2 + item];
    var pair_sum: i64 = 0;
    const output = output_opt.?;
    for (0..q) |operation| {
        const position = operations_at + 3 * operation;
        mergeRanges(@intCast(input[position]), @intCast(input[position + 1]),
            @intCast(input[position + 2]), &parent, &set_size, &weight, &pair_sum);
        storeI64Le(output, 8 * operation, pair_sum);
    }
    return @intCast(required);
}
