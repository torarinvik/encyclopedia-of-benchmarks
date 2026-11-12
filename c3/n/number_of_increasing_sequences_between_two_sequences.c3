/* Clean-room bounded implementation of the Library Checker sequence-counting task. */
module number_of_increasing_sequences_between_two_sequences;

const int MAX_N = 64;
const int MAX_M = 64;
const int MAX_INPUT_LENGTH = 130;
const long MOD = 998244353;

fn long number_of_increasing_sequences_between_two_sequences(long* input, usz length)
    @export("number_of_increasing_sequences_between_two_sequences") {
    if (input == null || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 1 || input[1] > MAX_M) return -1;
    usz n = (usz)input[0], m = (usz)input[1];
    if (length != 2 + 2 * n) return -1;
    long[MAX_N] lower = zeroed;
    long[MAX_N] upper = zeroed;
    for (usz i = 0; i < n; i++) {
        lower[i] = input[2 + i];
        upper[i] = input[2 + n + i];
        if (lower[i] < 0 || lower[i] >= upper[i] || upper[i] > (long)m) return -1;
    }
    long[MAX_M] previous = zeroed, current = zeroed;
    for (usz value = (usz)lower[0]; value < (usz)upper[0]; value++) previous[value] = 1;
    for (usz position = 1; position < n; position++) {
        long prefix = 0;
        for (usz value = 0; value < m; value++) {
            prefix += previous[value];
            if (prefix >= MOD) prefix -= MOD;
            current[value] = lower[position] <= (long)value && (long)value < upper[position] ? prefix : 0;
        }
        for (usz value = 0; value < m; value++) previous[value] = current[value];
    }
    long answer = 0;
    for (usz value = 0; value < m; value++) {
        answer += previous[value];
        if (answer >= MOD) answer -= MOD;
    }
    return answer;
}
