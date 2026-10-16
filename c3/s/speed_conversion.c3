module speed_conversion;

extern fn double floor(double value);
const double INVALID_RESULT = -1.0;

fn double round_two_php(double value) { return floor(value * 100.0 + 0.5) / 100.0; }

fn double speed_conversion(double speed, double route) @export("speed_conversion") {
    if (speed != speed || route != route || speed < 0.0 || speed > 1000000.0 ||
        route < 0.0 || route > 24.0 || floor(route) != route) return INVALID_RESULT;
    double[5] factors = {1.609344, 1.0, 3.6, 1.097, 1.852};
    double[5] inverse_factors = {0.6213712, 1.0, 0.277778, 0.911344, 0.539957};
    long encoded = (long)route;
    long unit_from = encoded / 5;
    long unit_to = encoded % 5;
    return round_two_php(speed * factors[unit_from] * inverse_factors[unit_to]);
}
