module stochastic_matrix;

const usz MAX_DIMENSION = 63;
const usz MAX_INPUT_VALUES = 3 + MAX_DIMENSION * MAX_DIMENSION;
const long MAX_ABS_CELL = 1000000000000L;
const double CELL_SCALE = 1.0e12;
const double TOLERANCE = 1.0e-9;

fn long stochastic_matrix(long* input, usz length) @export("stochastic_matrix") {
    if (input == null || length < 3 || length > MAX_INPUT_VALUES) return -1;
    long mode = input[0];
    long rows_value = input[1];
    long columns_value = input[2];
    if ((mode != 0 && mode != 1) || rows_value < 1 || rows_value > (long)MAX_DIMENSION ||
        columns_value < 1 || columns_value > (long)MAX_DIMENSION) return -1;

    usz rows = (usz)rows_value;
    usz columns = (usz)columns_value;
    usz total = rows * columns;
    if (length != 3 + total) return -1;

    for (usz index = 0; index < total; index++) {
        long units = input[3 + index];
        if (units < -MAX_ABS_CELL || units > MAX_ABS_CELL) return -1;
    }

    if (mode == 0) {
        for (usz row = 0; row < rows; row++) {
            double sum = 0.0;
            for (usz column = 0; column < columns; column++) {
                double value = (double)input[3 + row * columns + column] / CELL_SCALE;
                if (value < 0.0) return 0;
                sum += value;
            }
            double difference = sum - 1.0;
            if (difference > TOLERANCE || difference < -TOLERANCE) return 0;
        }
    } else {
        for (usz column = 0; column < columns; column++) {
            double sum = 0.0;
            for (usz row = 0; row < rows; row++) {
                double value = (double)input[3 + row * columns + column] / CELL_SCALE;
                if (value < 0.0) return 0;
                sum += value;
            }
            double difference = sum - 1.0;
            if (difference > TOLERANCE || difference < -TOLERANCE) return 0;
        }
    }
    return 1;
}
