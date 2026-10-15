module relativistic_velocity_summation;

const long SPEED_OF_LIGHT = 299792458;
const double INVALID_RESULT = -1.0e300;

fn double relativistic_velocity_summation(long* values, usz length) @export("relativistic_velocity_summation") {
    if (values == null || length != 2) return INVALID_RESULT;
    long object_velocity = values[0];
    long frame_velocity = values[1];
    if (object_velocity < -SPEED_OF_LIGHT || object_velocity > SPEED_OF_LIGHT ||
        frame_velocity < -(SPEED_OF_LIGHT - 1) || frame_velocity > SPEED_OF_LIGHT - 1)
        return INVALID_RESULT;
    long numerator = object_velocity + frame_velocity;
    double denominator = 1.0 + (double)(object_velocity * frame_velocity) /
        (double)(SPEED_OF_LIGHT * SPEED_OF_LIGHT);
    return (double)numerator / denominator;
}
