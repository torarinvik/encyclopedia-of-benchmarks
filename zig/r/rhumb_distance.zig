const std = @import("std");

const PI_VALUE: f64 = 3.14159265358979323846264338327950288;
const EARTH_RADIUS: f64 = 6_371_000.0;

export fn rhumb_distance(input_opt: ?[*]const f64, input_length: usize,
                         output_opt: ?[*]f64, output_capacity: usize) i64 {
    if (input_opt == null or input_length != 4) return -1;
    const input = input_opt.?;
    const lat1 = input[0]; const long1 = input[1]; const lat2 = input[2]; const long2 = input[3];
    if (!std.math.isFinite(lat1) or !std.math.isFinite(long1) or !std.math.isFinite(lat2) or !std.math.isFinite(long2) or
        lat1 < -85.0 or lat1 > 85.0 or lat2 < -85.0 or lat2 > 85.0 or
        long1 < -180.0 or long1 > 180.0 or long2 < -180.0 or long2 > 180.0) return -1;
    const phi1 = lat1 * PI_VALUE / 180.0;
    const phi2 = lat2 * PI_VALUE / 180.0;
    const del_phi = phi2 - phi1;
    var del_lambda = (long2 - long1) * PI_VALUE / 180.0;
    if (del_lambda > PI_VALUE) del_lambda -= 2.0 * PI_VALUE
    else if (del_lambda < -PI_VALUE) del_lambda += 2.0 * PI_VALUE;
    const del_psi = @log(@tan(phi2 / 2.0 + PI_VALUE / 4.0) / @tan(phi1 / 2.0 + PI_VALUE / 4.0));
    const q = if (@abs(del_psi) > 1e-12) del_phi / del_psi else @cos(phi1);
    const distance = @sqrt(std.math.pow(f64, del_phi, 2.0) + std.math.pow(f64, q * del_lambda, 2.0)) * EARTH_RADIUS;
    if (output_opt == null or output_capacity < 1) return -2;
    output_opt.?[0] = distance;
    return 1;
}
