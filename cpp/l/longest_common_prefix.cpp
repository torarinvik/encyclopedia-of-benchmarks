#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

static int compare_strings(const int64_t *input, size_t start_a, size_t len_a,
                           size_t start_b, size_t len_b) {
    const size_t limit = std::min(len_a, len_b);
    for (size_t i = 0; i < limit; ++i) {
        if (input[start_a + i] < input[start_b + i]) return -1;
        if (input[start_a + i] > input[start_b + i]) return 1;
    }
    return len_a < len_b ? -1 : len_a > len_b ? 1 : 0;
}

extern "C" int64_t longest_common_prefix(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == nullptr || length < 1 || length > 1041 || input[0] < 0 || input[0] > 16) return -1;
    const size_t count = static_cast<size_t>(input[0]);
    std::array<size_t, 16> starts{}, sizes{};
    size_t position = 1;
    for (size_t i = 0; i < count; ++i) {
        if (position >= length || input[position] < 0 || input[position] > 64) return -1;
        sizes[i] = static_cast<size_t>(input[position++]);
        if (sizes[i] > length - position) return -1;
        starts[i] = position;
        for (size_t j = 0; j < sizes[i]; ++j) if (input[position + j] < 0 || input[position + j] > 127) return -1;
        position += sizes[i];
    }
    if (position != length) return -1;
    if (count == 0) return 0;
    std::array<size_t, 16> order{};
    for (size_t i = 0; i < count; ++i) order[i] = i;
    for (size_t i = 1; i < count; ++i) {
        const size_t value = order[i]; size_t j = i;
        while (j > 0 && compare_strings(input, starts[order[j - 1]], sizes[order[j - 1]], starts[value], sizes[value]) > 0) {
            order[j] = order[j - 1]; --j;
        }
        order[j] = value;
    }
    const size_t first = order[0], last = order[count - 1];
    const size_t limit = std::min(sizes[first], sizes[last]);
    size_t prefix = 0;
    while (prefix < limit && input[starts[first] + prefix] == input[starts[last] + prefix]) ++prefix;
    if (capacity < prefix || (prefix != 0 && output == nullptr)) return -2;
    for (size_t i = 0; i < prefix; ++i) output[i] = static_cast<uint8_t>(input[starts[first] + i]);
    return static_cast<int64_t>(prefix);
}
