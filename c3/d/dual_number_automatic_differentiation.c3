module dual_number_automatic_differentiation;

const double INVALID_RESULT = -1e300;
const int MAX_POWER = 8;

fn double dual_number_automatic_differentiation(double position, double power, double order)
    @export("dual_number_automatic_differentiation")
{
    if (!(position >= -1.0 && position <= 1.0) || !(power >= 0.0 && power <= MAX_POWER) ||
        !(order >= 0.0 && order <= MAX_POWER)) return INVALID_RESULT;
    int exponent = (int)power, derivative_order = (int)order;
    if (power != (double)exponent || order != (double)derivative_order || derivative_order > exponent)
        return INVALID_RESULT;

    double[MAX_POWER + 1] coefficients;
    for (int degree = 0; degree <= MAX_POWER; degree++) coefficients[degree] = 0.0;
    coefficients[0] = 1.0;
    for (int step = 0; step < exponent; step++) {
        double[MAX_POWER + 1] next;
        for (int degree = 0; degree <= MAX_POWER; degree++) next[degree] = 0.0;
        next[0] = coefficients[0] * position;
        for (int degree = 1; degree <= step + 1; degree++)
            next[degree] = coefficients[degree] * position + coefficients[degree - 1];
        for (int degree = 0; degree <= MAX_POWER; degree++) coefficients[degree] = next[degree];
    }
    double result = coefficients[derivative_order];
    for (int factor = 2; factor <= derivative_order; factor++) result *= (double)factor;
    return result;
}
