#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 64;
constexpr std::size_t kMaxEvents = 2 * kMaxN;
}

extern "C" std::int64_t segment_union_length_klee(const std::int64_t* input,
                                                   std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > 130) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(kMaxN)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != 1 + 2 * n) return -1;
    std::array<std::int64_t, kMaxEvents> events{};
    for (std::size_t i = 0; i < n; ++i) {
        const auto left = input[1 + 2 * i], right = input[2 + 2 * i];
        if (left < -1000 || left > right || right > 1000) return -1;
        events[2 * i] = 2 * (left + 1000);
        events[2 * i + 1] = 2 * (right + 1000) + 1;
    }
    const auto event_count = 2 * n;
    std::sort(events.begin(), events.begin() + static_cast<std::ptrdiff_t>(event_count));
    std::int64_t active = 0, total = 0, previous = 0;
    std::size_t index = 0;
    while (index < event_count) {
        const auto coordinate_code = events[index] / 2;
        const auto coordinate = coordinate_code - 1000;
        if (index > 0 && active > 0) total += coordinate - previous;
        std::int64_t delta = 0;
        while (index < event_count && events[index] / 2 == coordinate_code) {
            delta += (events[index] % 2 == 0) ? 1 : -1;
            ++index;
        }
        active += delta;
        previous = coordinate;
    }
    return total;
}
