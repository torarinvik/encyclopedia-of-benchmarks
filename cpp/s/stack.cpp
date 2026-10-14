/* Bounded array-backed integer stack used by the shared operation-trace benchmark. */
#include <cstddef>
#include <cstdint>

namespace { constexpr std::int64_t invalid_result = -1; }

extern "C" std::int64_t stack_benchmark(const std::int64_t *values, std::size_t length) noexcept
{
    if (length > 1024 || length % 2 != 0) return invalid_result;
    const std::size_t operation_count = length / 2;
    std::int64_t data_stack[256];
    std::size_t top = 0;
    std::int64_t checksum = 0;
    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        const auto opcode = values[2 * operation];
        const auto payload = values[2 * operation + 1];
        std::int64_t observed = 0;
        bool returns_value = true;
        if (opcode == 0) {
            if (payload < -1000000 || payload > 1000000 || top == 256) return invalid_result;
            data_stack[top++] = payload;
            returns_value = false;
        } else if (opcode == 1) {
            if (payload != 0 || top == 0) return invalid_result;
            observed = data_stack[--top];
        } else if (opcode == 2) {
            if (payload != 0 || top == 0) return invalid_result;
            observed = data_stack[top - 1];
        } else if (opcode == 3) {
            if (payload != 0) return invalid_result;
            observed = top == 0 ? 1 : 0;
        } else return invalid_result;
        if (returns_value) checksum += (static_cast<std::int64_t>(operation) + 1) * (observed + 1000000);
    }
    for (std::size_t index = 0; index < top; ++index) {
        checksum += (static_cast<std::int64_t>(operation_count + index) + 1) * (data_stack[index] + 1000000);
    }
    return checksum;
}
