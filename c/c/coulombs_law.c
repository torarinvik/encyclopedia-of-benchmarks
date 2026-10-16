#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)
#define COULOMBS_CONSTANT 8.9875517923e9
#define MAX_CHARGE_MICROCOULOMBS 1000000
#define MAX_DISTANCE_MILLIMETERS 1000000

double coulombs_law(const int64_t *values, size_t length) {
    if (values == NULL || length != 3) return INVALID_RESULT;
    const int64_t charge1_value = values[0];
    const int64_t charge2_value = values[1];
    const int64_t distance_value = values[2];
    if (charge1_value == 0 || charge2_value == 0 ||
        charge1_value < -MAX_CHARGE_MICROCOULOMBS || charge1_value > MAX_CHARGE_MICROCOULOMBS ||
        charge2_value < -MAX_CHARGE_MICROCOULOMBS || charge2_value > MAX_CHARGE_MICROCOULOMBS ||
        distance_value < 1 || distance_value > MAX_DISTANCE_MILLIMETERS) return INVALID_RESULT;

    const double charge1 = (double)charge1_value / 1000000.0;
    const double charge2 = (double)charge2_value / 1000000.0;
    const double distance = (double)distance_value / 1000.0;
    double charge_product = charge1 * charge2;
    if (charge_product < 0.0) charge_product = -charge_product;
    return COULOMBS_CONSTANT * charge_product / (distance * distance);
}
