const MAX_VERTICES: usize = 8;
const MAX_EDGES: usize = 16;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_EDGES;

const Adjacency = [MAX_VERTICES]u64;
const Polynomial = [MAX_VERTICES + 1]i64;

fn chromaticPoly(adjacency: Adjacency, n: usize) Polynomial {
    var edge_u = n;
    var edge_v = n;
    for (0..n) |u| {
        if (edge_u == n) {
            for (u + 1..n) |v| {
                if (adjacency[u] & (@as(u64, 1) << @intCast(v))) != 0 {
                    edge_u = u;
                    edge_v = v;
                    break;
                }
            }
        }
    }
    var result: Polynomial = @splat(0);
    if (edge_u == n) {
        result[n] = 1;
        return result;
    }

    var deleted = adjacency;
    deleted[edge_u] &= ~(@as(u64, 1) << @intCast(edge_v));
    deleted[edge_v] &= ~(@as(u64, 1) << @intCast(edge_u));
    const without_edge = chromaticPoly(deleted, n);

    var contracted: Adjacency = @splat(0);
    for (0..n) |left| {
        for (left + 1..n) |right| {
            if (adjacency[left] & (@as(u64, 1) << @intCast(right)) == 0 or (left == edge_u and right == edge_v)) continue;
            var new_left = if (left == edge_v) edge_u else left;
            var new_right = if (right == edge_v) edge_u else right;
            if (new_left > edge_v) new_left -= 1;
            if (new_right > edge_v) new_right -= 1;
            if (new_left != new_right) {
                contracted[new_left] |= @as(u64, 1) << @intCast(new_right);
                contracted[new_right] |= @as(u64, 1) << @intCast(new_left);
            }
        }
    }
    const with_edge_contracted = chromaticPoly(contracted, n - 1);
    for (0..n + 1) |degree| {
        result[degree] = without_edge[degree] - with_edge_contracted[degree];
    }
    return result;
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn chromatic_polynomial(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    const m_value = input[1];
    if (n_value < 0 or n_value > MAX_VERTICES or m_value < 0 or m_value > MAX_EDGES) return -1;
    const n: usize = @intCast(n_value);
    const m: usize = @intCast(m_value);
    if (length != 2 + 2 * m) return -1;

    var adjacency: Adjacency = @splat(0);
    for (0..m) |edge| {
        const u_value = input[2 + 2 * edge];
        const v_value = input[3 + 2 * edge];
        if (u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value or u_value == v_value) return -1;
        const u: usize = @intCast(u_value);
        const v: usize = @intCast(v_value);
        const u_bit = @as(u64, 1) << @intCast(u);
        const v_bit = @as(u64, 1) << @intCast(v);
        if (adjacency[u] & v_bit != 0) return -1;
        adjacency[u] |= v_bit;
        adjacency[v] |= u_bit;
    }

    const output_bytes = 8 * (n + 1);
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    const coefficients = chromaticPoly(adjacency, n);
    for (0..n + 1) |degree| storeI64Le(output, 8 * degree, coefficients[degree]);
    return @intCast(output_bytes);
}
