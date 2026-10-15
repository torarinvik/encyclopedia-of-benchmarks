module kinetic_energy;

const double INVALID_RESULT = -1.0e300;

// Classical kinetic energy: 0.5 * mass * abs(velocity)^2.
fn double kinetic_energy(long* values, usz length) @export("kinetic_energy") {
    if (length != 2 || values == null) return INVALID_RESULT;
    long mass = values[0];
    long velocity = values[1];
    if (mass < 0 || mass > 1000 || velocity < -1000 || velocity > 1000)
        return INVALID_RESULT;
    long speed = velocity < 0 ? -velocity : velocity;
    return ((0.5 * (double)mass) * (double)speed) * (double)speed;
}
