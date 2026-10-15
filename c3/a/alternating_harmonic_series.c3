module alternating_harmonic_series;

const MAX_COUNT = 1000;

// Check that each packed rational matches its canonical alternating term.
fn long alternating_harmonic_series(long* values, usz length) @export("alternating_harmonic_series") {
    if (length < 1 || length > 1 + 2 * MAX_COUNT || values == null) { return -1; }
    long count_value = values[0];
    if (count_value < 0 || count_value > MAX_COUNT) { return -1; }
    usz count = (usz)count_value;
    if (length != 1 + 2 * count) { return -1; }
    if (count == 0) { return 0; }

    for (usz index = 0; index < count; index++) {
        long numerator = values[1 + 2 * index];
        long denominator = values[2 + 2 * index];
        if (numerator < -1000 || numerator > 1000 || denominator < 1 || denominator > 1000) { return -1; }
        long signed_denominator = (index % 2 == 0) ? denominator : -denominator;
        long difference = numerator * (long)(index + 1) - signed_denominator;
        if (difference < 0) { difference = -difference; }
        if (difference * 1000000000L > denominator * (long)(index + 1)) { return 0; }
    }
    return 1;
}
