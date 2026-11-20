#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_capacity = 8;
constexpr std::size_t max_requests = 64;
constexpr std::size_t page_count = 16;
constexpr std::size_t max_input_length = 67;
constexpr std::int64_t checksum_radix = 33'281;
}

extern "C" std::int64_t belady_optimal_paging(const std::int64_t* input,
        std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_capacity) ||
        input[1] < 0 || input[1] > static_cast<std::int64_t>(max_requests) ||
        length != static_cast<std::size_t>(2 + input[1])) return -1;
    const auto capacity = static_cast<std::size_t>(input[0]);
    const auto count = static_cast<std::size_t>(input[1]);
    std::array<std::size_t, max_requests> requests{};
    for (std::size_t time = 0; time < count; ++time) {
        if (input[2 + time] < 0 || input[2 + time] >= static_cast<std::int64_t>(page_count)) return -1;
        requests[time] = static_cast<std::size_t>(input[2 + time]);
    }
    std::array<std::array<std::size_t, page_count>, max_requests> next_after{};
    std::array<std::size_t, page_count> next_position{};
    next_position.fill(count);
    for (std::size_t time = count; time > 0; --time) {
        const auto index = time - 1;
        next_after[index] = next_position;
        next_position[requests[index]] = index;
    }

    std::array<bool, page_count> resident{};
    std::size_t resident_count = 0;
    std::int64_t misses = 0, eviction_checksum = 0;
    for (std::size_t time = 0; time < count; ++time) {
        const auto requested = requests[time];
        if (resident[requested]) continue;
        ++misses;
        if (resident_count == capacity) {
            std::size_t victim = page_count;
            std::size_t farthest = 0;
            for (std::size_t page = 0; page < page_count; ++page) {
                if (resident[page] && (victim == page_count || next_after[time][page] > farthest)) {
                    victim = page;
                    farthest = next_after[time][page];
                }
            }
            resident[victim] = false;
            --resident_count;
            eviction_checksum += static_cast<std::int64_t>((time + 1) * (victim + 1));
        }
        resident[requested] = true;
        ++resident_count;
    }
    return misses * checksum_radix + eviction_checksum;
}
