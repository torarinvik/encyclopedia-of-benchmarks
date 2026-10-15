module sum_of_odd_numbers;

fn long sum_of_odd_numbers(long n) @export("sum_of_odd_numbers")
{
    if (n < 0 || n > 46340) return -1;
    return n * n;
}
