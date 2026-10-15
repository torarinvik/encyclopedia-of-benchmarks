module power_using_recursion;

// Linear recursive integer power, with a bounded exact contract.
fn long decode_signed(ulong value)
{
    if (value <= 9223372036854775807) return (long)value;
    return -1 - (long)(~value);
}

fn long power_recursive(long base, ulong exponent)
{
    if (exponent == 0) return 1;
    return base * power_recursive(base, exponent - 1);
}

fn long power_using_recursion(ulong base_encoded, ulong exponent) @export("power_using_recursion")
{
    long base = decode_signed(base_encoded);
    if (base < -10 || base > 10 || exponent > 15) return -9223372036854775808;
    return power_recursive(base, exponent);
}
