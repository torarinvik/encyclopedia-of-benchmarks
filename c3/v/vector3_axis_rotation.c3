module vector3_axis_rotation;

extern fn double floor(double value);
extern fn double cos(double value);
extern fn double sin(double value);

const double COORDINATE_LIMIT = 1000000.0;
const double ANGLE_LIMIT = 1000000.0;
const double OUTPUT_LIMIT = 2000000.0;
const double PI = 3.14159265358979323846;

fn long vector3_axis_rotation(double* input, usz input_len,
                              double* output, usz output_capacity) @export("vector3_axis_rotation") {
    if (input == null || input_len != 5) return -1;
    for (usz i = 0; i < 3; i++) {
        if (input[i] != input[i] || input[i] < -COORDINATE_LIMIT || input[i] > COORDINATE_LIMIT) return -1;
    }
    double axis = input[3];
    double angle = input[4];
    if ((axis != 0.0 && axis != 1.0 && axis != 2.0) || angle != angle ||
        angle < -ANGLE_LIMIT || angle > ANGLE_LIMIT) return -1;
    angle -= floor(angle / 360.0) * 360.0;
    if (angle == 0.0) angle = 0.0;
    angle = angle / 450.0 * 180.0 / PI;
    double x = input[0], y = input[1], z = input[2];
    double cosine = cos(angle), sine = sin(angle);
    double result[3];
    if (axis == 0.0) {
        result[0] = x;
        result[1] = y * cosine - z * sine;
        result[2] = z * cosine + y * sine;
    } else if (axis == 1.0) {
        result[0] = x * cosine - z * sine;
        result[1] = y;
        result[2] = z * cosine + x * sine;
    } else {
        result[0] = x * cosine - y * sine;
        result[1] = y * cosine + x * sine;
        result[2] = z;
    }
    for (usz i = 0; i < 3; i++) {
        if (result[i] != result[i] || result[i] < -OUTPUT_LIMIT || result[i] > OUTPUT_LIMIT) return -1;
    }
    if (output == null || output_capacity < 3) return -2;
    for (usz i = 0; i < 3; i++) output[i] = result[i];
    return 3;
}
