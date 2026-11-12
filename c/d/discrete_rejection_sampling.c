#include <stddef.h>
#include <stdint.h>

#define DRS_MAX_CATEGORIES 8
#define DRS_MAX_SAMPLES 8
#define DRS_MAX_ATTEMPTS 32
#define DRS_MAX_INPUT_VALUES 83
#define DRS_DRAW_SCALE UINT64_C(4294967296)

static void drs_store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t discrete_rejection_sampling(const int64_t *input, size_t length,
                                    uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > DRS_MAX_INPUT_VALUES) return -1;
    const int64_t n_value = input[0];
    const int64_t samples_value = input[1];
    const int64_t attempts_value = input[2];
    if (n_value < 1 || n_value > DRS_MAX_CATEGORIES ||
        samples_value < 1 || samples_value > DRS_MAX_SAMPLES ||
        attempts_value < 1 || attempts_value > DRS_MAX_ATTEMPTS) return -1;
    const size_t n = (size_t)n_value;
    const size_t wanted = (size_t)samples_value;
    const size_t attempts = (size_t)attempts_value;
    if (length != 3 + 2 * n + 2 * attempts) return -1;

    int64_t target[DRS_MAX_CATEGORIES];
    int64_t proposal[DRS_MAX_CATEGORIES];
    int64_t cumulative[DRS_MAX_CATEGORIES];
    uint64_t target_total = 0;
    uint64_t proposal_total = 0;
    for (size_t i = 0; i < n; ++i) {
        const int64_t weight = input[3 + i];
        const int64_t q_weight = input[3 + n + i];
        if (weight < 1 || weight > 20 || q_weight < 1 || q_weight > 20) return -1;
        target[i] = weight;
        proposal[i] = q_weight;
        target_total += (uint64_t)weight;
        proposal_total += (uint64_t)q_weight;
        cumulative[i] = (int64_t)proposal_total;
    }

    uint64_t envelope = 1;
    for (size_t i = 0; i < n; ++i) {
        const uint64_t numerator = (uint64_t)target[i] * proposal_total;
        const uint64_t denominator = target_total * (uint64_t)proposal[i];
        const uint64_t ratio_ceiling = (numerator + denominator - 1) / denominator;
        if (ratio_ceiling > envelope) envelope = ratio_ceiling;
    }

    const size_t tape_offset = 3 + 2 * n;
    for (size_t attempt = 0; attempt < attempts; ++attempt) {
        const int64_t proposal_draw = input[tape_offset + 2 * attempt];
        const int64_t acceptance_draw = input[tape_offset + 2 * attempt + 1];
        if (proposal_draw < 0 || (uint64_t)proposal_draw >= proposal_total ||
            acceptance_draw < 0 || (uint64_t)acceptance_draw >= DRS_DRAW_SCALE) return -1;
    }

    const size_t output_bytes = 16 * wanted;
    if (output == NULL || capacity < output_bytes) return -2;

    int64_t staged[2 * DRS_MAX_SAMPLES];
    size_t produced = 0;
    size_t attempts_since_acceptance = 0;
    for (size_t attempt = 0; attempt < attempts; ++attempt) {
        ++attempts_since_acceptance;
        const uint64_t proposal_draw = (uint64_t)input[tape_offset + 2 * attempt];
        const uint64_t acceptance_draw = (uint64_t)input[tape_offset + 2 * attempt + 1];
        size_t category = 0;
        while ((uint64_t)cumulative[category] <= proposal_draw) ++category;

        const uint64_t left = acceptance_draw * target_total *
                              (uint64_t)proposal[category] * envelope;
        const uint64_t right = DRS_DRAW_SCALE * (uint64_t)target[category] * proposal_total;
        if (left < right) {
            staged[produced++] = (int64_t)category;
            staged[produced++] = (int64_t)attempts_since_acceptance;
            attempts_since_acceptance = 0;
            if (produced == 2 * wanted) break;
        }
    }
    if (produced != 2 * wanted) return -3;
    for (size_t i = 0; i < produced; ++i) drs_store_i64_le(output, 8 * i, staged[i]);
    return (int64_t)output_bytes;
}
