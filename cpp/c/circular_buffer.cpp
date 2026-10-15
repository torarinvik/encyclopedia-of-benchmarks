// Bounded circular buffer that overwrites the oldest item when full.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t circular_buffer_benchmark(const std::int64_t *values, std::size_t length) noexcept {
    constexpr std::size_t max_capacity = 256, max_operations = 512;
    constexpr std::int64_t offset = 1'000'000;
    if (values == nullptr || length < 1 || length > 1 + 2 * max_operations || (length - 1) % 2 != 0) return -1;
    if (values[0] < 1 || values[0] > static_cast<std::int64_t>(max_capacity)) return -1;
    const auto capacity = static_cast<std::size_t>(values[0]);
    const auto operation_count = (length - 1) / 2;
    std::int64_t buffer[max_capacity];
    std::size_t head = 0, tail = 0, count = 0;
    std::int64_t checksum = 0;
    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        const auto opcode = values[1 + 2 * operation], payload = values[2 + 2 * operation];
        std::int64_t observed = 0;
        if (opcode == 0) {
            if (payload < 0 || payload > offset) return -1;
            const bool was_empty = count == 0;
            if (count == capacity) head = (head + 1) % capacity;
            else ++count;
            buffer[tail] = payload;
            tail = (tail + 1) % capacity;
            observed = was_empty;
        } else if (opcode == 1) {
            if (payload != 0) return -1;
            if (count == 0) observed = -1;
            else {
                observed = buffer[head];
                head = (head + 1) % capacity;
                --count;
            }
        } else if (opcode == 2) {
            if (payload != 0) return -1;
            observed = count == 0;
        } else if (opcode == 3) {
            if (payload != 0) return -1;
            observed = count == capacity;
        } else if (opcode == 4) {
            if (payload != 0) return -1;
            observed = static_cast<std::int64_t>(count);
        } else return -1;
        checksum += (static_cast<std::int64_t>(operation) + 1) * (observed + offset);
    }
    for (std::size_t index = 0; index < count; ++index)
        checksum += (static_cast<std::int64_t>(operation_count + index) + 1)
            * (buffer[(head + index) % capacity] + offset);
    return checksum;
}
