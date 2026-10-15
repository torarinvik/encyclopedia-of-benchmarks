#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxNodes = 256;
struct SearchNode {
    std::int32_t x, y, g, f, parent;
};
void write_i64(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (unsigned shift = 0; shift < 64; shift += 8) output[offset++] = static_cast<std::uint8_t>(bits >> shift);
}
}

extern "C" std::int64_t astar(const std::int64_t *input, std::size_t length,
                              std::uint8_t *output, std::size_t capacity) {
    constexpr std::int32_t dx[8] = {-1, -1, -1, 0, 0, 1, 1, 1};
    constexpr std::int32_t dy[8] = {-1, 0, 1, -1, 1, -1, 0, 1};
    if (input == nullptr || length != 6) return -1;
    const auto rows64 = input[0], cols64 = input[1];
    const auto sx64 = input[2], sy64 = input[3], gx64 = input[4], gy64 = input[5];
    if (rows64 < 1 || rows64 > 16 || cols64 < 1 || cols64 > 16 ||
        sx64 < 0 || sx64 >= rows64 || sy64 < 0 || sy64 >= cols64 ||
        gx64 < 0 || gx64 >= rows64 || gy64 < 0 || gy64 >= cols64) return -1;
    const auto rows = static_cast<std::int32_t>(rows64), cols = static_cast<std::int32_t>(cols64);
    const auto sx = static_cast<std::int32_t>(sx64), sy = static_cast<std::int32_t>(sy64);
    const auto gx = static_cast<std::int32_t>(gx64), gy = static_cast<std::int32_t>(gy64);
    SearchNode nodes[kMaxNodes];
    std::int32_t open[kMaxNodes];
    std::size_t node_count = 1, open_count = 1;
    nodes[0] = {sx, sy, 0, 0, -1};
    open[0] = 0;
    std::int32_t current = 0;
    bool found = false;
    while (open_count > 0) {
        std::size_t best = 0;
        for (std::size_t i = 1; i < open_count; ++i)
            if (nodes[open[i]].f < nodes[open[best]].f) best = i;
        current = open[best];
        for (std::size_t i = best + 1; i < open_count; ++i) open[i - 1] = open[i];
        --open_count;
        if (nodes[current].x == gx && nodes[current].y == gy) { found = true; break; }
        for (std::size_t neighbor = 0; neighbor < 8; ++neighbor) {
            const auto x = nodes[current].x + dx[neighbor];
            const auto y = nodes[current].y + dy[neighbor];
            if (x < 0 || x >= rows || y < 0 || y >= cols) continue;
            if (node_count >= kMaxNodes || open_count >= kMaxNodes) return -1;
            const auto g = nodes[current].g + 1;
            const auto ex = gx - x, ey = gy - y;
            nodes[node_count] = {x, y, g, g + ex * ex + ey * ey, current};
            open[open_count++] = static_cast<std::int32_t>(node_count++);
        }
    }
    if (!found) return -1;
    std::size_t path_count = 0;
    for (auto cursor = current; cursor >= 0; cursor = nodes[cursor].parent) ++path_count;
    const std::size_t output_bytes = path_count * 16;
    if (output == nullptr || capacity < output_bytes) return -2;
    std::size_t offset = output_bytes;
    for (auto cursor = current; cursor >= 0; cursor = nodes[cursor].parent) {
        offset -= 16;
        write_i64(output, offset, nodes[cursor].x);
        write_i64(output, offset + 8, nodes[cursor].y);
    }
    return static_cast<std::int64_t>(output_bytes);
}
