module dividuus_number_predicate;

const long MAX_N = 100000;
const usz MAX_PARSEABLE_LENGTH = 2;

fn long sum_digits(long value) {
    long sum = 0;
    while (value > 0) {
        sum += value % 10;
        value /= 10;
    }
    return sum;
}

fn long product_digits(long value) {
    long product = 1;
    while (value > 0) {
        product *= value % 10;
        value /= 10;
    }
    return product;
}

fn long digital_root(long value) {
    while (value >= 10) value = sum_digits(value);
    return value;
}

fn long multiplicative_root(long value) {
    while (value >= 10) value = product_digits(value);
    return value;
}

fn bool is_dividuus(long n) {
    long sum = sum_digits(n);
    long product = product_digits(n);
    long root = digital_root(n);
    long mroot = multiplicative_root(n);
    if (sum == 0 || product == 0 || root == 0 || mroot == 0) return false;
    return n % sum == 0 && n % product == 0 && n % root == 0 && n % mroot == 0;
}

fn long dividuus_number_predicate(long* input, usz length) @export("dividuus_number_predicate") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    if (length != 1 || input[0] < 1 || input[0] > MAX_N) return -1;
    if (is_dividuus(input[0])) return 1;
    return 0;
}
