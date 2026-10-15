module fibonacci_matrix_exponentiation;

const ulong MAX_INDEX = 9007199254740991ul;
const ulong MAX_MODULUS = 4294967295ul;

fn ulong multiply_sum(ulong a, ulong b, ulong c, ulong d, ulong modulus) {
    return ((a * b) % modulus + (c * d) % modulus) % modulus;
}

fn double fibonacci_matrix_exponentiation(double index_input, double modulus_input)
    @export("fibonacci_matrix_exponentiation")
{
    if (!(index_input >= 1.0 && index_input <= (double)MAX_INDEX) ||
        !(modulus_input >= 1.0 && modulus_input <= (double)MAX_MODULUS)) return -1.0;
    ulong index = (ulong)index_input;
    ulong modulus = (ulong)modulus_input;
    if ((double)index != index_input || (double)modulus != modulus_input) return -1.0;

    ulong r00 = 1ul % modulus, r01 = 0ul, r10 = 0ul, r11 = 1ul % modulus;
    ulong t00 = 0ul, t01 = 1ul % modulus, t10 = 1ul % modulus, t11 = 1ul % modulus;
    ulong exponent = index - 1ul;
    while (exponent > 0ul) {
        if (exponent % 2ul == 1ul) {
            ulong n00 = multiply_sum(r00, t00, r01, t10, modulus);
            ulong n01 = multiply_sum(r00, t01, r01, t11, modulus);
            ulong n10 = multiply_sum(r10, t00, r11, t10, modulus);
            ulong n11 = multiply_sum(r10, t01, r11, t11, modulus);
            r00 = n00; r01 = n01; r10 = n10; r11 = n11;
            exponent--;
        } else {
            ulong n00 = multiply_sum(t00, t00, t01, t10, modulus);
            ulong n01 = multiply_sum(t00, t01, t01, t11, modulus);
            ulong n10 = multiply_sum(t10, t00, t11, t10, modulus);
            ulong n11 = multiply_sum(t10, t01, t11, t11, modulus);
            t00 = n00; t01 = n01; t10 = n10; t11 = n11;
            exponent /= 2ul;
        }
    }
    return (double)((r00 + r10) % modulus);
}
