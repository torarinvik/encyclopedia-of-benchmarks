#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 16, MAX_M = 16, MAX_INPUT = 34, MAX_OUTPUT = 136;
void put64(std::uint8_t* output, std::size_t position, std::int64_t value) {
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[position + byte] = static_cast<std::uint8_t>(bits >> (8U * byte));
}
std::size_t bit_count(std::uint64_t value) {
    std::size_t count = 0;
    while (value != 0) { value &= value - 1U; ++count; }
    return count;
}
}

extern "C" std::int64_t weighted_greedy_set_cover(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 4 || length > MAX_INPUT) return -1;
    const auto n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(MAX_N) || m64 < 1 ||
        m64 > static_cast<std::int64_t>(MAX_M) || length != 2 + 2 * static_cast<std::size_t>(m64)) return -1;
    const auto n = static_cast<std::size_t>(n64), m = static_cast<std::size_t>(m64);
    const std::uint64_t full = (UINT64_C(1) << n) - 1U;
    std::int64_t weight[MAX_M]{};
    std::uint64_t mask[MAX_M]{}, union_mask = 0;
    for (std::size_t set = 0; set < m; ++set) {
        weight[set] = input[2 + set];
        const auto value = input[2 + m + set];
        if (weight[set] < 0 || weight[set] > 10000 || value < 0 ||
            (static_cast<std::uint64_t>(value) & ~full) != 0) return -1;
        mask[set] = static_cast<std::uint64_t>(value);
        union_mask |= mask[set];
    }
    if (union_mask != full) return -1;

    std::uint64_t covered = 0;
    std::size_t selected[MAX_M]{}, selected_count = 0;
    while (covered != full) {
        std::size_t best = MAX_M, best_gain = 0;
        for (std::size_t set = 0; set < m; ++set) {
            const auto gain = bit_count(mask[set] & ~covered);
            if (gain == 0) continue;
            if (best == MAX_M || weight[set] * static_cast<std::int64_t>(best_gain) <
                weight[best] * static_cast<std::int64_t>(gain)) {
                best = set; best_gain = gain;
            }
        }
        if (best == MAX_M) return -1;
        selected[selected_count++] = best;
        covered |= mask[best];
    }
    const auto output_bytes = 8 * (selected_count + 1);
    if (output == nullptr || capacity < output_bytes) return -2;
    std::uint8_t staged[MAX_OUTPUT]{};
    put64(staged, 0, static_cast<std::int64_t>(selected_count));
    for (std::size_t index = 0; index < selected_count; ++index)
        put64(staged, 8 * (index + 1), static_cast<std::int64_t>(selected[index]));
    for (std::size_t index = 0; index < output_bytes; ++index) output[index] = staged[index];
    return static_cast<std::int64_t>(output_bytes);
}
