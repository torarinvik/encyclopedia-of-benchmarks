/* Integer sum specialization of the pinned square-root decomposition. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 64;
constexpr std::size_t MAX_OPERATIONS = 64;
constexpr std::size_t MAX_INPUT_LENGTH = 258;

std::size_t block_size_for(std::size_t n)
{
    std::size_t block_size = 1;
    while ((block_size + 1) * (block_size + 1) <= n) ++block_size;
    return block_size;
}

std::int64_t query_sum(const std::int64_t *elements, const std::int64_t *blocks,
                       std::size_t block_size, std::size_t start, std::size_t end)
{
    const std::size_t first_index_next_block = ((start / block_size) + 1) * block_size;
    std::int64_t sum = elements[start];
    if (first_index_next_block > end) {
        for (std::size_t index = start + 1; index < end; ++index) sum += elements[index];
    } else {
        for (std::size_t index = start + 1; index < first_index_next_block; ++index)
            sum += elements[index];
        const std::size_t end_block = end / block_size;
        for (std::size_t block = first_index_next_block / block_size; block < end_block; ++block)
            sum += blocks[block];
        for (std::size_t index = end_block * block_size; index < end; ++index)
            sum += elements[index];
    }
    return sum;
}
} // namespace

extern "C" std::int64_t sqrt_decomposition_range_sum(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept
{
    if (input == nullptr || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(MAX_N)) return -1;
    const std::size_t n = static_cast<std::size_t>(input[0]);
    if (length < n + 2) return -1;
    if (input[n + 1] < 0 || input[n + 1] > static_cast<std::int64_t>(MAX_OPERATIONS)) return -1;
    const std::size_t operation_count = static_cast<std::size_t>(input[n + 1]);
    if (length != 2 + n + 3 * operation_count) return -1;

    std::int64_t elements[MAX_N];
    for (std::size_t index = 0; index < n; ++index) {
        const std::int64_t value = input[index + 1];
        if (value < -1000 || value > 1000) return -1;
        elements[index] = value;
    }
    std::size_t query_count = 0;
    const std::size_t operations_start = n + 2;
    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        const std::size_t offset = operations_start + 3 * operation;
        const std::int64_t kind = input[offset];
        const std::int64_t first = input[offset + 1];
        const std::int64_t second = input[offset + 2];
        if (kind == 0) {
            if (first < 0 || first >= second || second > static_cast<std::int64_t>(n)) return -1;
            ++query_count;
        } else if (kind == 1) {
            if (first < 0 || first >= static_cast<std::int64_t>(n) || second < -1000 || second > 1000)
                return -1;
        } else {
            return -1;
        }
    }

    const std::size_t output_bytes = query_count * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    const std::size_t block_size = block_size_for(n);
    std::int64_t blocks[MAX_N]{};
    for (std::size_t index = 0; index < n; ++index) {
        const std::size_t block = index / block_size;
        if (index % block_size == 0) blocks[block] = elements[index];
        else blocks[block] += elements[index];
    }

    std::size_t output_offset = 0;
    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        const std::size_t offset = operations_start + 3 * operation;
        const std::int64_t kind = input[offset];
        const std::size_t first = static_cast<std::size_t>(input[offset + 1]);
        const std::int64_t second = input[offset + 2];
        if (kind == 0) {
            const std::int64_t sum = query_sum(elements, blocks, block_size, first,
                                               static_cast<std::size_t>(second));
            std::uint64_t bits = static_cast<std::uint64_t>(sum);
            for (std::size_t byte = 0; byte < 8; ++byte) {
                output[output_offset++] = static_cast<std::uint8_t>(bits & 255);
                bits >>= 8;
            }
        } else {
            const std::size_t block = first / block_size;
            blocks[block] = blocks[block] - elements[first] + second;
            elements[first] = second;
        }
    }
    return static_cast<std::int64_t>(output_bytes);
}
