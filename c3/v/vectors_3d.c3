module vectors_3d;

extern fn double sqrt(double value);
extern fn double acos(double value);

const double COMPONENT_LIMIT = 1000000.0;
const double EPSILON = 1.0e-9;

fn float dot_product(float ax, float ay, float az, float bx, float by, float bz) {
    float dot = ax * bx;
    dot += ay * by;
    dot += az * bz;
    return dot;
}

fn float vector_norm(float x, float y, float z) {
    float dot = dot_product(x, y, z, x, y, z);
    return (float)sqrt((double)dot);
}

fn long vectors_3d(double* input, usz input_len, double* output, usz output_capacity)
        @export("vectors_3d") {
    if (input == null || input_len == 0) return -1;
    double operation_value = input[0];
    if (operation_value != operation_value || operation_value < 0.0 || operation_value > 7.0 ||
        operation_value != (double)(long)operation_value) return -1;
    long operation = (long)operation_value;
    usz required_length = (operation <= 3 || operation == 7) ? 7 : 4;
    if (input_len != required_length) return -1;

    float[6] components = {0};
    usz component_count = required_length - 1;
    for (usz index = 0; index < component_count; index++) {
        double value = input[index + 1];
        if (value != value || value < -COMPONENT_LIMIT || value > COMPONENT_LIMIT) return -1;
        components[index] = (float)value;
    }
    float ax = components[0], ay = components[1], az = components[2];
    float bx = components[3], by = components[4], bz = components[5];
    double[9] result = {0};
    usz result_length = 0;

    if (operation == 0) {
        result_length = 3;
        result[0] = (double)(ax + bx); result[1] = (double)(ay + by); result[2] = (double)(az + bz);
    } else if (operation == 1) {
        result_length = 3;
        result[0] = (double)(ax - bx); result[1] = (double)(ay - by); result[2] = (double)(az - bz);
    } else if (operation == 2) {
        result_length = 1;
        result[0] = (double)dot_product(ax, ay, az, bx, by, bz);
    } else if (operation == 3) {
        result_length = 3;
        result[0] = (double)(ay * bz - az * by);
        result[1] = (double)(-ax * bz + az * bx);
        result[2] = (double)(ax * by - ay * bx);
    } else if (operation == 4) {
        result_length = 1;
        result[0] = (double)vector_norm(ax, ay, az);
    } else if (operation == 5) {
        result_length = 3;
        float norm = vector_norm(ax, ay, az);
        if ((double)norm >= EPSILON && norm != 1.0f) {
            result[0] = (double)(ax / norm); result[1] = (double)(ay / norm); result[2] = (double)(az / norm);
        }
    } else if (operation == 6) {
        result_length = 9;
        result[0] = 0.0; result[1] = (double)-az; result[2] = (double)ay;
        result[3] = (double)az; result[4] = 0.0; result[5] = (double)-ax;
        result[6] = (double)-ay; result[7] = (double)ax; result[8] = 0.0;
    } else {
        result_length = 1;
        float norm_a = vector_norm(ax, ay, az), norm_b = vector_norm(bx, by, bz);
        if ((double)norm_a < EPSILON || (double)norm_b < EPSILON) result[0] = acos(2.0);
        else {
            float cosine = dot_product(ax, ay, az, bx, by, bz) / (norm_a * norm_b);
            result[0] = acos((double)cosine);
        }
    }

    if (output == null || output_capacity < result_length) return -2;
    for (usz index = 0; index < result_length; index++) output[index] = result[index];
    return (long)result_length;
}
