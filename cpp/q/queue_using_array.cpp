#include <cstddef>
#include <cstdint>

extern "C" std::int64_t queue_using_array(const std::int64_t *packed, std::size_t length) noexcept {
    if (packed == nullptr || length < 1 || length > 1025) return -1;
    const auto qv = packed[0];
    if (qv < 0 || qv > 512 || length != 1 + static_cast<std::size_t>(qv) * 2) return -1;
    const auto q = static_cast<std::size_t>(qv);
    for (std::size_t i = 0; i < q; ++i) {
        const auto op = packed[1 + i * 2], value = packed[2 + i * 2];
        if (op == 0) { if (value < -128 || value > 127) return -1; }
        else if (op == 1) { if (value != 0) return -1; }
        else return -1;
    }
    std::int16_t values[10]{};
    int front = -1, rear = -1;
    std::int64_t checksum = 0, ordinal = 0;
    for (std::size_t i = 0; i < q; ++i) {
        const auto op = packed[1 + i * 2], value = packed[2 + i * 2];
        if (op == 0) {
            if (rear == 9) continue;
            if (front == -1 && rear == -1) { front = rear = 0; values[rear] = static_cast<std::int16_t>(value); }
            else if (rear < 10) { ++rear; values[rear] = static_cast<std::int16_t>(value); }
        } else {
            std::int64_t dequeued = 0;
            if (front != -1) {
                if (front == rear) { dequeued = static_cast<std::int8_t>(values[front]); front = rear = -1; }
                else { dequeued = static_cast<std::int8_t>(values[front]); ++front; }
            }
            ++ordinal;
            checksum += ordinal * (dequeued + 128);
        }
    }
    return checksum;
}
