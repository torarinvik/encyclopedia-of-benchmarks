module simultaneous_linear_equation_solver;

extern fn double floor(double value);
extern fn double fma(double first, double second, double third);

const long INVALID_RESULT = -1;
const long CAPACITY_ERROR = -2;
const double INVALID_SCALE = 100000.0;
const double HALF_STEP_LIMIT = 4503599627370496.0;
const long MAX_TICK_MAGNITUDE = 2251799813685248;

fn bool finite_value(double value) {
    return value == value && value < 1.7976931348623157e308 && value > -1.7976931348623157e308;
}

fn void write_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long simultaneous_linear_equation_solver(long* input, usz length, char* output, usz capacity)
    @export("simultaneous_linear_equation_solver") {
    if (input == null || length < 2 || length > 31) return INVALID_RESULT;
    long n_value = input[0];
    if (n_value < 1 || n_value > 5) return INVALID_RESULT;
    usz n = (usz)n_value;
    if (length != 1 + n * (n + 1)) return INVALID_RESULT;
    double matrix[5][6] = {{0}};
    bool has_zero = false;
    for (usz row = 0; row < n; row++) {
        for (usz col = 0; col <= n; col++) {
            long raw = input[1 + row * (n + 1) + col];
            if (raw < -100000 || raw > 100000) return INVALID_RESULT;
            matrix[row][col] = (double)raw / 1000.0;
            if (raw == 0) has_zero = true;
        }
    }
    if (n == 1) {
        if (matrix[0][0] == 0.0) return INVALID_RESULT;
    } else {
        if (has_zero) {
            usz full_row = n;
            for (usz row = 0; row < n; row++) {
                bool all_nonzero = true;
                for (usz col = 0; col <= n; col++)
                    if (matrix[row][col] == 0.0) all_nonzero = false;
                if (all_nonzero) { full_row = row; break; }
            }
            if (full_row == n) return INVALID_RESULT;
            if (full_row != 0) {
                double saved[6] = {0};
                for (usz col = 0; col <= n; col++) saved[col] = matrix[full_row][col];
                for (usz row = full_row; row > 0; row--)
                    for (usz col = 0; col <= n; col++) matrix[row][col] = matrix[row - 1][col];
                for (usz col = 0; col <= n; col++) matrix[0][col] = saved[col];
            }
        }
        for (usz level = 0; level + 2 <= n; level++) {
            if (matrix[level][level] == 0.0) return INVALID_RESULT;
            for (usz row = level; row < n; row++) {
                double magnitude = matrix[row][level];
                if (magnitude != 0.0)
                    for (usz col = level; col <= n; col++) matrix[row][col] /= magnitude;
            }
            double first_row[6] = {0};
            for (usz col = level; col <= n; col++) first_row[col] = matrix[level][col];
            for (usz row = level + 1; row < n; row++) {
                if (matrix[row][level] != 0.0)
                    for (usz col = level; col <= n; col++)
                        matrix[row][col] = first_row[col] - matrix[row][col];
            }
            for (usz row = level; row < n; row++)
                for (usz col = level; col <= n; col++)
                    if (!finite_value(matrix[row][col])) return INVALID_RESULT;
        }
    }

    double solutions[5] = {0};
    for (long row = (long)n - 1; row >= 0; row--) {
        if (matrix[row][row] == 0.0) return INVALID_RESULT;
        double value = matrix[row][n];
        for (usz col = (usz)row + 1; col < n; col++) value -= matrix[row][col] * solutions[col];
        value /= matrix[row][row];
        if (!finite_value(value)) return INVALID_RESULT;
        solutions[row] = value;
    }

    usz needed = 8 + 8 * n;
    char buffer[48] = {0};
    write_i64_le(buffer, 0, n_value);
    for (usz index = 0; index < n; index++) {
        double scaled = solutions[index] * INVALID_SCALE;
        if (!finite_value(scaled) || scaled <= -HALF_STEP_LIMIT || scaled >= HALF_STEP_LIMIT)
            return INVALID_RESULT;
        double lower = floor(scaled);
        double midpoint = lower + 0.5;
        double exact_side = fma(solutions[index], INVALID_SCALE, -midpoint);
        if (!finite_value(exact_side)) return INVALID_RESULT;
        long rounded = (long)lower;
        if (exact_side > 0.0 || (exact_side == 0.0 && rounded % 2 != 0)) rounded++;
        if (rounded < -MAX_TICK_MAGNITUDE || rounded > MAX_TICK_MAGNITUDE)
            return INVALID_RESULT;
        double rounded_value = (double)rounded / INVALID_SCALE;
        double projected = rounded_value * INVALID_SCALE;
        if (!finite_value(projected)) return INVALID_RESULT;
        double projected_lower = floor(projected);
        double projected_midpoint = projected_lower + 0.5;
        long ticks = (long)projected_lower;
        if (projected > projected_midpoint ||
            (projected == projected_midpoint && ticks % 2 != 0)) ticks++;
        if (ticks < -MAX_TICK_MAGNITUDE || ticks > MAX_TICK_MAGNITUDE)
            return INVALID_RESULT;
        write_i64_le(buffer, 8 + 8 * index, ticks);
    }
    if (output == null || capacity < needed) return CAPACITY_ERROR;
    for (usz index = 0; index < needed; index++) output[index] = buffer[index];
    return (long)needed;
}
