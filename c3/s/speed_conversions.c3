module speed_conversions;

extern fn double floor(double value);
extern fn double fma(double first, double second, double third);
const double INVALID_RESULT = -1.0;

fn double round_three_even(double value) {
    double lower = floor(value * 1000.0);
    double midpoint = lower + 0.5;
    double exact_side = fma(value, 1000.0, -midpoint);
    long rounded = (long)lower;
    if (exact_side > 0.0 || (exact_side == 0.0 && rounded % 2 != 0)) rounded++;
    return (double)rounded / 1000.0;
}

fn double speed_conversions(double speed, double route) @export("speed_conversions") {
    if (speed != speed || route != route || speed < 0.0 || speed > 1000000.0 ||
        route < 0.0 || route > 15.0 || floor(route) != route) return INVALID_RESULT;
    double[4] factors = {1.0, 3.6, 1.609344, 1.852};
    double[4] inverse_factors = {1.0, 0.277777778, 0.621371192, 0.539956803};
    long encoded = (long)route;
    long unit_from = encoded / 4;
    long unit_to = encoded % 4;
    return round_three_even(speed * factors[unit_from] * inverse_factors[unit_to]);
}
