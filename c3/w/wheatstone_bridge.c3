module wheatstone_bridge;

const double INVALID_RESULT = -1.0e300;

fn double wheatstone_bridge(long* values, usz length) @export("wheatstone_bridge") {
    if (values == null || length != 3) return INVALID_RESULT;
    long resistance_1 = values[0];
    long resistance_2 = values[1];
    long resistance_3 = values[2];
    if (resistance_1 < 1 || resistance_1 > 1000000 ||
        resistance_2 < 1 || resistance_2 > 1000000 ||
        resistance_3 < 1 || resistance_3 > 1000000) return INVALID_RESULT;
    return ((double)resistance_2 / (double)resistance_1) * (double)resistance_3;
}
