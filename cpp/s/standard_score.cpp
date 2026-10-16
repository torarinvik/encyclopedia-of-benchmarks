// Source formula: (value - mean) / std_dev.
extern "C" double standard_score(double value, double mean, double std_dev) noexcept
{
    const bool valid_std_dev =
        (std_dev >= -1000000.0 && std_dev <= -0.000001) ||
        (std_dev >= 0.000001 && std_dev <= 1000000.0);
    if (!(value >= -1000000.0 && value <= 1000000.0) ||
        !(mean >= -1000000.0 && mean <= 1000000.0) || !valid_std_dev) {
        return -1e300;
    }
    return (value - mean) / std_dev;
}
