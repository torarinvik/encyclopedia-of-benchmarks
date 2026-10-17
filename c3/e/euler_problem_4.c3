module euler_problem_4;

const usz MAX_INPUT_LENGTH = 2;

bool is_palindromic(uint value) {
    uint reversed = 0, remaining = value;
    while (remaining > 0) {
        reversed = 10 * reversed + remaining % 10;
        remaining /= 10;
    }
    return reversed == value;
}

fn long euler_problem_4(long* input, usz length) @export("euler_problem_4") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH || input[0] < 1 || input[0] > 3 || length != 1) return -1;
    uint lower = 1;
    for (int digit = 1; digit < (int)input[0]; ++digit) lower *= 10;
    uint upper = lower * 10 - 1, maximum = 0;
    for (uint left = lower; left <= upper; ++left) {
        for (uint right = lower; right <= upper; ++right) {
            uint product = left * right;
            if (product > maximum && is_palindromic(product)) maximum = product;
        }
    }
    return (long)maximum;
}
