#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_CAPACITY = 128;
constexpr std::size_t MAX_OPERATIONS = 256;
constexpr std::size_t MAX_INPUT_VALUES = 515;
constexpr std::size_t MAX_OUTPUT_BYTES = 4096;

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value)
{
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t priority_queues(const std::int64_t* input, std::size_t length,
                                        std::uint8_t* output, std::size_t output_capacity)
{
    if (input == nullptr || length < 2 || length > MAX_INPUT_VALUES) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(MAX_CAPACITY) ||
        input[1] < 0 || input[1] > static_cast<std::int64_t>(MAX_OPERATIONS)) return -1;

    const std::size_t capacity = static_cast<std::size_t>(input[0]);
    const std::size_t operation_count = static_cast<std::size_t>(input[1]);
    if (length != 2 + 2 * operation_count) return -1;

    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        const std::int64_t opcode = input[2 + 2 * operation];
        const std::int64_t argument = input[3 + 2 * operation];
        if (opcode < 0 || opcode > 5) return -1;
        if (opcode == 0) {
            if (argument < INT32_MIN || argument > INT32_MAX) return -1;
        } else if (argument != 0) {
            return -1;
        }
    }

    if (operation_count == 0) return 0;
    const std::size_t needed = operation_count * 16;
    if (needed > MAX_OUTPUT_BYTES || output == nullptr || output_capacity < needed) return -2;

    std::int32_t heap[MAX_CAPACITY + 1] = {};
    std::size_t size = 0;
    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        const std::int64_t opcode = input[2 + 2 * operation];
        const std::int64_t argument = input[3 + 2 * operation];
        std::int64_t status = 0;
        std::int64_t value = 0;

        if (opcode == 0) {
            if (size == capacity) {
                status = 1;
            } else {
                heap[++size] = static_cast<std::int32_t>(argument);
                std::size_t index = size;
                while (index > 1 && heap[index / 2] < heap[index]) {
                    const std::int32_t temporary = heap[index / 2];
                    heap[index / 2] = heap[index];
                    heap[index] = temporary;
                    index /= 2;
                }
            }
        } else if (opcode == 1) {
            if (size == 0) {
                status = 2;
            } else {
                value = heap[1];
                heap[1] = heap[size];
                heap[size] = 0;
                --size;
                std::size_t index = 1;
                while (index * 2 <= size) {
                    std::size_t child = index * 2;
                    if (child < size && heap[child + 1] > heap[child]) ++child;
                    if (heap[index] >= heap[child]) break;
                    const std::int32_t temporary = heap[index];
                    heap[index] = heap[child];
                    heap[child] = temporary;
                    index = child;
                }
            }
        } else if (opcode == 2) {
            value = size == 0 ? 0 : heap[1];
        } else if (opcode == 3) {
            value = size == 0 ? 1 : 0;
        } else if (opcode == 4) {
            value = size == capacity ? 1 : 0;
        } else {
            value = static_cast<std::int64_t>(size);
        }

        store_i64_le(output, operation * 16, status);
        store_i64_le(output, operation * 16 + 8, value);
    }
    return static_cast<std::int64_t>(needed);
}
