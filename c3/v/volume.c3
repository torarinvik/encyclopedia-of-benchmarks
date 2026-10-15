module volume;

const long INVALID_RESULT = -1;
const long MAX_DIMENSION = 1000;

fn long volume(long* input, usz length) @export("volume") {
    if (input == null || length != 4) return INVALID_RESULT;
    long operation = input[0], a = input[1], b = input[2], c = input[3];
    if (a < 0 || a > MAX_DIMENSION || b < 0 || b > MAX_DIMENSION || c < 0 || c > MAX_DIMENSION) return INVALID_RESULT;
    if (operation == 0) {
        if (b != 0 || c != 0) return INVALID_RESULT;
        return a * a * a;
    }
    if (operation == 1) return a * b * c;
    if (operation == 2) {
        long product = a * b * c;
        return product % 2 == 0 ? product / 2 : INVALID_RESULT;
    }
    if (operation == 3) {
        long product = a * b * c;
        return product % 3 == 0 ? product / 3 : INVALID_RESULT;
    }
    return INVALID_RESULT;
}
