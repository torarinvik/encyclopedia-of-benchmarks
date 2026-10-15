/* Breadth-first search over forward-reachable indices. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_length = 1024; }

extern "C" std::int64_t jump_game_ii(const std::int64_t *values,
                                      std::size_t length) noexcept {
    if (values == nullptr || length == 0 || length > max_length) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (values[index] < 0 || values[index] > static_cast<std::int64_t>(length)) return -1;
    if (length == 1) return 0;
    std::array<std::size_t, max_length> queue{};
    std::array<std::size_t, max_length> distance{};
    std::array<bool, max_length> visited{};
    std::size_t head = 0, tail = 1;
    queue[0] = 0;
    visited[0] = true;
    while (head < tail) {
        const auto cell = queue[head++];
        const auto farthest = cell + static_cast<std::size_t>(values[cell]);
        if (farthest >= length - 1) return static_cast<std::int64_t>(distance[cell]) + 1;
        for (auto next = cell + 1; next <= farthest; ++next) {
            if (!visited[next]) {
                visited[next] = true;
                distance[next] = distance[cell] + 1;
                queue[tail++] = next;
            }
        }
    }
    return -1;
}
