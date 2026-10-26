const std = @import("std");

export fn parboil_stencil_laplacian(
    input_opt: ?[*]const f64,
    length: usize,
    output_opt: ?[*]f64,
    capacity: usize,
) i64 {
    if (input_opt == null or length < 4 or length > 129) return -1;
    const input = input_opt.?;
    const nxv = input[0];
    const nyv = input[1];
    const nzv = input[2];
    const stepsv = input[3];
    if (!std.math.isFinite(nxv) or !std.math.isFinite(nyv) or !std.math.isFinite(nzv) or !std.math.isFinite(stepsv) or
        @trunc(nxv) != nxv or @trunc(nyv) != nyv or @trunc(nzv) != nzv or @trunc(stepsv) != stepsv or
        nxv < 3 or nxv > 5 or nyv < 3 or nyv > 5 or nzv < 3 or nzv > 5 or stepsv < 1 or stepsv > 4) return -1;
    const nx: usize = @intFromFloat(nxv);
    const ny: usize = @intFromFloat(nyv);
    const nz: usize = @intFromFloat(nzv);
    const steps: usize = @intFromFloat(stepsv);
    const cells = nx * ny * nz;
    if (length != 4 + cells) return -1;
    for (0..cells) |q| {
        const value = input[4 + q];
        if (!std.math.isFinite(value) or value < -8 or value > 8) return -1;
    }
    if (output_opt == null or capacity < cells) return -2;
    var a: [125]f32 = @splat(0.0);
    var b: [125]f32 = @splat(0.0);
    var staged: [125]f64 = @splat(0.0);
    for (0..cells) |q| {
        a[q] = @floatCast(input[4 + q]);
        b[q] = a[q];
    }
    const one: f32 = 1.0;
    const six: f32 = 6.0;
    const c0: f32 = one / six;
    const c1: f32 = c0 / six;
    for (0..steps) |_| {
        for (1..nx - 1) |i| for (1..ny - 1) |j| for (1..nz - 1) |k| {
            const q = i + nx * (j + ny * k);
            var sum: f32 = a[q + nx * ny] + a[q - nx * ny];
            sum = sum + a[q + nx];
            sum = sum + a[q - nx];
            sum = sum + a[q + 1];
            sum = sum + a[q - 1];
            const neighbor_term = sum * c1;
            const center_term = a[q] * c0;
            b[q] = neighbor_term - center_term;
        };
        for (0..cells) |q| {
            const temp = a[q];
            a[q] = b[q];
            b[q] = temp;
        }
    }
    for (0..cells) |q| staged[q] = @floatCast(a[q]);
    const output = output_opt.?;
    for (0..cells) |q| output[q] = staged[q];
    return @intCast(cells);
}
