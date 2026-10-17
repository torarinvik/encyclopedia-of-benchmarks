module polynom_for_points;

const usz MIN_POINTS = 2;
const usz MAX_POINTS = 8;
const long MIN_X = -4;
const long MAX_X = 4;
const long MIN_Y = -25000;
const long MAX_Y = 25000;
const double MAX_COEFFICIENT = 1000000.0;
const usz MAX_CONTRACT_BYTES = 124;
const usz SCRATCH_BYTES = 125;

fn double absolute(double value) { return value < 0.0 ? -value : value; }

fn usz append_text(char* buffer, usz position, char* text) {
    while (*text != '\0') buffer[position++] = *text++;
    return position;
}

fn usz append_i64(char* buffer, usz position, long value) {
    char[24] digits;
    usz count = 0;
    if (value < 0) { buffer[position++] = '-'; value = -value; }
    do { digits[count++] = (char)('0' + value % 10); value /= 10; } while (value != 0);
    while (count > 0) buffer[position++] = digits[--count];
    return position;
}

fn usz append_coefficient(char* buffer, usz position, double value) {
    if (value == 0.0) {
        if ((@bitcast(ulong, value) >> 63) != 0) buffer[position++] = '-';
        return append_text(buffer, position, "0.0");
    }
    position = append_i64(buffer, position, (long)value);
    return append_text(buffer, position, ".0");
}

fn long polynom_for_points(long* values, usz length, char* output,
                           usz output_capacity) @export("polynom_for_points") {
    if (values == null || length < 1 || length > 1 + 2 * MAX_POINTS) return -1;
    long raw_n = values[0];
    if (raw_n < (long)MIN_POINTS || raw_n > (long)MAX_POINTS ||
        length != 1 + 2 * (usz)raw_n) return -1;
    usz n = (usz)raw_n;
    long[MAX_POINTS] xs = {0};
    double[MAX_POINTS][MAX_POINTS] matrix = {0.0};
    double[MAX_POINTS] vector = {0.0};
    for (usz row = 0; row < n; row++) {
        long x = values[1 + 2 * row];
        long y = values[2 + 2 * row];
        if (x < MIN_X || x > MAX_X || y < MIN_Y || y > MAX_Y) return -1;
        for (usz previous = 0; previous < row; previous++) if (xs[previous] == x) return -1;
        xs[row] = x;
        for (usz column = 0; column < n; column++) {
            long power = 1;
            usz exponent = n - column - 1;
            for (usz step = 0; step < exponent; step++) power *= x;
            matrix[row][column] = (double)power;
        }
        vector[row] = (double)y;
    }

    for (usz count = 0; count < n; count++) {
        if (matrix[count][count] == 0.0) {
            usz pivot_row = count + 1;
            for (usz row = count + 2; row < n; row++)
                if (absolute(matrix[row][count]) > absolute(matrix[pivot_row][count])) pivot_row = row;
            if (pivot_row >= n || matrix[pivot_row][count] == 0.0) return -1;
            for (usz column = 0; column < n; column++) {
                double temporary = matrix[count][column];
                matrix[count][column] = matrix[pivot_row][column];
                matrix[pivot_row][column] = temporary;
            }
            double temporary = vector[count];
            vector[count] = vector[pivot_row];
            vector[pivot_row] = temporary;
        }
        for (usz row = 0; row < n; row++) {
            if (row == count) continue;
            double fraction = matrix[row][count] / matrix[count][count];
            for (usz column = 0; column < n; column++) {
                double product = matrix[count][column] * fraction;
                matrix[row][column] = matrix[row][column] - product;
            }
            double product = vector[count] * fraction;
            vector[row] = vector[row] - product;
        }
    }

    double[MAX_POINTS] coefficients = {0.0};
    for (usz index = 0; index < n; index++) {
        double value = vector[index] / matrix[index][index];
        if (value != value || value < -MAX_COEFFICIENT || value > MAX_COEFFICIENT ||
            value != (double)(long)value) return -1;
        coefficients[index] = value;
    }

    char[SCRATCH_BYTES] buffer;
    usz position = append_text(&buffer[0], 0, "f(x)=");
    for (usz index = 0; index < n; index++) {
        if (index != 0) buffer[position++] = '+';
        position = append_text(&buffer[0], position, "x^");
        position = append_i64(&buffer[0], position, (long)(n - index - 1));
        buffer[position++] = '*';
        position = append_coefficient(&buffer[0], position, coefficients[index]);
    }
    if (position > MAX_CONTRACT_BYTES) return -1;
    if (output == null || output_capacity < position) return -2;
    for (usz index = 0; index < position; index++) output[index] = buffer[index];
    return (long)position;
}
