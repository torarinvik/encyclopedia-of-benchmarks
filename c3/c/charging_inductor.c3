module charging_inductor;

extern fn double exp(double value);
const double INVALID_RESULT = -1.0e300;

fn double round_three_python(double value) {
    if (value == 0.0) return value;
    bool negative = value < 0.0;
    double normalized = negative ? -value : value;
    long exponent = 0;
    while (normalized >= 1.0) { normalized *= 0.5; exponent++; }
    while (normalized < 0.5) { normalized *= 2.0; exponent--; }
    ulong significand = (ulong)(normalized * 9007199254740992.0);
    ulong numerator = significand * 1000;
    long shift = 53 - exponent;
    ulong milliunits = 0;
    if (shift < 0) milliunits = numerator << (uint)(-shift);
    else if (shift == 0) milliunits = numerator;
    else if (shift < 64) {
        ulong denominator = ulong(1) << (uint)shift;
        milliunits = numerator >> (uint)shift;
        ulong remainder = numerator & (denominator - 1);
        ulong half = denominator >> 1;
        if (remainder > half || (remainder == half && (milliunits & 1) != 0)) milliunits++;
    }
    double rounded = (double)milliunits / 1000.0;
    return negative ? -rounded : rounded;
}

fn double charging_inductor(long* values, usz length) @export("charging_inductor") {
    if (values == null || length != 4) return INVALID_RESULT;
    long voltage_micro = values[0], resistance_micro = values[1];
    long inductance_micro = values[2], time_micro = values[3];
    if (voltage_micro < 1 || voltage_micro > 1000000000000L ||
        resistance_micro < 10000 || resistance_micro > 1000000000000000L ||
        inductance_micro < 1 || inductance_micro > 1000000000000L ||
        time_micro < -1000000000000L || time_micro > 1000000000000L) return INVALID_RESULT;
    double source_voltage = (double)voltage_micro / 1000000.0;
    double resistance = (double)resistance_micro / 1000000.0;
    double inductance = (double)inductance_micro / 1000000.0;
    double time_sec = (double)time_micro / 1000000.0;
    double exponent = (-time_sec * resistance) / inductance;
    if (exponent > 10.0) return INVALID_RESULT;
    return round_three_python(source_voltage / resistance * (1.0 - exp(exponent)));
}
