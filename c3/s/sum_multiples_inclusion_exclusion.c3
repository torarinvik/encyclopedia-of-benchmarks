module sum_multiples_formula;

fn long sum_multiples_inclusion_exclusion(long limit) @export("sum_multiples_inclusion_exclusion")
{
    if (limit < 1 || limit > 100000) return -1;
    long last = limit - 1;
    long threes = last / 3;
    long fives = last / 5;
    long fifteens = last / 15;
    return 3 * threes * (threes + 1) / 2
         + 5 * fives * (fives + 1) / 2
         - 15 * fifteens * (fifteens + 1) / 2;
}
