module lens_formulae;

const double INVALID_RESULT = -1.0e300;

fn double lens_formulae(long* values, usz length) @export("lens_formulae") {
    if (values == null || length != 3) return INVALID_RESULT;
    long operation = values[0];
    long first = values[1];
    long second = values[2];
    if (operation < 0 || operation > 2 || first == 0 || second == 0 ||
        first < -1000000 || first > 1000000 || second < -1000000 || second > 1000000)
        return INVALID_RESULT;
    if (operation == 0) {
        if (first == second) return INVALID_RESULT;
        return 1.0 / ((1.0 / (double)second) - (1.0 / (double)first));
    }
    if (operation == 1) {
        if (first == second) return INVALID_RESULT;
        return 1.0 / ((1.0 / (double)second) - (1.0 / (double)first));
    }
    if (first == -second) return INVALID_RESULT;
    return 1.0 / ((1.0 / (double)second) + (1.0 / (double)first));
}
