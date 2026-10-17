module pi_monte_carlo_estimation;

const usz MT_N = 624;
const usz MT_M = 397;
const usz MAX_PARSEABLE_INPUT_LENGTH = 3;
const long MAX_SIMULATIONS = 100000;
const long MAX_SEED = 4294967295;
const uint32 MT_MATRIX_A = 0x9908B0DFu;
const uint32 MT_UPPER_MASK = 0x80000000u;
const uint32 MT_LOWER_MASK = 0x7FFFFFFFu;

fn double rounded_multiply(double left, double right) @noinline {
    return left * right;
}

fn double rounded_add(double left, double right) @noinline {
    return left + right;
}

fn void mt_seed(uint32* state, uint32 seed) {
    state[0] = 19650218u;
    for (usz index = 1; index < MT_N; index++) {
        uint32 previous = state[index - 1];
        state[index] = 1812433253u *% (previous ^ (previous >> 30)) +% (uint32)index;
    }

    usz index = 1;
    usz key_index = 0;
    for (usz remaining = MT_N; remaining > 0; remaining--) {
        uint32 previous = state[index - 1];
        state[index] = (state[index] ^ ((previous ^ (previous >> 30)) *% 1664525u)) +% seed +% (uint32)key_index;
        index++;
        key_index++;
        if (index >= MT_N) {
            state[0] = state[MT_N - 1];
            index = 1;
        }
        if (key_index >= 1) key_index = 0;
    }

    for (usz remaining = MT_N - 1; remaining > 0; remaining--) {
        uint32 previous = state[index - 1];
        state[index] = (state[index] ^ ((previous ^ (previous >> 30)) *% 1566083941u)) -% (uint32)index;
        index++;
        if (index >= MT_N) {
            state[0] = state[MT_N - 1];
            index = 1;
        }
    }
    state[0] = MT_UPPER_MASK;
}

fn void mt_twist(uint32* state) {
    for (usz index = 0; index < MT_N - MT_M; index++) {
        uint32 joined = (state[index] & MT_UPPER_MASK) | (state[index + 1] & MT_LOWER_MASK);
        state[index] = state[index + MT_M] ^ (joined >> 1);
        if ((joined & 1u) != 0u) state[index] ^= MT_MATRIX_A;
    }
    for (usz index = MT_N - MT_M; index < MT_N - 1; index++) {
        uint32 joined = (state[index] & MT_UPPER_MASK) | (state[index + 1] & MT_LOWER_MASK);
        state[index] = state[index - (MT_N - MT_M)] ^ (joined >> 1);
        if ((joined & 1u) != 0u) state[index] ^= MT_MATRIX_A;
    }
    uint32 joined = (state[MT_N - 1] & MT_UPPER_MASK) | (state[0] & MT_LOWER_MASK);
    state[MT_N - 1] = state[MT_M - 1] ^ (joined >> 1);
    if ((joined & 1u) != 0u) state[MT_N - 1] ^= MT_MATRIX_A;
}

fn uint32 mt_next_uint32(uint32* state, usz* index) {
    if (*index >= MT_N) {
        mt_twist(state);
        *index = 0;
    }

    uint32 value = state[*index];
    *index += 1;
    value ^= value >> 11;
    value ^= (value << 7) & 0x9D2C5680u;
    value ^= (value << 15) & 0xEFC60000u;
    value ^= value >> 18;
    return value;
}

fn double mt_random(uint32* state, usz* index) {
    uint32 high = mt_next_uint32(state, index) >> 5;
    uint32 low = mt_next_uint32(state, index) >> 6;
    double significand = (double)high * 67108864.0 + (double)low;
    return significand * (1.0 / 9007199254740992.0);
}

fn bool exact_integer_in_range(double value, double minimum, double maximum) {
    if (value != value || value < minimum || value > maximum) return false;
    return value == (double)(long)value;
}

fn long pi_monte_carlo_estimation(double* input, usz input_length,
                                  double* output, usz output_capacity)
    @export("pi_monte_carlo_estimation")
{
    if (input == null || input_length == 0 || input_length > MAX_PARSEABLE_INPUT_LENGTH ||
        input_length != 2) return -1;
    if (!exact_integer_in_range(input[0], 1.0, (double)MAX_SIMULATIONS) ||
        !exact_integer_in_range(input[1], 0.0, (double)MAX_SEED)) return -1;

    usz simulations = (usz)input[0];
    uint32 seed = (uint32)input[1];
    if (output == null || output_capacity < 1) return -2;

    uint32[MT_N] state;
    mt_seed(&state[0], seed);
    usz random_index = MT_N;
    usz hits = 0;
    for (usz trial = 0; trial < simulations; trial++) {
        double x = mt_random(&state[0], &random_index);
        double y = mt_random(&state[0], &random_index);
        double x_squared = rounded_multiply(x, x);
        double y_squared = rounded_multiply(y, y);
        if (rounded_add(x_squared, y_squared) <= 1.0) hits++;
    }

    output[0] = (double)((usz)4 * hits) / (double)simulations;
    return 1;
}
