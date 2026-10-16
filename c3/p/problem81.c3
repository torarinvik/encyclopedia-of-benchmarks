module problem81;

const usz MAX_DIMENSION = 80;
const long MAX_CELL_VALUE = 9999;

fn long problem81(long* input, usz length) @export("problem81") {
    if (input == null || length < 1) return -1;
    long dimension_value = input[0];
    if (dimension_value < 1 || dimension_value > MAX_DIMENSION.long()) return -1;
    usz dimension = (usz)dimension_value;
    if (length != 1 + dimension * dimension) return -1;
    for (usz index = 1; index < length; index++)
        if (input[index] < 0 || input[index] > MAX_CELL_VALUE) return -1;

    long[80] costs;
    costs[0] = input[1];
    for (usz column = 1; column < dimension; column++)
        costs[column] = costs[column - 1] + input[1 + column];
    for (usz row = 1; row < dimension; row++) {
        usz row_offset = 1 + row * dimension;
        costs[0] += input[row_offset];
        for (usz column = 1; column < dimension; column++) {
            long above = costs[column];
            long left = costs[column - 1];
            costs[column] = (above < left ? above : left) + input[row_offset + column];
        }
    }
    return costs[dimension - 1];
}
