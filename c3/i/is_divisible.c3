module is_divisible;

// Remainder check from the pinned JavaScript and TypeScript sources.
fn long is_divisible(ulong dividend, ulong divisor) @export("is_divisible")
{
    if (dividend > 1000000000 || divisor == 0 || divisor > 1000000000) return -1;
    return dividend % divisor == 0 ? 1 : 0;
}
