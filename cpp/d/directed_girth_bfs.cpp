#include <array>
#include <cstddef>
#include <cstdint>

extern "C" int64_t directed_girth_bfs(const int64_t* input, size_t length) {
    if (!input || length < 2 || length > 131) return -1;
    if (input[0] < 1 || input[0] > 16 || input[1] < 0 || input[1] > 64) return -1;
    const auto n = static_cast<size_t>(input[0]);
    const auto m = static_cast<size_t>(input[1]);
    if (length != 2 + 2*m) return -1;
    std::array<uint32_t, 16> outgoing{};
    for (size_t i = 0; i < m; ++i) {
        const auto u = input[2+2*i], v = input[3+2*i];
        if (u < 0 || v < 0 || u >= static_cast<int64_t>(n) || v >= static_cast<int64_t>(n)) return -1;
        outgoing[static_cast<size_t>(u)] |= uint32_t{1} << static_cast<unsigned>(v);
    }
    int best = 17;
    for (size_t start = 0; start < n; ++start) {
        std::array<int, 16> distance;
        distance.fill(-1);
        std::array<size_t, 16> queue{};
        size_t head = 0, tail = 1;
        distance[start] = 0; queue[0] = start;
        while (head < tail) {
            const auto u = queue[head++];
            for (size_t v = 0; v < n; ++v) {
                if (!(outgoing[u] & (uint32_t{1} << v))) continue;
                if (v == start) {
                    if (distance[u] + 1 < best) best = distance[u] + 1;
                } else if (distance[v] < 0) {
                    distance[v] = distance[u] + 1; queue[tail++] = v;
                }
            }
        }
    }
    return best == 17 ? 0 : best;
}
