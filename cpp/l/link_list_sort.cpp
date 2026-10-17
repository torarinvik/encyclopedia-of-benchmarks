#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_ITEMS = 128;

void merge_sort(std::int32_t *items, std::int32_t *scratch, std::size_t count) {
    for (std::size_t width = 1; width < count; width *= 2) {
        for (std::size_t start = 0; start < count;) {
            const std::size_t middle = start + (width < count - start ? width : count - start);
            const std::size_t end = middle + (width < count - middle ? width : count - middle);
            std::size_t left = start, right = middle, out = start;
            while (left < middle && right < end)
                scratch[out++] = items[left] <= items[right] ? items[left++] : items[right++];
            while (left < middle) scratch[out++] = items[left++];
            while (right < end) scratch[out++] = items[right++];
            start = end;
        }
        for (std::size_t i = 0; i < count; ++i) items[i] = scratch[i];
    }
}

void insertion_sort(std::int32_t *items, std::size_t count) {
    for (std::size_t i = 1; i < count; ++i) {
        const std::int32_t value = items[i];
        std::size_t j = i;
        while (j > 0 && items[j - 1] > value) { items[j] = items[j - 1]; --j; }
        items[j] = value;
    }
}

void sift_down(std::int32_t *items, std::size_t count, std::size_t root) {
    while (root < count / 2) {
        std::size_t child = 2 * root + 1;
        if (child + 1 < count && items[child + 1] > items[child]) ++child;
        if (items[root] >= items[child]) return;
        const auto value = items[root]; items[root] = items[child]; items[child] = value;
        root = child;
    }
}

void heap_sort(std::int32_t *items, std::size_t count) {
    for (std::size_t start = count / 2; start > 0;) { --start; sift_down(items, count, start); }
    for (std::size_t end = count; end > 1;) {
        --end; const auto value = items[0]; items[0] = items[end]; items[end] = value;
        sift_down(items, end, 0);
    }
}
}  // namespace

extern "C" std::int64_t link_list_sort(const std::int64_t *input, std::size_t length,
                                        std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || length < 2 || length > 2 + MAX_ITEMS) return -1;
    const auto selector = input[0], count_value = input[1];
    if (selector < 1 || selector > 3 || count_value < 0 || count_value > static_cast<std::int64_t>(MAX_ITEMS)) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != 2 + count) return -1;
    std::int32_t items[MAX_ITEMS]{}, scratch[MAX_ITEMS]{};
    for (std::size_t i = 0; i < count; ++i) {
        if (input[2 + i] < INT32_MIN || input[2 + i] > INT32_MAX) return -1;
        items[i] = static_cast<std::int32_t>(input[2 + i]);
    }
    if (selector == 1) merge_sort(items, scratch, count);
    else if (selector == 2) insertion_sort(items, count);
    else heap_sort(items, count);
    const std::size_t required = 4 * count;
    if (output == nullptr || output_capacity < required) return -2;
    for (std::size_t i = 0; i < count; ++i) {
        const auto bits = static_cast<std::uint32_t>(items[i]);
        for (std::size_t byte = 0; byte < 4; ++byte)
            output[4 * i + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
    }
    return static_cast<std::int64_t>(required);
}
