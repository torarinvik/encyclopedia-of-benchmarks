/* Clean-room bounded YACR2 Maze1 profile; rights status is documented with the package. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kMaxColumns = 16;
constexpr std::int64_t kMaxTracks = 16;
bool free_vertical(const std::int64_t *v, std::size_t plane, std::size_t columns,
                   std::size_t x, std::size_t y1, std::size_t y2) {
    const auto lo = y1 < y2 ? y1 : y2;
    const auto hi = y1 < y2 ? y2 : y1;
    for (std::size_t y = lo; y <= hi; ++y)
        if (v[plane + y * columns + (x - 1)] != 0) return false;
    return true;
}
bool free_horizontal(const std::int64_t *v, std::size_t plane, std::size_t columns,
                     std::size_t x1, std::size_t x2, std::size_t y) {
    const auto lo = x1 < x2 ? x1 : x2;
    const auto hi = x1 < x2 ? x2 : x1;
    for (std::size_t x = lo; x <= hi; ++x)
        if (v[plane + y * columns + (x - 1)] != 0) return false;
    return true;
}
bool try_dogleg(const std::int64_t *v, std::size_t plane, std::size_t vcv,
                std::size_t columns, std::size_t tracks, std::size_t column,
                std::size_t bottom, std::size_t top, int dx, bool upper) {
    const auto neighbor = static_cast<std::size_t>(static_cast<int>(column) + dx);
    if (upper) {
        const auto jog = bottom - 1;
        return free_vertical(v, plane, columns, column, tracks + 1, bottom) &&
               free_vertical(v, plane, columns, column, 0, jog) &&
               free_horizontal(v, plane, columns, column, neighbor, jog) &&
               free_vertical(v, plane, columns, neighbor, jog, top) &&
               v[vcv + neighbor - 1] == 0;
    }
    const auto jog = top + 1;
    return free_vertical(v, plane, columns, column, 0, top) &&
           free_vertical(v, plane, columns, column, tracks + 1, jog) &&
           free_horizontal(v, plane, columns, column, neighbor, jog) &&
           free_vertical(v, plane, columns, neighbor, jog, bottom) &&
           v[vcv + neighbor - 1] == 0;
}
}

extern "C" std::int64_t ptrdist_yacr2_maze1_dogleg(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 5) return -1;
    if (input[0] < 2 || input[0] > kMaxColumns || input[1] < 2 || input[1] > kMaxTracks) return -1;
    const auto columns = static_cast<std::size_t>(input[0]);
    const auto tracks = static_cast<std::size_t>(input[1]);
    if (input[2] < 1 || input[2] > input[0] || input[3] < 1 || input[3] >= input[4] || input[4] > input[1]) return -1;
    const auto column = static_cast<std::size_t>(input[2]);
    const auto bottom = static_cast<std::size_t>(input[3]);
    const auto top = static_cast<std::size_t>(input[4]);
    if (length != 5 + columns + columns * (tracks + 2)) return -1;
    constexpr std::size_t vcv = 5;
    const auto plane = vcv + columns;
    for (std::size_t i = vcv; i < plane; ++i) if (input[i] != 0 && input[i] != 1) return -1;
    for (std::size_t i = plane; i < length; ++i) if (input[i] != 0 && input[i] != 1) return -1;

    if (bottom > 1 && column > 1 && try_dogleg(input, plane, vcv, columns, tracks, column, bottom, top, -1, true)) return 1;
    if (bottom > 1 && column < columns && try_dogleg(input, plane, vcv, columns, tracks, column, bottom, top, 1, true)) return 2;
    if (top < tracks && column > 1 && try_dogleg(input, plane, vcv, columns, tracks, column, bottom, top, -1, false)) return 3;
    if (top < tracks && column < columns && try_dogleg(input, plane, vcv, columns, tracks, column, bottom, top, 1, false)) return 4;
    return 0;
}
