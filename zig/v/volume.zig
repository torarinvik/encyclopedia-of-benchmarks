const INVALID_RESULT: i64 = -1;
const MAX_DIMENSION: i64 = 1000;

export fn volume(input: [*]const i64, length: usize) i64 {
    if (length != 4) return INVALID_RESULT;
    const operation = input[0];
    const a = input[1];
    const b = input[2];
    const c = input[3];
    if (a < 0 or a > MAX_DIMENSION or b < 0 or b > MAX_DIMENSION or c < 0 or c > MAX_DIMENSION) return INVALID_RESULT;
    if (operation == 0) {
        if (b != 0 or c != 0) return INVALID_RESULT;
        return a * a * a;
    }
    if (operation == 1) return a * b * c;
    if (operation == 2) {
        const product = a * b * c;
        if (@mod(product, 2) != 0) return INVALID_RESULT;
        return @divTrunc(product, 2);
    }
    if (operation == 3) {
        const product = a * b * c;
        if (@mod(product, 3) != 0) return INVALID_RESULT;
        return @divTrunc(product, 3);
    }
    return INVALID_RESULT;
}
