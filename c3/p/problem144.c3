module problem144;

extern fn double fabs(double value);
extern fn double sqrt(double value);
const double INVALID_RESULT = -1.0e300;
const long MAX_REFLECTIONS = 10000;

fn bool is_close(double left, double right) {
    double left_abs = fabs(left);
    double right_abs = fabs(right);
    double scale = left_abs > right_abs ? left_abs : right_abs;
    return fabs(left - right) <= 1.0e-9 * scale;
}

fn void next_point(double point_x, double point_y, double incoming_gradient,
                   double* next_x, double* next_y, double* outgoing_gradient) {
    double normal_gradient = point_y / 4.0 / point_x;
    double s2 = 2.0 * normal_gradient / (1.0 + normal_gradient * normal_gradient);
    double c2 = (1.0 - normal_gradient * normal_gradient) /
                (1.0 + normal_gradient * normal_gradient);
    *outgoing_gradient = (s2 - c2 * incoming_gradient) /
                         (c2 + s2 * incoming_gradient);
    double quadratic_term = *outgoing_gradient * *outgoing_gradient + 4.0;
    double line_offset = point_y - *outgoing_gradient * point_x;
    double linear_term = 2.0 * *outgoing_gradient * line_offset;
    double constant_term = line_offset * line_offset - 100.0;
    double discriminant = linear_term * linear_term -
                          4.0 * quadratic_term * constant_term;
    double root = sqrt(discriminant);
    double x_minus = (-linear_term - root) / (2.0 * quadratic_term);
    double x_plus = (-linear_term + root) / (2.0 * quadratic_term);
    *next_x = is_close(x_plus, point_x) ? x_minus : x_plus;
    *next_y = point_y + *outgoing_gradient * (*next_x - point_x);
}

fn double problem144(double first_x_coord, double first_y_coord) @export("problem144") {
    if (first_x_coord != first_x_coord || first_y_coord != first_y_coord ||
        first_x_coord < 1.0e-5 || first_x_coord > 5.0 ||
        first_y_coord < -10.0 || first_y_coord > 0.0) return INVALID_RESULT;
    double ellipse_residual = 4.0 * first_x_coord * first_x_coord +
                              first_y_coord * first_y_coord - 100.0;
    if (fabs(ellipse_residual) > 1.0e-6) return INVALID_RESULT;

    double point_x = first_x_coord;
    double point_y = first_y_coord;
    double gradient = (10.1 - point_y) / (0.0 - point_x);
    long reflections = 0;
    while (!(point_x >= -0.01 && point_x <= 0.01 && point_y > 0.0)) {
        if (reflections >= MAX_REFLECTIONS) return INVALID_RESULT;
        double next_x, next_y, outgoing_gradient;
        next_point(point_x, point_y, gradient, &next_x, &next_y, &outgoing_gradient);
        if (next_x != next_x || next_y != next_y) return INVALID_RESULT;
        point_x = next_x;
        point_y = next_y;
        gradient = outgoing_gradient;
        reflections++;
    }
    return reflections.double();
}
