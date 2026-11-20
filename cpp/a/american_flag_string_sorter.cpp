#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_strings = 256;
constexpr std::size_t max_string_length = 32;
constexpr std::size_t bucket_count = 257;
constexpr std::size_t max_parseable_length = 8450;

std::size_t key_at(const std::int64_t *input, const std::size_t *offsets,
                   const std::size_t *string_lengths,
                   std::size_t string_index, std::size_t depth) noexcept {
    if (depth >= string_lengths[string_index]) return 0;
    return static_cast<std::size_t>(input[offsets[string_index] + depth]) + 1;
}

void sort_indices(const std::int64_t *input, const std::size_t *offsets,
                  const std::size_t *string_lengths, std::size_t *order,
                  std::size_t low, std::size_t high,
                  std::size_t depth) noexcept {
    if (high - low < 2) return;

    std::size_t counts[bucket_count]{};
    std::size_t starts[bucket_count];
    std::size_t next[bucket_count];
    for (std::size_t index = low; index < high; ++index) {
        ++counts[key_at(input, offsets, string_lengths, order[index], depth)];
    }

    std::size_t position = low;
    for (std::size_t bucket = 0; bucket < bucket_count; ++bucket) {
        starts[bucket] = position;
        next[bucket] = position;
        position += counts[bucket];
    }

    for (std::size_t bucket = 0; bucket < bucket_count; ++bucket) {
        const std::size_t end = starts[bucket] + counts[bucket];
        while (next[bucket] < end) {
            const std::size_t current = next[bucket];
            const std::size_t target_bucket =
                key_at(input, offsets, string_lengths, order[current], depth);
            if (target_bucket == bucket) {
                ++next[bucket];
            } else {
                const std::size_t target = next[target_bucket];
                const std::size_t temporary = order[target];
                order[target] = order[current];
                order[current] = temporary;
                ++next[target_bucket];
            }
        }
    }

    for (std::size_t bucket = 1; bucket < bucket_count; ++bucket) {
        if (counts[bucket] > 1) {
            sort_indices(input, offsets, string_lengths, order, starts[bucket],
                         starts[bucket] + counts[bucket], depth + 1);
        }
    }
}
} // namespace

extern "C" std::int64_t american_flag_string_sorter(
    const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > max_parseable_length) {
        return -1;
    }

    const std::int64_t count_value = input[0];
    if (count_value < 0 || count_value > static_cast<std::int64_t>(max_strings)) {
        return -1;
    }
    const auto count = static_cast<std::size_t>(count_value);

    std::size_t offsets[max_strings];
    std::size_t string_lengths[max_strings];
    std::size_t order[max_strings];
    std::size_t position = 1;
    for (std::size_t index = 0; index < count; ++index) {
        if (position >= length) return -1;
        const std::int64_t string_length_value = input[position++];
        if (string_length_value < 0
            || string_length_value > static_cast<std::int64_t>(max_string_length)) {
            return -1;
        }
        const auto string_length = static_cast<std::size_t>(string_length_value);
        if (string_length > length - position) return -1;

        offsets[index] = position;
        string_lengths[index] = string_length;
        order[index] = index;
        for (std::size_t byte = 0; byte < string_length; ++byte) {
            if (input[position + byte] < 0 || input[position + byte] > 255) {
                return -1;
            }
        }
        position += string_length;
    }
    if (position != length) return -1;

    if (count > 1) {
        sort_indices(input, offsets, string_lengths, order, 0, count, 0);
    }

    std::int64_t checksum = 0;
    for (std::size_t rank = 0; rank < count; ++rank) {
        const std::size_t string_index = order[rank];
        std::int64_t contribution =
            static_cast<std::int64_t>(string_lengths[string_index]) + 1;
        for (std::size_t byte = 0; byte < string_lengths[string_index]; ++byte) {
            contribution += input[offsets[string_index] + byte] + 1;
        }
        checksum += static_cast<std::int64_t>(rank + 1) * contribution;
    }
    return checksum;
}
