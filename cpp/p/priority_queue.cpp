#include <array>
#include <cstddef>
#include <cstdint>
#include <climits>
#include <utility>

namespace {
constexpr std::size_t max_ops = 64, max_input = 130, max_output = 4 * max_ops;
}

extern "C" std::int64_t priority_queue(const std::int64_t* input, std::size_t input_length,
                                        std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || input_length == 0 || input_length > max_input || input[0] < 0 || input[0] > static_cast<std::int64_t>(max_ops)) return -1;
    const auto op_count = static_cast<std::size_t>(input[0]);
    std::array<std::int32_t, max_ops> heap{}, seen{};
    std::array<std::uint8_t, max_output> staged{};
    std::size_t heap_size = 0, seen_count = 0, offset = 1, output_size = 0;
    for (std::size_t k = 0; k < op_count; ++k) {
        if (offset >= input_length) return -1;
        const auto op = input[offset++];
        if (op == 0) {
            if (offset >= input_length) return -1;
            const auto raw = input[offset++];
            if (raw < INT32_MIN || raw > INT32_MAX) return -1;
            const auto value = static_cast<std::int32_t>(raw);
            for (std::size_t i = 0; i < seen_count; ++i) if (seen[i] == value) return -1;
            seen[seen_count++] = value;
            std::size_t i = heap_size++;
            heap[i] = value;
            while (i != 0) {
                const std::size_t p = (i - 1) / 2;
                if (heap[p] <= heap[i]) break;
                std::swap(heap[p], heap[i]); i = p;
            }
        } else if (op == 1 || op == 2) {
            if (heap_size == 0) return -1;
            const auto bits = static_cast<std::uint32_t>(heap[0]);
            staged[output_size++] = static_cast<std::uint8_t>(bits);
            staged[output_size++] = static_cast<std::uint8_t>(bits >> 8);
            staged[output_size++] = static_cast<std::uint8_t>(bits >> 16);
            staged[output_size++] = static_cast<std::uint8_t>(bits >> 24);
            if (op == 2) {
                heap[0] = heap[--heap_size];
                std::size_t i = 0;
                while (i < heap_size) {
                    std::size_t child = 2 * i + 1;
                    if (child >= heap_size) break;
                    if (child + 1 < heap_size && heap[child + 1] < heap[child]) ++child;
                    if (heap[i] <= heap[child]) break;
                    std::swap(heap[i], heap[child]); i = child;
                }
            }
        } else return -1;
    }
    if (offset != input_length) return -1;
    if (output == nullptr || capacity < output_size) return -2;
    for (std::size_t i = 0; i < output_size; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(output_size);
}
