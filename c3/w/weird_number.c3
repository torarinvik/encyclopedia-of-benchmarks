module weird_number;

fn long weird_number(long value) @export("weird_number")
{
    if (value < 0 || value > 512) return -1;
    if (value == 0) return 0;
    bool[513] reachable;
    reachable[0] = true;
    long divisor_sum = 0;
    for (long divisor = 1; divisor <= value / 2; divisor++) {
        if (value % divisor != 0) continue;
        divisor_sum += divisor;
        for (long total = value; total >= divisor; total--) {
            if (reachable[(usz)(total - divisor)]) reachable[(usz)total] = true;
        }
    }
    if (divisor_sum > value && !reachable[(usz)value]) return 1;
    return 0;
}
