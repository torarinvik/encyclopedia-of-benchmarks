module matrix_exponentiation;

const usz MAX_ORDER = 8;
const usz MAX_INPUT_WORDS = 18;
const long MOD = 1000000007L;
const long MAX_N = 1000000000000L;

struct Matrix { long[8][8] cell; }

fn Matrix multiply(Matrix left, Matrix right, int order) {
    Matrix result = zeroed;
    for (int row = 0; row < order; row += 1)
        for (int col = 0; col < order; col += 1)
            for (int inner = 0; inner < order; inner += 1)
                result.cell[row][col] = (result.cell[row][col] + (left.cell[row][inner] * right.cell[inner][col]) % MOD) % MOD;
    return result;
}
fn Matrix power(Matrix matrix, long exponent, int order) {
    if (exponent == 1) return matrix;
    if (exponent % 2 == 1) return multiply(matrix, power(matrix, exponent - 1, order), order);
    Matrix half = power(matrix, exponent / 2, order);
    return multiply(half, half, order);
}

long matrix_exponentiation(long* input, usz length) @export("matrix_exponentiation") {
    if (input == null || length < 1 || length > MAX_INPUT_WORDS) return -1;
    long order_value = input[0];
    if (order_value < 1 || order_value > 8 || length != (usz)(2*order_value+2)) return -1;
    int order = (int)order_value;
    for (int i = 0; i < 2*order; i += 1) if (input[1+i] < 0 || input[1+i] >= MOD) return -1;
    long n = input[2*order+1];
    if (n < 0 || n > MAX_N) return -1;
    if (n == 0) return 0;
    if (n <= order_value) return input[(usz)n];
    Matrix transition = zeroed;
    for (int i = 0; i < order-1; i += 1) transition.cell[i][i+1] = 1;
    for (int col = 0; col < order; col += 1) transition.cell[order-1][col] = input[2*order-col];
    transition = power(transition, n-1, order);
    long result = 0;
    for (int i = 0; i < order; i += 1) result = (result + (transition.cell[0][i] * input[1+i]) % MOD) % MOD;
    return result;
}
