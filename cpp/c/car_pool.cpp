#include <cstddef>
#include <cstdint>

extern "C" std::int64_t car_pool(const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length < 2 || length > 194) return -1;
    if (input[0] < 0 || input[0] > 1000 || input[1] < 0 || input[1] > 64) return -1;
    const auto capacity = input[0];
    const auto trip_count = static_cast<std::size_t>(input[1]);
    if (length != 2 + 3 * trip_count) return -1;

    std::int32_t events[1001]{};
    for (std::size_t trip = 0; trip < trip_count; ++trip) {
        const auto offset = 2 + 3 * trip;
        const auto passengers = input[offset];
        const auto origin = input[offset + 1];
        const auto destination = input[offset + 2];
        if (passengers < 1 || passengers > 1000 || origin < 0 || origin >= destination || destination > 1000) return -1;
        events[origin] += static_cast<std::int32_t>(passengers);
        events[destination] -= static_cast<std::int32_t>(passengers);
    }

    std::int32_t occupants = 0;
    for (std::size_t position = 0; position < 1000; ++position) {
        occupants += events[position];
        if (occupants > capacity) return 0;
    }
    return 1;
}
