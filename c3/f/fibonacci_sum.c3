module fibonacci_sum;

fn long fibonacci_sum(ulong start, ulong end) @export("fibonacci_sum")
{
    if (end > 90 || start > end) {
        return -1;
    }
    ulong upper = end + 2;
    ulong lower = start + 1;
    long prev_upper = 0;
    long curr_upper = 1;
    long prev_lower = 0;
    long curr_lower = 1;
    for (ulong i = 1; i < upper; i += 1) {
        long next = prev_upper + curr_upper;
        prev_upper = curr_upper;
        curr_upper = next;
        if (i < lower) {
            long lower_next = prev_lower + curr_lower;
            prev_lower = curr_lower;
            curr_lower = lower_next;
        }
    }
    return curr_upper - curr_lower;
}
