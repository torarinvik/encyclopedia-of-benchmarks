module power_sum;

fn long power_sum_search(long target, long power, long base, long current_sum)
{
    long term = 1;
    for (long exponent = 0; exponent < power; exponent++) term *= base;
    long new_sum = current_sum + term;
    if (new_sum == target) return 1;
    if (new_sum > target) return 0;
    return power_sum_search(target, power, base + 1, new_sum)
         + power_sum_search(target, power, base + 1, current_sum);
}

fn long power_sum(long* packed, usz length) @export("power_sum")
{
    if (length != 2) return -1;
    long target = packed[0];
    long power = packed[1];
    if (target < 1 || target > 1000 || power < 2 || power > 10) return -1;
    return power_sum_search(target, power, 1, 0);
}
