const MAX_DIMENSION: usize = 16;
const MAX_A_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION * MAX_DIMENSION;
const MAX_C4_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION;
const INVALID_RESULT: f64 = -1e300;

export fn doitgen(values_opt: ?[*]const i64, length: usize) f64 {
    if (values_opt == null or length != 3) return INVALID_RESULT;
    const values = values_opt.?;
    for (0..3) |i| {
        if (values[i] < 1 or values[i] > @as(i64, @intCast(MAX_DIMENSION))) return INVALID_RESULT;
    }
    const nr: usize = @intCast(values[0]);
    const nq: usize = @intCast(values[1]);
    const np: usize = @intCast(values[2]);
    var a: [MAX_A_CELLS]f64 = [_]f64{0} ** MAX_A_CELLS;
    var c4: [MAX_C4_CELLS]f64 = [_]f64{0} ** MAX_C4_CELLS;
    var sums: [MAX_DIMENSION]f64 = [_]f64{0} ** MAX_DIMENSION;
    for (0..nr) |r| {
        for (0..nq) |q| {
            for (0..np) |p| a[(r * nq + q) * np + p] = @as(f64, @floatFromInt((r * q + p) % np)) / @as(f64, @floatFromInt(np));
        }
    }
    for (0..np) |i| {
        for (0..np) |j| c4[i * np + j] = @as(f64, @floatFromInt((i * j) % np)) / @as(f64, @floatFromInt(np));
    }
    for (0..nr) |r| {
        for (0..nq) |q| {
            for (0..np) |p| {
                sums[p] = 0.0;
                for (0..np) |s| sums[p] += a[(r * nq + q) * np + s] * c4[s * np + p];
            }
            for (0..np) |p| a[(r * nq + q) * np + p] = sums[p];
        }
    }
    var checksum: f64 = 0;
    for (0..nr) |r| {
        for (0..nq) |q| {
            for (0..np) |p| checksum += a[(r * nq + q) * np + p];
        }
    }
    return checksum;
}
