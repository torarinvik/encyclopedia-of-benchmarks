#include <array>
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t MaxInput = 4, MaxTrips = 32; }

extern "C" std::int64_t ski_rental_deterministic(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) noexcept {
    if (!input || length < 3 || length > MaxInput) return -1;
    const auto rent = input[0], purchase = input[1], trips = input[2];
    if (length != 3 || rent < 1 || rent > 32 || purchase < 1 || purchase > 64 || trips < 0 || trips > 32) return -1;
    const auto count = static_cast<std::size_t>(trips);
    if (!output || capacity < count) return -2;
    std::array<std::uint8_t, MaxTrips> actions{};
    const auto threshold = purchase / rent;
    for (std::size_t trip = 0; trip < count; ++trip) {
        if (static_cast<std::int64_t>(trip) < threshold) actions[trip] = 0;
        else if (static_cast<std::int64_t>(trip) == threshold) actions[trip] = 1;
        else actions[trip] = 2;
    }
    for (std::size_t trip = 0; trip < count; ++trip) output[trip] = actions[trip];
    return static_cast<std::int64_t>(count);
}
