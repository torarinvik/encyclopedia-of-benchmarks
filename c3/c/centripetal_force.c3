module centripetal_force;

const double INVALID_RESULT = -1.0e300;

// Centripetal force: (mass * velocity^2) / radius.
fn double centripetal_force(long* values, usz length) @export("centripetal_force") {
    if (length != 3 || values == null) return INVALID_RESULT;
    long mass = values[0];
    long velocity = values[1];
    long radius = values[2];
    if (mass < 0 || mass > 1000 || velocity < -1000 || velocity > 1000 || radius < 1 || radius > 1000)
        return INVALID_RESULT;
    double velocity_squared = (double)velocity * (double)velocity;
    return ((double)mass * velocity_squared) / (double)radius;
}
