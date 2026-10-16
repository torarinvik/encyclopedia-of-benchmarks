const std = @import("std");
const INVALID_RESULT: f64 = -1.0e300;
const MAX_REFLECTIONS: usize = 10_000;

const RayPoint = struct { x: f64, y: f64, gradient: f64 };

fn isClose(left: f64, right: f64) bool {
    return @abs(left - right) <= 1.0e-9 * @max(@abs(left), @abs(right));
}

fn nextPoint(point_x: f64, point_y: f64, incoming_gradient: f64) RayPoint {
    const normal_gradient = point_y / 4.0 / point_x;
    const s2 = 2.0 * normal_gradient / (1.0 + normal_gradient * normal_gradient);
    const c2 = (1.0 - normal_gradient * normal_gradient) / (1.0 + normal_gradient * normal_gradient);
    const outgoing_gradient = (s2 - c2 * incoming_gradient) / (c2 + s2 * incoming_gradient);
    const quadratic_term = outgoing_gradient * outgoing_gradient + 4.0;
    const line_offset = point_y - outgoing_gradient * point_x;
    const linear_term = 2.0 * outgoing_gradient * line_offset;
    const constant_term = line_offset * line_offset - 100.0;
    const root = @sqrt(linear_term * linear_term - 4.0 * quadratic_term * constant_term);
    const x_minus = (-linear_term - root) / (2.0 * quadratic_term);
    const x_plus = (-linear_term + root) / (2.0 * quadratic_term);
    const next_x = if (isClose(x_plus, point_x)) x_minus else x_plus;
    return .{ .x = next_x, .y = point_y + outgoing_gradient * (next_x - point_x), .gradient = outgoing_gradient };
}

pub export fn problem144(first_x_coord: f64, first_y_coord: f64) f64 {
    if (std.math.isNan(first_x_coord) or std.math.isNan(first_y_coord) or
        first_x_coord < 1.0e-5 or first_x_coord > 5.0 or first_y_coord < -10.0 or first_y_coord > 0.0) {
        return INVALID_RESULT;
    }
    const ellipse_residual = 4.0 * first_x_coord * first_x_coord + first_y_coord * first_y_coord - 100.0;
    if (@abs(ellipse_residual) > 1.0e-6) return INVALID_RESULT;

    var point_x = first_x_coord;
    var point_y = first_y_coord;
    var gradient = (10.1 - point_y) / (0.0 - point_x);
    var reflections: usize = 0;
    while (!(point_x >= -0.01 and point_x <= 0.01 and point_y > 0.0)) {
        if (reflections >= MAX_REFLECTIONS) return INVALID_RESULT;
        const next = nextPoint(point_x, point_y, gradient);
        if (std.math.isNan(next.x) or std.math.isNan(next.y)) return INVALID_RESULT;
        point_x = next.x;
        point_y = next.y;
        gradient = next.gradient;
        reflections += 1;
    }
    return @floatFromInt(reflections);
}
