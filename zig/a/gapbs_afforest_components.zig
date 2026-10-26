// Clean-room bounded GAPBS Afforest profile; see package LICENSE.txt.
const max_n: usize = 16;
const max_m: usize = 64;
const max_samples: usize = 64;
const max_input: usize = 3 + max_samples + 2 * max_m;

fn linkComponents(u: usize, v: usize, component: *[max_n]usize) void {
    var p1 = component[u];
    var p2 = component[v];
    while (p1 != p2) {
        const high = @max(p1, p2);
        const low = @min(p1, p2);
        const parent_high = component[high];
        if (parent_high == low) break;
        if (parent_high == high) { component[high] = low; break; }
        p1 = component[component[high]];
        p2 = component[low];
    }
}

fn compressComponents(n: usize, component: *[max_n]usize) void {
    for (0..n) |vertex| {
        while (component[vertex] != component[component[vertex]])
            component[vertex] = component[component[vertex]];
    }
}

fn storeI64LE(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn gapbs_afforest_components(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 4 or length > max_input) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    const sample_count64 = input[2];
    if (n64 < 1 or n64 > 16 or m64 < 0 or m64 > 64 or sample_count64 < 1 or sample_count64 > 64) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    const sample_count: usize = @intCast(sample_count64);
    if (length != 3 + sample_count + 2 * m) return -1;
    var samples: [max_samples]usize = [_]usize{0} ** max_samples;
    for (0..sample_count) |i| {
        const sample = input[3 + i];
        if (sample < 0 or sample >= n64) return -1;
        samples[i] = @intCast(sample);
    }
    var adjacency: [max_n][max_n]bool = [_][max_n]bool{[_]bool{false} ** max_n} ** max_n;
    for (0..m) |edge| {
        const pos = 3 + sample_count + 2 * edge;
        const u = input[pos];
        const v = input[pos + 1];
        if (u < 0 or v <= u or v >= n64 or adjacency[@intCast(u)][@intCast(v)]) return -1;
        adjacency[@intCast(u)][@intCast(v)] = true;
        adjacency[@intCast(v)][@intCast(u)] = true;
    }
    const output_bytes = 8 * n;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;

    var neighbors: [max_n][max_n]usize = [_][max_n]usize{[_]usize{0} ** max_n} ** max_n;
    var degree: [max_n]usize = [_]usize{0} ** max_n;
    for (0..n) |u| {
        for (0..n) |v| {
            if (adjacency[u][v]) { neighbors[u][degree[u]] = v; degree[u] += 1; }
        }
    }
    var component: [max_n]usize = [_]usize{0} ** max_n;
    for (0..n) |vertex| component[vertex] = vertex;
    for (0..2) |round| {
        for (0..n) |u| if (degree[u] > round) {
            linkComponents(u, neighbors[u][round], &component);
        };
        compressComponents(n, &component);
    }
    var sample_counts: [max_n]usize = [_]usize{0} ** max_n;
    for (0..sample_count) |i| sample_counts[component[samples[i]]] += 1;
    var skip_label: usize = 0;
    for (1..n) |label| {
        if (sample_counts[label] > sample_counts[skip_label]) skip_label = label;
    }
    var skip_is_safe = true;
    for (0..n) |u| {
        if (component[u] != skip_label) continue;
        if (degree[u] > 2) {
            for (2..degree[u]) |offset| {
                if (component[neighbors[u][offset]] != skip_label) { skip_is_safe = false; break; }
            }
        }
        if (!skip_is_safe) break;
    }
    for (0..n) |u| {
        if (skip_is_safe and component[u] == skip_label) continue;
        if (degree[u] > 2) {
            for (2..degree[u]) |offset| linkComponents(u, neighbors[u][offset], &component);
        }
    }
    compressComponents(n, &component);
    for (0..n) |vertex| storeI64LE(output, 8 * vertex, @intCast(component[vertex]));
    return @intCast(output_bytes);
}
