#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxN = 32, MaxInput = 33;
constexpr std::int64_t Capacity = 10000;
void storeI64LE(std::uint8_t* out, std::size_t offset, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) { out[offset + byte] = static_cast<std::uint8_t>(bits & 255U); bits >>= 8; }
}
}

extern "C" std::int64_t harmonic_4_bin_packing(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (!input || length < 2 || length > MaxInput) return -1;
    const auto n64 = input[0];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(MaxN) || length != 1 + static_cast<std::size_t>(n64)) return -1;
    const auto n = static_cast<std::size_t>(n64);
    for (std::size_t i = 0; i < n; ++i) if (input[1 + i] < 1 || input[1 + i] > Capacity) return -1;
    const auto outputBytes = 8 * (n + 1);
    if (!output || capacity < outputBytes) return -2;
    std::int64_t current[4] = {-1, -1, -1, -1}, remaining[4]{}, assignment[MaxN]{};
    std::int64_t bins = 0;
    for (std::size_t i = 0; i < n; ++i) {
        const auto size = input[1 + i];
        const std::size_t kind = size * 2 > Capacity ? 0 : size * 3 > Capacity ? 1 : size * 4 > Capacity ? 2 : 3;
        if (current[kind] < 0 || size > remaining[kind]) { current[kind] = bins++; remaining[kind] = Capacity; }
        assignment[i] = current[kind];
        remaining[kind] -= size;
    }
    storeI64LE(output, 0, bins);
    for (std::size_t i = 0; i < n; ++i) storeI64LE(output, 8 * (i + 1), assignment[i]);
    return static_cast<std::int64_t>(outputBytes);
}
