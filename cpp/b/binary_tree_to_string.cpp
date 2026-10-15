#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_nodes = 127;

bool validate_tree(const std::int64_t *values, std::size_t count, std::size_t root)
{
    std::uint8_t parents[max_nodes]{};
    std::uint8_t seen[max_nodes]{};
    std::int64_t stack[max_nodes];
    std::size_t top = 0, visited = 0;
    for (std::size_t i = 0; i < count; ++i) {
        const std::size_t base = 2 + 3 * i;
        const auto value = values[base];
        const auto left = values[base + 1], right = values[base + 2];
        if (value < INT32_MIN || value > INT32_MAX || left < -1 || right < -1 ||
            (left >= 0 && static_cast<std::uint64_t>(left) >= count) ||
            (right >= 0 && static_cast<std::uint64_t>(right) >= count)) return false;
        if (left >= 0 && ++parents[static_cast<std::size_t>(left)] > 1) return false;
        if (right >= 0 && ++parents[static_cast<std::size_t>(right)] > 1) return false;
    }
    for (std::size_t i = 0; i < count; ++i)
        if (parents[i] != (i == root ? 0 : 1)) return false;
    stack[top++] = static_cast<std::int64_t>(root);
    while (top > 0) {
        const auto index = static_cast<std::size_t>(stack[--top]);
        if (seen[index]) return false;
        seen[index] = 1;
        ++visited;
        const std::size_t base = 2 + 3 * index;
        const auto left = values[base + 1], right = values[base + 2];
        if (left >= 0) stack[top++] = left;
        if (right >= 0) stack[top++] = right;
    }
    return visited == count;
}

std::size_t decimal_length(std::int64_t value)
{
    std::size_t length = value < 0 ? 1 : 0;
    std::uint64_t magnitude = value < 0 ? static_cast<std::uint64_t>(-value) : static_cast<std::uint64_t>(value);
    do { ++length; magnitude /= 10; } while (magnitude != 0);
    return length;
}

void append_value(std::int32_t value, std::uint8_t *output, std::size_t *position)
{
    char digits[10];
    std::size_t count = 0;
    std::int64_t remaining = value;
    std::uint64_t magnitude;
    if (remaining < 0) { output[(*position)++] = '-'; magnitude = static_cast<std::uint64_t>(-remaining); }
    else magnitude = static_cast<std::uint64_t>(remaining);
    do { digits[count++] = static_cast<char>('0' + magnitude % 10); magnitude /= 10; } while (magnitude != 0);
    while (count > 0) output[(*position)++] = static_cast<std::uint8_t>(digits[--count]);
}

void emit_node(const std::int64_t *values, std::size_t index, std::uint8_t *output, std::size_t *position)
{
    const std::size_t base = 2 + 3 * index;
    const auto value = static_cast<std::int32_t>(values[base]);
    const auto left = values[base + 1], right = values[base + 2];
    append_value(value, output, position);
    if (left >= 0) { output[(*position)++] = '('; emit_node(values, static_cast<std::size_t>(left), output, position); output[(*position)++] = ')'; }
    else if (right >= 0) { output[(*position)++] = '('; output[(*position)++] = ')'; }
    if (right >= 0) { output[(*position)++] = '('; emit_node(values, static_cast<std::size_t>(right), output, position); output[(*position)++] = ')'; }
}
}

extern "C" std::int64_t binary_tree_to_string(const std::int64_t *values, std::size_t length,
                                                 std::uint8_t *output, std::size_t output_capacity)
{
    if (values == nullptr || length < 2 || values[0] < 0 || values[0] > static_cast<std::int64_t>(max_nodes)) return -1;
    const auto count = static_cast<std::size_t>(values[0]);
    if (length != 2 + 3 * count) return -1;
    const auto root = values[1];
    if (count == 0) return root == -1 ? 0 : -1;
    if (root < 0 || static_cast<std::uint64_t>(root) >= count || !validate_tree(values, count, static_cast<std::size_t>(root))) return -1;
    std::size_t required = 2 * (count - 1);
    for (std::size_t i = 0; i < count; ++i) {
        const std::size_t base = 2 + 3 * i;
        required += decimal_length(values[base]);
        if (values[base + 1] == -1 && values[base + 2] >= 0) required += 2;
    }
    if (output == nullptr || output_capacity < required) return -2;
    std::size_t position = 0;
    emit_node(values, static_cast<std::size_t>(root), output, &position);
    return static_cast<std::int64_t>(position);
}
