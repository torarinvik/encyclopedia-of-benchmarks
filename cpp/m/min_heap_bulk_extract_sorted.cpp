#include <cstddef>
#include <cstdint>

namespace {
void sift_down(std::int64_t* heap, std::size_t count, std::size_t index) noexcept {
    for (;;) {
        std::size_t smallest = index;
        const std::size_t left = index * 2 + 1, right = left + 1;
        if (left < count && heap[left] < heap[smallest]) smallest = left;
        if (right < count && heap[right] < heap[smallest]) smallest = right;
        if (smallest == index) return;
        const auto temporary = heap[index]; heap[index] = heap[smallest]; heap[smallest] = temporary;
        index = smallest;
    }
}
void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) { output[offset + byte] = static_cast<std::uint8_t>(bits & 255); bits >>= 8; }
}
}
extern "C" std::int64_t min_heap_bulk_extract_sorted(const std::int64_t* values, std::size_t length,
                                                std::uint8_t* output, std::size_t capacity) noexcept {
    if (values == nullptr || length < 2 || length > 4096) return -1;
    const auto raw_count = values[0];
    if (raw_count < 1 || raw_count > 4095 || length != static_cast<std::size_t>(raw_count) + 1) return -1;
    auto count = static_cast<std::size_t>(raw_count);
    std::int64_t heap[4095];
    for (std::size_t index = 0; index < count; ++index) {
        const auto value = values[index + 1];
        if (value < -2147483648LL || value > 2147483647LL) return -1;
        auto position = index;
        heap[position] = value;
        while (position > 0) {
            const auto parent = (position - 1) / 2;
            if (heap[parent] <= heap[position]) break;
            const auto temporary = heap[parent]; heap[parent] = heap[position]; heap[position] = temporary;
            position = parent;
        }
    }
    const auto output_bytes = 8 * count;
    if (output == nullptr || capacity < output_bytes) return -2;
    auto remaining = count;
    for (std::size_t index = 0; index < count; ++index) {
        const auto minimum = heap[0];
        store_i64_le(output, 8 * index, minimum);
        --remaining;
        if (remaining > 0) { heap[0] = heap[remaining]; sift_down(heap, remaining, 0); }
    }
    return static_cast<std::int64_t>(output_bytes);
}
