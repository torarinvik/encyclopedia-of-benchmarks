#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t Scale = 16;
constexpr std::size_t MaxN = 12, MaxSteps = 64, MaxInput = 79, MaxOutput = 208;
void put_i64(std::uint8_t *out, std::size_t offset, std::int64_t value) {
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) { out[offset + b] = static_cast<std::uint8_t>(bits & 255); bits >>= 8; }
}
}

extern "C" std::int64_t ring_exact_covering_protocol(const std::int64_t *v, std::size_t length,
                                                       std::uint8_t *output, std::size_t capacity) {
    if (!v || length < 3 || length > MaxInput || v[0] < 2 || v[0] > static_cast<std::int64_t>(MaxN)) return -1;
    const std::size_t n = static_cast<std::size_t>(v[0]);
    if (v[2] < 0 || v[2] > static_cast<std::int64_t>(MaxSteps) || length != 3 + n + static_cast<std::size_t>(v[2])) return -1;
    const std::size_t steps = static_cast<std::size_t>(v[2]);
    const std::int64_t circumference = Scale * static_cast<std::int64_t>(n), visibility = v[1];
    if (visibility < 2 * Scale || visibility > circumference) return -1;
    std::int64_t position[MaxN];
    for (std::size_t i = 0; i < n; ++i) {
        position[i] = v[3 + i];
        if (position[i] < 0 || position[i] >= circumference || (i && position[i - 1] >= position[i])) return -1;
    }
    for (std::size_t j = 0; j < steps; ++j) if (v[3 + n + j] < 0 || v[3 + n + j] >= static_cast<std::int64_t>(n)) return -1;
    std::int64_t moved = 0;
    for (std::size_t j = 0; j < steps; ++j) {
        const std::size_t i = static_cast<std::size_t>(v[3 + n + j]), next = (i + 1) % n;
        const std::int64_t gap = (position[next] - position[i] + circumference) % circumference;
        const std::int64_t distance = gap > visibility ? Scale : (gap > Scale ? gap - Scale : 0);
        if (distance) { position[i] = (position[i] + distance) % circumference; ++moved; }
    }
    const std::size_t words = 2 + 2 * n, bytes = 8 * words;
    if (!output || capacity < bytes) return -2;
    std::int64_t result[2 + 2 * MaxN]{}; result[0] = static_cast<std::int64_t>(n); result[1] = moved;
    for (std::size_t i = 0; i < n; ++i) result[2 + i] = position[i];
    for (std::size_t i = 0; i < n; ++i) result[2 + n + i] = (position[(i + 1) % n] - position[i] + circumference) % circumference;
    std::uint8_t staged[MaxOutput]; for (std::size_t i = 0; i < words; ++i) put_i64(staged, 8 * i, result[i]);
    for (std::size_t i = 0; i < bytes; ++i) output[i] = staged[i]; return static_cast<std::int64_t>(bytes);
}
