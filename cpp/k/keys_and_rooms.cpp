// Return whether every room is reachable from room zero.
#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t keys_and_rooms(const std::int64_t *values, std::size_t length)
{
    constexpr std::size_t max_rooms = 1000;
    constexpr std::size_t max_input_length = 100001;
    if (values == nullptr || length < 3 || length > max_input_length) return -1;
    if (values[0] < 2 || values[0] > static_cast<std::int64_t>(max_rooms)) return -1;
    const auto room_count = static_cast<std::size_t>(values[0]);
    std::array<std::size_t, max_rooms> starts{};
    std::array<std::size_t, max_rooms> degrees{};
    std::size_t cursor = 1;

    for (std::size_t room = 0; room < room_count; ++room) {
        if (cursor >= length) return -1;
        const auto count_value = values[cursor++];
        if (count_value < 0 || count_value > static_cast<std::int64_t>(room_count)) return -1;
        const auto degree = static_cast<std::size_t>(count_value);
        if (degree > length - cursor) return -1;
        starts[room] = cursor;
        degrees[room] = degree;
        for (std::size_t edge = 0; edge < degree; ++edge) {
            if (values[cursor + edge] < 0 || values[cursor + edge] >= static_cast<std::int64_t>(room_count))
                return -1;
        }
        cursor += degree;
    }
    if (cursor != length) return -1;

    std::array<bool, max_rooms> visited{};
    std::array<std::size_t, max_rooms> stack{};
    std::size_t stack_size = 1;
    std::size_t reached = 0;
    stack[0] = 0;
    visited[0] = true;
    while (stack_size > 0) {
        const auto room = stack[--stack_size];
        ++reached;
        for (std::size_t edge = 0; edge < degrees[room]; ++edge) {
            const auto key = static_cast<std::size_t>(values[starts[room] + edge]);
            if (!visited[key]) {
                visited[key] = true;
                stack[stack_size++] = key;
            }
        }
    }
    return reached == room_count ? 1 : 0;
}
