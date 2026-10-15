module hookes_law;

const double INVALID_RESULT = -1.0e300;

fn double hookes_law(long* values, usz length) @export("hookes_law") {
    if (values == null || length != 2) return INVALID_RESULT;
    long spring_constant = values[0];
    long displacement = values[1];
    if (spring_constant < 1 || spring_constant > 1000 || displacement < -1000 || displacement > 1000)
        return INVALID_RESULT;
    return (-(double)spring_constant) * (double)displacement;
}
