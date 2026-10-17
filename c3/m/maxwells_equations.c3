module maxwells_equations;

extern fn double sqrt(double value);
const long MAX_PHYSICAL = 1000000000000000;
const long MAX_FLUX_RATE = 1000000000000000000;
const long MIN_CONSTANT = 1000000;
const long MAX_CONSTANT = 1000000000000000;
const double EPSILON_DEFAULT = 8.8541878128e-12;
const double MU_DEFAULT = 4.0 * 3.14159265358979323846264338327950288 * 1e-7;
const double INVALID_RESULT = -1e300;

bool in_range(long value, long limit) { return value >= -limit && value <= limit; }
bool decode_constant(long raw, double fallback, double* value) {
    if (raw == 0) { *value = fallback; return true; }
    if (raw < MIN_CONSTANT || raw > MAX_CONSTANT) return false;
    *value = (double)raw / 1e18;
    return true;
}
double law_result(double actual, double expected) {
    double difference = actual - expected;
    if (difference < 0.0) difference = -difference;
    double tolerance = expected != 0.0 ? 0.01 * (expected < 0.0 ? -expected : expected) : 1e-10;
    return difference <= tolerance ? 1.0 : 0.0;
}

fn double maxwells_equations(long* input, usz length) @export("maxwells_equations") {
    if (input == null || length < 1 || length > 7) return INVALID_RESULT;
    long operation = input[0];
    if (operation == 0) {
        if (length != 5) return INVALID_RESULT;
        long field = input[1], area = input[2], charge = input[3], epsilon_raw = input[4];
        if (!in_range(field, MAX_PHYSICAL) || area < 0 || area > MAX_PHYSICAL || !in_range(charge, MAX_PHYSICAL)) return INVALID_RESULT;
        double epsilon;
        if (!decode_constant(epsilon_raw, EPSILON_DEFAULT, &epsilon)) return INVALID_RESULT;
        double electric_flux = ((double)field / 1e12) * ((double)area / 1e12);
        double expected_flux = ((double)charge / 1e12) / epsilon;
        return law_result(electric_flux, expected_flux);
    }
    if (operation == 1) {
        if (length != 3 || !in_range(input[1], MAX_PHYSICAL) || !in_range(input[2], MAX_PHYSICAL)) return INVALID_RESULT;
        double circulation = (double)input[1] / 1e12;
        double expected = -((double)input[2] / 1e12);
        return law_result(circulation, expected);
    }
    if (operation == 2) {
        if (length != 6 || !in_range(input[1], MAX_PHYSICAL) || !in_range(input[2], MAX_PHYSICAL) || !in_range(input[3], MAX_FLUX_RATE)) return INVALID_RESULT;
        double mu, epsilon;
        if (!decode_constant(input[4], MU_DEFAULT, &mu) || !decode_constant(input[5], EPSILON_DEFAULT, &epsilon)) return INVALID_RESULT;
        double displacement_current = epsilon * ((double)input[3] / 1e6);
        double total_current = ((double)input[2] / 1e12) + displacement_current;
        double expected = mu * total_current;
        return law_result((double)input[1] / 1e12, expected);
    }
    if (operation == 3 || operation == 4) {
        if (length != 3) return INVALID_RESULT;
        double mu, epsilon;
        if (!decode_constant(input[1], MU_DEFAULT, &mu) || !decode_constant(input[2], EPSILON_DEFAULT, &epsilon)) return INVALID_RESULT;
        if (operation == 3) return 1.0 / sqrt(mu * epsilon);
        return sqrt(mu / epsilon);
    }
    if (operation == 5) {
        if (length != 4 || !in_range(input[1], MAX_PHYSICAL) || !in_range(input[2], MAX_PHYSICAL)) return INVALID_RESULT;
        double mu;
        if (!decode_constant(input[3], MU_DEFAULT, &mu)) return INVALID_RESULT;
        return (((double)input[1] / 1e12) * ((double)input[2] / 1e12)) / mu;
    }
    if (operation == 6) {
        if (length != 5 || !in_range(input[1], MAX_PHYSICAL) || !in_range(input[2], MAX_PHYSICAL)) return INVALID_RESULT;
        double epsilon, mu;
        if (!decode_constant(input[3], EPSILON_DEFAULT, &epsilon) || !decode_constant(input[4], MU_DEFAULT, &mu)) return INVALID_RESULT;
        double electric_field = (double)input[1] / 1e12;
        double magnetic_field = (double)input[2] / 1e12;
        double electric_energy = 0.5 * epsilon * (electric_field * electric_field);
        double magnetic_energy = 0.5 * (magnetic_field * magnetic_field) / mu;
        return electric_energy + magnetic_energy;
    }
    return INVALID_RESULT;
}
