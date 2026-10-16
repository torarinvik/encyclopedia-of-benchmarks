module ground_to_ground_projectile_motion;

extern fn double sin(double value);
extern fn double cos(double value);
extern fn double pow(double base, double exponent);

const long INPUT_SCALE = 1000000;
const long MAX_SPEED = 1000000000;
const long MAX_ANGLE = 360000000;
const long MIN_GRAVITY = 1000;
const long MAX_GRAVITY = 100000000;
const long MAX_TIME = 1000000000;
const double INVALID_RESULT = -1.0e300;
const double PI_VALUE = 3.14159265358979323846264338327950288;

fn double ground_to_ground_projectile_motion_impl(long* values, usz length) {
    if (values == null || length != 4) return INVALID_RESULT;
    long operation = values[0], speed_value = values[1];
    long angle_value = values[2], auxiliary_value = values[3];
    if (operation < 0 || operation > 2 || speed_value < 0 || speed_value > MAX_SPEED ||
        angle_value < -MAX_ANGLE || angle_value > MAX_ANGLE) return INVALID_RESULT;
    if (operation == 1) {
        if (auxiliary_value < 0 || auxiliary_value > MAX_TIME) return INVALID_RESULT;
    } else if (auxiliary_value < MIN_GRAVITY || auxiliary_value > MAX_GRAVITY) {
        return INVALID_RESULT;
    }

    double speed = (double)speed_value / (double)INPUT_SCALE;
    double angle = (double)angle_value / (double)INPUT_SCALE;
    double radians = angle * (PI_VALUE / 180.0);
    double vertical_velocity = speed * sin(radians);
    if (operation == 0) {
        double gravity = (double)auxiliary_value / (double)INPUT_SCALE;
        return 2.0 * vertical_velocity / gravity;
    }
    if (operation == 1) {
        double time = (double)auxiliary_value / (double)INPUT_SCALE;
        return (speed * cos(radians)) * time;
    }
    double gravity = (double)auxiliary_value / (double)INPUT_SCALE;
    return pow(vertical_velocity, 2.0) / (2.0 * gravity);
}

fn double ground_to_ground_projectile_motion(long* values, usz length)
    @export("ground_to_ground_projectile_motion") {
    return ground_to_ground_projectile_motion_impl(values, length);
}
