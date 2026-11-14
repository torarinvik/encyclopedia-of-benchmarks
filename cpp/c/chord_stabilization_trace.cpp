#include <array>
#include <cstddef>
#include <cstdint>

namespace {
bool between(const std::array<int, 16>& ids, int ring, int left, int item, int right) noexcept {
    const int distance = (ids[item]-ids[left]+ring)%ring;
    const int span = (ids[right]-ids[left]+ring)%ring;
    return distance > 0 && (span == 0 || distance < span);
}
}
extern "C" std::int64_t chord_stabilization_trace(const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) noexcept {
    if (!input || length < 6 || length > 115 || input[0] < 1 || input[0] > 6 || input[1] < 1 || input[1] > 16 || input[2] < 0 || input[2] > 64) return -1;
    const int ring = 1 << input[0], n = static_cast<int>(input[1]), q = static_cast<int>(input[2]);
    if (n > ring || length != static_cast<std::size_t>(3+3*n+q)) return -1;
    std::array<int, 16> ids{}, succ{}, pred{};
    for (int i = 0; i < n; ++i) {
        if (input[3+i] < 0 || input[3+i] >= ring || (i > 0 && input[3+i] <= ids[i-1]) ||
            input[3+n+i] < 0 || input[3+n+i] >= n || input[3+2*n+i] < -1 || input[3+2*n+i] >= n) return -1;
        ids[i] = static_cast<int>(input[3+i]); succ[i] = static_cast<int>(input[3+n+i]); pred[i] = static_cast<int>(input[3+2*n+i]);
    }
    for (int i = 0; i < q; ++i) if (input[3+3*n+i] < 0 || input[3+3*n+i] >= n) return -1;
    for (int i = 0; i < q; ++i) {
        const int node = static_cast<int>(input[3+3*n+i]), candidate = pred[succ[node]];
        if (candidate >= 0 && between(ids, ring, node, candidate, succ[node])) succ[node] = candidate;
        const int receiver = succ[node];
        if (pred[receiver] < 0 || between(ids, ring, pred[receiver], node, receiver)) pred[receiver] = node;
    }
    if (!output || capacity < static_cast<std::size_t>(2*n)) return -2;
    for (int i = 0; i < n; ++i) { output[i] = static_cast<std::uint8_t>(succ[i]); output[n+i] = pred[i] < 0 ? 255 : static_cast<std::uint8_t>(pred[i]); }
    return 2*n;
}
