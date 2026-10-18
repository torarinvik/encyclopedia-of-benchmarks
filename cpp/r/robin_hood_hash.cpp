#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr std::size_t table_capacity = 16;
constexpr std::size_t max_active_entries = 14;
constexpr std::size_t max_operations = 64;
constexpr std::size_t max_input_length = 1 + 3 * max_operations;
constexpr std::size_t max_output_bytes = 8 * max_operations;
constexpr std::uint32_t max_probe_distance = 64;

struct Entry {
    std::uint32_t key = 0;
    std::uint32_t value = 0;
    std::uint32_t psl = 0;
    bool occupied = false;
};

struct RobinHoodMap {
    Entry entries[table_capacity]{};
    std::size_t count = 0;
};

std::size_t hash_key(std::uint32_t key) {
    const std::uint64_t product = static_cast<std::uint64_t>(key) * UINT64_C(0x9E3779B97F4A7C15);
    return static_cast<std::size_t>((product >> 32) & (table_capacity - 1));
}

void put_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255);
        bits >>= 8;
    }
}

bool map_put(RobinHoodMap& map, std::uint32_t key, std::uint32_t value) {
    if ((map.count * 100) / table_capacity >= 90) return false;
    Entry entry{key, value, 0, true};
    auto index = hash_key(key);
    std::uint32_t probes = 0;
    while (probes < max_probe_distance) {
        auto& resident = map.entries[index];
        if (!resident.occupied) {
            resident = entry;
            ++map.count;
            return true;
        }
        if (resident.key == key) {
            resident.value = value;
            return true;
        }
        if (entry.psl > resident.psl) std::swap(entry, resident);
        ++entry.psl;
        index = (index + 1) & (table_capacity - 1);
        ++probes;
    }
    return false;
}

std::int64_t map_get(const RobinHoodMap& map, std::uint32_t key) {
    auto index = hash_key(key);
    std::uint32_t psl = 0;
    while (psl < max_probe_distance) {
        const auto& resident = map.entries[index];
        if (!resident.occupied) return -1;
        if (resident.key == key) return resident.value;
        if (psl > resident.psl) return -1;
        index = (index + 1) & (table_capacity - 1);
        ++psl;
    }
    return -1;
}

void map_backshift(RobinHoodMap& map, std::size_t start) {
    auto index = start;
    for (std::size_t iteration = 0; iteration < table_capacity; ++iteration) {
        const auto next = (index + 1) & (table_capacity - 1);
        if (!map.entries[next].occupied || map.entries[next].psl == 0) {
            map.entries[index].occupied = false;
            map.entries[index].psl = 0;
            return;
        }
        map.entries[index] = map.entries[next];
        --map.entries[index].psl;
        index = next;
    }
}

bool map_remove(RobinHoodMap& map, std::uint32_t key) {
    auto index = hash_key(key);
    std::uint32_t psl = 0;
    while (psl < max_probe_distance) {
        auto& resident = map.entries[index];
        if (!resident.occupied) return false;
        if (resident.key == key) {
            map_backshift(map, index);
            --map.count;
            return true;
        }
        if (psl > resident.psl) return false;
        index = (index + 1) & (table_capacity - 1);
        ++psl;
    }
    return false;
}

void map_clear(RobinHoodMap& map) {
    for (auto& entry : map.entries) { entry.occupied = false; entry.psl = 0; }
    map.count = 0;
}

std::uint32_t map_max_psl(const RobinHoodMap& map) {
    std::uint32_t maximum = 0;
    for (const auto& entry : map.entries)
        if (entry.occupied && entry.psl > maximum) maximum = entry.psl;
    return maximum;
}
}

extern "C" std::int64_t robin_hood_hash(const std::int64_t* input, std::size_t length,
                                        std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > max_input_length) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_operations)) return -1;
    const auto operation_count = static_cast<std::size_t>(input[0]);
    if (length != 1 + 3 * operation_count) return -1;

    RobinHoodMap map{};
    std::int64_t results[max_operations]{};
    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        const auto offset = 1 + 3 * operation;
        const auto opcode = input[offset];
        const auto raw_key = input[offset + 1];
        const auto raw_value = input[offset + 2];
        if (opcode == 0) {
            if (raw_key < 0 || raw_key > UINT32_MAX || raw_value < 100 || raw_value > 1000000) return -1;
            if (!map_put(map, static_cast<std::uint32_t>(raw_key), static_cast<std::uint32_t>(raw_value))) return -1;
            if (map.count > max_active_entries) return -1;
            results[operation] = -2;
        } else if (opcode == 1 || opcode == 2) {
            if (raw_key < 0 || raw_key > UINT32_MAX || raw_value != 0) return -1;
            const auto key = static_cast<std::uint32_t>(raw_key);
            results[operation] = opcode == 1 ? map_get(map, key) : (map_remove(map, key) ? 1 : 0);
        } else if (opcode >= 3 && opcode <= 7) {
            if (raw_key != 0 || raw_value != 0) return -1;
            if (opcode == 3) results[operation] = static_cast<std::int64_t>(map.count);
            else if (opcode == 4) results[operation] = static_cast<std::int64_t>((map.count * 100) / table_capacity);
            else if (opcode == 5) results[operation] = map_max_psl(map);
            else if (opcode == 6) { map_clear(map); results[operation] = -3; }
            else results[operation] = map.count == 0 ? 1 : 0;
        } else return -1;
    }

    const auto output_bytes = operation_count * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    std::uint8_t staged[max_output_bytes];
    for (std::size_t operation = 0; operation < operation_count; ++operation)
        put_i64_le(staged, operation * 8, results[operation]);
    for (std::size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return static_cast<std::int64_t>(output_bytes);
}
