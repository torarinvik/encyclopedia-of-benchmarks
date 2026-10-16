#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_set_size = 64;
constexpr std::size_t max_result_size = 2 * max_set_size;
constexpr std::size_t max_input_length = 4 + 2 * max_set_size;

bool contains(const std::int64_t *values, std::size_t count, std::int64_t value) {
    for (std::size_t i = 0; i < count; ++i) if (values[i] == value) return true;
    return false;
}
bool is_subset(const std::int64_t *left, std::size_t left_count, const std::int64_t *right, std::size_t right_count) {
    if (left_count > right_count) return false;
    for (std::size_t i = 0; i < left_count; ++i) if (!contains(right, right_count, left[i])) return false;
    return true;
}
void put_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t set_algebra(const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 4 || length > max_input_length) return -1;
    const auto operation = input[0], left_raw = input[1], right_raw = input[2], query_key = input[3];
    if (operation < 0 || operation > 8 || left_raw < 0 || left_raw > 64 || right_raw < 0 || right_raw > 64 || query_key < -1000000 || query_key > 1000000) return -1;
    const auto left_length = static_cast<std::size_t>(left_raw), right_length = static_cast<std::size_t>(right_raw);
    if (length != 4 + left_length + right_length) return -1;

    std::int64_t left[max_set_size], right[max_set_size], result[max_result_size];
    std::size_t left_count = 0, right_count = 0, result_count = 0;
    for (std::size_t i = 0; i < left_length; ++i) {
        const auto value = input[4 + i];
        if (value < -1000000 || value > 1000000) return -1;
        if (!contains(left, left_count, value)) left[left_count++] = value;
    }
    for (std::size_t i = 0; i < right_length; ++i) {
        const auto value = input[4 + left_length + i];
        if (value < -1000000 || value > 1000000) return -1;
        if (!contains(right, right_count, value)) right[right_count++] = value;
    }

    if (operation == 0) { result[0] = contains(left, left_count, query_key) ? 1 : 0; result_count = 1; }
    else if (operation == 1) { result[0] = is_subset(left, left_count, right, right_count) ? 1 : 0; result_count = 1; }
    else if (operation == 2) { result[0] = left_count < right_count && is_subset(left, left_count, right, right_count) ? 1 : 0; result_count = 1; }
    else if (operation == 3) { result[0] = is_subset(right, right_count, left, left_count) ? 1 : 0; result_count = 1; }
    else if (operation == 4) { result[0] = right_count < left_count && is_subset(right, right_count, left, left_count) ? 1 : 0; result_count = 1; }
    else if (operation == 5) {
        for (std::size_t i = 0; i < left_count; ++i) result[result_count++] = left[i];
        for (std::size_t i = 0; i < right_count; ++i) if (!contains(left, left_count, right[i])) result[result_count++] = right[i];
    } else if (operation == 6) {
        for (std::size_t i = 0; i < left_count; ++i) if (contains(right, right_count, left[i])) result[result_count++] = left[i];
    } else if (operation == 7) {
        for (std::size_t i = 0; i < left_count; ++i) if (!contains(right, right_count, left[i])) result[result_count++] = left[i];
    } else {
        for (std::size_t i = 0; i < left_count; ++i) if (!contains(right, right_count, left[i])) result[result_count++] = left[i];
        for (std::size_t i = 0; i < right_count; ++i) if (!contains(left, left_count, right[i])) result[result_count++] = right[i];
    }
    for (std::size_t i = 1; i < result_count; ++i) {
        const auto value = result[i];
        std::size_t j = i;
        while (j > 0 && result[j - 1] > value) { result[j] = result[j - 1]; --j; }
        result[j] = value;
    }

    const std::size_t output_bytes = result_count * 8;
    if (capacity < output_bytes || (output_bytes > 0 && output == nullptr)) return -2;
    for (std::size_t i = 0; i < result_count; ++i) put_i64_le(output, i * 8, result[i]);
    return static_cast<std::int64_t>(output_bytes);
}
