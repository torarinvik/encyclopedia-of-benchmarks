module min_of_mod_of_linear;

fn long floor_sum(long n, long m, long a, long b) {
    long answer = 0;
    while (true) {
        if (a >= m) {
            long quotient = a / m;
            long left = n;
            long right = n - 1;
            if (left % 2 == 0) left /= 2;
            else right /= 2;
            answer += left * right * quotient;
            a %= m;
        }
        if (b >= m) {
            answer += n * (b / m);
            b %= m;
        }
        long numerator = a * n + b;
        long height = numerator / m;
        if (height == 0) return answer;
        b = numerator % m;
        n = height;
        long previous_m = m;
        m = a;
        a = previous_m;
    }
}

fn long min_of_mod_of_linear(long* input, usz length)
    @export("min_of_mod_of_linear") {
    const long MAX_PARAMETER = 1000000000;
    if (input == null || length != 4) return -1;
    long n = input[0];
    long m = input[1];
    long a = input[2];
    long b = input[3];
    if (n < 1 || n > MAX_PARAMETER || m < 1 || m > MAX_PARAMETER
        || a < 0 || a >= m || b < 0 || b >= m) return -1;
    long target = floor_sum(n, m, a, b) + n;
    long low = -1;
    long high = m - 1;
    while (high - low > 1) {
        long candidate = low + (high - low) / 2;
        long shift = m - 1 - candidate;
        if (floor_sum(n, m, a, b + shift) < target) high = candidate;
        else low = candidate;
    }
    return high;
}
