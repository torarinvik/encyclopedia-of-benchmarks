module rodrigues_arbitrary_axis_rotation;

extern fn double sqrt(double value);
extern fn double cos(double value);
extern fn double sin(double value);

const double COMPONENT_LIMIT = 1000000.0;
const double ANGLE_LIMIT = 6.283185307179586;
const double OUTPUT_LIMIT = 2000000.0;

fn long rodrigues_arbitrary_axis_rotation(double* input, usz input_len,
                                          double* output, usz output_capacity)
                                          @export("rodrigues_arbitrary_axis_rotation") {
    if (input == null || input_len != 7) return -1;
    for (usz i = 0; i < 6; i++) {
        double value = input[i];
        if (value != value || value < -COMPONENT_LIMIT || value > COMPONENT_LIMIT) return -1;
    }
    double theta = input[6];
    if (theta != theta || theta < -ANGLE_LIMIT || theta > ANGLE_LIMIT) return -1;
    double scale = input[0];
    if (scale < 0.0) scale = -scale;
    double next = input[1];
    if (next < 0.0) next = -next;
    if (next > scale) scale = next;
    next = input[2];
    if (next < 0.0) next = -next;
    if (next > scale) scale = next;
    if (scale == 0.0) return -1;
    double qx = input[0] / scale;
    double qy = input[1] / scale;
    double qz = input[2] / scale;
    double norm = sqrt((qx * qx + qy * qy) + qz * qz);
    if (norm != norm || norm == 0.0) return -1;
    double nx = qx / norm;
    double ny = qy / norm;
    double nz = qz / norm;
    double vx = input[3], vy = input[4], vz = input[5];
    double cosine = cos(theta), sine = sin(theta);
    double one_minus_cosine = 1.0 - cosine;
    double cx = ny * vz - nz * vy;
    double cy = nz * vx - nx * vz;
    double cz = nx * vy - ny * vx;
    double dot = (nx * vx + ny * vy) + nz * vz;
    double[3] result;
    result[0] = (vx * cosine + cx * sine) + (nx * dot) * one_minus_cosine;
    result[1] = (vy * cosine + cy * sine) + (ny * dot) * one_minus_cosine;
    result[2] = (vz * cosine + cz * sine) + (nz * dot) * one_minus_cosine;
    for (usz i = 0; i < 3; i++) {
        double value = result[i];
        if (value != value || value < -OUTPUT_LIMIT || value > OUTPUT_LIMIT) return -1;
    }
    if (output == null || output_capacity < 3) return -2;
    for (usz i = 0; i < 3; i++) output[i] = result[i];
    return 3;
}
