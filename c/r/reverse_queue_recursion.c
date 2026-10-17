#include <stddef.h>
#include <stdint.h>

#define MAX_QUEUE_LENGTH 32
#define MAX_INPUT_LENGTH 34

static void reverse_queue_recursive(uint8_t *queue, size_t capacity,
                                    size_t *front, size_t *size)
{
    if (*size == 0) return;
    const uint8_t value = queue[*front];
    *front = (*front + 1) % capacity;
    --*size;
    reverse_queue_recursive(queue, capacity, front, size);
    const size_t rear = (*front + *size) % capacity;
    queue[rear] = value;
    ++*size;
}

int64_t reverse_queue_recursion(const int64_t *input, size_t input_length,
                                uint8_t *output, size_t output_capacity)
{
    if (input == NULL) {
        if (input_length != 1) return -1;
        return output == NULL ? -2 : 0;
    }
    if (input_length < 1 || input_length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_QUEUE_LENGTH) return -1;
    const size_t queue_length = (size_t)input[0];
    if (input_length != queue_length + 1) return -1;
    for (size_t index = 0; index < queue_length; ++index) {
        if (input[index + 1] < 0 || input[index + 1] > 255) return -1;
    }
    if (output == NULL || output_capacity < queue_length) return -2;

    uint8_t queue[MAX_QUEUE_LENGTH] = {0};
    for (size_t index = 0; index < queue_length; ++index)
        queue[index] = (uint8_t)input[index + 1];
    size_t front = 0;
    size_t size = queue_length;
    reverse_queue_recursive(queue, queue_length, &front, &size);
    for (size_t index = 0; index < queue_length; ++index)
        output[index] = queue[(front + index) % queue_length];
    return (int64_t)queue_length;
}
