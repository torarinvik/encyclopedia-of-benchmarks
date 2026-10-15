module babylonian_sqrt;

fn double absolute(double value) {
    return value < 0.0 ? -value : value;
}

fn double babylonian_sqrt(double input) @export("babylonian_sqrt") {
    if (!(input >= 0.0 && input <= 1000000.0)) return -1.0;
    double estimate = input / 2.0;
    double tolerance = 0.000001;
    while (tolerance <= absolute(estimate * estimate - input)) {
        estimate = 0.5 * (estimate + input / estimate);
    }
    return estimate;
}
