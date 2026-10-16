module matrix_exponentiation_recursive;
struct Matrix2 { long[4] v; }
fn Matrix2 multiply(Matrix2 a, Matrix2 b) {
    Matrix2 c = {{0, 0, 0, 0}};
    for (usz r = 0; r < 2; r++) for (usz col = 0; col < 2; col++) for (usz k = 0; k < 2; k++) c.v[r*2+col] += a.v[r*2+k] * b.v[k*2+col];
    return c;
}
fn Matrix2 power(Matrix2 a, long e) {
    if (e == 0) return {{1, 0, 0, 1}};
    if (e % 2 == 1) return multiply(power(a, e-1), a);
    Matrix2 half = power(a, e/2); return multiply(half, half);
}
fn void store(long value, char* output, usz offset) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) output[offset+b] = (char)((bits >> (8*b)) & 255);
}
fn long matrix_exponentiation_recursive(long* input, usz length, char* output, usz capacity) @export("matrix_exponentiation_recursive") {
    if (input == null || length != 5 || input[0] < 0 || input[0] > 30) return -2;
    for (usz i = 1; i < 5; i++) if (input[i] < -1 || input[i] > 1) return -2;
    if (output == null || capacity < 32) return -3;
    Matrix2 result = power({{input[1], input[2], input[3], input[4]}}, input[0]);
    for (usz i = 0; i < 4; i++) store(result.v[i], output, i*8);
    return 4;
}
