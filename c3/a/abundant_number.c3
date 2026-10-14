module abundant_number;

fn long abundant_number(long n) @export("abundant_number")
{
    if (n < 1 || n > 1000000000) return -1;
    long sum = 1;
    for (long divisor = 2; divisor <= n / divisor; divisor++) {
        if (n % divisor == 0) {
            sum += divisor;
            long partner = n / divisor;
            if (partner != divisor) sum += partner;
            if (sum > n) return 1;
        }
    }
    return 0;
}
