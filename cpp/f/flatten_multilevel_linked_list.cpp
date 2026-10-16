// Recursively flatten sorted child chains by merging from the right.
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_lists = 8;
constexpr std::size_t max_chain_length = 8;
constexpr std::size_t max_total_values = max_lists * max_chain_length;
constexpr std::size_t max_input_length = 1 + max_lists * (1 + max_chain_length);

std::size_t merge_recursive(const std::int64_t *left, std::size_t left_length,
                            std::size_t left_index, const std::int64_t *right,
                            std::size_t right_length, std::size_t right_index,
                            std::int64_t *output, std::size_t output_index) {
    if (left_index == left_length) {
        const auto remaining = right_length - right_index;
        for (std::size_t i = 0; i < remaining; ++i) output[output_index + i] = right[right_index + i];
        return output_index + remaining;
    }
    if (right_index == right_length) {
        const auto remaining = left_length - left_index;
        for (std::size_t i = 0; i < remaining; ++i) output[output_index + i] = left[left_index + i];
        return output_index + remaining;
    }
    if (left[left_index] < right[right_index]) {
        output[output_index] = left[left_index];
        return merge_recursive(left, left_length, left_index + 1, right, right_length,
                               right_index, output, output_index + 1);
    }
    output[output_index] = right[right_index];
    return merge_recursive(left, left_length, left_index, right, right_length,
                           right_index + 1, output, output_index + 1);
}

std::size_t flatten_suffix(
    const std::array<std::array<std::int64_t, max_chain_length>, max_lists> &lists,
    const std::array<std::size_t, max_lists> &lengths, std::size_t count,
    std::size_t index, std::array<std::int64_t, max_total_values> &output) {
    if (index + 1 == count) {
        for (std::size_t i = 0; i < lengths[index]; ++i) output[i] = lists[index][i];
        return lengths[index];
    }
    std::array<std::int64_t, max_total_values> suffix{};
    const auto suffix_length = flatten_suffix(lists, lengths, count, index + 1, suffix);
    return merge_recursive(lists[index].data(), lengths[index], 0, suffix.data(),
                           suffix_length, 0, output.data(), 0);
}

void store_i64(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t flatten_multilevel_linked_list(
    const std::int64_t *values, std::size_t length, std::uint8_t *output,
    std::size_t output_capacity) noexcept {
    if (!values || length < 1 || length > max_input_length) return -1;
    if (values[0] < 0 || values[0] > static_cast<std::int64_t>(max_lists)) return -1;
    const auto count = static_cast<std::size_t>(values[0]);
    if (count == 0) return length == 1 ? 0 : -1;

    std::array<std::array<std::int64_t, max_chain_length>, max_lists> lists{};
    std::array<std::size_t, max_lists> lengths{};
    std::size_t total = 0, cursor = 1;
    for (std::size_t list = 0; list < count; ++list) {
        if (cursor >= length || values[cursor] < 1 ||
            values[cursor] > static_cast<std::int64_t>(max_chain_length)) return -1;
        const auto chain_length = static_cast<std::size_t>(values[cursor++]);
        if (chain_length > length - cursor) return -1;
        lengths[list] = chain_length;
        for (std::size_t item = 0; item < chain_length; ++item) {
            const auto value = values[cursor++];
            if (value < -1000 || value > 1000 ||
                (item > 0 && value < lists[list][item - 1])) return -1;
            lists[list][item] = value;
        }
        total += chain_length;
    }
    if (cursor != length) return -1;
    const auto required = total * 8;
    if (!output || output_capacity < required) return -2;

    std::array<std::int64_t, max_total_values> flattened{};
    flatten_suffix(lists, lengths, count, 0, flattened);
    for (std::size_t i = 0; i < total; ++i) store_i64(output, 8 * i, flattened[i]);
    return static_cast<std::int64_t>(total);
}
