#include <stddef.h>
#include <stdint.h>

int64_t queue_using_array(const int64_t *packed, size_t length)
{
    if (packed == NULL || length < 1 || length > 1025) return -1;
    const int64_t qv = packed[0];
    if (qv < 0 || qv > 512 || length != 1 + (size_t)qv * 2) return -1;
    const size_t q = (size_t)qv;
    for (size_t i = 0; i < q; ++i) {
        const int64_t op = packed[1 + i * 2], value = packed[2 + i * 2];
        if (op == 0) { if (value < -128 || value > 127) return -1; }
        else if (op == 1) { if (value != 0) return -1; }
        else return -1;
    }
    int16_t values[10] = {0};
    int front = -1, rear = -1;
    int64_t checksum = 0, ordinal = 0;
    for (size_t i = 0; i < q; ++i) {
        const int64_t op = packed[1 + i * 2], value = packed[2 + i * 2];
        if (op == 0) {
            if (rear == 9) continue;
            if (front == -1 && rear == -1) { front = rear = 0; values[rear] = (int16_t)value; }
            else if (rear < 10) { ++rear; values[rear] = (int16_t)value; }
        } else {
            int64_t dequeued = 0;
            if (front != -1) {
                if (front == rear) { dequeued = (int8_t)values[front]; front = rear = -1; }
                else { dequeued = (int8_t)values[front]; ++front; }
            }
            ++ordinal;
            checksum += ordinal * (dequeued + 128);
        }
    }
    return checksum;
}
