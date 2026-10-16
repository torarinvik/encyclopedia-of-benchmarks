#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_requests = 64;
constexpr std::int64_t max_cylinder_count = 128;

void sort_ascending(std::array<std::int64_t, max_requests>& items, std::size_t count)
{
    for (std::size_t index = 1; index < count; ++index) {
        const auto value = items[index];
        std::size_t position = index;
        while (position > 0 && items[position - 1] > value) {
            items[position] = items[position - 1];
            --position;
        }
        items[position] = value;
    }
}
}

extern "C" std::int64_t circular_look_scheduling(const std::int64_t* values, std::size_t length,
                                                   std::uint8_t* output, std::size_t capacity)
{
    if (values == nullptr || length < 4 || length > 4 + max_requests) return -1;
    const auto max_cylinder = values[0];
    const auto start = values[1];
    const auto moving_up = values[2];
    const auto request_count = values[3];
    if (max_cylinder < 1 || max_cylinder > max_cylinder_count || start < 0 || start >= max_cylinder ||
        (moving_up != 0 && moving_up != 1) || request_count < 0 || request_count > static_cast<std::int64_t>(max_requests) ||
        length != 4 + static_cast<std::size_t>(request_count)) return -1;

    std::array<std::int64_t, max_requests> up{}, down{};
    std::size_t up_count = 0, down_count = 0;
    for (std::size_t index = 0; index < static_cast<std::size_t>(request_count); ++index) {
        const auto request = values[4 + index];
        if (request < -128 || request > 255) return -1;
        if (request < 0 || request >= max_cylinder || request == start) continue;
        if (request > start) up[up_count++] = request;
        else down[down_count++] = request;
    }
    sort_ascending(up, up_count);
    sort_ascending(down, down_count);

    const auto output_count = up_count + down_count;
    if (capacity < output_count || (output_count > 0 && output == nullptr)) return -2;
    std::size_t position = 0;
    if (moving_up == 1) {
        for (std::size_t index = 0; index < up_count; ++index) output[position++] = static_cast<std::uint8_t>(up[index]);
        for (std::size_t index = 0; index < down_count; ++index) output[position++] = static_cast<std::uint8_t>(down[index]);
    } else {
        for (std::size_t index = down_count; index > 0; --index) output[position++] = static_cast<std::uint8_t>(down[index - 1]);
        for (std::size_t index = up_count; index > 0; --index) output[position++] = static_cast<std::uint8_t>(up[index - 1]);
    }
    return static_cast<std::int64_t>(output_count);
}
