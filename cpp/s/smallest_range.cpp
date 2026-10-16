#include <cstddef>
#include <cstdint>

namespace {
bool less_head(const std::int64_t values[16][16], const std::size_t positions[16], std::size_t a, std::size_t b) {
    const auto left = values[a][positions[a]], right = values[b][positions[b]];
    return left < right || (left == right && a < b);
}
void sift_down(std::size_t heap[16], std::size_t size, std::size_t root,
               const std::int64_t values[16][16], const std::size_t positions[16]) {
    for (;;) {
        std::size_t child = root * 2 + 1;
        if (child >= size) return;
        if (child + 1 < size && less_head(values, positions, heap[child + 1], heap[child])) ++child;
        if (!less_head(values, positions, heap[child], heap[root])) return;
        const auto swap = heap[root]; heap[root] = heap[child]; heap[child] = swap;
        root = child;
    }
}
}

extern "C" std::int64_t smallest_range(const std::int64_t *packed, std::size_t length) noexcept {
    if (packed == nullptr || length < 2 || length > 273) return -1;
    if (packed[0] < 1 || packed[0] > 16) return -1;
    const auto count = static_cast<std::size_t>(packed[0]);
    std::int64_t values[16][16]{};
    std::size_t lengths[16]{}, positions[16]{}, heap[16]{};
    std::size_t offset = 1, total = 0;
    std::int64_t current_max = -1000000001;
    for (std::size_t i = 0; i < count; ++i) {
        if (offset >= length || packed[offset] < 1 || packed[offset] > 16) return -1;
        lengths[i] = static_cast<std::size_t>(packed[offset++]);
        if (lengths[i] > 256 - total || offset + lengths[i] > length) return -1;
        total += lengths[i];
        for (std::size_t j = 0; j < lengths[i]; ++j) {
            const auto value = packed[offset++];
            if (value < -1000000000 || value > 1000000000 || (j && value < values[i][j - 1])) return -1;
            values[i][j] = value;
        }
        heap[i] = i;
        if (values[i][0] > current_max) current_max = values[i][0];
    }
    if (offset != length) return -1;
    std::size_t heap_size = count;
    for (std::size_t i = heap_size / 2; i > 0; --i) sift_down(heap, heap_size, i - 1, values, positions);
    std::int64_t best_lo = 0, best_hi = 0, best_width = INT64_MAX;
    for (;;) {
        const auto list = heap[0];
        const auto lo = values[list][positions[list]], width = current_max - lo;
        if (width < best_width) { best_width = width; best_lo = lo; best_hi = current_max; }
        if (++positions[list] == lengths[list]) break;
        if (values[list][positions[list]] > current_max) current_max = values[list][positions[list]];
        sift_down(heap, heap_size, 0, values, positions);
    }
    return (best_lo + 1000000000) * INT64_C(2000000001) + (best_hi + 1000000000);
}
