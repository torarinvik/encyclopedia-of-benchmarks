module speed;

const double INVALID_RESULT = -1.0e300;
const long MAX_SPEED_MICRO = 1000000000000000L;
const double MAX_ROUNDED_MILLI = 9007199254740992.0;

fn double to_kmh_factor(long unit) {
    if (unit == 0) return 1.0;
    if (unit == 1) return 3.6;
    if (unit == 2) return 1.609344;
    if (unit == 3) return 1.852;
    if (unit == 4) return 1.09728;
    if (unit == 5) return 1225.08;
    return 1079252848.8;
}

fn double from_kmh_factor(long unit) {
    if (unit == 0) return 1.0;
    if (unit == 1) return 0.277777778;
    if (unit == 2) return 0.621371192;
    if (unit == 3) return 0.539956803;
    if (unit == 4) return 0.911344415;
    if (unit == 5) return 0.000816164;
    return 9.265669311e-10;
}

fn double round_three_away(double scaled) {
    if (scaled == 0.0) return scaled / 1000.0;
    bool negative = scaled < 0.0;
    double magnitude = negative ? -scaled : scaled;
    ulong rounded_milli = (ulong)magnitude;
    if (magnitude - (double)rounded_milli >= 0.5) rounded_milli++;
    double rounded = (double)rounded_milli / 1000.0;
    return negative ? -rounded : rounded;
}

fn double speed(long* values, usz length) @export("speed") {
    if (values == null || length != 3) return INVALID_RESULT;
    long speed_micro = values[0], from_unit = values[1], to_unit = values[2];
    if (speed_micro < -MAX_SPEED_MICRO || speed_micro > MAX_SPEED_MICRO ||
        from_unit < 0 || from_unit > 6 || to_unit < 0 || to_unit > 6) return INVALID_RESULT;
    double speed_value = (double)speed_micro / 1000000.0;
    double kmh = speed_value * to_kmh_factor(from_unit);
    double result = kmh * from_kmh_factor(to_unit);
    double scaled = result * 1000.0;
    if (scaled > MAX_ROUNDED_MILLI || scaled < -MAX_ROUNDED_MILLI) return INVALID_RESULT;
    return round_three_away(scaled);
}
