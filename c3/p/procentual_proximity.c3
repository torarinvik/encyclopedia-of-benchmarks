module procentual_proximity;

const usz MAX_ROWS = 64;
const usz MAX_COLUMNS = 8;

fn void write_f64_le(char* output, usz offset, double value) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long procentual_proximity(long* input, usz length, char* output, usz capacity)
    @export("procentual_proximity") {
    if (input == null || length < 3 || length > 522) return -1;
    long row_value = input[0];
    long column_value = input[1];
    if (row_value < 1 || row_value > MAX_ROWS || column_value < 1 || column_value > MAX_COLUMNS) return -1;
    usz rows = (usz)row_value;
    usz columns = (usz)column_value;
    if (length != 2 + columns + rows * columns) return -1;
    for (usz column = 0; column < columns; column++) {
        long weight = input[2 + column];
        if (weight != 0 && weight != 1) return -1;
    }
    double[MAX_ROWS][MAX_COLUMNS] data = {0};
    for (usz row = 0; row < rows; row++) {
        for (usz column = 0; column < columns; column++) {
            long value = input[2 + columns + row * columns + column];
            if (value < -10000 || value > 10000) return -1;
            data[row][column] = (double)value;
        }
    }
    usz output_length = rows * (columns + 1) * 8;
    if (output == null || capacity < output_length) return -2;

    double[MAX_ROWS] scores = {0};
    for (usz column = 0; column < columns; column++) {
        double minimum = data[0][column];
        double maximum = data[0][column];
        for (usz row = 1; row < rows; row++) {
            if (data[row][column] < minimum) minimum = data[row][column];
            if (data[row][column] > maximum) maximum = data[row][column];
        }
        long weight = input[2 + column];
        if (minimum == maximum) {
            if (weight == 0) for (usz row = 0; row < rows; row++) scores[row] += 1.0;
        } else {
            double value_range = maximum - minimum;
            for (usz row = 0; row < rows; row++) {
                double item_score = (data[row][column] - minimum) / value_range;
                if (weight == 0) item_score = 1.0 - item_score;
                scores[row] = scores[row] + item_score;
            }
        }
    }
    usz offset = 0;
    for (usz row = 0; row < rows; row++) {
        for (usz column = 0; column < columns; column++) {
            write_f64_le(output, offset, data[row][column]);
            offset += 8;
        }
        write_f64_le(output, offset, scores[row]);
        offset += 8;
    }
    return (long)output_length;
}
