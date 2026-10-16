module conjugate_gradient;

const usz MAX_DIMENSION = 8;
const long MAX_ENTRY_MICRO = 1000000000;
const double SCALE = 1000000.0;
const double TOLERANCE = 1.0e-10;
const usz MAX_ITERATIONS = 1000;

fn void write_f64_le(char* output, usz offset, double value) {
    ulong bits = bitcast(value, ulong);
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long conjugate_gradient(long* values, usz length, char* output, usz output_capacity)
    @export("conjugate_gradient") {
    if (values == null || length < 1 || values[0] < 1 || values[0] > (long)MAX_DIMENSION) return -1;
    usz n = (usz)values[0];
    if (length != 1 + n * n + n) return -1;
    usz vector_offset = 1 + n * n;
    double[MAX_DIMENSION * MAX_DIMENSION] matrix;
    double[MAX_DIMENSION] rhs;
    double[MAX_DIMENSION] solution;
    double[MAX_DIMENSION] residual;
    double[MAX_DIMENSION] direction;
    double[MAX_DIMENSION] product;
    for (usz index = 0; index < n * n + n; index++) {
        if (values[index + 1] < -MAX_ENTRY_MICRO || values[index + 1] > MAX_ENTRY_MICRO) return -1;
    }

    for (usz row = 0; row < n; row++) {
        long diagonal = values[1 + row * n + row];
        if (diagonal <= 0) return -1;
        long off_diagonal_sum = 0;
        for (usz column = 0; column < n; column++) {
            long entry = values[1 + row * n + column];
            if (entry != values[1 + column * n + row]) return -1;
            if (column != row) {
                if (entry < 0) {
                    off_diagonal_sum -= entry;
                } else {
                    off_diagonal_sum += entry;
                }
            }
            matrix[row * n + column] = (double)entry / SCALE;
        }
        if (diagonal <= off_diagonal_sum) return -1;
        rhs[row] = (double)values[vector_offset + row] / SCALE;
        residual[row] = rhs[row];
        direction[row] = rhs[row];
    }
    usz output_bytes = n * 8;
    if (output == null || output_capacity < output_bytes) return -2;

    double residual_squared = 0.0;
    for (usz index = 0; index < n; index++) {
        residual_squared += residual[index] * residual[index];
    }
    for (usz iteration = 0; iteration < MAX_ITERATIONS && residual_squared > TOLERANCE * TOLERANCE; iteration++) {
        for (usz row = 0; row < n; row++) {
            product[row] = 0.0;
            for (usz column = 0; column < n; column++) {
                product[row] += matrix[row * n + column] * direction[column];
            }
        }
        double denominator = 0.0;
        for (usz index = 0; index < n; index++) {
            denominator += direction[index] * product[index];
        }
        if (denominator <= 0.0) return -1;
        double alpha = residual_squared / denominator;
        for (usz index = 0; index < n; index++) {
            solution[index] += alpha * direction[index];
            residual[index] -= alpha * product[index];
        }
        double next_residual_squared = 0.0;
        for (usz index = 0; index < n; index++) {
            next_residual_squared += residual[index] * residual[index];
        }
        if (next_residual_squared <= TOLERANCE * TOLERANCE) {
            residual_squared = next_residual_squared;
            break;
        }
        double beta = next_residual_squared / residual_squared;
        for (usz index = 0; index < n; index++) {
            direction[index] = residual[index] + beta * direction[index];
        }
        residual_squared = next_residual_squared;
    }
    for (usz index = 0; index < n; index++) write_f64_le(output, index * 8, solution[index]);
    return (long)output_bytes;
}
