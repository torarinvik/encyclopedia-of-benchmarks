module problem26;

fn long problem26(long limit) @export("problem26")
{
    if (limit < 0 || limit > 1000) return -1;
    long best_denominator = 1;
    long longest_remainder_list = 0;
    for (long denominator = 1; denominator <= limit; denominator++) {
        bool[1001] seen = {};
        long remainder = 1;
        long remainder_count = 0;
        for (long step = 0; step < limit; step++) {
            if (seen[remainder]) {
                if (remainder_count > longest_remainder_list) {
                    longest_remainder_list = remainder_count;
                    best_denominator = denominator;
                }
                break;
            }
            seen[remainder] = true;
            remainder_count++;
            remainder = (remainder * 10) % denominator;
        }
    }
    return best_denominator;
}
