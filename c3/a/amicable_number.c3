module amicable_number;

fn ulong proper_divisor_sum(ulong number)
{
    if (number <= 1) return 0;
    ulong sum = 1;
    for (ulong divisor = 2; divisor <= number / divisor; divisor++) {
        if (number % divisor == 0) {
            sum += divisor;
            ulong partner = number / divisor;
            if (partner != divisor) sum += partner;
        }
    }
    return sum;
}

fn long amicable_number(ulong left, ulong right) @export("amicable_number")
{
    if (left < 1 || left > 1000000000 || right < 1 || right > 1000000000) return -1;
    if (left == right) return 0;
    return proper_divisor_sum(left) == right && proper_divisor_sum(right) == left ? 1 : 0;
}
