/* Bounded Java Integer SpreadSort semantics with signed-i32 output. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_LENGTH = 128;
constexpr std::size_t INSERTION_THRESHOLD = 16;
constexpr std::size_t MAX_BUCKETS = 8;
constexpr std::size_t BUCKET_STRIDE = 128;

void spread_sort_segment(std::int32_t *values, std::size_t length)
{
    if (length < 2) return;

    if (length <= INSERTION_THRESHOLD) {
        for (std::size_t index = 1; index < length; ++index) {
            const std::int32_t key = values[index];
            std::size_t position = index;
            while (position > 0 && values[position - 1] > key) {
                values[position] = values[position - 1];
                --position;
            }
            values[position] = key;
        }
        return;
    }

    std::int32_t minimum = values[0];
    std::int32_t maximum = values[0];
    for (std::size_t index = 1; index < length; ++index) {
        if (values[index] < minimum) minimum = values[index];
        if (values[index] > maximum) maximum = values[index];
    }
    if (minimum == maximum) return;

    std::size_t bucket_count = length / INSERTION_THRESHOLD;
    if (bucket_count < 2) bucket_count = 2;
    const std::size_t middle_bucket = bucket_count / 2;
    std::int32_t bucket_values[MAX_BUCKETS][BUCKET_STRIDE]{};
    std::size_t bucket_sizes[MAX_BUCKETS]{};

    for (std::size_t index = 0; index < length; ++index) {
        const std::size_t bucket = values[index] == minimum ? 0 : middle_bucket;
        bucket_values[bucket][bucket_sizes[bucket]++] = values[index];
    }

    std::size_t written = 0;
    for (std::size_t bucket = 0; bucket < bucket_count; ++bucket) {
        if (bucket_sizes[bucket] == 0) continue;
        spread_sort_segment(bucket_values[bucket], bucket_sizes[bucket]);
        for (std::size_t index = 0; index < bucket_sizes[bucket]; ++index)
            values[written++] = bucket_values[bucket][index];
    }
}
} // namespace

extern "C" std::int64_t spread_sort(const std::int64_t *input, std::size_t length,
                                    std::uint8_t *output, std::size_t capacity) noexcept
{
    if (input == nullptr || length > MAX_LENGTH) return -1;

    std::int32_t values[MAX_LENGTH];
    for (std::size_t index = 0; index < length; ++index) {
        if (input[index] < INT32_MIN || input[index] > INT32_MAX) return -1;
        values[index] = static_cast<std::int32_t>(input[index]);
    }
    if (length == 0) return 0;

    const std::size_t output_bytes = length * 4;
    if (output == nullptr || capacity < output_bytes) return -2;

    spread_sort_segment(values, length);
    for (std::size_t index = 0; index < length; ++index) {
        const std::uint32_t bits = static_cast<std::uint32_t>(values[index]);
        output[index * 4] = static_cast<std::uint8_t>(bits & 255);
        output[index * 4 + 1] = static_cast<std::uint8_t>((bits >> 8) & 255);
        output[index * 4 + 2] = static_cast<std::uint8_t>((bits >> 16) & 255);
        output[index * 4 + 3] = static_cast<std::uint8_t>((bits >> 24) & 255);
    }
    return static_cast<std::int64_t>(output_bytes);
}
