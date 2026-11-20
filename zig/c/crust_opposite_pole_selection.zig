const MAX_SAMPLES: usize = 8;
const MAX_CELL_VERTICES: usize = 8;

fn putI64(out: [*]u8, word: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| out[word * 8 + b] = @truncate(bits >> @as(u6, @intCast(8 * b)));
}
fn samePoint(a: [3]i64, b: [3]i64) bool { return a[0] == b[0] and a[1] == b[1] and a[2] == b[2]; }

export fn crust_opposite_pole_selection(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 1 or length > 226) return -1;
    const values = input.?;
    const n_raw = values[0];
    if (n_raw < 1 or n_raw > 8) return -1;
    const n: usize = @intCast(n_raw);
    var samples = [_][3]i64{.{ 0, 0, 0 }} ** MAX_SAMPLES;
    var answer = [_][2]i64{.{ 0, 0 }} ** MAX_SAMPLES;
    var offset: usize = 1;
    for (0..n) |row| {
        if (offset + 4 > length) return -1;
        const sample = [3]i64{ values[offset], values[offset + 1], values[offset + 2] };
        const count_raw = values[offset + 3]; offset += 4;
        if (count_raw < 1 or count_raw > 8) return -1;
        for (sample) |coordinate| {
            if (coordinate < -16 or coordinate > 16) return -1;
        }
        for (0..row) |prev| {
            if (samePoint(sample, samples[prev])) return -1;
        }
        samples[row] = sample;
        const count: usize = @intCast(count_raw);
        if (offset + 3 * count > length) return -1;
        var cell = [_][3]i64{.{ 0, 0, 0 }} ** MAX_CELL_VERTICES;
        for (0..count) |v| {
            for (0..3) |axis| { cell[v][axis] = values[offset]; offset += 1; if (cell[v][axis] < -16 or cell[v][axis] > 16) return -1; }
            if (samePoint(sample, cell[v])) return -1;
            for (0..v) |prev| {
                if (samePoint(cell[v], cell[prev])) return -1;
            }
        }
        var positive: usize = 0;
        var positive_distance: i64 = -1;
        for (0..count) |v| {
            var distance: i64 = 0;
            for (0..3) |axis| { const delta = cell[v][axis] - sample[axis]; distance += delta * delta; }
            if (distance > positive_distance) { positive_distance = distance; positive = v; }
        }
        const forward = [3]i64{ cell[positive][0] - sample[0], cell[positive][1] - sample[1], cell[positive][2] - sample[2] };
        var negative: i64 = -1;
        var negative_distance: i64 = -1;
        for (0..count) |v| {
            var distance: i64 = 0; var projection: i64 = 0;
            for (0..3) |axis| { const delta = cell[v][axis] - sample[axis]; distance += delta * delta; projection += delta * forward[axis]; }
            if (projection < 0 and distance > negative_distance) { negative_distance = distance; negative = @intCast(v); }
        }
        answer[row] = .{ @intCast(positive), negative };
    }
    if (offset != length) return -1;
    const bytes = 8 * (1 + 2 * n);
    if (output == null or capacity < bytes) return -2;
    const out = output.?;
    putI64(out, 0, n_raw);
    var word: usize = 1;
    for (0..n) |row| { putI64(out, word, answer[row][0]); word += 1; putI64(out, word, answer[row][1]); word += 1; }
    return @intCast(bytes);
}
