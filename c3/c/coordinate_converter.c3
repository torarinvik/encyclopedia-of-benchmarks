module coordinate_converter;

extern fn double sqrt(double value);
extern fn double atan2(double y, double x);
extern fn double cos(double value);
extern fn double sin(double value);

const double INVALID_RESULT = -1.0e300;
const double COORDINATE_LIMIT = 1000000.0;
const double ANGLE_LIMIT_DEGREES = 36000.0;
const double DEGREES_PER_RADIAN = 57.2957795130823208768;
const double RADIANS_PER_DEGREE = 0.0174532925199432957692;

fn double coordinate_converter(double first, double second, double component) @export("coordinate_converter") {
    if (component == 0.0 || component == 1.0) {
        if (first != first || second != second || first < -COORDINATE_LIMIT || first > COORDINATE_LIMIT ||
            second < -COORDINATE_LIMIT || second > COORDINATE_LIMIT) return INVALID_RESULT;
        if (component == 0.0) return sqrt(first * first + second * second);
        return atan2(second, first) * DEGREES_PER_RADIAN;
    }
    if (component == 2.0 || component == 3.0) {
        if (first != first || second != second || first < 0.0 || first > COORDINATE_LIMIT ||
            second < -ANGLE_LIMIT_DEGREES || second > ANGLE_LIMIT_DEGREES) return INVALID_RESULT;
        double radians = second * RADIANS_PER_DEGREE;
        return first * (component == 2.0 ? cos(radians) : sin(radians));
    }
    return INVALID_RESULT;
}
