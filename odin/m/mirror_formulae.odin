package mirror_formulae

valid_distance :: proc(value: f64) -> bool {
    return (value >= -1.0e6 && value <= -1.0e-6) || (value >= 1.0e-6 && value <= 1.0e6)
}

// The source module exposes three mirror-equation rearrangements.
@(export)
mirror_formulae :: proc "c" (distance_a, distance_b, operation_code: f64) -> f64 {
    invalid: f64 = -1.0e300
    if !valid_distance(distance_a) || !valid_distance(distance_b)
        || !(operation_code == 0.0 || operation_code == 1.0 || operation_code == 2.0) {
        return invalid
    }

    denominator: f64
    if operation_code == 0.0 {
        denominator = (1.0 / distance_a) + (1.0 / distance_b)
    } else {
        denominator = (1.0 / distance_a) - (1.0 / distance_b)
    }
    if denominator == 0.0 {
        return invalid
    }
    return 1.0 / denominator
}
