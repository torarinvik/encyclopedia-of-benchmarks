#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t xor_filter_peeling(const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 3 || input[0] < 0 || input[0] > 32 || input[1] < 3 || input[1] > 96 || input[2] < 0 || input[2] > 32) return -1;
    const int n = static_cast<int>(input[0]), slots = static_cast<int>(input[1]), q = static_cast<int>(input[2]);
    if (length != static_cast<std::size_t>(3+4*(n+q))) return -1;
    for (int i = 0; i < n+q; ++i) {
        const auto* r = input+3+4*i;
        if (r[0] < 0 || r[0] >= slots || r[1] < 0 || r[1] >= slots || r[2] < 0 || r[2] >= slots || r[0] == r[1] || r[0] == r[2] || r[1] == r[2] || r[3] < 0 || r[3] > 255) return -1;
    }
    std::array<int, 96> degree{}, edge_xor{}, queue{}, table{};
    std::array<int, 32> stack_slot{}, stack_edge{};
    for (int edge = 0; edge < n; ++edge) for (int j = 0; j < 3; ++j) {
        const auto slot = static_cast<std::size_t>(input[3+4*edge+j]);
        ++degree[slot];
        edge_xor[slot] ^= edge;
    }
    int head = 0, tail = 0, used = 0;
    for (int slot = 0; slot < slots; ++slot) if (degree[slot] == 1) queue[tail++] = slot;
    while (head < tail) {
        const int slot = queue[head++];
        if (degree[slot] != 1) continue;
        const int edge = edge_xor[slot];
        stack_slot[used] = slot;
        stack_edge[used++] = edge;
        for (int j = 0; j < 3; ++j) {
            const auto v = static_cast<std::size_t>(input[3+4*edge+j]);
            --degree[v];
            edge_xor[v] ^= edge;
            if (degree[v] == 1) queue[tail++] = static_cast<int>(v);
        }
    }
    if (used != n) return -2;
    while (used > 0) {
        --used;
        const auto* r = input+3+4*stack_edge[used];
        table[stack_slot[used]] = static_cast<int>(r[3]) ^ table[r[0]] ^ table[r[1]] ^ table[r[2]];
    }
    std::int64_t result = 0;
    for (int i = 0; i < q; ++i) {
        const auto* r = input+3+4*(n+i);
        if ((table[r[0]] ^ table[r[1]] ^ table[r[2]]) == r[3]) result += i+1;
    }
    return result;
}
