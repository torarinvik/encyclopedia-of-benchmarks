#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxTerms = 4097;
constexpr std::size_t kMaxInputLength = 3;
constexpr std::int64_t kMaxSeed = 100000;
constexpr std::int64_t kMaxValue = 100000;
constexpr std::int64_t kMaxTransitions = 4096;

std::int64_t aliquot_sum(std::int64_t value) noexcept {
    if (value == 1) return 0;
    std::int64_t sum = 1;
    for (std::int64_t d = 2; d <= value / d; ++d) {
        if (value % d == 0) {
            sum += d;
            const auto partner = value / d;
            if (partner != d) sum += partner;
        }
    }
    return sum;
}

void store_i64(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t aliquot_orbit_decomposition(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 1 || length > kMaxInputLength) return -1;
    if (length != 2 || input[0] < 1 || input[0] > kMaxSeed ||
        input[1] < 1 || input[1] > kMaxTransitions) return -1;

    std::array<std::int64_t, kMaxTerms> keys{};
    std::array<std::int64_t, kMaxTerms> first_indices{};
    std::size_t key_count = 0;
    std::array<std::int64_t, 3> words{};
    auto current = input[0];
    const auto max_transitions = input[1];
    std::int64_t transitions = 0;
    std::int64_t positive_term_count = 0;

    for (;;) {
        if (current == 0) {
            words = {0, positive_term_count, 0};
            break;
        }
        std::size_t low = 0, high = key_count;
        while (low < high) {
            const auto middle = low + (high - low) / 2;
            if (keys[middle] < current) low = middle + 1;
            else high = middle;
        }
        if (low < key_count && keys[low] == current) {
            words = {1, first_indices[low], transitions - first_indices[low]};
            break;
        }
        for (std::size_t i = key_count; i > low; --i) {
            keys[i] = keys[i - 1];
            first_indices[i] = first_indices[i - 1];
        }
        keys[low] = current;
        first_indices[low] = transitions;
        ++key_count;
        ++positive_term_count;
        if (transitions >= max_transitions) {
            words = {-3, transitions, current};
            break;
        }
        const auto next_value = aliquot_sum(current);
        ++transitions;
        if (next_value > kMaxValue) {
            words = {-2, transitions, next_value};
            break;
        }
        current = next_value;
    }

    if (output == nullptr || capacity < 24) return -2;
    for (std::size_t word = 0; word < words.size(); ++word)
        store_i64(output, word * 8, words[word]);
    return 24;
}
