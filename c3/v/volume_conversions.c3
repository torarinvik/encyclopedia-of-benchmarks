module volume_conversions;

fn double unit_factor_to_cubic_meters(long unit) {
    return unit == 1 ? 0.001 : 1.0;
}

fn void put_f64_le(double value, char* output) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte++) {
        output[byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long volume_conversions(long* input, usz length, char* output, usz capacity) @export("volume_conversions") {
    if (input == null || length != 3) return -1;
    long value = input[0], from_unit = input[1], to_unit = input[2];
    if (value < 0 || value > 1000 || from_unit < 0 || from_unit > 2 ||
        to_unit < 0 || to_unit > 2 || from_unit == to_unit) return -1;
    if (capacity < 8 || output == null) return -2;
    double cubic_meters = (double)value * unit_factor_to_cubic_meters(from_unit);
    double converted = cubic_meters / unit_factor_to_cubic_meters(to_unit);
    put_f64_le(converted, output);
    return 8;
}
