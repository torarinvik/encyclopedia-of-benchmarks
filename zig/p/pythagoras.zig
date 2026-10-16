const std = @import("std");
export fn pythagoras(v: [*c]const i64, n: usize) f64 {
    if (v == null or n != 6) return -1.0e300;
    for (0..6) |i| if (v[i] < -1000000 or v[i] > 1000000) return -1.0e300;
    const dx: f64 = @floatFromInt(v[3] - v[0]);
    const dy: f64 = @floatFromInt(v[4] - v[1]);
    const dz: f64 = @floatFromInt(v[5] - v[2]);
    return @sqrt(dx * dx + dy * dy + dz * dz);
}
