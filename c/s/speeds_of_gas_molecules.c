#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH ((size_t)4)
#define MAX_TEMPERATURE_MK INT64_C(1000000)
#define MAX_MOLAR_MASS_MICRO INT64_C(1000000000)
#define GAS_CONSTANT 8.31446261815324
#define PI_VALUE 3.14159265358979323846264338327950288
#define INVALID_RESULT (-1.0e300)

double speeds_of_gas_molecules(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const int64_t operation = input[0];
    const int64_t temperature_mk = input[1];
    const int64_t molar_mass_micro = input[2];
    if (length != 3 || operation < 0 || operation > 1 ||
        temperature_mk < 0 || temperature_mk > MAX_TEMPERATURE_MK ||
        molar_mass_micro < 1 || molar_mass_micro > MAX_MOLAR_MASS_MICRO) return INVALID_RESULT;

    const double temperature = (double)temperature_mk / 1000.0;
    const double molar_mass = (double)molar_mass_micro / 1000000.0;
    if (operation == 0)
        return pow((8.0 * GAS_CONSTANT * temperature) / (PI_VALUE * molar_mass), 0.5);
    return pow((2.0 * GAS_CONSTANT * temperature) / molar_mass, 0.5);
}
