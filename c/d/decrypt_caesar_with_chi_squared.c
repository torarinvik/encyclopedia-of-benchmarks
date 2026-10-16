/* Select the Caesar plaintext with the smallest pinned-source chi-square score. */
#include <stddef.h>
#include <stdint.h>

static const double frequencies[26] = {
    0.08497, 0.01492, 0.02202, 0.04253, 0.11162, 0.02228, 0.02015,
    0.06094, 0.07546, 0.00153, 0.01292, 0.04025, 0.02406, 0.06749,
    0.07507, 0.01929, 0.00095, 0.07587, 0.06327, 0.09356, 0.02758,
    0.00978, 0.02560, 0.00150, 0.01994, 0.00077
};

static void write_f64_le(uint8_t *out, double value) {
    union { double f; uint64_t u; } bits;
    bits.f = value;
    for (unsigned i = 0; i < 8; ++i) out[i] = (uint8_t)(bits.u >> (8 * i));
}

int64_t decrypt_caesar_with_chi_squared(const int64_t *input, size_t length,
                                         uint8_t *output, size_t output_capacity) {
    if (length < 1 || length > 129 || input[0] < 0 || input[0] > 128
        || length != (size_t)input[0] + 1) return -1;
    size_t n = (size_t)input[0];
    for (size_t i = 0; i < n; ++i) if (input[i + 1] < 0 || input[i + 1] > 127) return -1;
    if (output_capacity < n + 8) return -2;

    double best_score = 0.0;
    int best_shift = 0;
    uint8_t best[128];
    int have_best = 0;
    for (int shift = 0; shift < 26; ++shift) {
        uint8_t decoded[128];
        int counts[26] = {0};
        for (size_t i = 0; i < n; ++i) {
            int value = (int)input[i + 1];
            if (value >= 'A' && value <= 'Z') value += 'a' - 'A';
            if (value >= 'a' && value <= 'z') {
                value = 'a' + (value - 'a' - shift + 26) % 26;
                ++counts[value - 'a'];
            }
            decoded[i] = (uint8_t)value;
        }
        double score = 0.0;
        for (int letter = 0; letter < 26; ++letter) {
            int observed = counts[letter];
            if (observed) {
                double expected = frequencies[letter] * observed;
                double difference = observed - expected;
                score += (difference * difference) / expected;
            }
        }
        int lex_less = 0;
        if (have_best && score == best_score) {
            for (size_t i = 0; i < n; ++i) {
                if (decoded[i] != best[i]) { lex_less = decoded[i] < best[i]; break; }
            }
        }
        if (!have_best || score < best_score || (score == best_score && lex_less)) {
            best_score = score;
            best_shift = shift;
            for (size_t i = 0; i < n; ++i) best[i] = decoded[i];
            have_best = 1;
        }
    }
    write_f64_le(output, best_score);
    for (size_t i = 0; i < n; ++i) output[8 + i] = best[i];
    return best_shift;
}
