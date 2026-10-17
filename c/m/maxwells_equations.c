#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1e300)
#define MAX_PHYSICAL INT64_C(1000000000000000)
#define MAX_FLUX_RATE INT64_C(1000000000000000000)
#define MIN_CONSTANT INT64_C(1000000)
#define MAX_CONSTANT INT64_C(1000000000000000)
#define PHYSICAL_SCALE 1e12
#define CONSTANT_SCALE 1e18
#define PI 3.14159265358979323846264338327950288

static int in_range(int64_t value, int64_t limit) { return value >= -limit && value <= limit; }
static int decode_constant(int64_t raw, double fallback, double* value) {
    if (raw == 0) { *value = fallback; return 1; }
    if (raw < MIN_CONSTANT || raw > MAX_CONSTANT) return 0;
    *value = (double)raw / CONSTANT_SCALE;
    return 1;
}
static double law_result(double actual, double expected) {
    const double tolerance = expected != 0.0 ? 0.01 * fabs(expected) : 1e-10;
    return fabs(actual - expected) <= tolerance ? 1.0 : 0.0;
}

double maxwells_equations(const int64_t* input, size_t length) {
    const double epsilon_default = 8.8541878128e-12;
    const double mu_default = 4.0 * PI * 1e-7;
    if (input == NULL || length < 1 || length > 7) return INVALID_RESULT;
    const int64_t operation = input[0];
    if (operation == 0) {
        if (length != 5) return INVALID_RESULT;
        int64_t field = input[1], area = input[2], charge = input[3], epsilon_raw = input[4];
        if (!in_range(field, MAX_PHYSICAL) || area < 0 || area > MAX_PHYSICAL || !in_range(charge, MAX_PHYSICAL)) return INVALID_RESULT;
        double epsilon;
        if (!decode_constant(epsilon_raw, epsilon_default, &epsilon)) return INVALID_RESULT;
        double electric_flux = ((double)field / PHYSICAL_SCALE) * ((double)area / PHYSICAL_SCALE);
        double expected_flux = ((double)charge / PHYSICAL_SCALE) / epsilon;
        return law_result(electric_flux, expected_flux);
    }
    if (operation == 1) {
        if (length != 3 || !in_range(input[1], MAX_PHYSICAL) || !in_range(input[2], MAX_PHYSICAL)) return INVALID_RESULT;
        double circulation = (double)input[1] / PHYSICAL_SCALE;
        double expected = -((double)input[2] / PHYSICAL_SCALE);
        return law_result(circulation, expected);
    }
    if (operation == 2) {
        if (length != 6 || !in_range(input[1], MAX_PHYSICAL) || !in_range(input[2], MAX_PHYSICAL) || !in_range(input[3], MAX_FLUX_RATE)) return INVALID_RESULT;
        double mu, epsilon;
        if (!decode_constant(input[4], mu_default, &mu) || !decode_constant(input[5], epsilon_default, &epsilon)) return INVALID_RESULT;
        double displacement_current = epsilon * ((double)input[3] / 1e6);
        double total_current = ((double)input[2] / PHYSICAL_SCALE) + displacement_current;
        double expected = mu * total_current;
        return law_result((double)input[1] / PHYSICAL_SCALE, expected);
    }
    if (operation == 3 || operation == 4) {
        if (length != 3) return INVALID_RESULT;
        double mu, epsilon;
        if (!decode_constant(input[1], mu_default, &mu) || !decode_constant(input[2], epsilon_default, &epsilon)) return INVALID_RESULT;
        if (operation == 3) return 1.0 / sqrt(mu * epsilon);
        return sqrt(mu / epsilon);
    }
    if (operation == 5) {
        if (length != 4 || !in_range(input[1], MAX_PHYSICAL) || !in_range(input[2], MAX_PHYSICAL)) return INVALID_RESULT;
        double mu;
        if (!decode_constant(input[3], mu_default, &mu)) return INVALID_RESULT;
        return (((double)input[1] / PHYSICAL_SCALE) * ((double)input[2] / PHYSICAL_SCALE)) / mu;
    }
    if (operation == 6) {
        if (length != 5 || !in_range(input[1], MAX_PHYSICAL) || !in_range(input[2], MAX_PHYSICAL)) return INVALID_RESULT;
        double epsilon, mu;
        if (!decode_constant(input[3], epsilon_default, &epsilon) || !decode_constant(input[4], mu_default, &mu)) return INVALID_RESULT;
        double electric_energy = 0.5 * epsilon * pow((double)input[1] / PHYSICAL_SCALE, 2.0);
        double magnetic_energy = 0.5 * pow((double)input[2] / PHYSICAL_SCALE, 2.0) / mu;
        return electric_energy + magnetic_energy;
    }
    return INVALID_RESULT;
}
