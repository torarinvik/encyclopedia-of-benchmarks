#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t min_lists = 2;
constexpr std::size_t max_lists = 8;
constexpr std::size_t max_list_length = 32;
constexpr std::size_t max_input_length = max_lists * (max_list_length + 1) + 2;
constexpr std::size_t bytes_per_value = 4;

void store_i32_le(std::uint8_t *output, std::size_t position, std::int32_t value) noexcept {
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < bytes_per_value; ++byte)
        output[position + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t inverted_list_svs_binary_search(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < min_lists + 1 || length > max_input_length) return -1;
    if (input[0] < static_cast<std::int64_t>(min_lists) || input[0] > static_cast<std::int64_t>(max_lists)) return -1;
    const auto count = static_cast<std::size_t>(input[0]);
    std::size_t starts[max_lists], sizes[max_lists], order[max_lists];
    std::size_t position = 1;
    for (std::size_t list = 0; list < count; ++list) {
        if (position >= length || input[position] < 0 || input[position] > static_cast<std::int64_t>(max_list_length)) return -1;
        const auto size = static_cast<std::size_t>(input[position++]);
        if (size > length - position) return -1;
        starts[list] = position; sizes[list] = size; order[list] = list;
        for (std::size_t i = 0; i < size; ++i) {
            const auto value = input[position + i];
            if (value < std::numeric_limits<std::int32_t>::min() || value > std::numeric_limits<std::int32_t>::max()) return -1;
            if (i > 0 && input[position + i - 1] >= value) return -1;
        }
        position += size;
    }
    if (position != length) return -1;
    for (std::size_t i = 1; i < count; ++i) {
        const auto key = order[i];
        auto j = i;
        while (j > 0 && sizes[order[j - 1]] > sizes[key]) { order[j] = order[j - 1]; --j; }
        order[j] = key;
    }
    const auto maximum_result = sizes[order[0]];
    if (output_capacity < maximum_result * bytes_per_value || (maximum_result != 0 && output == nullptr)) return -2;

    std::int32_t candidates[max_list_length];
    auto candidate_count = sizes[order[0]];
    for (std::size_t i = 0; i < candidate_count; ++i)
        candidates[i] = static_cast<std::int32_t>(input[starts[order[0]] + i]);
    for (std::size_t rank = 1; rank < count && candidate_count != 0; ++rank) {
        const auto list = order[rank], start = starts[list], size = sizes[list];
        std::size_t cursor = 0, kept = 0;
        for (std::size_t i = 0; i < candidate_count; ++i) {
            const auto candidate = candidates[i];
            auto low = cursor, high = size;
            while (low < high) {
                const auto middle = low + (high - low) / 2;
                if (input[start + middle] < candidate) low = middle + 1;
                else high = middle;
            }
            if (low < size && input[start + low] == candidate) { candidates[kept++] = candidate; cursor = low + 1; }
            else cursor = low;
        }
        candidate_count = kept;
    }
    for (std::size_t i = 0; i < candidate_count; ++i) store_i32_le(output, i * bytes_per_value, candidates[i]);
    return static_cast<std::int64_t>(candidate_count);
}
