module discrete_rejection_sampling;

const usz MAX_CATEGORIES = 8;
const usz MAX_SAMPLES = 8;
const usz MAX_ATTEMPTS = 32;
const usz MAX_INPUT_VALUES = 83;
const ulong DRAW_SCALE = 4294967296ul;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long discrete_rejection_sampling(long* input, usz length, char* output,
                                    usz capacity) @export("discrete_rejection_sampling") {
    if (input == null || length < 3 || length > MAX_INPUT_VALUES) return -1;
    long n_value = input[0];
    long samples_value = input[1];
    long attempts_value = input[2];
    if (n_value < 1 || n_value > (long)MAX_CATEGORIES ||
        samples_value < 1 || samples_value > (long)MAX_SAMPLES ||
        attempts_value < 1 || attempts_value > (long)MAX_ATTEMPTS) return -1;
    usz n = (usz)n_value;
    usz wanted = (usz)samples_value;
    usz attempts = (usz)attempts_value;
    if (length != 3 + 2 * n + 2 * attempts) return -1;

    long[MAX_CATEGORIES] target;
    long[MAX_CATEGORIES] proposal;
    long[MAX_CATEGORIES] cumulative;
    ulong target_total = 0;
    ulong proposal_total = 0;
    for (usz i = 0; i < n; ++i) {
        long weight = input[3 + i];
        long q_weight = input[3 + n + i];
        if (weight < 1 || weight > 20 || q_weight < 1 || q_weight > 20) return -1;
        target[i] = weight;
        proposal[i] = q_weight;
        target_total += (ulong)weight;
        proposal_total += (ulong)q_weight;
        cumulative[i] = (long)proposal_total;
    }

    ulong envelope = 1;
    for (usz i = 0; i < n; ++i) {
        ulong numerator = (ulong)target[i] * proposal_total;
        ulong denominator = target_total * (ulong)proposal[i];
        ulong ratio_ceiling = (numerator + denominator - 1) / denominator;
        if (ratio_ceiling > envelope) envelope = ratio_ceiling;
    }

    usz tape_offset = 3 + 2 * n;
    for (usz attempt = 0; attempt < attempts; ++attempt) {
        long proposal_draw = input[tape_offset + 2 * attempt];
        long acceptance_draw = input[tape_offset + 2 * attempt + 1];
        if (proposal_draw < 0 || (ulong)proposal_draw >= proposal_total ||
            acceptance_draw < 0 || (ulong)acceptance_draw >= DRAW_SCALE) return -1;
    }

    usz output_bytes = 16 * wanted;
    if (output == null || capacity < output_bytes) return -2;
    long[2 * MAX_SAMPLES] staged;
    usz produced = 0;
    usz attempts_since_acceptance = 0;
    for (usz attempt = 0; attempt < attempts; ++attempt) {
        attempts_since_acceptance += 1;
        ulong proposal_draw = (ulong)input[tape_offset + 2 * attempt];
        ulong acceptance_draw = (ulong)input[tape_offset + 2 * attempt + 1];
        usz category = 0;
        while ((ulong)cumulative[category] <= proposal_draw) category += 1;
        ulong left = acceptance_draw * target_total * (ulong)proposal[category] * envelope;
        ulong right = DRAW_SCALE * (ulong)target[category] * proposal_total;
        if (left < right) {
            staged[produced] = (long)category;
            staged[produced + 1] = (long)attempts_since_acceptance;
            produced += 2;
            attempts_since_acceptance = 0;
            if (produced == 2 * wanted) break;
        }
    }
    if (produced != 2 * wanted) return -3;
    for (usz i = 0; i < produced; ++i) store_i64_le(output, 8 * i, staged[i]);
    return (long)output_bytes;
}
