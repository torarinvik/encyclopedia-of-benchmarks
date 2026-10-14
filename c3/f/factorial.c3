module factorial;

// Portable factorial for the shared signed 64-bit benchmark contract.
fn long factorial(long n) @export("factorial")
{
    if (n < 0 || n > 20) return -1;

    long product = 1;
    long factor = 2;
    while (factor <= n) {
        product *= factor;
        factor++;
    }
    return product;
}
