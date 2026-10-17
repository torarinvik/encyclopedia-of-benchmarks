#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_operations = 64;
constexpr std::size_t max_input_length = 1 + 2 * max_operations;
constexpr std::size_t max_depth = 64;
constexpr std::size_t max_output_bytes = 4 + 8 * max_operations;

struct StackNode {
    std::int32_t value;
    std::int32_t next;
};

void put_i32_le(std::uint8_t* output, std::size_t offset, std::int32_t value) {
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t linked_list_stack(const std::int64_t* input,
                                            std::size_t length,
                                            std::uint8_t* output,
                                            std::size_t capacity) {
    if (input == nullptr || length < 1 || length > max_input_length) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_operations)) return -1;

    const auto operation_count = static_cast<std::size_t>(input[0]);
    std::array<StackNode, max_depth> nodes{};
    std::array<std::int32_t, 2 * max_operations> records{};
    std::size_t node_count = 0, query_count = 0, cursor = 1;
    std::int32_t top = -1, stack_size = 0;

    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        if (cursor >= length) return -1;
        const auto opcode = input[cursor++];
        if (opcode == 0) {
            if (cursor >= length) return -1;
            const auto value = input[cursor++];
            if (value < INT32_MIN || value > INT32_MAX
                    || stack_size >= static_cast<std::int32_t>(max_depth)
                    || node_count >= max_depth) return -1;
            nodes[node_count] = {static_cast<std::int32_t>(value), top};
            top = static_cast<std::int32_t>(node_count++);
            ++stack_size;
        } else if (opcode == 1) {
            if (stack_size == 0 || top < 0) return -1;
            records[2 * query_count] = 1;
            records[2 * query_count + 1] = nodes[static_cast<std::size_t>(top)].value;
            ++query_count;
            top = nodes[static_cast<std::size_t>(top)].next;
            --stack_size;
        } else if (opcode == 2) {
            records[2 * query_count] = 2;
            records[2 * query_count + 1] = stack_size;
            ++query_count;
        } else if (opcode == 3) {
            records[2 * query_count] = 3;
            records[2 * query_count + 1] = stack_size == 0 ? 1 : 0;
            ++query_count;
        } else {
            return -1;
        }
    }
    if (cursor != length) return -1;

    const auto output_bytes = 4 + 8 * query_count;
    if (output == nullptr || capacity < output_bytes) return -2;
    std::array<std::uint8_t, max_output_bytes> buffer{};
    put_i32_le(buffer.data(), 0, static_cast<std::int32_t>(query_count));
    for (std::size_t index = 0; index < 2 * query_count; ++index)
        put_i32_le(buffer.data(), 4 + 4 * index, records[index]);
    for (std::size_t byte = 0; byte < output_bytes; ++byte) output[byte] = buffer[byte];
    return static_cast<std::int64_t>(output_bytes);
}
