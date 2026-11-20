module ruth_aaron_number_predicate;

const long MAX_N = 100000;
const usz MAX_PARSEABLE_LENGTH = 2;

fn long factor_sum_counted(long value) {
    long sum = 0;
    for (long divisor = 2; divisor <= value / divisor; divisor++) {
        while (value % divisor == 0) {
            sum += divisor;
            value /= divisor;
        }
    }
    if (value > 1) sum += value;
    return sum;
}

fn long ruth_aaron_number_predicate(long* input, usz length) @export("ruth_aaron_number_predicate") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    if (length != 1 || input[0] < 1 || input[0] > MAX_N) return -1;
    long n = input[0];
    if (factor_sum_counted(n) == factor_sum_counted(n + 1)) return 1;
    return 0;
}
