#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_parseable_input_length = 1025;
constexpr std::size_t max_operations = 512;
constexpr std::size_t max_size = 256;
constexpr std::int64_t max_value = 1'000'000;
constexpr std::int64_t checksum_offset = 1'000'000;

std::size_t lower_bound_i64(const std::int64_t *values, std::size_t size, std::int64_t target)
{
    std::size_t left = 0;
    std::size_t right = size;
    while (left < right) {
        const std::size_t middle = left + (right - left) / 2;
        if (values[middle] < target) left = middle + 1;
        else right = middle;
    }
    return left;
}
}

extern "C" std::int64_t sorted_list_benchmark(const std::int64_t *input, std::size_t length)
{
    if (length > max_parseable_input_length || (length > 0 && input == nullptr) || (length & 1) != 0) return -1;
    const std::size_t operation_count = length / 2;
    if (operation_count > max_operations) return -1;

    std::int64_t items[max_size];
    std::size_t size = 0;
    std::int64_t checksum = 0;
    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        const std::int64_t opcode = input[2 * operation];
        const std::int64_t payload = input[2 * operation + 1];
        std::int64_t observed = 0;
        bool has_observation = true;

        if (opcode == 0) {
            if (payload < 0 || payload > max_value || size >= max_size) return -1;
            const std::size_t position = lower_bound_i64(items, size, payload);
            for (std::size_t index = size; index > position; --index) items[index] = items[index - 1];
            items[position] = payload;
            ++size;
            has_observation = false;
        } else if (opcode == 1 || opcode == 2) {
            if (payload < 0 || payload > max_value) return -1;
            const std::size_t position = lower_bound_i64(items, size, payload);
            const bool found = position < size && items[position] == payload;
            observed = found ? 1 : 0;
            if (opcode == 2 && found) {
                for (std::size_t index = position; index + 1 < size; ++index) items[index] = items[index + 1];
                --size;
            }
        } else if (opcode == 3) {
            if (payload != 0) return -1;
            observed = static_cast<std::int64_t>(size);
        } else if (opcode == 4) {
            if (payload < 0 || static_cast<std::uint64_t>(payload) >= size) return -1;
            observed = items[static_cast<std::size_t>(payload)];
        } else if (opcode == 5) {
            if (payload != 0) return -1;
            size = 0;
            has_observation = false;
        } else {
            return -1;
        }

        if (has_observation)
            checksum += static_cast<std::int64_t>(operation + 1) * (observed + checksum_offset);
    }

    for (std::size_t index = 0; index < size; ++index)
        checksum += static_cast<std::int64_t>(operation_count + index + 1) * (items[index] + checksum_offset);
    return checksum;
}
