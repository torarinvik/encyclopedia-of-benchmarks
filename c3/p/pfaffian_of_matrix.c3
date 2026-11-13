module pfaffian_of_matrix;

const long MODULUS = 998244353;
const usz MAX_N = 8, MAX_DIMENSION = 16, MAX_PARSEABLE = 258;

fn long normalize(long value) {
    value %= MODULUS;
    return value < 0 ? value + MODULUS : value;
}

fn long multiply(long left, long right) { return (left * right) % MODULUS; }

fn long power(long base, long exponent) {
    long result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = multiply(result, base);
        base = multiply(base, base);
        exponent >>= 1;
    }
    return result;
}

fn long pfaffian_of_matrix(long* input, usz length) @export("pfaffian_of_matrix") {
    if (input == null || length < 5 || length > MAX_PARSEABLE) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_N) return -1;
    usz dimension = (usz)(2 * input[0]);
    if (length != 1 + dimension * dimension) return -1;

    long[MAX_DIMENSION * MAX_DIMENSION] matrix = zeroed;
    for (usz row = 0; row < dimension; row += 1) {
        for (usz column = 0; column < dimension; column += 1) {
            long value = input[1 + row * dimension + column];
            if (value < 0 || value >= MODULUS) return -1;
            matrix[row * MAX_DIMENSION + column] = value;
        }
    }
    for (usz row = 0; row < dimension; row += 1) {
        if (matrix[row * MAX_DIMENSION + row] != 0) return -1;
        for (usz column = row + 1; column < dimension; column += 1)
            if ((matrix[row * MAX_DIMENSION + column]
                    + matrix[column * MAX_DIMENSION + row]) % MODULUS != 0) return -1;
    }

    long result = 1;
    for (usz pivot_index = 0; pivot_index < dimension; pivot_index += 2) {
        usz partner = pivot_index + 1;
        while (partner < dimension && matrix[pivot_index * MAX_DIMENSION + partner] == 0)
            partner += 1;
        if (partner == dimension) return 0;
        if (partner != pivot_index + 1) {
            usz swapped = pivot_index + 1;
            for (usz k = 0; k < dimension; k += 1) {
                long temporary = matrix[swapped * MAX_DIMENSION + k];
                matrix[swapped * MAX_DIMENSION + k] = matrix[partner * MAX_DIMENSION + k];
                matrix[partner * MAX_DIMENSION + k] = temporary;
            }
            for (usz k = 0; k < dimension; k += 1) {
                long temporary = matrix[k * MAX_DIMENSION + swapped];
                matrix[k * MAX_DIMENSION + swapped] = matrix[k * MAX_DIMENSION + partner];
                matrix[k * MAX_DIMENSION + partner] = temporary;
            }
            result = result == 0 ? 0 : MODULUS - result;
        }

        usz first = pivot_index * MAX_DIMENSION, second = (pivot_index + 1) * MAX_DIMENSION;
        long pivot = matrix[first + pivot_index + 1];
        result = multiply(result, pivot);
        long inverse = power(pivot, MODULUS - 2);
        for (usz row = pivot_index + 2; row < dimension; row += 1) {
            for (usz column = row + 1; column < dimension; column += 1) {
                long cross = normalize(multiply(matrix[first + row], matrix[second + column])
                    - multiply(matrix[first + column], matrix[second + row]));
                long value = normalize(matrix[row * MAX_DIMENSION + column]
                    - multiply(cross, inverse));
                matrix[row * MAX_DIMENSION + column] = value;
                matrix[column * MAX_DIMENSION + row] = value == 0 ? 0 : MODULUS - value;
            }
        }
    }
    return result;
}
