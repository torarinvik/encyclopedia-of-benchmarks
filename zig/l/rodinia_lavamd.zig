/// Rodinia source-order screened pair interactions over a home and one neighbor box.
const bias: i64 = 1_000_000_000_000;

fn roundMicro(value: f64) i64 {
    const scaled = value * 1_000_000.0;
    if (scaled < 0.0) return -@as(i64, @intFromFloat(@floor(-scaled + 0.5)));
    return @as(i64, @intFromFloat(@floor(scaled + 0.5)));
}

export fn rodinia_lavamd(input: [*]const i64, length: usize) i64 {
    if (length < 12 or length > 42) return -1;
    if (input[0] < 1 or input[0] > 4 or input[1] < 1 or input[1] > 4) return -1;
    const home_n: usize = @intCast(input[0]); const neighbor_n: usize = @intCast(input[1]);
    if (length != 2 + 5 * (home_n + neighbor_n)) return -1;
    var particles: [2][4][5]f64 = .{.{.{0,0,0,0,0},.{0,0,0,0,0},.{0,0,0,0,0},.{0,0,0,0,0}},.{.{0,0,0,0,0},.{0,0,0,0,0},.{0,0,0,0,0},.{0,0,0,0,0}}};
    const counts = [2]usize{home_n, neighbor_n};
    var cursor: usize = 2;
    for (0..2) |box| for (0..counts[box]) |p| for (0..5) |c| {
        const raw = input[cursor]; cursor += 1;
        if (raw < 0 or raw > 1_000_000) return -1;
        particles[box][p][c] = @as(f64, @floatFromInt(raw)) / 1_000_000.0;
    };
    var total: f64 = 0.0;
    for (0..home_n) |i| {
        var fv: f64 = 0.0; var fx: f64 = 0.0; var fy: f64 = 0.0; var fz: f64 = 0.0;
        const a = particles[0][i];
        for (0..2) |box| for (0..counts[box]) |j| {
            const b = particles[box][j];
            const dot = a[1] * b[1] + a[2] * b[2] + a[3] * b[3];
            const r2 = a[0] + b[0] - dot;
            const vij = @exp(-(0.5 * r2)); const fs = 2.0 * vij;
            const dx = a[1] - b[1]; const dy = a[2] - b[2]; const dz = a[3] - b[3];
            fv += b[4] * vij; fx += b[4] * (fs * dx); fy += b[4] * (fs * dy); fz += b[4] * (fs * dz);
        };
        total += @as(f64, @floatFromInt(i + 1)) * ((fv + fx) + fy + fz);
    }
    return bias + roundMicro(total);
}
