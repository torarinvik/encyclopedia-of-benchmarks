module automorphic_number;

// Check whether the square ends with the original nonnegative integer.
fn ulong add_mod(ulong left, ulong right, ulong modulus)
{
    if (left >= modulus - right) return left - (modulus - right);
    return left + right;
}

fn ulong multiply_mod(ulong left, ulong right, ulong modulus)
{
    ulong result = 0;
    while (right != 0) {
        if ((right & 1ul) != 0ul) result = add_mod(result, left, modulus);
        right >>= 1;
        if (right != 0) left = add_mod(left, left, modulus);
    }
    return result;
}

fn long automorphic_number(long n) @export("automorphic_number")
{
    if (n < 0) return 0;
    ulong number = (ulong)n;
    ulong modulus = 10ul;
    for (ulong digits = number; digits >= 10ul; digits /= 10ul) modulus *= 10ul;
    return multiply_mod(number, number, modulus) == number ? 1 : 0;
}
