module capacitor_equivalence;

const double INVALID_RESULT = -1.0e300;

fn double capacitor_equivalence(long* values, usz length) @export("capacitor_equivalence") {
    if (values == null || length < 2 || length > 33) return INVALID_RESULT;
    long operation = values[0];
    if (operation != 0 && operation != 1) return INVALID_RESULT;
    double accumulated = 0.0;
    for (usz index = 1; index < length; index++) {
        long capacitor = values[index];
        if (capacitor < (operation == 0 ? 0 : 1) || capacitor > 1000) return INVALID_RESULT;
        if (operation == 0) {
            accumulated += (double)capacitor;
        } else {
            accumulated += 1.0 / (double)capacitor;
        }
    }
    if (operation == 0) return accumulated;
    return 1.0 / accumulated;
}
