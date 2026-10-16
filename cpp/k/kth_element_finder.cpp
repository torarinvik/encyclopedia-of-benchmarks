#include <array>
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::int64_t invalid_result = std::numeric_limits<std::int64_t>::min();

void sift_down(std::array<std::int64_t, 256> &heap, std::size_t heap_size,
               std::size_t root, bool min_heap) {
    for (;;) {
        std::size_t best = root;
        const std::size_t left = root * 2 + 1;
        const std::size_t right = left + 1;
        if (left < heap_size && (min_heap ? heap[left] < heap[best] : heap[left] > heap[best])) best = left;
        if (right < heap_size && (min_heap ? heap[right] < heap[best] : heap[right] > heap[best])) best = right;
        if (best == root) return;
        const auto temporary = heap[root];
        heap[root] = heap[best];
        heap[best] = temporary;
        root = best;
    }
}
}  // namespace

extern "C" std::int64_t kth_element_finder(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 4 || length > 259) return invalid_result;
    const auto mode = input[0];
    const auto n_value = input[1];
    const auto k_value = input[2];
    if ((mode != 0 && mode != 1) || n_value < 1 || n_value > 256 ||
        k_value < 1 || k_value > n_value || length != static_cast<std::size_t>(n_value) + 3) {
        return invalid_result;
    }
    const auto n = static_cast<std::size_t>(n_value);
    const auto k = static_cast<std::size_t>(k_value);
    for (std::size_t i = 0; i < n; ++i) {
        if (input[i + 3] < -1000000 || input[i + 3] > 1000000) return invalid_result;
    }

    const bool min_heap = mode == 0;
    std::array<std::int64_t, 256> heap{};
    for (std::size_t i = 0; i < k; ++i) heap[i] = input[i + 3];
    for (std::size_t i = k / 2; i > 0; --i) sift_down(heap, k, i - 1, min_heap);
    for (std::size_t i = k; i < n; ++i) {
        const auto value = input[i + 3];
        if ((min_heap && value > heap[0]) || (!min_heap && value < heap[0])) {
            heap[0] = value;
            sift_down(heap, k, 0, min_heap);
        }
    }
    return heap[0];
}
