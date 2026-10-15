module resistor_equivalence;

const double INVALID_RESULT = -1.0e300;

fn double resistor_equivalence(long* values, usz length) @export("resistor_equivalence") {
    if (values == null || length < 2 || length > 33) return INVALID_RESULT;
    long operation = values[0];
    if (operation != 0 && operation != 1) return INVALID_RESULT;
    double accumulated = 0.0;
    for (usz index = 1; index < length; index++) {
        long resistor = values[index];
        if (resistor < (operation == 0 ? 1 : 0) || resistor > 1000) return INVALID_RESULT;
        if (operation == 0) {
            accumulated += 1.0 / (double)resistor;
        } else {
            accumulated += (double)resistor;
        }
    }
    if (operation == 0) return 1.0 / accumulated;
    return accumulated;
}
