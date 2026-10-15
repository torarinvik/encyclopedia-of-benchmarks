module distance_between_two_points;

extern fn double sqrt(double value);

const long MAX_COORDINATE = 1000000;
const double INVALID_RESULT = -1.0e300;

fn double distance_between_two_points(long* values, usz length) @export("distance_between_two_points") {
    if (values == null || length != 4) return INVALID_RESULT;
    for (usz index = 0; index < 4; index++) {
        if (values[index] < -MAX_COORDINATE || values[index] > MAX_COORDINATE) return INVALID_RESULT;
    }
    double dx = (double)(values[2] - values[0]);
    double dy = (double)(values[3] - values[1]);
    return sqrt(dx * dx + dy * dy);
}
