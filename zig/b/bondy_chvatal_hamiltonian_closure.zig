const MAX_VERTICES: usize = 8;
const MAX_EDGES: usize = 28;
const MAX_INPUT_WORDS: usize = 59;
const MAX_OUTPUT_WORDS: usize = 10;

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn bondy_chvatal_hamiltonian_closure(raw: ?[*]const i64,
    length: usize, output_raw: ?[*]u8, capacity: usize) i64 {
    const input = raw orelse return -1;
    if (length < 2 or length > MAX_INPUT_WORDS) return -1;
    const n_word = input[0];
    const m_word = input[1];
    if (n_word < 3 or n_word > @as(i64, @intCast(MAX_VERTICES)) or m_word < 0 or m_word > @as(i64, @intCast(MAX_EDGES))) return -1;
    const n: usize = @intCast(n_word);
    const m: usize = @intCast(m_word);
    if (m > n * (n - 1) / 2 or length != 2 + 2 * m) return -1;

    var adjacency = [_][MAX_VERTICES]bool{[_]bool{false} ** MAX_VERTICES} ** MAX_VERTICES;
    for (0..m) |edge| {
        const u_word = input[2 + 2 * edge];
        const v_word = input[3 + 2 * edge];
        if (u_word < 0 or u_word >= n_word or v_word < 0 or v_word >= n_word or u_word == v_word) return -1;
        const u: usize = @intCast(u_word);
        const v: usize = @intCast(v_word);
        if (adjacency[u][v]) return -1;
        adjacency[u][v] = true;
        adjacency[v][u] = true;
    }

    var added: i64 = 0;
    while (true) {
        var degree = [_]usize{0} ** MAX_VERTICES;
        for (0..n) |u| {
            for (0..n) |v| {
                if (adjacency[u][v]) degree[u] += 1;
            }
        }
        var chosen_u = n;
        var chosen_v = n;
        for (0..n) |u| {
            if (chosen_u < n) break;
            for (u + 1..n) |v| {
                if (!adjacency[u][v] and degree[u] + degree[v] >= n) {
                    chosen_u = u;
                    chosen_v = v;
                    break;
                }
            }
        }
        if (chosen_u == n) break;
        adjacency[chosen_u][chosen_v] = true;
        adjacency[chosen_v][chosen_u] = true;
        added += 1;
    }

    var staged = [_]i64{0} ** MAX_OUTPUT_WORDS;
    const full_mask = (1 << n) - 1;
    var complete = true;
    for (0..n) |u| {
        var row: usize = 0;
        for (0..n) |v| {
            if (adjacency[u][v]) row |= 1 << v;
        }
        staged[2 + u] = @intCast(row);
        if (row != (full_mask ^ (1 << u))) complete = false;
    }
    staged[0] = if (complete) 1 else 0;
    staged[1] = added;

    const output_bytes = (2 + n) * 8;
    const output = output_raw orelse return -2;
    if (capacity < output_bytes) return -2;
    for (0..2 + n) |word| storeI64Le(output, word * 8, staged[word]);
    return @intCast(output_bytes);
}
