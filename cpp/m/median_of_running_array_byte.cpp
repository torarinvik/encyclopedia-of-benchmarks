#include <cstddef>
#include <cstdint>

namespace {
void push_max(std::int32_t* heap, std::size_t& count, std::int32_t value) {
    std::size_t i = count++;
    while (i > 0 && heap[(i - 1) / 2] < value) { heap[i] = heap[(i - 1) / 2]; i = (i - 1) / 2; }
    heap[i] = value;
}
std::int32_t pop_max(std::int32_t* heap, std::size_t& count) {
    const auto result = heap[0]; const auto value = heap[--count];
    if (count == 0) return result;
    std::size_t i = 0;
    while (2 * i + 1 < count) { auto child = 2 * i + 1; if (child + 1 < count && heap[child + 1] > heap[child]) ++child; if (heap[child] <= value) break; heap[i] = heap[child]; i = child; }
    heap[i] = value; return result;
}
void push_min(std::int32_t* heap, std::size_t& count, std::int32_t value) {
    std::size_t i = count++;
    while (i > 0 && heap[(i - 1) / 2] > value) { heap[i] = heap[(i - 1) / 2]; i = (i - 1) / 2; }
    heap[i] = value;
}
std::int32_t pop_min(std::int32_t* heap, std::size_t& count) {
    const auto result = heap[0]; const auto value = heap[--count];
    if (count == 0) return result;
    std::size_t i = 0;
    while (2 * i + 1 < count) { auto child = 2 * i + 1; if (child + 1 < count && heap[child + 1] < heap[child]) ++child; if (heap[child] >= value) break; heap[i] = heap[child]; i = child; }
    heap[i] = value; return result;
}
}

extern "C" std::int64_t median_of_running_array_byte(const std::int32_t* input, std::size_t length,
                                                       std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > 66) return -1;
    const std::int32_t count = input[0];
    if (count < 1 || count > 64 || length != 1 + static_cast<std::size_t>(count)) return -1;
    std::int32_t lower[64]{}, upper[64]{};
    std::uint8_t medians[64]{};
    std::size_t lower_count = 0, upper_count = 0;
    for (std::size_t i = 0; i < static_cast<std::size_t>(count); ++i) {
        const std::int32_t sample = input[i + 1];
        if (sample < -128 || sample > 127) return -1;
        if (upper_count > 0 && sample < upper[0]) push_max(lower, lower_count, sample);
        else push_min(upper, upper_count, sample);
        if (lower_count > upper_count + 1) push_min(upper, upper_count, pop_max(lower, lower_count));
        else if (upper_count > lower_count + 1) push_max(lower, lower_count, pop_min(upper, upper_count));
        std::int32_t median;
        if (lower_count > upper_count) median = lower[0];
        else if (upper_count > lower_count) median = upper[0];
        else {
            const std::int32_t sum = lower[0] + upper[0];
            median = sum < 0 ? -((-sum) / 2) : sum / 2;
        }
        medians[i] = static_cast<std::uint8_t>(static_cast<std::int8_t>(median));
    }
    if (output == nullptr || capacity < static_cast<std::size_t>(count)) return -2;
    for (std::size_t i = 0; i < static_cast<std::size_t>(count); ++i) output[i] = medians[i];
    return count;
}
