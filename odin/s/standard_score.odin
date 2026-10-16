package standard_score

@(export)
standard_score :: proc "c" (value, mean, std_dev: f64) -> f64 {
    valid_std_dev := (std_dev >= -1_000_000.0 && std_dev <= -0.000001) ||
                     (std_dev >= 0.000001 && std_dev <= 1_000_000.0)
    if !(value >= -1_000_000.0 && value <= 1_000_000.0) ||
       !(mean >= -1_000_000.0 && mean <= 1_000_000.0) || !valid_std_dev {
        return -1e300
    }
    return (value - mean) / std_dev
}
