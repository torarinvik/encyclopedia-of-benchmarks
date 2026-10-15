module newtons_second_law_of_motion;

const double INVALID_RESULT = -1.0e300;

fn double newtons_second_law_of_motion(long* values, usz length) @export("newtons_second_law_of_motion") {
    if (values == null || length != 2) return INVALID_RESULT;
    long mass = values[0];
    long acceleration = values[1];
    if (mass < -1000 || mass > 1000 || acceleration < -1000 || acceleration > 1000)
        return INVALID_RESULT;
    return (double)mass * (double)acceleration;
}
