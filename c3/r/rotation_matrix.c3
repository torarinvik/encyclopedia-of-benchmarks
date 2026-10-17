module rotation_matrix;
import "math";

const double MAX_ANGLE = 1000.0;

fn long rotation_matrix(double* input, usz input_length,
        double* output, usz output_capacity) @export("rotation_matrix") {
    if (input == null || input_length != 1) return -1;
    double theta = input[0];
    if (theta != theta || theta < -MAX_ANGLE || theta > MAX_ANGLE) return -1;
    double cosine = math.cos(theta);
    double sine = math.sin(theta);
    double[4] matrix = {cosine, -sine, sine, cosine};
    if (output == null || output_capacity < 4) return -2;
    for (usz index = 0; index < 4; index++) output[index] = matrix[index];
    return 4;
}
