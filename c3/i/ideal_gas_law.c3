module ideal_gas_law;

const double INVALID_RESULT = -1.0e300;

// Solve one ideal-gas-law variable using a portable operation selector.
fn double ideal_gas_law(long* values, usz length) @export("ideal_gas_law") {
    if (length != 4 || values == null) return INVALID_RESULT;
    long operation = values[0];
    long a = values[1], b = values[2], c = values[3];
    if (operation < 0 || operation > 3 || a < 0 || a > 1000 || b < 0 || b > 1000 || c < 0 || c > 1000)
        return INVALID_RESULT;
    if (operation == 0 || operation == 1) {
        if (c == 0) return INVALID_RESULT;
        return ((double)a * (double)b * 8.314462) / (double)c;
    }
    if (a == 0) return INVALID_RESULT;
    return ((double)c * (double)b) / ((double)a * 8.314462);
}
