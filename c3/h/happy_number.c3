module happy_number;

// Repeatedly sum squared decimal digits until reaching one or a cycle.
fn long digit_square_sum(long n)
{
    long total = 0;
    while (n > 0) {
        long digit = n % 10;
        total += digit * digit;
        n /= 10;
    }
    return total;
}

fn long happy_number(long n) @export("happy_number")
{
    if (n <= 0) return -1;
    long slow = digit_square_sum(n);
    long fast = digit_square_sum(digit_square_sum(n));
    while (slow != fast) {
        slow = digit_square_sum(slow);
        fast = digit_square_sum(digit_square_sum(fast));
    }
    return slow == 1 ? 1 : 0;
}
