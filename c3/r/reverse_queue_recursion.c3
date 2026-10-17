module reverse_queue_recursion;

const long MAX_QUEUE_LENGTH = 32;
const usz MAX_INPUT_LENGTH = 34;

fn void reverse_queue_recursive(uint8* queue, usz capacity, usz* front, usz* size) {
    if (*size == 0) return;
    uint8 value = queue[*front];
    *front = (*front + 1) % capacity;
    *size = *size - 1;
    reverse_queue_recursive(queue, capacity, front, size);
    usz rear = (*front + *size) % capacity;
    queue[rear] = value;
    *size = *size + 1;
}

fn long reverse_queue_recursion(long* input, usz input_length, uint8* output,
                                usz output_capacity) @export("reverse_queue_recursion") {
    if (input == null) {
        if (input_length != 1) return -1;
        return output == null ? -2 : 0;
    }
    if (input_length < 1 || input_length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_QUEUE_LENGTH) return -1;
    usz queue_length = (usz)input[0];
    if (input_length != queue_length + 1) return -1;
    for (usz index = 0; index < queue_length; index++) {
        if (input[index + 1] < 0 || input[index + 1] > 255) return -1;
    }
    if (output == null || output_capacity < queue_length) return -2;

    uint8[MAX_QUEUE_LENGTH] queue = {0};
    for (usz index = 0; index < queue_length; index++) queue[index] = (uint8)input[index + 1];
    usz front = 0;
    usz size = queue_length;
    reverse_queue_recursive(&queue[0], queue_length, &front, &size);
    for (usz index = 0; index < queue_length; index++)
        output[index] = queue[(front + index) % queue_length];
    return (long)queue_length;
}
