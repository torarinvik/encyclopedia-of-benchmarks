#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_jobs = 32;
constexpr std::int64_t max_burst = 4096;
constexpr std::int64_t quantum = 2;

void put_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t round_robin(const std::int64_t* input, std::size_t length,
                                     std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 1) return -1;
    const auto raw_count = input[0];
    if (raw_count < 0 || raw_count > max_jobs || length != static_cast<std::size_t>(raw_count) + 1) return -1;
    const auto count = static_cast<std::size_t>(raw_count);
    std::int64_t remaining[32]{};
    std::int64_t waiting[32]{};
    for (std::size_t i = 0; i < count; ++i) {
        const auto burst = input[i + 1];
        if (burst < 0 || burst > max_burst) return -1;
        remaining[i] = burst;
    }
    const auto bytes = (1 + 2 * count) * 8;
    if (output == nullptr || capacity < bytes) return -2;
    std::int64_t elapsed = 0;
    for (;;) {
        bool done = true;
        for (std::size_t i = 0; i < count; ++i) {
            if (remaining[i] > 0) {
                done = false;
                if (remaining[i] > quantum) {
                    elapsed += quantum;
                    remaining[i] -= quantum;
                } else {
                    elapsed += remaining[i];
                    waiting[i] = elapsed - input[i + 1];
                    remaining[i] = 0;
                }
            }
        }
        if (done) break;
    }
    put_i64_le(output, 0, raw_count);
    for (std::size_t i = 0; i < count; ++i) put_i64_le(output, 8 * (1 + i), waiting[i]);
    for (std::size_t i = 0; i < count; ++i) put_i64_le(output, 8 * (1 + count + i), input[i + 1] + waiting[i]);
    return static_cast<std::int64_t>(bytes);
}
