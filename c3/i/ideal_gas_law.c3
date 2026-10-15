module ideal_gas_law;

const double INVALID_RESULT = -1.0e300;

// Pressure from the ideal gas law: n * T * R / V.
fn double ideal_gas_law(long* values, usz length) @export("ideal_gas_law") {
    if (length != 3 || values == null) return INVALID_RESULT;
    long moles = values[0];
    long kelvin = values[1];
    long volume = values[2];
    if (moles < 0 || moles > 1000 || kelvin < 0 || kelvin > 1000 || volume < 1 || volume > 1000)
        return INVALID_RESULT;
    return ((double)moles * (double)kelvin * 8.314462) / (double)volume;
}
