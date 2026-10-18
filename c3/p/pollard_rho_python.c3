module pollard_rho_python;

const long MAX_NUM = 1000000L;

fn long gcd_nonnegative(long left, long right) {
    while (right != 0L) {
        long remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

fn long advance(long value, long step, long modulus) {
    return (value * value + step) % modulus;
}

fn long pollard_rho_python(long* input, usz length) @export("pollard_rho_python") {
    if (input == null || length != 5) return -1L;
    long num = input[0];
    long seed = input[1];
    long step = input[2];
    long attempts = input[3];
    long step_limit = input[4];
    if (num < 2L || num > MAX_NUM || seed < 0L || seed >= num || step < 0L || step > 1000L || attempts < 1L || attempts > 8L || step_limit < 1L || step_limit > 64L) return -1L;
    if (num > 2L && num % 2L == 0L) return 2L;

    for (long attempt = 0L; attempt < attempts; attempt++) {
        long tortoise = seed;
        long hare = seed;
        for (long iteration = 0L; iteration < step_limit; iteration++) {
            tortoise = advance(tortoise, step, num);
            hare = advance(advance(hare, step, num), step, num);
            long difference = hare - tortoise;
            if (difference < 0L) difference = -difference;
            long divisor = gcd_nonnegative(difference, num);
            if (divisor == 1L) continue;
            if (divisor < num) return divisor;
            break;
        }
        seed = hare;
        step += 1L;
    }
    return 0L;
}
