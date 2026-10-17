#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_parseable_input_length = 259;
constexpr std::size_t max_capacity = 64;
constexpr std::size_t max_count = 256;
constexpr std::int64_t max_value = 1'000'000;
constexpr std::int64_t invalid_result = INT64_MIN;
}

extern "C" std::int64_t sliding_window_aggregator(const std::int64_t *input, std::size_t length)
{
    if (input == nullptr || length < 2 || length > max_parseable_input_length) return invalid_result;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_capacity) ||
        input[1] < 1 || input[1] > static_cast<std::int64_t>(max_count)) return invalid_result;

    const std::size_t capacity = static_cast<std::size_t>(input[0]);
    const std::size_t count = static_cast<std::size_t>(input[1]);
    if (length != count + 2) return invalid_result;
    for (std::size_t index = 0; index < count; ++index) {
        if (input[index + 2] < -max_value || input[index + 2] > max_value) return invalid_result;
    }

    std::array<std::int64_t, max_capacity> window{};
    std::size_t head = 0;
    std::size_t size = 0;
    std::int64_t sum = 0;
    for (std::size_t index = 0; index < count; ++index) {
        const std::int64_t value = input[index + 2];
        if (size < capacity) {
            const std::size_t tail = (head + size) % capacity;
            window[tail] = value;
            sum += value;
            ++size;
        } else {
            sum -= window[head];
            window[head] = value;
            sum += value;
            head = (head + 1) % capacity;
        }
    }
    return sum;
}
