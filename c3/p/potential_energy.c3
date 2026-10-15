module potential_energy;

const double INVALID_RESULT = -1.0e300;

// Gravitational potential energy: mass * standard gravity * height.
fn double potential_energy(long* values, usz length) @export("potential_energy") {
    if (length != 2 || values == null) return INVALID_RESULT;
    long mass = values[0];
    long height = values[1];
    if (mass < 0 || mass > 1000 || height < 0 || height > 1000)
        return INVALID_RESULT;
    return ((double)mass * 9.80665) * (double)height;
}
