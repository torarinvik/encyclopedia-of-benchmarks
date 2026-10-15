#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t max_operations = 512, max_insertions = 256;
void store_i64_le(std::uint8_t* out, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t i = 0; i < 8; ++i) out[offset + i] = static_cast<std::uint8_t>(bits >> (8 * i));
}
}
extern "C" std::int64_t max_heap(const std::int64_t* input, std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (!input || length < 1 || input[0] < 0 || input[0] > static_cast<std::int64_t>(max_operations)) return -1;
    const auto operations = static_cast<std::size_t>(input[0]);
    if (length != 1 + operations * 2) return -1;
    std::size_t inserts = 0, words = 0;
    for (std::size_t i = 0; i < operations; ++i) {
        const auto op = input[1 + 2 * i], value = input[2 + 2 * i];
        if (op < 0 || op > 2) return -1;
        if (op == 0) { if (++inserts > max_insertions || value < INT32_MIN || value > INT32_MAX) return -1; }
        else { if (value != 0) return -1; ++words; }
    }
    if (capacity < words * 8 || (words && !output)) return -2;
    std::int64_t heap[max_insertions]; std::size_t size = 0, out = 0;
    for (std::size_t i = 0; i < operations; ++i) {
        const auto op = input[1 + 2 * i], value = input[2 + 2 * i];
        if (op == 0) { std::size_t at = size++; heap[at] = value;
            while (at) { const auto parent = (at - 1) / 2; if (heap[parent] >= heap[at]) break;
                auto t = heap[parent]; heap[parent] = heap[at]; heap[at] = t; at = parent; } continue; }
        auto result = std::numeric_limits<std::int64_t>::min();
        if (size) { result = heap[0]; if (op == 2) { heap[0] = heap[--size]; std::size_t at = 0;
            while (at < size / 2) { auto child = at * 2 + 1; if (child + 1 < size && heap[child + 1] > heap[child]) ++child;
                if (heap[at] >= heap[child]) break; auto t = heap[at]; heap[at] = heap[child]; heap[child] = t; at = child; } } }
        store_i64_le(output, out++ * 8, result);
    }
    return static_cast<std::int64_t>(words);
}
