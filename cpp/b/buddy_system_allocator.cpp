#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t arena = 256;
constexpr std::size_t max_order = 8;
constexpr std::size_t max_operations = 64;
constexpr std::size_t max_ids = 32;
constexpr std::size_t max_input_words = 194;
constexpr std::size_t max_output_words = 3 * max_operations + 1 + 2 * arena;
}

extern "C" std::int64_t buddy_system_allocator(
    const std::int64_t* values, std::size_t length,
    std::uint8_t* output, std::size_t capacity) {
    if (values == nullptr || length < 1 || length > max_input_words) return -1;
    const auto raw_count = values[0];
    if (raw_count < 0 || raw_count > static_cast<std::int64_t>(max_operations)
        || length != 1 + 3 * static_cast<std::size_t>(raw_count)) return -1;
    const auto count = static_cast<std::size_t>(raw_count);

    std::array<std::array<bool, arena>, max_order + 1> free_blocks{};
    std::array<bool, max_ids> active{};
    std::array<std::uint16_t, max_ids> allocation_base{};
    std::array<std::uint8_t, max_ids> allocation_order{};
    std::array<std::int64_t, max_output_words> staged{};
    free_blocks[max_order][0] = true;
    std::size_t staged_words = 0;

    for (std::size_t i = 0; i < count; ++i) {
        const auto opcode = values[1 + 3 * i];
        const auto raw_id = values[2 + 3 * i];
        const auto argument = values[3 + 3 * i];
        if (raw_id < 0 || raw_id >= static_cast<std::int64_t>(max_ids)) return -1;
        const auto id = static_cast<std::size_t>(raw_id);
        if (opcode == 0) {
            if (argument < 1 || argument > static_cast<std::int64_t>(arena) || active[id]) return -1;
            std::size_t target = 0, rounded = 1;
            while (rounded < static_cast<std::size_t>(argument)) { rounded <<= 1; ++target; }
            std::size_t found_order = max_order + 1, found_base = arena;
            for (std::size_t order = target; order <= max_order; ++order) {
                const auto size = std::size_t{1} << order;
                for (std::size_t base = 0; base + size <= arena; base += size) {
                    if (free_blocks[order][base]) { found_order = order; found_base = base; break; }
                }
                if (found_order <= max_order) break;
            }
            if (found_order > max_order) {
                staged[staged_words++] = 0; staged[staged_words++] = -1; staged[staged_words++] = 0;
                continue;
            }
            free_blocks[found_order][found_base] = false;
            while (found_order > target) {
                --found_order;
                const auto half = std::size_t{1} << found_order;
                free_blocks[found_order][found_base + half] = true;
            }
            active[id] = true;
            allocation_base[id] = static_cast<std::uint16_t>(found_base);
            allocation_order[id] = static_cast<std::uint8_t>(target);
            staged[staged_words++] = 1;
            staged[staged_words++] = static_cast<std::int64_t>(found_base);
            staged[staged_words++] = static_cast<std::int64_t>(std::size_t{1} << target);
        } else if (opcode == 1) {
            if (argument != 0 || !active[id]) return -1;
            const auto original_base = static_cast<std::size_t>(allocation_base[id]);
            const auto original_order = static_cast<std::size_t>(allocation_order[id]);
            const auto original_size = std::size_t{1} << original_order;
            active[id] = false;
            auto base = original_base;
            auto order = original_order;
            while (order < max_order) {
                const auto buddy = base ^ (std::size_t{1} << order);
                if (!free_blocks[order][buddy]) break;
                free_blocks[order][buddy] = false;
                if (buddy < base) base = buddy;
                ++order;
            }
            free_blocks[order][base] = true;
            staged[staged_words++] = 1;
            staged[staged_words++] = static_cast<std::int64_t>(original_base);
            staged[staged_words++] = static_cast<std::int64_t>(original_size);
        } else {
            return -1;
        }
    }

    staged[staged_words++] = 0;
    const auto count_index = staged_words - 1;
    for (std::size_t base = 0; base < arena; ++base) {
        for (std::size_t order = max_order + 1; order > 0;) {
            --order;
            if (free_blocks[order][base]) {
                staged[count_index] += 1;
                staged[staged_words++] = static_cast<std::int64_t>(base);
                staged[staged_words++] = static_cast<std::int64_t>(std::size_t{1} << order);
                break;
            }
        }
    }
    const auto required = staged_words * 8;
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t i = 0; i < staged_words; ++i) {
        const auto word = static_cast<std::uint64_t>(staged[i]);
        for (std::size_t byte = 0; byte < 8; ++byte)
            output[8 * i + byte] = static_cast<std::uint8_t>(word >> (8 * byte));
    }
    return static_cast<std::int64_t>(required);
}
