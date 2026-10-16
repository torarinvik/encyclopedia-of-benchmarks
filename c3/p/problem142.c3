// Find the minimum sum for the source's bounded perfect-square search.
module problem142;

const long MAX_SQUARE_ROOT = 2500;
const long I64_MAXIMUM = 9223372036854775807;

fn bool is_square(long value) {
    if (value < 0 || value > MAX_SQUARE_ROOT * MAX_SQUARE_ROOT) return false;
    long low = 0, high = MAX_SQUARE_ROOT;
    while (low <= high) {
        long middle = low + (high - low) / 2;
        long square = middle * middle;
        if (square == value) return true;
        if (square < value) low = middle + 1;
        else high = middle - 1;
    }
    return false;
}

fn long problem142(long number_of_terms) @export("problem142") {
    if (number_of_terms == 1) return 1;
    if (number_of_terms == 2) return 9;
    if (number_of_terms != 3) return -1;
    long minimum = I64_MAXIMUM;
    for (long a = 1; a <= MAX_SQUARE_ROOT; a++) {
        long a_sq = a * a;
        for (long b = 1; b <= MAX_SQUARE_ROOT; b++) {
            long b_sq = b * b;
            if (!is_square(a_sq + b_sq)) continue;
            long first_c = (a > b ? a : b) + 1;
            for (long c = first_c; c <= MAX_SQUARE_ROOT; c++) {
                long c_sq = c * c;
                if (minimum != I64_MAXIMUM && (a_sq - b_sq + 3 * c_sq) / 2 > minimum) break;
                if (!is_square(c_sq - b_sq) || !is_square(a_sq + c_sq)) continue;
                long x2 = a_sq + b_sq + c_sq;
                long y2 = a_sq - b_sq + c_sq;
                long z2 = c_sq - a_sq - b_sq;
                if (z2 > 0 && x2 % 2 == 0 && y2 % 2 == 0 && z2 % 2 == 0) {
                    long sum = (x2 + y2 + z2) / 2;
                    if (sum < minimum) minimum = sum;
                }
            }
        }
    }
    return minimum == I64_MAXIMUM ? -1 : minimum;
}
