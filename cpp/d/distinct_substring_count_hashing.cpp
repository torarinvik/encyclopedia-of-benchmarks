#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kMaxText = 64;
constexpr std::int64_t kModulus = 1'000'000'007;
constexpr std::size_t kHashSlots = 64;
}

extern "C" std::int64_t distinct_substring_count_hashing(
    const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > 66) return -1;
    const std::int64_t n_value = input[0];
    if (n_value < 0 || n_value > kMaxText || length != static_cast<std::size_t>(n_value + 1)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    for (std::size_t i = 0; i < n; ++i) if (input[i + 1] < 0 || input[i + 1] > 255) return -1;

    std::int64_t prefix[65]{}, powers[65]{};
    powers[0] = 1;
    for (std::size_t i = 0; i < n; ++i) {
        prefix[i + 1] = (prefix[i] * 257 + input[i + 1] + 1) % kModulus;
        powers[i + 1] = powers[i] * 257 % kModulus;
    }
    std::int64_t group_hash[64], group_head[64], representative_start[64], representative_next[64];
    std::int64_t distinct = 0;
    for (std::size_t width = 1; width <= n; ++width) {
        for (std::size_t slot = 0; slot < kHashSlots; ++slot) group_hash[slot] = group_head[slot] = -1;
        std::size_t representative_count = 0;
        for (std::size_t start = 0; start + width <= n; ++start) {
            const auto end = start + width;
            auto fingerprint = (prefix[end] - prefix[start] * powers[width] % kModulus) % kModulus;
            if (fingerprint < 0) fingerprint += kModulus;
            auto slot = static_cast<std::size_t>(fingerprint % static_cast<std::int64_t>(kHashSlots));
            while (group_hash[slot] != -1 && group_hash[slot] != fingerprint) slot = (slot + 1) % kHashSlots;
            if (group_hash[slot] == -1) group_hash[slot] = fingerprint;

            bool duplicate = false;
            auto prior = group_head[slot];
            while (prior >= 0) {
                const auto old_start = static_cast<std::size_t>(representative_start[static_cast<std::size_t>(prior)]);
                std::size_t offset = 0;
                while (offset < width && input[start + offset + 1] == input[old_start + offset + 1]) ++offset;
                if (offset == width) { duplicate = true; break; }
                prior = representative_next[static_cast<std::size_t>(prior)];
            }
            if (!duplicate) {
                representative_start[representative_count] = static_cast<std::int64_t>(start);
                representative_next[representative_count] = group_head[slot];
                group_head[slot] = static_cast<std::int64_t>(representative_count++);
                ++distinct;
            }
        }
    }
    return distinct;
}
