#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_operations = 24;
constexpr std::size_t max_initial_capacity = 8;
constexpr std::size_t max_table_capacity = 64;
constexpr std::size_t max_input_length = 51;
constexpr std::size_t max_inserts_to_capacity_64 = max_table_capacity / 4;
constexpr std::size_t max_output_elements =
    3 + (max_operations - max_inserts_to_capacity_64) + max_table_capacity;
constexpr std::size_t max_output_bytes = 8 * max_output_elements;

constexpr std::int64_t op_insert = 0;
constexpr std::int64_t op_remove = 1;
constexpr std::int64_t op_find = 2;

struct Table {
    std::array<std::int64_t, max_table_capacity> slots{};
    std::size_t capacity{};
    std::size_t size{};
};

std::int64_t probe_insert(const Table &table, std::int64_t key) noexcept
{
    for (std::size_t probe = 0; probe < table.capacity * 100; ++probe) {
        // The benchmark normatively defines hash(key)=key.
        const auto index = static_cast<std::size_t>(
            (key + static_cast<std::int64_t>(probe * probe)) %
            static_cast<std::int64_t>(table.capacity));
        if (table.slots[index] == 0 || table.slots[index] == -1)
            return static_cast<std::int64_t>(index);
    }
    return -1;
}

std::int64_t probe_find(const Table &table, std::int64_t key) noexcept
{
    for (std::size_t probe = 0; probe < table.capacity * 100; ++probe) {
        const auto index = static_cast<std::size_t>(
            (key + static_cast<std::int64_t>(probe * probe)) %
            static_cast<std::int64_t>(table.capacity));
        const auto slot = table.slots[index];
        if (slot == 0) return -1;
        if (slot == key) return static_cast<std::int64_t>(index);
    }
    return -1;
}

bool insert_key(Table &table, std::int64_t key);

bool rehash(Table &table)
{
    const auto old_capacity = table.capacity;
    if (old_capacity > max_table_capacity / 2) return false;

    const auto old_slots = table.slots;
    const auto new_capacity = old_capacity * 2;
    table.slots.fill(0);
    table.capacity = new_capacity;

    // Reinsertion follows add(), which can recursively trigger rehash again.
    for (std::size_t index = 0; index < old_capacity; ++index) {
        const auto key = old_slots[index];
        if (key == 0 || key == -1) continue;
        if (table.size == 0) return false;
        --table.size;
        if (!insert_key(table, key)) return false;
    }
    return true;
}

bool insert_key(Table &table, std::int64_t key)
{
    const auto index = probe_insert(table, key);
    if (index < 0) return false;
    table.slots[static_cast<std::size_t>(index)] = key;
    ++table.size;
    if (table.size * 2 >= table.capacity) return rehash(table);
    return true;
}

void write_i64_le(std::uint8_t *output, std::size_t &offset, std::int64_t value) noexcept
{
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset++] = static_cast<std::uint8_t>(bits & UINT64_C(0xff));
        bits >>= 8;
    }
}
}

extern "C" std::int64_t quadratic_probing_hash_table(
    const std::int64_t *values, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (values == nullptr || length < 2 || length > max_input_length) return -1;
    if (values[0] < 1 || values[0] > static_cast<std::int64_t>(max_initial_capacity) ||
        values[1] < 0 || values[1] > static_cast<std::int64_t>(max_operations)) return -1;

    const auto initial_capacity = static_cast<std::size_t>(values[0]);
    const auto operation_count = static_cast<std::size_t>(values[1]);
    if (length != 2 + 2 * operation_count) return -1;

    Table table{};
    table.capacity = initial_capacity;
    std::array<bool, max_table_capacity + 1> active{};
    std::array<std::int64_t, max_operations> find_results{};
    std::size_t find_count = 0;

    for (std::size_t operation_index = 0; operation_index < operation_count; ++operation_index) {
        const auto operation = values[2 + 2 * operation_index];
        const auto key = values[3 + 2 * operation_index];
        if (operation < op_insert || operation > op_find || key < 1 || key > 64) return -1;
        const auto key_index = static_cast<std::size_t>(key);

        if (operation == op_insert) {
            if (active[key_index]) return -1;
            if (!insert_key(table, key)) return -1;
            active[key_index] = true;
        } else if (operation == op_remove) {
            if (!active[key_index]) return -1;
            const auto index = probe_find(table, key);
            if (index < 0) return -1;
            table.slots[static_cast<std::size_t>(index)] = -1;
            active[key_index] = false;
            --table.size;
        } else {
            const auto index = probe_find(table, key);
            // Source find() uses index zero as its not-present sentinel.
            find_results[find_count++] = index <= 0 ? 0 : table.slots[static_cast<std::size_t>(index)];
        }
    }

    const auto output_elements = 3 + find_count + table.capacity;
    const auto output_bytes = output_elements * 8;
    if (output_bytes > max_output_bytes) return -1;
    if (output == nullptr || output_capacity < output_bytes) return -2;

    std::size_t offset = 0;
    write_i64_le(output, offset, static_cast<std::int64_t>(table.capacity));
    write_i64_le(output, offset, static_cast<std::int64_t>(table.size));
    write_i64_le(output, offset, static_cast<std::int64_t>(find_count));
    for (std::size_t index = 0; index < find_count; ++index)
        write_i64_le(output, offset, find_results[index]);
    for (std::size_t index = 0; index < table.capacity; ++index)
        write_i64_le(output, offset, table.slots[index]);
    return static_cast<std::int64_t>(offset);
}
