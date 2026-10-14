module double_factorial;

// Iterative double factorial for the signed 64-bit benchmark contract.
fn long double_factorial(long n) @export("double_factorial")
{
    if (n < 0 || n > 33) return -1;
    long result = 1;
    for (long factor = n; factor > 1; factor -= 2) result *= factor;
    return result;
}
