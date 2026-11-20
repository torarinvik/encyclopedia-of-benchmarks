#include <array>
#include <cstddef>
#include <cstdint>

namespace {
void store_i64(uint8_t *out, size_t offset, int64_t value) {
    const uint64_t bits = static_cast<uint64_t>(value);
    for (size_t b = 0; b < 8; ++b) out[offset + b] = static_cast<uint8_t>(bits >> (8 * b));
}
}

extern "C" int64_t order_preserving_huffman_greedy_trace(
    const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == nullptr || length < 3 || length > 10) return -1;
    const int64_t raw_n = input[0];
    if (raw_n < 2 || raw_n > 8 || length != static_cast<size_t>(raw_n) + 1) return -1;
    const size_t n = static_cast<size_t>(raw_n);
    std::array<int64_t, 15> weight{};
    std::array<int, 15> left{}, right{};
    std::array<int, 8> active{};
    left.fill(-1); right.fill(-1);
    int64_t total = 0;
    for (size_t i = 0; i < n; ++i) {
        if (input[i + 1] < 1 || input[i + 1] > 15) return -1;
        weight[i] = input[i + 1]; total += weight[i]; active[i] = static_cast<int>(i);
    }
    if (total > 120) return -1;
    size_t count = n, next_node = n;
    while (count > 1) {
        size_t pair = 0;
        int64_t best = weight[static_cast<size_t>(active[0])] + weight[static_cast<size_t>(active[1])];
        for (size_t i = 1; i + 1 < count; ++i) {
            const int64_t candidate = weight[static_cast<size_t>(active[i])] + weight[static_cast<size_t>(active[i + 1])];
            if (candidate < best) { pair = i; best = candidate; }
        }
        const int a = active[pair], b = active[pair + 1];
        weight[next_node] = best; left[next_node] = a; right[next_node] = b;
        for (size_t i = pair; i + 2 < count; ++i) active[i] = active[i + 2];
        count -= 2;
        for (size_t i = count; i > pair; --i) active[i] = active[i - 1];
        active[pair] = static_cast<int>(next_node);
        ++count; ++next_node;
    }
    std::array<int, 8> depths{};
    std::array<int, 16> node_stack{}, depth_stack{};
    size_t top = 1; node_stack[0] = active[0]; depth_stack[0] = 0;
    while (top > 0) {
        --top;
        const int node = node_stack[top], depth = depth_stack[top];
        if (static_cast<size_t>(node) < n) depths[static_cast<size_t>(node)] = depth;
        else {
            node_stack[top] = left[static_cast<size_t>(node)]; depth_stack[top] = depth + 1; ++top;
            node_stack[top] = right[static_cast<size_t>(node)]; depth_stack[top] = depth + 1; ++top;
        }
    }
    std::array<int64_t, 10> words{};
    words[0] = raw_n;
    for (size_t i = 0; i < n; ++i) { words[1] += input[i + 1] * depths[i]; words[i + 2] = depths[i]; }
    const size_t needed = 8 * (n + 2);
    std::array<uint8_t, 80> staged{};
    for (size_t i = 0; i < n + 2; ++i) store_i64(staged.data(), 8 * i, words[i]);
    if (output == nullptr || capacity < needed) return -2;
    for (size_t i = 0; i < needed; ++i) output[i] = staged[i];
    return static_cast<int64_t>(needed);
}
