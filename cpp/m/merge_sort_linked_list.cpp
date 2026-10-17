#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_ITEMS = 128;

std::int32_t merge_nodes(const std::int32_t *values, std::int32_t *next,
                         std::int32_t left, std::int32_t right) {
    if (left < 0) return right;
    if (right < 0) return left;
    if (values[left] <= values[right]) {
        next[left] = merge_nodes(values, next, next[left], right);
        return left;
    }
    next[right] = merge_nodes(values, next, left, next[right]);
    return right;
}

std::int32_t merge_sort_nodes(const std::int32_t *values, std::int32_t *next,
                              std::int32_t head) {
    if (head < 0 || next[head] < 0) return head;
    std::int32_t slow = head, fast = next[head];
    while (fast >= 0 && next[fast] >= 0) {
        slow = next[slow];
        fast = next[next[fast]];
    }
    const auto right_head = next[slow];
    next[slow] = -1;
    const auto left = merge_sort_nodes(values, next, head);
    const auto right = merge_sort_nodes(values, next, right_head);
    return merge_nodes(values, next, left, right);
}

void put_i32_le(std::uint8_t *output, std::size_t offset, std::int32_t value) {
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}  // namespace

extern "C" std::int64_t merge_sort_linked_list(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || length < 1 || length > 1 + MAX_ITEMS) return -1;
    const auto count_value = input[0];
    if (count_value < 0 || count_value > static_cast<std::int64_t>(MAX_ITEMS)) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != 1 + count) return -1;
    std::int32_t values[MAX_ITEMS]{}, next[MAX_ITEMS]{};
    for (std::size_t i = 0; i < count; ++i) {
        if (input[1 + i] < INT32_MIN || input[1 + i] > INT32_MAX) return -1;
        values[i] = static_cast<std::int32_t>(input[1 + i]);
        for (std::size_t j = 0; j < i; ++j) if (values[j] == values[i]) return -1;
        next[i] = i + 1 < count ? static_cast<std::int32_t>(i + 1) : -1;
    }
    const auto head = merge_sort_nodes(values, next, count == 0 ? -1 : 0);
    const std::size_t required = 4 * count;
    if (output == nullptr || output_capacity < required) return -2;
    auto node = head;
    for (std::size_t i = 0; i < count; ++i) {
        put_i32_le(output, i * 4, values[node]);
        node = next[node];
    }
    return static_cast<std::int64_t>(required);
}
