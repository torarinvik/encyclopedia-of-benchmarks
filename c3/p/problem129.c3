// Search odd divisors for the first source repunit length exceeding limit.
module problem129;

const long MAX_LIMIT = 1000000;

fn long least_divisible_repunit(long divisor) {
    if (divisor % 5 == 0 || divisor % 2 == 0) return 0;
    long repunit = 1;
    long repunit_index = 1;
    while (repunit != 0) {
        repunit = (10 * repunit + 1) % divisor;
        repunit_index++;
    }
    return repunit_index;
}

fn long problem129(long limit) @export("problem129") {
    if (limit < 1 || limit > MAX_LIMIT) return -1;
    long divisor = limit - 1;
    if (divisor % 2 == 0) divisor++;
    while (least_divisible_repunit(divisor) <= limit) divisor += 2;
    return divisor;
}
