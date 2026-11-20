/* Elias–Fano encode-and-access checksum for a bounded monotone sequence. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_n = 32;
constexpr int max_high_bits = 3 * max_n;
}

extern "C" std::int64_t elias_fano_monotone_sequence(
    const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 3 || length > max_n + 3) return -1;
    const std::int64_t raw_n = input[0], upper_bound = input[1];
    if (raw_n < 1 || raw_n > max_n || upper_bound < 0 || upper_bound > 1'000'000 ||
        raw_n > upper_bound + 1 || length != static_cast<std::size_t>(raw_n + 2)) return -1;
    const int n = static_cast<int>(raw_n);

    std::int64_t values[max_n]{}, low_parts[max_n]{};
    for (int i = 0; i < n; ++i) {
        const auto value = input[i + 2];
        if (value < 0 || value > upper_bound || (i > 0 && value < values[i - 1])) return -1;
        values[i] = value;
    }

    int low_width = 0;
    std::int64_t low_scale = 1;
    while (static_cast<std::int64_t>(n) * (low_scale << 1) <= upper_bound + 1) {
        low_scale <<= 1;
        ++low_width;
    }
    const std::uint64_t low_mask = (std::uint64_t{1} << low_width) - 1;
    for (int i = 0; i < n; ++i)
        low_parts[i] = static_cast<std::int64_t>(static_cast<std::uint64_t>(values[i]) & low_mask);

    const std::int64_t high_length = (upper_bound >> low_width) + n;
    if (high_length < 1 || high_length > max_high_bits) return -1;
    std::uint64_t high_bits[(max_high_bits + 63) / 64]{};
    for (int i = 0; i < n; ++i) {
        const std::int64_t position = (values[i] >> low_width) + i;
        if (position < 0 || position >= high_length) return -1;
        high_bits[position / 64] |= std::uint64_t{1} << (position % 64);
    }

    std::int64_t checksum = 0;
    int item_index = 0;
    for (std::int64_t position = 0; position < high_length; ++position) {
        if (((high_bits[position / 64] >> (position % 64)) & std::uint64_t{1}) == 0) continue;
        if (item_index >= n || position < item_index) return -1;
        const std::int64_t high_part = position - item_index;
        const std::int64_t decoded = (high_part << low_width) | low_parts[item_index];
        checksum += static_cast<std::int64_t>(item_index + 1) * decoded;
        ++item_index;
    }
    return item_index == n ? checksum : -1;
}
