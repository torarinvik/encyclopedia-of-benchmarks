#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_operations = 1024;
constexpr std::size_t max_elements = 256;
constexpr std::size_t hash_capacity = 512;
constexpr std::int64_t max_key = INT64_C(1000000000);

std::size_t hash_slot(std::int32_t value) noexcept
{
    const auto mixed = static_cast<std::uint64_t>(static_cast<std::uint32_t>(value)) * UINT64_C(2654435761);
    return static_cast<std::size_t>(static_cast<std::uint32_t>(mixed) >> 23);
}

std::size_t find_slot(const std::int32_t *keys, const std::uint8_t *states,
                      std::int32_t value, bool &found) noexcept
{
    auto slot = hash_slot(value);
    auto deleted = hash_capacity;
    for (std::size_t probes = 0; probes < hash_capacity; ++probes) {
        if (states[slot] == 0) {
            found = false;
            return deleted < hash_capacity ? deleted : slot;
        }
        if (states[slot] == 2) {
            if (deleted == hash_capacity) deleted = slot;
        } else if (keys[slot] == value) {
            found = true;
            return slot;
        }
        slot = (slot + 1) % hash_capacity;
    }
    found = false;
    return deleted;
}
}

extern "C" std::int64_t choiceset(const std::int64_t *values, std::size_t length,
                                   std::uint8_t *output, std::size_t capacity) noexcept
{
    if (values == nullptr || length < 1 || values[0] < 0 || values[0] > static_cast<std::int64_t>(max_operations)) return -1;
    const auto operation_count = static_cast<std::size_t>(values[0]);
    if (length != 1 + 2 * operation_count) return -1;
    const auto output_bytes = operation_count * 8;

    std::int32_t elements[max_elements] = {}, map_keys[hash_capacity] = {}, map_indices[hash_capacity] = {};
    std::uint8_t states[hash_capacity] = {};
    std::int64_t results[max_operations] = {};
    std::size_t element_count = 0;
    for (std::size_t operation_index = 0; operation_index < operation_count; ++operation_index) {
        const auto operation = values[1 + 2 * operation_index];
        const auto argument = values[2 + 2 * operation_index];
        if (operation >= 1 && operation <= 3) {
            if (argument < -max_key || argument > max_key) return -1;
            const auto key = static_cast<std::int32_t>(argument);
            bool found = false;
            const auto slot = find_slot(map_keys, states, key, found);
            if (operation == 1) {
                if (found) results[operation_index] = 0;
                else {
                    if (element_count == max_elements || slot >= hash_capacity) return -1;
                    elements[element_count] = key;
                    map_keys[slot] = key;
                    map_indices[slot] = static_cast<std::int32_t>(element_count);
                    states[slot] = 1;
                    ++element_count;
                    results[operation_index] = 1;
                }
            } else if (operation == 2) {
                results[operation_index] = found ? 1 : 0;
            } else if (!found) {
                results[operation_index] = 0;
            } else {
                const auto index = static_cast<std::size_t>(map_indices[slot]);
                const auto last = element_count - 1;
                if (index != last) {
                    const auto moved = elements[last];
                    bool moved_found = false;
                    const auto moved_slot = find_slot(map_keys, states, moved, moved_found);
                    if (!moved_found) return -1;
                    elements[index] = moved;
                    map_indices[moved_slot] = static_cast<std::int32_t>(index);
                }
                --element_count;
                states[slot] = 2;
                results[operation_index] = 1;
            }
        } else if (operation == 4) {
            if (argument < 1 || static_cast<std::uint64_t>(argument) > element_count) return -1;
            results[operation_index] = elements[static_cast<std::size_t>(argument) - 1];
        } else return -1;
    }
    if (capacity < output_bytes || (output_bytes > 0 && output == nullptr)) return -2;
    for (std::size_t index = 0; index < operation_count; ++index) {
        const auto bits = static_cast<std::uint64_t>(results[index]);
        for (std::size_t byte = 0; byte < 8; ++byte)
            output[index * 8 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
    }
    return static_cast<std::int64_t>(output_bytes);
}
