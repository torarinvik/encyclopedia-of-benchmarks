#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t min_key = -1'000'000;
constexpr std::int64_t max_key = 1'000'000;
constexpr std::int64_t key_offset = 1'000'001;
constexpr std::int64_t hash_modulus = 1'000'000'007;
constexpr std::size_t max_parseable_input_length = 899;
constexpr std::size_t max_initial_keys = 128;
constexpr std::size_t max_operations = 256;
constexpr std::size_t max_size = 256;

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

std::size_t upper_bound_i64(const std::int64_t *values, std::size_t size, std::int64_t target)
{
    std::size_t left = 0;
    std::size_t right = size;
    while (left < right) {
        const std::size_t middle = left + (right - left) / 2;
        if (values[middle] <= target) left = middle + 1;
        else right = middle;
    }
    return left;
}

std::int64_t key_code(std::int64_t key) { return key + key_offset; }

std::int64_t sequence_code(const std::int64_t *values, std::size_t first,
                           std::size_t last, bool descending)
{
    const std::size_t count = last - first;
    std::int64_t hash = 0;
    if (descending) {
        while (last > first) {
            --last;
            hash = (31 * hash + key_code(values[last])) % hash_modulus;
        }
    } else {
        for (std::size_t index = first; index < last; ++index)
            hash = (31 * hash + key_code(values[index])) % hash_modulus;
    }
    return static_cast<std::int64_t>(count) * hash_modulus + hash;
}
}

extern "C" std::int64_t sorted_table_benchmark(const std::int64_t *input, std::size_t length)
{
    if (length > max_parseable_input_length || (length > 0 && input == nullptr) || length < 2) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_initial_keys)) return -1;
    const std::size_t initial_count = static_cast<std::size_t>(input[0]);
    const std::size_t operation_count_index = initial_count + 1;
    if (operation_count_index >= length) return -1;
    const std::int64_t operation_count_value = input[operation_count_index];
    if (operation_count_value < 0 || operation_count_value > static_cast<std::int64_t>(max_operations)) return -1;
    const std::size_t operation_count = static_cast<std::size_t>(operation_count_value);
    const std::size_t operations_start = operation_count_index + 1;
    if (length != operations_start + 3 * operation_count) return -1;

    std::int64_t items[max_size];
    for (std::size_t index = 0; index < initial_count; ++index) {
        const std::int64_t key = input[index + 1];
        if (key < min_key || key > max_key || (index > 0 && items[index - 1] >= key)) return -1;
        items[index] = key;
    }
    std::size_t size = initial_count;
    std::int64_t checksum = 0;

    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        const std::size_t offset = operations_start + 3 * operation;
        const std::int64_t opcode = input[offset];
        const std::int64_t a = input[offset + 1];
        const std::int64_t b = input[offset + 2];
        bool has_observation = true;
        std::int64_t observed = 0;
        std::size_t position = 0;

        if (opcode == 0 || opcode == 1 || opcode == 4 || opcode == 5 || opcode == 7) {
            if (b != 0 || a < min_key || a > max_key) return -1;
            position = lower_bound_i64(items, size, a);
            const bool found = position < size && items[position] == a;
            if (opcode == 0) observed = found ? key_code(a) : 0;
            else if (opcode == 1) observed = found ? 1 : 0;
            else if (opcode == 4) {
                if (found) ++position;
                if (position < size) observed = key_code(items[position]);
            } else if (opcode == 5) {
                if (position > 0) observed = key_code(items[position - 1]);
            } else if (found) {
                observed = key_code(a);
                for (std::size_t index = position; index + 1 < size; ++index) items[index] = items[index + 1];
                --size;
            }
        } else if (opcode == 2 || opcode == 3) {
            if (a != 0 || b != 0) return -1;
            if (size > 0) observed = key_code(items[opcode == 2 ? 0 : size - 1]);
        } else if (opcode == 6) {
            if (a < min_key || a > max_key || (b != 0 && b != 1)) return -1;
            position = lower_bound_i64(items, size, a);
            const bool found = position < size && items[position] == a;
            if (found) observed = key_code(a);
            else {
                if (size >= max_size) return -1;
                for (std::size_t index = size; index > position; --index) items[index] = items[index - 1];
                items[position] = a;
                ++size;
            }
        } else if (opcode == 8 || opcode == 9) {
            if (a < min_key || a > max_key || b < min_key || b > max_key) return -1;
            if (a <= b) {
                const std::size_t first = lower_bound_i64(items, size, a);
                const std::size_t last = upper_bound_i64(items, size, b);
                observed = sequence_code(items, first, last, opcode == 9);
            }
        } else if (opcode == 10 || opcode == 11) {
            if (a != 0 || b != 0) return -1;
            observed = sequence_code(items, 0, size, opcode == 11);
        } else if (opcode == 12) {
            if (a != 0 || b != 0) return -1;
            observed = size == 0 ? 1 : 0;
        } else if (opcode == 13) {
            if (a != 0 || b != 0) return -1;
            size = 0;
            has_observation = false;
        } else {
            return -1;
        }

        if (has_observation)
            checksum += static_cast<std::int64_t>(operation + 1) * (observed + 1);
    }

    for (std::size_t index = 0; index < size; ++index)
        checksum += static_cast<std::int64_t>(operation_count + index + 1) * key_code(items[index]);
    return checksum;
}
