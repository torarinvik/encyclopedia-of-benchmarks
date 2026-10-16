/* Source formula: (value - mean) / std_dev. */
double standard_score(double value, double mean, double std_dev)
{
    const int valid_value = value >= -1000000.0 && value <= 1000000.0;
    const int valid_mean = mean >= -1000000.0 && mean <= 1000000.0;
    const int valid_std_dev =
        (std_dev >= -1000000.0 && std_dev <= -0.000001) ||
        (std_dev >= 0.000001 && std_dev <= 1000000.0);
    if (!valid_value || !valid_mean || !valid_std_dev) return -1e300;
    return (value - mean) / std_dev;
}
