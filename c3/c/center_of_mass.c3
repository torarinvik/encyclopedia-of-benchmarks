module center_of_mass;

const double INVALID_RESULT = -1.0e300;
const MAX_PARTICLES = 64;
const MAX_COORDINATE_UNITS = 1000000;
const MAX_MASS_UNITS = 1000000;

// Round the exact binary64 input to cents, matching Python round(value, 2).
fn double round_two_python(double value) {
    if (value == 0.0) return value;
    bool negative = value < 0.0;
    double normalized = negative ? -value : value;
    long exponent = 0;
    while (normalized >= 1.0) { normalized *= 0.5; exponent++; }
    while (normalized < 0.5) { normalized *= 2.0; exponent--; }
    ulong significand = (ulong)(normalized * 9007199254740992.0);
    ulong numerator = significand * 100;
    long shift = 53 - exponent;
    ulong cents = 0;
    if (shift < 0) cents = numerator << (uint)(-shift);
    else if (shift == 0) cents = numerator;
    else if (shift < 64) {
        ulong denominator = ulong(1) << (uint)shift;
        cents = numerator >> (uint)shift;
        ulong remainder = numerator & (denominator - 1);
        ulong half = denominator >> 1;
        if (remainder > half || (remainder == half && (cents & 1) != 0)) cents++;
    }
    double rounded = (double)cents / 100.0;
    return negative ? -rounded : rounded;
}

fn double center_of_mass(long* values, usz length) @export("center_of_mass") {
    if (values == null || length < 2 || length > 258) return INVALID_RESULT;
    long selector = values[0];
    long count_value = values[1];
    if (selector < 0 || selector > 2 || count_value < 1 || count_value > MAX_PARTICLES ||
        length != 2 + 4 * (usz)count_value) return INVALID_RESULT;
    usz count = (usz)count_value;
    for (usz index = 0; index < count; index++) {
        usz offset = 2 + 4 * index;
        for (usz coordinate = 0; coordinate < 3; coordinate++)
            if (values[offset + coordinate] < -MAX_COORDINATE_UNITS ||
                values[offset + coordinate] > MAX_COORDINATE_UNITS) return INVALID_RESULT;
        if (values[offset + 3] < 1 || values[offset + 3] > MAX_MASS_UNITS) return INVALID_RESULT;
    }
    double total_mass = 0.0;
    for (usz index = 0; index < count; index++)
        total_mass += (double)values[2 + 4 * index + 3] / 1000.0;
    double weighted_coordinate = 0.0;
    for (usz index = 0; index < count; index++) {
        usz offset = 2 + 4 * index;
        double coordinate = (double)values[offset + (usz)selector] / 1000.0;
        double mass = (double)values[offset + 3] / 1000.0;
        weighted_coordinate += coordinate * mass;
    }
    return round_two_python(weighted_coordinate / total_mass);
}
