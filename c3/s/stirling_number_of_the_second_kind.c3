module stirling_number_of_the_second_kind;

const long MODULUS = 998244353;
const usz MAX_N = 16;

fn long stirling_number_of_the_second_kind(long* input, usz length)
    @export("stirling_number_of_the_second_kind") {
    if (input == null || length != 1) return -1;
    long n_value = input[0];
    if (n_value < 0 || n_value > (long)MAX_N) return -1;
    usz n = (usz)n_value;

    long[MAX_N + 1] row = zeroed;
    row[0] = 1;
    for (usz current_n = 1; current_n <= n; current_n += 1) {
        for (usz k = current_n; k > 0; k -= 1) {
            row[k] = (row[k - 1] + (long)k * row[k]) % MODULUS;
        }
        row[0] = 0;
    }

    long result = 0;
    for (usz k = 0; k <= n; k += 1) {
        long weight = (long)(k + 1) * (long)(k + 1) * (long)(k + 1);
        result = (result + weight * row[k]) % MODULUS;
    }
    return result;
}
