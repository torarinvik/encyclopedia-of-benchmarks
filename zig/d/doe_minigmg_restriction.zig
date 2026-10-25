export fn doe_minigmg_restriction(values: [*]const i64, length: usize) f64 {
    if (length < 11 or length > 515) return -1.0e300;
    const nx_raw = values[0];
    const ny_raw = values[1];
    const nz_raw = values[2];
    if (nx_raw < 2 or nx_raw > 8 or @mod(nx_raw, 2) != 0 or
        ny_raw < 2 or ny_raw > 8 or @mod(ny_raw, 2) != 0 or
        nz_raw < 2 or nz_raw > 8 or @mod(nz_raw, 2) != 0) return -1.0e300;

    const nx: usize = @intCast(nx_raw);
    const ny: usize = @intCast(ny_raw);
    const nz: usize = @intCast(nz_raw);
    const cells = nx * ny * nz;
    if (length != 3 + cells) return -1.0e300;
    for (0..cells) |q| {
        if (values[3 + q] < -32768 or values[3 + q] > 32767) return -1.0e300;
    }

    const coarse_nx = nx / 2;
    const coarse_ny = ny / 2;
    const coarse_nz = nz / 2;
    const plane = nx * ny;
    var checksum: f64 = 0.0;
    var coarse_index: usize = 0;
    for (0..coarse_nz) |k| {
        for (0..coarse_ny) |j| {
            for (0..coarse_nx) |i| {
                const base = 3 + 2 * i + 2 * j * nx + 2 * k * plane;
                const sum = @as(f64, @floatFromInt(values[base])) + @as(f64, @floatFromInt(values[base + 1])) +
                    @as(f64, @floatFromInt(values[base + nx])) + @as(f64, @floatFromInt(values[base + nx + 1])) +
                    @as(f64, @floatFromInt(values[base + plane])) + @as(f64, @floatFromInt(values[base + plane + 1])) +
                    @as(f64, @floatFromInt(values[base + plane + nx])) + @as(f64, @floatFromInt(values[base + plane + nx + 1]));
                const restricted = sum * 0.125;
                const weight: f64 = @floatFromInt(coarse_index + 1);
                checksum += weight * restricted * restricted;
                coarse_index += 1;
            }
        }
    }
    return checksum;
}
