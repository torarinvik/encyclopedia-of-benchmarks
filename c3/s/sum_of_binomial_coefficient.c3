module sum_of_binomial_coefficient;

fn long sum_of_binomial_coefficient(long n) @export("sum_of_binomial_coefficient")
{
    if (n < 0 || n > 30) return -1;
    return (long)(1L << n);
}
