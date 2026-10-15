fn absolute(value: f64) f64 {
    return if (value < 0.0) -value else value;
}

export fn babylonian_sqrt(input: f64) f64 {
    if (!(input >= 0.0 and input <= 1_000_000.0)) return -1.0;
    var estimate = input / 2.0;
    const tolerance: f64 = 0.000001;
    while (tolerance <= absolute(estimate * estimate - input)) {
        estimate = 0.5 * (estimate + input / estimate);
    }
    return estimate;
}
