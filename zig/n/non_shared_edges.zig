const MAX_LEAVES: usize = 8;
const MAX_EDGES: usize = 13;
const MAX_INPUT: usize = 27;

fn store_i64_le(output: [*]u8, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[byte] = @truncate(bits >> @intCast(8 * byte));
}

fn bit_count(value: u64, n: usize) usize {
    var count: usize = 0;
    for (0..n) |bit| count += @intCast((value >> @intCast(bit)) & 1);
    return count;
}

fn valid_tree(input: [*]const i64, offset: usize, n: usize, edges: usize) bool {
    var masks: [MAX_EDGES]u64 = @splat(0);
    var internal: [MAX_EDGES]u64 = @splat(0);
    var internal_count: usize = 0;
    const universe = (@as(u64, 1) << @intCast(n)) - 1;
    for (0..edges) |edge| {
        const raw = input[offset + edge];
        if (raw <= 0 or @as(u64, @intCast(raw)) >= universe or @mod(raw, 2) != 0) return false;
        masks[edge] = @intCast(raw);
        for (0..edge) |earlier| if (masks[earlier] == masks[edge]) return false;
        const size = bit_count(masks[edge], n);
        if (size == 1 or size == n - 1) {
            if (size == n - 1 and masks[edge] != (universe ^ 1)) return false;
        } else if (size >= 2 and size <= n - 2) {
            internal[internal_count] = masks[edge];
            internal_count += 1;
        } else return false;
    }
    if (internal_count != n - 3) return false;
    for (1..n) |leaf| {
        const pendant = @as(u64, 1) << @intCast(leaf);
        var found: usize = 0;
        for (0..edges) |edge| if (masks[edge] == pendant) { found += 1; };
        if (found != 1) return false;
    }
    var root_pendant: usize = 0;
    for (0..edges) |edge| if (masks[edge] == (universe ^ 1)) { root_pendant += 1; };
    if (root_pendant != 1) return false;
    for (0..internal_count) |i| {
        for (i + 1..internal_count) |j| {
            const intersection = internal[i] & internal[j];
            if (intersection != 0 and intersection != internal[i] and intersection != internal[j]) return false;
        }
    }
    return true;
}

export fn non_shared_edges(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 7 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 3 or input[0] > @as(i64, MAX_LEAVES)) return -1;
    const leaves: usize = @intCast(input[0]);
    const edges = 2 * leaves - 3;
    if (length != 1 + 2 * edges) return -1;
    const second = 1 + edges;
    if (!valid_tree(input, 1, leaves, edges) or !valid_tree(input, second, leaves, edges)) return -1;
    var shared: i64 = 0;
    for (0..edges) |left| {
        for (0..edges) |right| {
            if (input[1 + left] == input[second + right]) { shared += 1; break; }
        }
    }
    if (output_opt == null or capacity < 8) return -2;
    const output = output_opt.?;
    var staged: [8]u8 = @splat(0);
    store_i64_le(&staged, @as(i64, @intCast(edges)) - shared);
    for (0..8) |byte| output[byte] = staged[byte];
    return 8;
}
