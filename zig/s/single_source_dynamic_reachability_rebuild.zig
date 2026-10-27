const MAX_N: usize = 8;
const MAX_INITIAL_EDGES: usize = 16;
const MAX_OPERATIONS: usize = 20;
const MAX_OUTPUT_BYTES: usize = 168;

fn store_i64_le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn rebuild_reachable(n: usize, source: usize, adjacency: *[MAX_N][MAX_N]bool,
    reachable: *[MAX_N]bool) void {
    var queue: [MAX_N]usize = @splat(0);
    var head: usize = 0;
    var tail: usize = 0;
    for (0..n) |i| reachable.*[i] = false;
    reachable.*[source] = true;
    queue[tail] = source; tail += 1;
    while (head < tail) {
        const u = queue[head]; head += 1;
        for (0..n) |v| {
            if (adjacency.*[u][v] and !reachable.*[v]) {
                reachable.*[v] = true;
                queue[tail] = v; tail += 1;
            }
        }
    }
}

export fn single_source_dynamic_reachability_rebuild(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 4 or length > 97) return -1;
    const input = input_opt.?;
    const n_raw = input[0];
    const source_raw = input[1];
    const edge_count_raw = input[2];
    if (n_raw < 2 or n_raw > @as(i64, MAX_N) or source_raw < 0 or source_raw >= n_raw or
            edge_count_raw < 0 or edge_count_raw > @as(i64, MAX_INITIAL_EDGES)) return -1;
    const n: usize = @intCast(n_raw);
    const source: usize = @intCast(source_raw);
    const edge_count: usize = @intCast(edge_count_raw);
    const operation_count_offset = 3 + 2 * edge_count;
    if (length <= operation_count_offset) return -1;
    const operation_count_raw = input[operation_count_offset];
    if (operation_count_raw < 0 or operation_count_raw > @as(i64, MAX_OPERATIONS) or
            length != operation_count_offset + 1 + 3 * @as(usize, @intCast(operation_count_raw))) return -1;
    const operation_count: usize = @intCast(operation_count_raw);

    var adjacency: [MAX_N][MAX_N]bool = @splat(@splat(false));
    var cursor: usize = 3;
    for (0..edge_count) |_| {
        const u_raw = input[cursor]; const v_raw = input[cursor + 1]; cursor += 2;
        if (u_raw < 0 or u_raw >= n_raw or v_raw < 0 or v_raw >= n_raw) return -1;
        const u: usize = @intCast(u_raw); const v: usize = @intCast(v_raw);
        if (adjacency[u][v]) return -1;
        adjacency[u][v] = true;
    }
    cursor = operation_count_offset + 1;
    var op_type: [MAX_OPERATIONS]i64 = @splat(0);
    var op_u: [MAX_OPERATIONS]usize = @splat(0);
    var op_v: [MAX_OPERATIONS]usize = @splat(0);
    var query_count: usize = 0;
    for (0..operation_count) |i| {
        const kind = input[cursor]; const u_raw = input[cursor + 1]; const v_raw = input[cursor + 2]; cursor += 3;
        if (kind == 0 or kind == 1) {
            if (u_raw < 0 or u_raw >= n_raw or v_raw < 0 or v_raw >= n_raw) return -1;
        } else if (kind == 2) {
            if (u_raw < 0 or u_raw >= n_raw or v_raw != 0) return -1;
            query_count += 1;
        } else return -1;
        op_type[i] = kind;
        op_u[i] = @intCast(u_raw);
        op_v[i] = @intCast(v_raw);
    }

    const output_bytes = 8 * (1 + query_count);
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    var reachable: [MAX_N]bool = @splat(false);
    var answers: [MAX_OPERATIONS]i64 = @splat(0);
    var answer_count: usize = 0;
    rebuild_reachable(n, source, &adjacency, &reachable);
    for (0..operation_count) |i| {
        if (op_type[i] == 0) {
            adjacency[op_u[i]][op_v[i]] = true;
            rebuild_reachable(n, source, &adjacency, &reachable);
        } else if (op_type[i] == 1) {
            adjacency[op_u[i]][op_v[i]] = false;
            rebuild_reachable(n, source, &adjacency, &reachable);
        } else {
            answers[answer_count] = if (reachable[op_u[i]]) 1 else 0;
            answer_count += 1;
        }
    }
    var staged: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    store_i64_le(&staged, 0, @intCast(answer_count));
    for (0..answer_count) |i| store_i64_le(&staged, 8 * (i + 1), answers[i]);
    for (0..output_bytes) |byte| output[byte] = staged[byte];
    return @intCast(output_bytes);
}
