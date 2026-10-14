/* Amortized FIFO queue implemented with an input and an output stack. */
#include <cstddef>
#include <cstdint>

namespace { constexpr std::int64_t invalid_result = -1; }

extern "C" std::int64_t queue_using_two_stacks_benchmark(const std::int64_t *values, std::size_t length) noexcept
{
    if (length > 1024 || length % 2 != 0) return invalid_result;
    const std::size_t operation_count = length / 2;
    std::int64_t in_stack[256], out_stack[256];
    std::size_t in_count = 0, out_count = 0;
    std::int64_t checksum = 0;
    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        const auto opcode = values[2 * operation], payload = values[2 * operation + 1];
        std::int64_t observed = 0;
        bool returns_value = true;
        if (opcode == 0) {
            if (payload < -1000000 || payload > 1000000 || in_count + out_count == 256) return invalid_result;
            in_stack[in_count++] = payload;
            returns_value = false;
        } else if (opcode == 1 || opcode == 2) {
            if (payload != 0) return invalid_result;
            if (out_count == 0) {
                while (in_count > 0) out_stack[out_count++] = in_stack[--in_count];
            }
            if (out_count == 0) return invalid_result;
            if (opcode == 1) observed = out_stack[--out_count];
            else observed = out_stack[out_count - 1];
        } else if (opcode == 3) {
            if (payload != 0) return invalid_result;
            observed = static_cast<std::int64_t>(in_count + out_count == 0);
        } else if (opcode == 4) {
            if (payload != 0) return invalid_result;
            observed = static_cast<std::int64_t>(in_count + out_count);
        } else return invalid_result;
        if (returns_value) checksum += (static_cast<std::int64_t>(operation) + 1) * (observed + 1000000);
    }
    for (std::size_t index = 0; index < out_count; ++index) {
        checksum += (static_cast<std::int64_t>(operation_count + index) + 1)
            * (out_stack[out_count - index - 1] + 1000000);
    }
    for (std::size_t index = 0; index < in_count; ++index) {
        checksum += (static_cast<std::int64_t>(operation_count + out_count + index) + 1)
            * (in_stack[index] + 1000000);
    }
    return checksum;
}
