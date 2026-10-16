module problem206;

const long START = 138902663;
const long MINIMUM = 101010103;

fn bool is_square_form(long value) {
    long digit = 9;
    while (value > 0) {
        if (value % 10 != digit) return false;
        value /= 100;
        digit--;
    }
    return true;
}

fn long problem206(long unused) @export("problem206") {
    if (unused != 0) return -1;
    long candidate = START;
    while (candidate >= MINIMUM) {
        if (is_square_form(candidate * candidate)) return candidate * 10;
        candidate -= candidate % 10 == 3 ? 6 : 4;
    }
    return -1;
}
