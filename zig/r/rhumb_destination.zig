const std = @import("std");

const PI_VALUE: f64 = 3.14159265358979323846264338327950288;
const EARTH_RADIUS: f64 = 6_371_000.0;

export fn rhumb_destination(input_opt: ?[*]const f64, input_length: usize,
                            output_opt: ?[*]f64, output_capacity: usize) i64 {
    if (input_opt == null or input_length != 4) return -1;
    const input = input_opt.?;
    const latitude = input[0]; const longitude = input[1]; const distance = input[2]; const bearing = input[3];
    if (!std.math.isFinite(latitude) or !std.math.isFinite(longitude) or !std.math.isFinite(distance) or !std.math.isFinite(bearing) or
        latitude < -80.0 or latitude > 80.0 or longitude < -180.0 or longitude > 180.0 or
        distance < 0.0 or distance > 300000.0 or bearing < 0.0 or bearing > 360.0) return -1;
    const del = distance / EARTH_RADIUS;
    const phi1 = latitude * PI_VALUE / 180.0;
    const lambda1 = longitude * PI_VALUE / 180.0;
    const theta = bearing * PI_VALUE / 180.0;
    const del_phi = del * @cos(theta);
    var phi2 = phi1 + del_phi;
    if (phi2 > PI_VALUE / 2.0) phi2 = PI_VALUE / 2.0
    else if (phi2 < -PI_VALUE / 2.0) phi2 = -PI_VALUE / 2.0;
    const del_psi = @log(@tan(phi2 / 2.0 + PI_VALUE / 4.0) / @tan(phi1 / 2.0 + PI_VALUE / 4.0));
    const q = if (@abs(del_psi) > 1e-12) del_phi / del_psi else @cos(phi1);
    const del_lambda = del * @sin(theta) / q;
    const result_latitude = phi2 * 180.0 / PI_VALUE;
    const result_longitude = (lambda1 + del_lambda) * 180.0 / PI_VALUE;
    if (output_opt == null or output_capacity < 2) return -2;
    const output = output_opt.?;
    output[0] = result_latitude;
    output[1] = result_longitude;
    return 2;
}
