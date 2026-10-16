#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_OPERATIONS = 512;
constexpr std::size_t MAX_ITEMS = 128;
constexpr std::size_t ID_CAPACITY = 4096;
constexpr std::size_t MAX_INPUT_LENGTH = 1537;
constexpr std::uint64_t FNV_OFFSET = UINT64_C(0xcbf29ce484222325);
constexpr std::uint64_t FNV_PRIME = UINT64_C(0x100000001b3);

std::uint64_t hash_byte(std::uint64_t hash, std::uint8_t byte) {
    return (hash ^ byte) * FNV_PRIME;
}

std::uint64_t hash_i32(std::uint64_t hash, std::int64_t value) {
    const auto bits = static_cast<std::uint32_t>(value);
    for (unsigned shift = 0; shift < 32; shift += 8)
        hash = hash_byte(hash, static_cast<std::uint8_t>(bits >> shift));
    return hash;
}

void swap_items(std::int64_t *ids, std::int64_t *priorities, int *positions,
                std::size_t first, std::size_t second) {
    auto temporary = ids[first]; ids[first] = ids[second]; ids[second] = temporary;
    temporary = priorities[first]; priorities[first] = priorities[second]; priorities[second] = temporary;
    positions[ids[first]] = static_cast<int>(first);
    positions[ids[second]] = static_cast<int>(second);
}

void heapify_up(std::int64_t *ids, std::int64_t *priorities, int *positions, std::size_t index) {
    while (index > 0) {
        const auto parent = (index - 1) / 2;
        if (priorities[index] <= priorities[parent]) break;
        swap_items(ids, priorities, positions, index, parent);
        index = parent;
    }
}

void heapify_down(std::int64_t *ids, std::int64_t *priorities, int *positions,
                  std::size_t heap_size, std::size_t index) {
    for (;;) {
        auto best = index;
        const auto left = 2 * index + 1;
        const auto right = left + 1;
        if (left < heap_size && priorities[left] > priorities[best]) best = left;
        if (right < heap_size && priorities[right] > priorities[best]) best = right;
        if (best == index) return;
        swap_items(ids, priorities, positions, index, best);
        index = best;
    }
}

void erase_item(std::int64_t *ids, std::int64_t *priorities, int *positions,
                std::size_t &heap_size, std::int64_t item_id) {
    const auto index = static_cast<std::size_t>(positions[item_id]);
    const auto last = heap_size - 1;
    positions[item_id] = -1;
    if (index != last) {
        ids[index] = ids[last];
        priorities[index] = priorities[last];
        positions[ids[index]] = static_cast<int>(index);
    }
    heap_size = last;
    if (index < heap_size) {
        heapify_up(ids, priorities, positions, index);
        heapify_down(ids, priorities, positions, heap_size, index);
    }
}
}

extern "C" std::int64_t heap_generic(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const auto operation_count_value = values[0];
    if (operation_count_value < 0 || operation_count_value > static_cast<std::int64_t>(MAX_OPERATIONS) ||
        length != 1 + 3 * static_cast<std::size_t>(operation_count_value)) return -1;

    std::int64_t ids[MAX_ITEMS] = {};
    std::int64_t priorities[MAX_ITEMS] = {};
    int positions[ID_CAPACITY];
    bool used_ids[ID_CAPACITY] = {};
    for (std::size_t i = 0; i < ID_CAPACITY; ++i) positions[i] = -1;
    std::size_t heap_size = 0;
    std::uint64_t hash = FNV_OFFSET;

    for (std::size_t operation = 0; operation < static_cast<std::size_t>(operation_count_value); ++operation) {
        const auto opcode = values[1 + 3 * operation];
        const auto item_id = values[2 + 3 * operation];
        const auto priority = values[3 + 3 * operation];
        bool present = false;
        std::int64_t returned_id = 0, returned_priority = 0;

        if (opcode == 0) {
            if (item_id < 0 || item_id >= static_cast<std::int64_t>(ID_CAPACITY) ||
                priority < INT32_MIN || priority > INT32_MAX || used_ids[item_id] || heap_size >= MAX_ITEMS) return -1;
            for (std::size_t i = 0; i < heap_size; ++i) if (priorities[i] == priority) return -1;
            used_ids[item_id] = true;
            ids[heap_size] = item_id;
            priorities[heap_size] = priority;
            positions[item_id] = static_cast<int>(heap_size);
            ++heap_size;
            heapify_up(ids, priorities, positions, heap_size - 1);
        } else if (opcode == 1 || opcode == 2) {
            if (item_id != 0 || priority != 0) return -1;
            if (heap_size != 0) {
                present = true;
                returned_id = ids[0];
                returned_priority = priorities[0];
                if (opcode == 2) erase_item(ids, priorities, positions, heap_size, returned_id);
            }
        } else if (opcode == 3) {
            if (item_id < 0 || item_id >= static_cast<std::int64_t>(ID_CAPACITY) ||
                priority < INT32_MIN || priority > INT32_MAX || positions[item_id] < 0) return -1;
            const auto index = static_cast<std::size_t>(positions[item_id]);
            for (std::size_t i = 0; i < heap_size; ++i)
                if (i != index && priorities[i] == priority) return -1;
            priorities[index] = priority;
            heapify_up(ids, priorities, positions, index);
            heapify_down(ids, priorities, positions, heap_size, index);
        } else if (opcode == 4) {
            if (item_id < 0 || item_id >= static_cast<std::int64_t>(ID_CAPACITY) ||
                priority != 0 || positions[item_id] < 0) return -1;
            erase_item(ids, priorities, positions, heap_size, item_id);
        } else return -1;

        hash = hash_byte(hash, static_cast<std::uint8_t>(opcode));
        hash = hash_byte(hash, static_cast<std::uint8_t>(present));
        if (present) {
            hash = hash_i32(hash, returned_id);
            hash = hash_i32(hash, returned_priority);
        }
    }
    return static_cast<std::int64_t>(hash);
}
