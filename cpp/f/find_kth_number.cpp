#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t invalid_result = INT64_MIN;
constexpr std::size_t max_values = 1024;
}

extern "C" std::int64_t find_kth_number(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 2 || length > max_values + 1) return invalid_result;
    const std::int64_t k = values[0];
    const std::size_t count = length - 1;
    if (k < 1 || k > static_cast<std::int64_t>(count)) return invalid_result;
    std::int32_t heap[max_values];
    for (std::size_t i = 0; i < count; ++i) {
        const std::int64_t input = values[i + 1];
        if (input < INT32_MIN || input > INT32_MAX) return invalid_result;
        std::size_t index = i;
        heap[index] = static_cast<std::int32_t>(input);
        while (index > 0) {
            const std::size_t parent = (index - 1) / 2;
            if (heap[parent] >= heap[index]) break;
            const auto temp = heap[parent]; heap[parent] = heap[index]; heap[index] = temp;
            index = parent;
        }
    }
    std::size_t heap_size = count;
    for (std::int64_t removed = 1; removed < k; ++removed) {
        --heap_size;
        heap[0] = heap[heap_size];
        std::size_t index = 0;
        while (index * 2 + 1 < heap_size) {
            std::size_t child = index * 2 + 1;
            if (child + 1 < heap_size && heap[child + 1] > heap[child]) ++child;
            if (heap[index] >= heap[child]) break;
            const auto temp = heap[index]; heap[index] = heap[child]; heap[child] = temp;
            index = child;
        }
    }
    return heap[0];
}
