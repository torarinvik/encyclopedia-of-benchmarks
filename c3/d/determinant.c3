module determinant;

const int MAX_DIMENSION = 6;
const int MAX_INPUT_LENGTH = 1 + MAX_DIMENSION * MAX_DIMENSION;
const long INVALID_RESULT = -9223372036854775807L - 1L;

fn long determinant_recursive(long* matrix, int dimension) {
    if (dimension == 1) return matrix[0];
    long result = 0;
    long[(MAX_DIMENSION - 1) * (MAX_DIMENSION - 1)] minor;
    for (int column = 0; column < dimension; column++) {
        int minor_index = 0;
        for (int row = 1; row < dimension; row++) {
            for (int source_column = 0; source_column < dimension; source_column++) {
                if (source_column != column) {
                    minor[minor_index] = matrix[row * dimension + source_column];
                    minor_index++;
                }
            }
        }
        long term = matrix[column] * determinant_recursive(&minor[0], dimension - 1);
        result += column % 2 == 0 ? term : -term;
    }
    return result;
}

fn long determinant(long* input, usz length) @export("determinant") {
    if (input == null || length < 1 || length > (usz)MAX_INPUT_LENGTH) return INVALID_RESULT;
    long dimension_value = input[0];
    if (dimension_value < 1 || dimension_value > MAX_DIMENSION) return INVALID_RESULT;
    int dimension = (int)dimension_value;
    if (length != (usz)(1 + dimension * dimension)) return INVALID_RESULT;
    for (int index = 0; index < dimension * dimension; index++) {
        if (input[1 + index] < -9 || input[1 + index] > 9) return INVALID_RESULT;
    }
    return determinant_recursive(&input[1], dimension);
}
