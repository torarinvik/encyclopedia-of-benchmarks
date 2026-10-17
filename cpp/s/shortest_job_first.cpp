#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_jobs = 32;
constexpr std::int64_t max_arrival = 64;
constexpr std::int64_t max_burst = 128;
constexpr std::int64_t sentinel = 999999999;

void put_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t shortest_job_first(const std::int64_t* input, std::size_t length,
                                             std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 1) return -1;
    const auto raw_count = input[0];
    if (raw_count < 0 || raw_count > max_jobs || length != 1 + 2 * static_cast<std::size_t>(raw_count)) return -1;
    const auto count = static_cast<std::size_t>(raw_count);
    std::int64_t remaining[32]{};
    std::int64_t waiting[32]{};
    for (std::size_t i = 0; i < count; ++i) {
        if (input[1 + i] < 0 || input[1 + i] > max_arrival) return -1;
        const auto burst = input[1 + count + i];
        if (burst < 1 || burst > max_burst || burst >= sentinel) return -1;
        remaining[i] = burst;
    }
    const auto bytes = (1 + 2 * count) * 8;
    if (output == nullptr || capacity < bytes) return -2;
    std::size_t complete = 0, short_index = 0;
    std::int64_t time = 0, minimum = sentinel;
    bool check = false;
    while (complete != count) {
        for (std::size_t j = 0; j < count; ++j) {
            if (input[1 + j] <= time && remaining[j] > 0 && remaining[j] < minimum) {
                minimum = remaining[j];
                short_index = j;
                check = true;
            }
        }
        if (!check) { ++time; continue; }
        --remaining[short_index];
        minimum = remaining[short_index];
        if (minimum == 0) minimum = sentinel;
        if (remaining[short_index] == 0) {
            ++complete;
            check = false;
            const auto finish_time = time + 1;
            const auto wait = finish_time - input[1 + short_index] - input[1 + count + short_index];
            waiting[short_index] = wait > 0 ? wait : 0;
        }
        ++time;
    }
    put_i64_le(output, 0, raw_count);
    for (std::size_t i = 0; i < count; ++i) put_i64_le(output, 8 * (1 + i), waiting[i]);
    for (std::size_t i = 0; i < count; ++i) put_i64_le(output, 8 * (1 + count + i), input[1 + count + i] + waiting[i]);
    return static_cast<std::int64_t>(bytes);
}
