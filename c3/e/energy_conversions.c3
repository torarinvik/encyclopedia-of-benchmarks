module energy_conversions;

fn double factor(double code) {
    if (code == 0.0) return 1.0;
    if (code == 1.0) return 1000.0;
    if (code == 2.0) return 1000000.0;
    if (code == 3.0) return 1000000000.0;
    if (code == 4.0) return 1.0;
    if (code == 5.0) return 3600.0;
    if (code == 6.0) return 3600000.0;
    if (code == 7.0) return 1.0;
    if (code == 8.0) return 4186.8;
    if (code == 9.0) return 4186800.0;
    if (code == 10.0) return 1.602176634e-19;
    if (code == 11.0) return 1055.05585;
    if (code == 12.0) return 1.355818;
    return 0.0;
}

fn double energy_conversions(double value, double from_code, double to_code) @export("energy_conversions") {
    if (value != value || value < -1000000.0 || value > 1000000.0) return -1e300;
    double source = factor(from_code);
    double target = factor(to_code);
    if (source == 0.0 || target == 0.0) return -1e300;
    double scaled = value * source;
    return scaled / target;
}
