module schur_complement;

const double INVALID_RESULT = -1.0e300;

fn double schur_complement(long* input, usz length) @export("schur_complement") {
    if (input == null || length != 6) return INVALID_RESULT;
    long a00 = input[0], a01 = input[1], a11 = input[2];
    long b0 = input[3], b1 = input[4], c00 = input[5];
    if (a00 < -8 || a00 > 8 || a01 < -8 || a01 > 8 || a11 < -8 || a11 > 8 ||
        b0 < -100 || b0 > 100 || b1 < -100 || b1 > 100 || c00 < -100 || c00 > 100) return INVALID_RESULT;
    long determinant = a00 * a11 - a01 * a01;
    if (determinant == 0) return INVALID_RESULT;
    double inv00 = (double)a11 / (double)determinant;
    double inv01 = -(double)a01 / (double)determinant;
    double inv10 = -(double)a01 / (double)determinant;
    double inv11 = (double)a00 / (double)determinant;
    double left0 = (double)b0 * inv00 + (double)b1 * inv10;
    double left1 = (double)b0 * inv01 + (double)b1 * inv11;
    double quadratic = left0 * (double)b0 + left1 * (double)b1;
    return (double)c00 - quadratic;
}
