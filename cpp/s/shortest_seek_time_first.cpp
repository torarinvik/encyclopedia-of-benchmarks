#include <array>
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_requests = 64; }

extern "C" std::int64_t shortest_seek_time_first(const std::int64_t* values, std::size_t length,
                                                   std::uint8_t* output, std::size_t capacity)
{
    if (values == nullptr || length < 2 || length > 2 + max_requests) return -1;
    const auto initial_track = values[0], request_count = values[1];
    if (initial_track < 0 || initial_track > 255 || request_count < 0 ||
        request_count > static_cast<std::int64_t>(max_requests) ||
        length != 2 + static_cast<std::size_t>(request_count)) return -1;
    for (std::size_t i = 0; i < static_cast<std::size_t>(request_count); ++i)
        if (values[2 + i] < 0 || values[2 + i] > 255) return -1;
    if (output == nullptr || capacity < static_cast<std::size_t>(request_count)) return -2;

    std::array<bool, max_requests> serviced{};
    auto current = initial_track;
    for (std::size_t step = 0; step < static_cast<std::size_t>(request_count); ++step) {
        auto best = max_requests;
        std::int64_t best_distance = 256;
        for (std::size_t i = 0; i < static_cast<std::size_t>(request_count); ++i) {
            if (serviced[i]) continue;
            auto distance = current - values[2 + i];
            if (distance < 0) distance = -distance;
            if (distance < best_distance) { best = i; best_distance = distance; }
        }
        const auto selected = values[2 + best];
        output[step] = static_cast<std::uint8_t>(selected);
        serviced[best] = true;
        current = selected;
    }
    return request_count;
}
