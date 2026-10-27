const max_n: usize = 8;
const max_input: usize = 84;
const max_output: usize = 80;
const output_values: usize = 10;

fn put64(output: [*]u8, position: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[position + byte] = @truncate(bits >> @intCast(8 * byte));
}
fn angleBetter(da: i64, la: i64, db: i64, lb: i64) bool {
    if ((da >= 0) != (db >= 0)) return da >= 0;
    const left = da * da * lb;
    const right = db * db * la;
    if (da >= 0) return left > right;
    return left < right;
}
fn angleEqual(da: i64, la: i64, db: i64, lb: i64) bool {
    return (da >= 0) == (db >= 0) and da * da * lb == db * db * la;
}

export fn geometric_greedy_compass_routing(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 12 or length > max_input) return -1;
    const input = input_opt.?;
    const n64 = input[0]; const mode = input[1]; const source64 = input[2]; const target64 = input[3];
    if (n64 < 2 or n64 > 8 or mode < 0 or mode > 1 or source64 < 0 or target64 < 0 or source64 >= n64 or target64 >= n64) return -1;
    const n: usize = @intCast(n64); const source: usize = @intCast(source64); const target: usize = @intCast(target64);
    if (length != 4 + 2*n + n*n) return -1;
    var x: [max_n]i64 = @splat(0); var y: [max_n]i64 = @splat(0);
    const adjacency = 4 + 2*n;
    for (0..n) |i| {
        x[i] = input[4+i]; y[i] = input[4+n+i];
        if (x[i] < -8 or x[i] > 8 or y[i] < -8 or y[i] > 8) return -1;
        for (0..i) |j| {
            if (x[i] == x[j] and y[i] == y[j]) return -1;
        }
    }
    for (0..n) |i| {
        for (0..n) |j| {
            const a = input[adjacency+i*n+j]; const b = input[adjacency+j*n+i];
            if ((a != 0 and a != 1) or a != b or (i == j and a != 0)) return -1;
        }
    }
    if (output_opt == null or capacity < max_output) return -2;
    const output = output_opt.?;
    var path: [max_n]usize = @splat(0); var visited: [max_n]bool = @splat(false);
    var count: usize = 1; path[0] = source; visited[source] = true;
    var current = source;
    while (current != target and count < n) {
        var best = n; var best_dot: i64 = 0; var best_len: i64 = 1; var best_distance: i64 = 0;
        const tx = x[target]-x[current]; const ty = y[target]-y[current];
        for (0..n) |v| {
            if (input[adjacency+current*n+v] != 1) continue;
            var better = best == n;
            const dx = x[v]-x[current]; const dy = y[v]-y[current];
            if (mode == 0) {
                const rx = x[v]-x[target]; const ry = y[v]-y[target];
                const distance = rx*rx+ry*ry;
                if (!better) better = distance < best_distance or (distance == best_distance and v < best);
                if (better) best_distance = distance;
            } else {
                const dot = dx*tx+dy*ty; const length_sq = dx*dx+dy*dy;
                if (!better) better = angleBetter(dot,length_sq,best_dot,best_len) or (angleEqual(dot,length_sq,best_dot,best_len) and v < best);
                if (better) { best_dot = dot; best_len = length_sq; }
            }
            if (better) best = v;
        }
        if (best == n or visited[best]) break;
        path[count] = best; count += 1; visited[best] = true; current = best;
    }
    var record: [output_values]i64 = @splat(0);
    record[0] = if (current == target) 1 else 0;
    record[1] = @intCast(count-1);
    for (0..max_n) |i| record[2+i] = -1;
    for (0..count) |i| record[2+i] = @intCast(path[i]);
    var staged: [max_output]u8 = @splat(0);
    for (0..output_values) |i| put64(&staged,8*i,record[i]);
    for (0..max_output) |i| output[i] = staged[i];
    return @intCast(max_output);
}
