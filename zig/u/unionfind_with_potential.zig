const MAX_N: usize = 64;
const MAX_Q: usize = 256;
const MODULUS: i64 = 998_244_353;

fn normalize(value_input: i64) i64 {
    const value = @mod(value_input, MODULUS);
    return if (value < 0) value + MODULUS else value;
}

fn findRoot(parent: *[MAX_N]usize, difference: *[MAX_N]i64, item: usize) usize {
    if (parent[item] != item) {
        const old_parent = parent[item];
        const root = findRoot(parent, difference, old_parent);
        difference[item] = normalize(difference[item] + difference[old_parent]);
        parent[item] = root;
    }
    return parent[item];
}

fn writeI64(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn unionfind_with_potential(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 6 or length > 2 + 4 * MAX_Q) return -1;
    const n_value = input[0];
    const q_value = input[1];
    if (n_value < 1 or n_value > @as(i64, @intCast(MAX_N)) or
        q_value < 1 or q_value > @as(i64, @intCast(MAX_Q))) return -1;
    const n: usize = @intCast(n_value);
    const q: usize = @intCast(q_value);
    if (length != 2 + 4 * q) return -1;
    for (0..q) |operation| {
        const position = 2 + 4 * operation;
        const kind = input[position];
        const u = input[position + 1];
        const v = input[position + 2];
        const x = input[position + 3];
        if (u < 0 or u >= n_value or v < 0 or v >= n_value) return -1;
        if (kind == 0) {
            if (x < 0 or x >= MODULUS) return -1;
        } else if (kind == 1) {
            if (x != 0) return -1;
        } else return -1;
    }
    const required = 8 * q;
    if (output == null or capacity < required) return -2;

    var parent: [MAX_N]usize = undefined;
    var set_size: [MAX_N]usize = undefined;
    var difference: [MAX_N]i64 = @splat(0);
    for (0..n) |item| { parent[item] = item; set_size[item] = 1; }
    for (0..q) |operation| {
        const position = 2 + 4 * operation;
        const kind = input[position];
        const u: usize = @intCast(input[position + 1]);
        const v: usize = @intCast(input[position + 2]);
        const x = input[position + 3];
        const root_u = findRoot(&parent, &difference, u);
        const root_v = findRoot(&parent, &difference, v);
        var answer: i64 = 0;
        if (kind == 1) {
            answer = if (root_u == root_v) normalize(difference[u] - difference[v]) else -1;
        } else if (root_u == root_v) {
            answer = if (normalize(difference[u] - difference[v]) == x) 1 else 0;
        } else if (set_size[root_u] < set_size[root_v]) {
            parent[root_u] = root_v;
            difference[root_u] = normalize(x - difference[u] + difference[v]);
            set_size[root_v] += set_size[root_u];
            answer = 1;
        } else {
            parent[root_v] = root_u;
            difference[root_v] = normalize(difference[u] - difference[v] - x);
            set_size[root_u] += set_size[root_v];
            answer = 1;
        }
        writeI64(output, 8 * operation, answer);
    }
    return @intCast(required);
}
