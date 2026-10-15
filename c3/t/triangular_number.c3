module triangular_number;

// Compute T(n) = n(n+1)/2 without an overflowing intermediate product.
fn long triangular_number(long input) @export("triangular_number")
{
    if (input < 0 || input > 4294967295) return -1;
    long left = input % 2 == 0 ? input / 2 : input;
    long right = input % 2 == 0 ? input + 1 : (input + 1) / 2;
    return left * right;
}
