#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text_length = 64;
constexpr std::size_t max_input_length = 65;

bool pair_less(std::size_t left, std::size_t right, const std::int64_t* rank,
               std::size_t length, std::size_t step)
{
    if (rank[left] != rank[right]) return rank[left] < rank[right];
    const auto left_second = left + step < length ? rank[left + step] : -1;
    const auto right_second = right + step < length ? rank[right + step] : -1;
    return left_second < right_second;
}
}

extern "C" std::int64_t suffix_array(const std::int64_t* values, std::size_t length,
                                     std::uint8_t* output, std::size_t capacity)
{
    if (values == nullptr || length < 1 || length > max_input_length) return -1;
    const auto count_value = values[0];
    if (count_value < 0 || count_value > static_cast<std::int64_t>(max_text_length)) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != 1 + count) return -1;
    for (std::size_t i = 0; i < count; ++i)
        if (values[1 + i] < 0 || values[1 + i] > 127) return -1;

    const auto output_bytes = count * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    if (count == 0) return 0;

    std::size_t suffixes[max_text_length];
    std::int64_t rank[max_text_length], next_rank[max_text_length];
    for (std::size_t i = 0; i < count; ++i) {
        suffixes[i] = i;
        rank[i] = values[1 + i];
    }

    for (std::size_t step = 1; step < count; step *= 2) {
        for (std::size_t i = 1; i < count; ++i) {
            const auto key = suffixes[i];
            auto position = i;
            while (position > 0 && pair_less(key, suffixes[position - 1], rank, count, step)) {
                suffixes[position] = suffixes[position - 1];
                --position;
            }
            suffixes[position] = key;
        }
        next_rank[suffixes[0]] = 0;
        for (std::size_t i = 1; i < count; ++i) {
            const auto previous = suffixes[i - 1];
            const auto current = suffixes[i];
            const auto previous_second = previous + step < count ? rank[previous + step] : -1;
            const auto current_second = current + step < count ? rank[current + step] : -1;
            next_rank[current] = next_rank[previous] +
                ((rank[previous] == rank[current] && previous_second == current_second) ? 0 : 1);
        }
        for (std::size_t i = 0; i < count; ++i) rank[i] = next_rank[i];
        if (rank[suffixes[count - 1]] == static_cast<std::int64_t>(count - 1)) break;
    }

    for (std::size_t i = 0; i < count; ++i) {
        const auto bits = static_cast<std::uint64_t>(suffixes[i]);
        for (std::size_t byte = 0; byte < 8; ++byte)
            output[i * 8 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
    }
    return static_cast<std::int64_t>(output_bytes);
}
