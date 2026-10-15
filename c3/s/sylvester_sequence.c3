module sylvester_sequence;

fn long sylvester_term(long n)
{
    if (n == 1) return 2;
    long previous = sylvester_term(n - 1);
    return previous * (previous - 1) + 1;
}

// Recursive Sylvester recurrence on the signed 64-bit benchmark domain.
fn long sylvester_sequence(long n) @export("sylvester_sequence")
{
    if (n < 1 || n > 7) return -1;
    return sylvester_term(n);
}
