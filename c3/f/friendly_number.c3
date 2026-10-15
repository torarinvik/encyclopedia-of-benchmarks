module friendly_number;

fn long sum_divisors(ulong number) {
    long sum = 0;
    for (ulong divisor = 1; divisor * divisor <= number; divisor++) {
        if (number % divisor == 0) {
            sum += (long)divisor;
            ulong other = number / divisor;
            if (other != divisor) sum += (long)other;
        }
    }
    return sum;
}

fn long friendly_number(ulong a, ulong b) @export("friendly_number") {
    if (a > 1000000 || b > 1000000) return -1;
    if (a == 0 || b == 0) return 0;
    long sigma_a = sum_divisors(a);
    long sigma_b = sum_divisors(b);
    return sigma_a * (long)b == sigma_b * (long)a ? 1 : 0;
}
