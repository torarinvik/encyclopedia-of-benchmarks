module speeds_of_gas_molecules;

extern fn double pow(double base, double exponent);

const usz MAX_INPUT_LENGTH = 4;
const long MAX_TEMPERATURE_MK = 1000000;
const long MAX_MOLAR_MASS_MICRO = 1000000000;
const double GAS_CONSTANT = 8.31446261815324;
const double PI_VALUE = 3.14159265358979323846264338327950288;
const double INVALID_RESULT = -1.0e300;

fn double speeds_of_gas_molecules(long* input, usz length) @export("speeds_of_gas_molecules") {
    if (input == null || length < 3 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    long operation = input[0];
    long temperature_mk = input[1];
    long molar_mass_micro = input[2];
    if (length != 3 || operation < 0 || operation > 1 ||
        temperature_mk < 0 || temperature_mk > MAX_TEMPERATURE_MK ||
        molar_mass_micro < 1 || molar_mass_micro > MAX_MOLAR_MASS_MICRO) return INVALID_RESULT;

    double temperature = (double)temperature_mk / 1000.0;
    double molar_mass = (double)molar_mass_micro / 1000000.0;
    if (operation == 0)
        return pow((8.0 * GAS_CONSTANT * temperature) / (PI_VALUE * molar_mass), 0.5);
    return pow((2.0 * GAS_CONSTANT * temperature) / molar_mass, 0.5);
}
