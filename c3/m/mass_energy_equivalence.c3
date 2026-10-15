module mass_energy_equivalence;

const double INVALID_RESULT = -1.0e300;
const double SPEED_OF_LIGHT = 299792458.0;
const double SPEED_OF_LIGHT_SQUARED = SPEED_OF_LIGHT * SPEED_OF_LIGHT;

fn double mass_energy_equivalence(long* values, usz length) @export("mass_energy_equivalence") {
    if (values == null || length != 2) return INVALID_RESULT;
    long operation = values[0], value = values[1];
    if ((operation != 0 && operation != 1) || value < 0 || value > 1000000000) return INVALID_RESULT;
    if (operation == 0) return (double)value * SPEED_OF_LIGHT_SQUARED;
    return (double)value / SPEED_OF_LIGHT_SQUARED;
}
