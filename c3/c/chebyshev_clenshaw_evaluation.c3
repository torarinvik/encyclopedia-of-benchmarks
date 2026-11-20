module chebyshev_clenshaw_evaluation;

const long MODULUS = 998244353;
const long MAX_DEGREE = 16;
const usz MAX_PARSEABLE_LENGTH = 21;

fn long reduce_field(long value) {
    value %= MODULUS;
    return value < 0 ? value + MODULUS : value;
}

fn long chebyshev_clenshaw_evaluation(long* input, usz length)
        @export("chebyshev_clenshaw_evaluation") {
    if (input == null || length < 3 || length > MAX_PARSEABLE_LENGTH) return -1;
    long degree_value = input[0];
    if (degree_value < 0 || degree_value > MAX_DEGREE) return -1;
    usz degree = (usz)degree_value;
    if (length != degree + 3) return -1;
    long x = input[1];
    if (x < 0 || x >= MODULUS) return -1;
    for (usz i = 0; i <= degree; i++)
        if (input[2 + i] < 0 || input[2 + i] >= MODULUS) return -1;

    long twice_x = (2 * x) % MODULUS;
    long next_one = 0;
    long next_two = 0;
    usz k = degree;
    while (k > 0) {
        long current = reduce_field(input[2 + k] + twice_x * next_one - next_two);
        next_two = next_one;
        next_one = current;
        k--;
    }
    return reduce_field(input[2] + x * next_one - next_two);
}
