module sociable_number;

fn ulong sum_proper_divisors(ulong number)
{
    if (number <= 1) return 0;
    ulong sum = 1;
    ulong divisor = 2;
    while (divisor <= number / divisor) {
        if (number % divisor == 0) {
            ulong other = number / divisor;
            sum += divisor;
            if (other != divisor) sum += other;
        }
        divisor++;
    }
    return sum;
}

// Exact-cycle sociable-number check adapted from the pinned Java source.
fn long sociable_number(ulong number, ulong cycle_length) @export("sociable_number")
{
    if (number == 0 || number > 100000 || cycle_length < 2 || cycle_length > 3) return -1;
    ulong current = number;
    ulong step = 0;
    while (step < cycle_length) {
        current = sum_proper_divisors(current);
        if (current == number) return step == cycle_length - 1 ? 1 : 0;
        step++;
    }
    return 0;
}
