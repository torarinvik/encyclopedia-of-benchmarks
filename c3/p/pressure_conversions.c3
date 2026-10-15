module pressure_conversions;

fn double from_factor(double code) {
    if (code == 0.0) return 1.0;
    if (code == 1.0) return 0.0000098;
    if (code == 2.0) return 0.986923;
    if (code == 3.0) return 0.00986923;
    if (code == 4.0) return 9.86923;
    if (code == 5.0) return 0.068046;
    if (code == 6.0) return 0.0334211;
    if (code == 7.0) return 0.00131579;
    return 0.0;
}

fn double to_factor(double code) {
    if (code == 0.0) return 1.0;
    if (code == 1.0) return 101325.0;
    if (code == 2.0) return 1.01325;
    if (code == 3.0) return 101.325;
    if (code == 4.0) return 0.101325;
    if (code == 5.0) return 14.6959;
    if (code == 6.0) return 29.9213;
    if (code == 7.0) return 760.0;
    return 0.0;
}

fn double pressure_conversions(double value, double from_code, double to_code) @export("pressure_conversions") {
    if (value != value || value < -1000000.0 || value > 1000000.0) return -1.0;
    double source = from_factor(from_code);
    double target = to_factor(to_code);
    if (source == 0.0 || target == 0.0) return -1.0;
    double scaled = value * source;
    return scaled * target;
}
