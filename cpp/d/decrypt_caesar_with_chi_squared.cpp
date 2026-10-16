/* Select the Caesar plaintext with the smallest pinned-source chi-square score. */
#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <cstring>

extern "C" int64_t decrypt_caesar_with_chi_squared(const int64_t *input,
    size_t length, uint8_t *output, size_t output_capacity) {
    static constexpr std::array<double, 26> frequencies = {
        0.08497, 0.01492, 0.02202, 0.04253, 0.11162, 0.02228, 0.02015,
        0.06094, 0.07546, 0.00153, 0.01292, 0.04025, 0.02406, 0.06749,
        0.07507, 0.01929, 0.00095, 0.07587, 0.06327, 0.09356, 0.02758,
        0.00978, 0.02560, 0.00150, 0.01994, 0.00077
    };
    if (length < 1 || length > 129 || input[0] < 0 || input[0] > 128
        || length != static_cast<size_t>(input[0]) + 1) return -1;
    const size_t n = static_cast<size_t>(input[0]);
    for (size_t i = 0; i < n; ++i) if (input[i + 1] < 0 || input[i + 1] > 127) return -1;
    if (output_capacity < n + 8) return -2;

    double best_score = 0.0;
    int best_shift = 0;
    std::array<uint8_t, 128> best{};
    bool have_best = false;
    for (int shift = 0; shift < 26; ++shift) {
        std::array<uint8_t, 128> decoded{};
        std::array<int, 26> counts{};
        for (size_t i = 0; i < n; ++i) {
            int value = static_cast<int>(input[i + 1]);
            if (value >= 'A' && value <= 'Z') value += 'a' - 'A';
            if (value >= 'a' && value <= 'z') {
                value = 'a' + (value - 'a' - shift + 26) % 26;
                ++counts[static_cast<size_t>(value - 'a')];
            }
            decoded[i] = static_cast<uint8_t>(value);
        }
        double score = 0.0;
        for (size_t letter = 0; letter < 26; ++letter) {
            const int observed = counts[letter];
            if (observed) {
                const double expected = frequencies[letter] * observed;
                const double difference = observed - expected;
                score += (difference * difference) / expected;
            }
        }
        const bool lex_less = have_best && score == best_score
            && std::lexicographical_compare(decoded.begin(), decoded.begin() + n,
                                            best.begin(), best.begin() + n);
        if (!have_best || score < best_score || lex_less) {
            best_score = score;
            best_shift = shift;
            std::copy_n(decoded.begin(), n, best.begin());
            have_best = true;
        }
    }
    const uint64_t bits = [&] { uint64_t value; std::memcpy(&value, &best_score, sizeof value); return value; }();
    for (unsigned i = 0; i < 8; ++i) output[i] = static_cast<uint8_t>(bits >> (8 * i));
    std::copy_n(best.begin(), n, output + 8);
    return best_shift;
}
