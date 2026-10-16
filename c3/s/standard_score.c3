module standard_score;

fn double standard_score(double value, double mean, double std_dev) @export("standard_score") {
    bool valid_std_dev =
        (std_dev >= -1000000.0 && std_dev <= -0.000001) ||
        (std_dev >= 0.000001 && std_dev <= 1000000.0);
    if (!(value >= -1000000.0 && value <= 1000000.0) ||
        !(mean >= -1000000.0 && mean <= 1000000.0) || !valid_std_dev) {
        return -1e300;
    }
    return (value - mean) / std_dev;
}
