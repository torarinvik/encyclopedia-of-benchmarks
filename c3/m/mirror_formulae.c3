module mirror_formulae;

fn bool valid_distance(double value) {
    return (value >= -1.0e6 && value <= -1.0e-6)
        || (value >= 1.0e-6 && value <= 1.0e6);
}

// The source module exposes three mirror-equation rearrangements.
fn double mirror_formulae(double distance_a, double distance_b, double operation_code) @export("mirror_formulae") {
    double invalid = -1.0e300;
    if (!valid_distance(distance_a) || !valid_distance(distance_b)
        || !(operation_code == 0.0 || operation_code == 1.0 || operation_code == 2.0)) {
        return invalid;
    }

    double denominator;
    if (operation_code == 0.0) {
        denominator = (1.0 / distance_a) + (1.0 / distance_b);
    } else {
        denominator = (1.0 / distance_a) - (1.0 / distance_b);
    }
    if (denominator == 0.0) return invalid;
    return 1.0 / denominator;
}
