#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_QUEUE_LENGTH = 32;
constexpr std::size_t MAX_INPUT_LENGTH = 34;

void reverse_queue_recursive(std::uint8_t *queue, std::size_t capacity,
                             std::size_t *front, std::size_t *size)
{
    if (*size == 0) return;
    const std::uint8_t value = queue[*front];
    *front = (*front + 1) % capacity;
    --*size;
    reverse_queue_recursive(queue, capacity, front, size);
    const std::size_t rear = (*front + *size) % capacity;
    queue[rear] = value;
    ++*size;
}
}

extern "C" std::int64_t reverse_queue_recursion(const std::int64_t *input,
                                                  std::size_t input_length,
                                                  std::uint8_t *output,
                                                  std::size_t output_capacity) noexcept
{
    if (input == nullptr) {
        if (input_length != 1) return -1;
        return output == nullptr ? -2 : 0;
    }
    if (input_length < 1 || input_length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(MAX_QUEUE_LENGTH)) return -1;
    const std::size_t queue_length = static_cast<std::size_t>(input[0]);
    if (input_length != queue_length + 1) return -1;
    for (std::size_t index = 0; index < queue_length; ++index) {
        if (input[index + 1] < 0 || input[index + 1] > 255) return -1;
    }
    if (output == nullptr || output_capacity < queue_length) return -2;

    std::uint8_t queue[MAX_QUEUE_LENGTH]{};
    for (std::size_t index = 0; index < queue_length; ++index)
        queue[index] = static_cast<std::uint8_t>(input[index + 1]);
    std::size_t front = 0;
    std::size_t size = queue_length;
    reverse_queue_recursive(queue, queue_length, &front, &size);
    for (std::size_t index = 0; index < queue_length; ++index)
        output[index] = queue[(front + index) % queue_length];
    return static_cast<std::int64_t>(queue_length);
}
