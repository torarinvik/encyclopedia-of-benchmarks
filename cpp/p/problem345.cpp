#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxDimension = 15;
constexpr unsigned kMaxStates = 1U << kMaxDimension;
int bit_count(unsigned value) noexcept {
    int count = 0;
    while (value != 0) { count += static_cast<int>(value & 1U); value >>= 1; }
    return count;
}
}

extern "C" std::int64_t problem345(const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > kMaxDimension * kMaxDimension + 1) return -1;
    const auto dimension = input[0];
    if (dimension < 1 || dimension > kMaxDimension
        || length != static_cast<std::size_t>(dimension * dimension) + 1) return -1;
    for (std::size_t index = 1; index < length; ++index)
        if (input[index] < 0 || input[index] > 1000) return -1;

    std::int64_t best[kMaxStates];
    for (unsigned mask = 0; mask < kMaxStates; ++mask) best[mask] = -1;
    best[0] = 0;
    const unsigned state_count = 1U << static_cast<unsigned>(dimension);
    for (unsigned mask = 0; mask < state_count; ++mask) {
        if (best[mask] < 0) continue;
        const int row = bit_count(mask);
        if (row >= dimension) continue;
        for (int column = 0; column < dimension; ++column) {
            const unsigned bit = 1U << static_cast<unsigned>(column);
            if ((mask & bit) != 0) continue;
            const unsigned next = mask | bit;
            const auto candidate = best[mask] + input[1 + static_cast<std::size_t>(row * dimension + column)];
            if (candidate > best[next]) best[next] = candidate;
        }
    }
    return best[state_count - 1];
}
