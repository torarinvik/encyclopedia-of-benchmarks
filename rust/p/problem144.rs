const INVALID_RESULT: f64 = -1.0e300;
const MAX_REFLECTIONS: usize = 10_000;

#[derive(Clone, Copy)]
struct RayPoint { x: f64, y: f64, gradient: f64 }

fn is_close(left: f64, right: f64) -> bool {
    (left - right).abs() <= 1.0e-9 * left.abs().max(right.abs())
}

fn next_point(point_x: f64, point_y: f64, incoming_gradient: f64) -> RayPoint {
    let normal_gradient = point_y / 4.0 / point_x;
    let s2 = 2.0 * normal_gradient / (1.0 + normal_gradient * normal_gradient);
    let c2 = (1.0 - normal_gradient * normal_gradient) / (1.0 + normal_gradient * normal_gradient);
    let outgoing_gradient = (s2 - c2 * incoming_gradient) / (c2 + s2 * incoming_gradient);
    let quadratic_term = outgoing_gradient * outgoing_gradient + 4.0;
    let line_offset = point_y - outgoing_gradient * point_x;
    let linear_term = 2.0 * outgoing_gradient * line_offset;
    let constant_term = line_offset * line_offset - 100.0;
    let root = (linear_term * linear_term - 4.0 * quadratic_term * constant_term).sqrt();
    let x_minus = (-linear_term - root) / (2.0 * quadratic_term);
    let x_plus = (-linear_term + root) / (2.0 * quadratic_term);
    let next_x = if is_close(x_plus, point_x) { x_minus } else { x_plus };
    RayPoint { x: next_x, y: point_y + outgoing_gradient * (next_x - point_x), gradient: outgoing_gradient }
}

#[no_mangle]
pub extern "C" fn problem144(first_x_coord: f64, first_y_coord: f64) -> f64 {
    if first_x_coord.is_nan() || first_y_coord.is_nan() ||
        first_x_coord < 1.0e-5 || first_x_coord > 5.0 || first_y_coord < -10.0 || first_y_coord > 0.0 {
        return INVALID_RESULT;
    }
    let ellipse_residual = 4.0 * first_x_coord * first_x_coord + first_y_coord * first_y_coord - 100.0;
    if ellipse_residual.abs() > 1.0e-6 { return INVALID_RESULT; }

    let mut point_x = first_x_coord;
    let mut point_y = first_y_coord;
    let mut gradient = (10.1 - point_y) / (0.0 - point_x);
    let mut reflections = 0usize;
    while !(point_x >= -0.01 && point_x <= 0.01 && point_y > 0.0) {
        if reflections >= MAX_REFLECTIONS { return INVALID_RESULT; }
        let next = next_point(point_x, point_y, gradient);
        if next.x.is_nan() || next.y.is_nan() { return INVALID_RESULT; }
        point_x = next.x;
        point_y = next.y;
        gradient = next.gradient;
        reflections += 1;
    }
    reflections as f64
}
