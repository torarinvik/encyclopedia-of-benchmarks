const MAX_N: usize = 8;
const MAX_M: usize = 12;
const MAX_INPUT: usize = 111;
const MAX_PARSEABLE: usize = 112;
const BUCKET_COUNT: usize = 25;
const MAX_BUCKET_GAIN: i64 = 12;

fn cut(mask: i64, edge_count: usize, degrees: *const [MAX_M]usize,
    vertices: *const [MAX_M * MAX_N]usize) usize {
    var count: usize = 0;
    for (0..edge_count) |edge| {
        var in_a = false;
        var in_b = false;
        for (0..degrees.*[edge]) |slot| {
            const vertex = vertices.*[edge * MAX_N + slot];
            if (((mask >> @intCast(vertex)) & 1) != 0) {
                in_a = true;
            } else {
                in_b = true;
            }
        }
        if (in_a and in_b) count += 1;
    }
    return count;
}

fn gain(mask: i64, vertex: usize, edge_count: usize,
    degrees: *const [MAX_M]usize, vertices: *const [MAX_M * MAX_N]usize) i64 {
    var total: i64 = 0;
    const vertex_bit = @as(i64, 1) << @intCast(vertex);
    const in_a_now = (mask & vertex_bit) != 0;
    for (0..edge_count) |edge| {
        var contains_vertex = false;
        var other_a = false;
        var other_b = false;
        for (0..degrees.*[edge]) |slot| {
            const member = vertices.*[edge * MAX_N + slot];
            if (member == vertex) {
                contains_vertex = true;
            } else if (((mask >> @intCast(member)) & 1) != 0) {
                other_a = true;
            } else {
                other_b = true;
            }
        }
        if (contains_vertex) {
            const before_cut = (other_a or in_a_now) and (other_b or !in_a_now);
            const after_cut = if (in_a_now) other_a else other_b;
            if (before_cut) total += 1;
            if (after_cut) total -= 1;
        }
    }
    return total;
}

fn execute(values: []const i64) ?i64 {
    if (values.len < 3 or values.len > MAX_PARSEABLE) return null;
    const n_value = values[0];
    const m_value = values[1];
    var mask = values[2];
    if (n_value < 4 or n_value > @as(i64, @intCast(MAX_N)) or @rem(n_value, 2) != 0 or
        m_value < 0 or m_value > @as(i64, @intCast(MAX_M))) return null;
    const n: usize = @intCast(n_value);
    const edge_count: usize = @intCast(m_value);
    if (mask < 0 or mask >= (@as(i64, 1) << @intCast(n))) return null;
    var initial_a: usize = 0;
    for (0..n) |vertex| {
        if (((mask >> @intCast(vertex)) & 1) != 0) initial_a += 1;
    }
    if (initial_a != n / 2) return null;

    var degrees: [MAX_M]usize = @splat(0);
    var vertices: [MAX_M * MAX_N]usize = @splat(0);
    var position: usize = 3;
    for (0..edge_count) |edge| {
        if (position >= values.len) return null;
        const degree_value = values[position];
        if (degree_value < 2 or degree_value > @as(i64, @intCast(n))) return null;
        const degree: usize = @intCast(degree_value);
        if (position + 1 + degree > values.len) return null;
        var previous_vertex: i64 = -1;
        for (0..degree) |slot| {
            const vertex_value = values[position + 1 + slot];
            if (vertex_value < 0 or vertex_value >= @as(i64, @intCast(n)) or vertex_value <= previous_vertex) return null;
            vertices[edge * MAX_N + slot] = @intCast(vertex_value);
            previous_vertex = vertex_value;
        }
        degrees[edge] = degree;
        position += 1 + degree;
    }
    if (position != values.len or values.len > MAX_INPUT) return null;

    var current_cut = cut(mask, edge_count, &degrees, &vertices);
    var a_size = initial_a;
    var pass_count: usize = 0;
    while (pass_count <= edge_count) {
        const pass_start_mask = mask;
        const pass_start_cut = current_cut;
        var best_prefix_mask = mask;
        var best_prefix_cut = current_cut;
        var working_a_size = a_size;
        var locked: [MAX_N]bool = @splat(false);
        var moves: usize = 0;
        while (moves < n) {
            var bucket_best: [BUCKET_COUNT]i64 = @splat(-1);
            var bucket_balance: [BUCKET_COUNT]usize = @splat(0);
            for (0..n) |vertex| {
                if (!locked[vertex]) {
                    const bit = @as(i64, 1) << @intCast(vertex);
                    const in_a = (mask & bit) != 0;
                    const resulting_a = if (in_a) working_a_size - 1 else working_a_size + 1;
                    if (resulting_a >= n / 2 - 1 and resulting_a <= n / 2 + 1) {
                        const move_gain = gain(mask, vertex, edge_count, &degrees, &vertices);
                        const bucket_index: usize = @intCast(move_gain + MAX_BUCKET_GAIN);
                        const balance = if (2 * resulting_a >= n) 2 * resulting_a - n else n - 2 * resulting_a;
                        if (bucket_best[bucket_index] < 0 or balance < bucket_balance[bucket_index] or
                            (balance == bucket_balance[bucket_index] and @as(i64, @intCast(vertex)) < bucket_best[bucket_index])) {
                            bucket_best[bucket_index] = @intCast(vertex);
                            bucket_balance[bucket_index] = balance;
                        }
                    }
                }
            }

            var selected = n;
            var selected_gain: i64 = 0;
            var bucket = BUCKET_COUNT;
            while (bucket > 0) {
                bucket -= 1;
                if (bucket_best[bucket] >= 0) {
                    selected = @intCast(bucket_best[bucket]);
                    selected_gain = @as(i64, @intCast(bucket)) - MAX_BUCKET_GAIN;
                    break;
                }
            }
            if (selected == n) break;

            const bit = @as(i64, 1) << @intCast(selected);
            if ((mask & bit) != 0) {
                mask -= bit;
                working_a_size -= 1;
            } else {
                mask += bit;
                working_a_size += 1;
            }
            locked[selected] = true;
            current_cut = @intCast(@as(i64, @intCast(current_cut)) - selected_gain);
            moves += 1;
            if (current_cut < best_prefix_cut) {
                best_prefix_cut = current_cut;
                best_prefix_mask = mask;
            }
        }

        if (best_prefix_cut < pass_start_cut) {
            mask = best_prefix_mask;
            current_cut = best_prefix_cut;
            a_size = 0;
            for (0..n) |vertex| {
                if (((mask >> @intCast(vertex)) & 1) != 0) a_size += 1;
            }
            pass_count += 1;
        } else {
            mask = pass_start_mask;
            current_cut = pass_start_cut;
            break;
        }
    }
    return @as(i64, @intCast(current_cut * 256)) + mask;
}

export fn fiduccia_mattheyses_hypergraph_bipartitioning(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 3 or length > MAX_PARSEABLE) return -1;
    var staged: [MAX_PARSEABLE]i64 = @splat(0);
    for (0..length) |index| staged[index] = input[index];
    return execute(staged[0..length]) orelse -1;
}
