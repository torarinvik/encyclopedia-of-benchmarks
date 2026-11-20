#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_capacity = 32;
constexpr std::size_t max_input_length = 35;
constexpr std::int64_t max_key = 1'000'000;
}

extern "C" std::int64_t lcfs_hashing(const std::int64_t* input,
                                      std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    const std::int64_t capacity_value = input[0], count_value = input[1];
    if (capacity_value < 1 || capacity_value > static_cast<std::int64_t>(max_capacity)
            || count_value < 0 || count_value > capacity_value
            || length != static_cast<std::size_t>(count_value) + 2) return -1;
    const auto capacity = static_cast<std::size_t>(capacity_value);
    const auto count = static_cast<std::size_t>(count_value);
    for (std::size_t i = 0; i < count; ++i) {
        const auto key = input[i + 2];
        if (key < 0 || key > max_key) return -1;
        for (std::size_t j = 0; j < i; ++j)
            if (input[j + 2] == key) return -1;
    }

    std::int64_t table[max_capacity];
    for (std::size_t i = 0; i < capacity; ++i) table[i] = -1;
    std::int64_t displacements = 0;
    for (std::size_t i = 0; i < count; ++i) {
        auto incoming = input[i + 2];
        auto slot = static_cast<std::size_t>(incoming % capacity_value);
        std::size_t probes = 0;
        while (table[slot] != -1) {
            if (probes >= capacity) return -1;
            const auto resident = table[slot];
            table[slot] = incoming;
            incoming = resident;
            slot = (slot + 1) % capacity;
            ++probes;
            ++displacements;
        }
        table[slot] = incoming;
    }
    return displacements;
}
