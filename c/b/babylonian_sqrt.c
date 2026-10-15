/* Babylonian square root using the pinned Julia defaults. */
static double absolute(double value)
{
    return value < 0.0 ? -value : value;
}

double babylonian_sqrt(double input)
{
    if (!(input >= 0.0 && input <= 1000000.0)) return -1.0;
    double estimate = input / 2.0;
    const double tolerance = 0.000001;
    while (tolerance <= absolute(estimate * estimate - input)) {
        estimate = 0.5 * (estimate + input / estimate);
    }
    return estimate;
}
