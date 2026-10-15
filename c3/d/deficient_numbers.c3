module deficient_numbers;

// Proper-divisor pair scan from the pinned Python source.
fn long deficient_numbers(long number) @export("deficient_numbers")
{
    if (number <= 0) return 0;
    if (number > 100000000) return -1;
    if (number == 1) return 1;

    long sum = 1;
    long divisor = 2;
    while (divisor <= number / divisor) {
        if (number % divisor == 0) {
            long other = number / divisor;
            sum += divisor;
            if (other != divisor) sum += other;
        }
        divisor++;
    }
    return sum < number ? 1 : 0;
}
