#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_count = 64;
constexpr std::size_t max_input_length = 66;
void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
void push_max(std::int64_t* heap, std::size_t& count, std::int64_t value) {
    std::size_t position = count++;
    while (position > 0 && heap[(position - 1) / 2] < value) { const auto parent = (position - 1) / 2; heap[position] = heap[parent]; position = parent; }
    heap[position] = value;
}
std::int64_t pop_max(std::int64_t* heap, std::size_t& count) {
    const auto result = heap[0], value = heap[--count]; if (count == 0) return result;
    std::size_t position = 0;
    while (2 * position + 1 < count) { std::size_t child = 2 * position + 1; if (child + 1 < count && heap[child + 1] > heap[child]) ++child; if (heap[child] <= value) break; heap[position] = heap[child]; position = child; }
    heap[position] = value; return result;
}
void push_min(std::int64_t* heap, std::size_t& count, std::int64_t value) {
    std::size_t position = count++;
    while (position > 0 && heap[(position - 1) / 2] > value) { const auto parent = (position - 1) / 2; heap[position] = heap[parent]; position = parent; }
    heap[position] = value;
}
std::int64_t pop_min(std::int64_t* heap, std::size_t& count) {
    const auto result = heap[0], value = heap[--count]; if (count == 0) return result;
    std::size_t position = 0;
    while (2 * position + 1 < count) { std::size_t child = 2 * position + 1; if (child + 1 < count && heap[child + 1] < heap[child]) ++child; if (heap[child] >= value) break; heap[position] = heap[child]; position = child; }
    heap[position] = value; return result;
}
}

extern "C" std::int64_t median_of_running_array_long(const std::int64_t* input, std::size_t length,
                                                      std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > max_input_length) return -1;
    const auto count_value = input[0];
    if (count_value < 1 || count_value > static_cast<std::int64_t>(max_count) || length != 1 + static_cast<std::size_t>(count_value)) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    std::int64_t lower[max_count], upper[max_count], medians[max_count];
    std::size_t lower_count = 0, upper_count = 0;
    for (std::size_t i = 0; i < count; ++i) {
        const auto sample = input[i + 1];
        if (sample < -4611686018427387904LL || sample > 4611686018427387903LL) return -1;
        if (upper_count > 0 && sample < upper[0]) push_max(lower, lower_count, sample);
        else push_min(upper, upper_count, sample);
        if (lower_count > upper_count + 1) push_min(upper, upper_count, pop_max(lower, lower_count));
        else if (upper_count > lower_count + 1) push_max(lower, lower_count, pop_min(upper, upper_count));
        if (lower_count > upper_count) medians[i] = lower[0];
        else if (upper_count > lower_count) medians[i] = upper[0];
        else medians[i] = (lower[0] + upper[0]) / 2;
    }
    const std::size_t output_bytes = count * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t i = 0; i < count; ++i) store_i64_le(output, 8 * i, medians[i]);
    return static_cast<std::int64_t>(output_bytes);
}
