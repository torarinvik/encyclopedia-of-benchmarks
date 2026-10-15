module circular_arc;
const double INVALID_RESULT = -1.0e300;

fn double circular_arc(long* input, usz length) @export("circular_arc") {
    if (input == null || length != 3) return INVALID_RESULT;
    long mode = input[0], radius = input[1], degrees = input[2];
    if ((mode != 0 && mode != 1) || radius < -1000000 || radius > 1000000 || degrees < -360000 || degrees > 360000) return INVALID_RESULT;
    double angle = (double)degrees * (3.14159265358979323846 / 180.0);
    if (mode == 0) return (double)radius * angle;
    return (double)(radius * radius) * angle / 2.0;
}
