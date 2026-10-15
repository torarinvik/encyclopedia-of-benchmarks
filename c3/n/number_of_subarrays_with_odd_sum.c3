module odd_sum_subarrays;

const long ODD_SUM_MODULUS = 1000000007;

fn long number_of_subarrays_with_odd_sum(long* values, usz length)
    @export("number_of_subarrays_with_odd_sum")
{
    if (length > 100000 || (length != 0 && values == null)) return -1;
    long even_prefixes = 1;
    long odd_prefixes = 0;
    long result = 0;
    long parity = 0;
    for (usz index = 0; index < length; index++) {
        long value = values[index];
        if (value < -2147483648 || value > 2147483647) return -1;
        if (value % 2 != 0) parity = 1 - parity;
        if (parity == 0) {
            result = (result + odd_prefixes) % ODD_SUM_MODULUS;
            even_prefixes++;
        } else {
            result = (result + even_prefixes) % ODD_SUM_MODULUS;
            odd_prefixes++;
        }
    }
    return result;
}
