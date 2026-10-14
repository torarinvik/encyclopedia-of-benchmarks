/* Bounded ring-buffer queue used by the shared operation-trace benchmark. */
#include <cstddef>
#include <cstdint>

namespace { constexpr std::int64_t invalid_result = -1; }

extern "C" std::int64_t queue_benchmark(const std::int64_t *values, std::size_t length) noexcept
{
    if (length > 1024 || length % 2 != 0) return invalid_result;
    const std::size_t operation_count = length / 2;
    std::int64_t data_queue[256];
    std::size_t head = 0;
    std::size_t count = 0;
    std::int64_t checksum = 0;
    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        const auto opcode = values[2 * operation];
        const auto payload = values[2 * operation + 1];
        std::int64_t observed = 0;
        bool returns_value = true;
        if (opcode == 0) {
            if (payload < -1000000 || payload > 1000000 || count == 256) return invalid_result;
            data_queue[(head + count) % 256] = payload;
            ++count;
            returns_value = false;
        } else if (opcode == 1) {
            if (payload != 0 || count == 0) return invalid_result;
            observed = data_queue[head];
            head = (head + 1) % 256;
            --count;
        } else if (opcode == 2) {
            if (payload != 0 || count == 0) return invalid_result;
            observed = data_queue[head];
        } else if (opcode == 3) {
            if (payload != 0 || count == 0) return invalid_result;
            observed = data_queue[(head + count - 1) % 256];
        } else if (opcode == 4) {
            if (payload != 0) return invalid_result;
            observed = count == 0 ? 1 : 0;
        } else if (opcode == 5) {
            if (payload != 0) return invalid_result;
            observed = static_cast<std::int64_t>(count);
        } else return invalid_result;
        if (returns_value) checksum += (static_cast<std::int64_t>(operation) + 1) * (observed + 1000000);
    }
    for (std::size_t index = 0; index < count; ++index) {
        checksum += (static_cast<std::int64_t>(operation_count + index) + 1)
            * (data_queue[(head + index) % 256] + 1000000);
    }
    return checksum;
}
