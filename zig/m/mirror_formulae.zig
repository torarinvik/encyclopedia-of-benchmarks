fn valid_distance(value: f64) bool {
    return (value >= -1.0e6 and value <= -1.0e-6) or (value >= 1.0e-6 and value <= 1.0e6);
}

/// The source module exposes three mirror-equation rearrangements.
export fn mirror_formulae(distance_a: f64, distance_b: f64, operation_code: f64) f64 {
    const invalid = -1.0e300;
    if (!valid_distance(distance_a) or !valid_distance(distance_b)
        or !(operation_code == 0.0 or operation_code == 1.0 or operation_code == 2.0)) {
        return invalid;
    }

    const denominator = if (operation_code == 0.0)
        (1.0 / distance_a) + (1.0 / distance_b)
    else
        (1.0 / distance_a) - (1.0 / distance_b);
    if (denominator == 0.0) {
        return invalid;
    }
    return 1.0 / denominator;
}
