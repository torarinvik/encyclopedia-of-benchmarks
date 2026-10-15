module rms_speed_of_molecule;

extern fn double pow(double base, double exponent);
const double INVALID_RESULT = -1.0e300;

fn double rms_speed_of_molecule(long* values, usz length) @export("rms_speed_of_molecule") {
    if (values == null || length != 2) return INVALID_RESULT;
    long temperature = values[0];
    long molar_mass = values[1];
    if (temperature < 0 || temperature > 1000 || molar_mass < 1 || molar_mass > 1000)
        return INVALID_RESULT;
    double numerator = (3.0 * 8.3144598) * (double)temperature;
    return pow(numerator / (double)molar_mass, 0.5);
}
