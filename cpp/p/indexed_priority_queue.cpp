#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_events = 256;
constexpr std::size_t max_active = 64;
constexpr std::size_t max_input_values = 1538;

void store_i64_le(std::uint8_t *output, std::size_t position, std::int64_t value) noexcept
{
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[position + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}

bool key_in_use(const std::int64_t *heap_ids, const std::int64_t *heap_keys,
                std::size_t size, std::int64_t key, std::int64_t except_id) noexcept
{
    for (std::size_t index = 0; index < size; ++index)
        if (heap_ids[index] != except_id && heap_keys[index] == key) return true;
    return false;
}

bool sift_up(std::int64_t *heap_ids, std::int64_t *heap_keys, std::int32_t *positions,
             std::size_t index) noexcept
{
    const auto item_id = heap_ids[index];
    const auto item_key = heap_keys[index];
    const auto original = index;
    while (index > 0) {
        const auto parent = (index - 1) / 2;
        if (item_key >= heap_keys[parent]) break;
        heap_ids[index] = heap_ids[parent];
        heap_keys[index] = heap_keys[parent];
        positions[heap_ids[index]] = static_cast<std::int32_t>(index);
        index = parent;
    }
    heap_ids[index] = item_id;
    heap_keys[index] = item_key;
    positions[item_id] = static_cast<std::int32_t>(index);
    return index != original;
}

void sift_down(std::int64_t *heap_ids, std::int64_t *heap_keys, std::int32_t *positions,
               std::size_t size, std::size_t index) noexcept
{
    const auto item_id = heap_ids[index];
    const auto item_key = heap_keys[index];
    const auto half = size / 2;
    while (index < half) {
        auto child = index * 2 + 1;
        const auto right = child + 1;
        if (right < size && heap_keys[child] > heap_keys[right]) child = right;
        if (item_key <= heap_keys[child]) break;
        heap_ids[index] = heap_ids[child];
        heap_keys[index] = heap_keys[child];
        positions[heap_ids[index]] = static_cast<std::int32_t>(index);
        index = child;
    }
    heap_ids[index] = item_id;
    heap_keys[index] = item_key;
    positions[item_id] = static_cast<std::int32_t>(index);
}

void remove_at(std::size_t &size, std::int64_t *heap_ids, std::int64_t *heap_keys,
               std::int32_t *positions, std::size_t index) noexcept
{
    const auto new_size = size - 1;
    const auto removed_id = heap_ids[index];
    const auto moved_id = heap_ids[new_size];
    const auto moved_key = heap_keys[new_size];
    size = new_size;
    positions[removed_id] = -1;
    if (index == new_size) return;
    heap_ids[index] = moved_id;
    heap_keys[index] = moved_key;
    positions[moved_id] = static_cast<std::int32_t>(index);
    if (!sift_up(heap_ids, heap_keys, positions, index))
        sift_down(heap_ids, heap_keys, positions, size, index);
}
} // namespace

extern "C" std::int64_t indexed_priority_queue(const std::int64_t *values, std::size_t length,
                                                std::uint8_t *output,
                                                std::size_t output_capacity) noexcept
{
    if (values == nullptr || length < 1 || length > max_input_values) return -1;
    if (values[0] < 0 || values[0] > static_cast<std::int64_t>(max_events)) return -1;
    const auto event_count = static_cast<std::size_t>(values[0]);
    if (length != 1 + 6 * event_count) return -1;
    if (event_count == 0) return 0;

    std::int64_t heap_ids[max_active], heap_keys[max_active];
    std::int32_t positions[max_active];
    std::int64_t records[max_events][6];
    for (auto &position : positions) position = -1;
    std::size_t size = 0;

    for (std::size_t event_index = 0; event_index < event_count; ++event_index) {
        const auto start = 1 + event_index * 6;
        const auto opcode = values[start];
        const auto element_id = values[start + 1];
        const auto key = values[start + 2];
        if (values[start + 3] != 0 || values[start + 4] != 0 || values[start + 5] != 0) return -1;
        std::int64_t status = 1, result_id = 0, result_key = 0;

        if (opcode == 0) {
            if (element_id < 0 || element_id >= static_cast<std::int64_t>(max_active) ||
                key < INT32_MIN || key > INT32_MAX || positions[element_id] >= 0 ||
                size >= max_active || key_in_use(heap_ids, heap_keys, size, key, -1)) return -1;
            heap_ids[size] = element_id;
            heap_keys[size] = key;
            positions[element_id] = static_cast<std::int32_t>(size);
            ++size;
            (void)sift_up(heap_ids, heap_keys, positions, size - 1);
        } else if (opcode == 1 || opcode == 2) {
            if (element_id != 0 || key != 0) return -1;
            if (size == 0) status = 0;
            else {
                result_id = heap_ids[0];
                result_key = heap_keys[0];
                if (opcode == 2) remove_at(size, heap_ids, heap_keys, positions, 0);
            }
        } else if (opcode == 3 || opcode == 4) {
            if (element_id < 0 || element_id >= static_cast<std::int64_t>(max_active) || key != 0) return -1;
            const auto position = positions[element_id];
            status = position >= 0 ? 1 : 0;
            if (opcode == 3 && position >= 0)
                remove_at(size, heap_ids, heap_keys, positions, static_cast<std::size_t>(position));
        } else if (opcode >= 5 && opcode <= 7) {
            if (element_id < 0 || element_id >= static_cast<std::int64_t>(max_active) ||
                key < INT32_MIN || key > INT32_MAX) return -1;
            const auto position = positions[element_id];
            if (position < 0) return -1;
            const auto old_key = heap_keys[position];
            if ((opcode == 6 && key >= old_key) || (opcode == 7 && key <= old_key) ||
                key_in_use(heap_ids, heap_keys, size, key, element_id)) return -1;
            heap_keys[position] = key;
            if (opcode == 6) (void)sift_up(heap_ids, heap_keys, positions, static_cast<std::size_t>(position));
            else if (opcode == 7) sift_down(heap_ids, heap_keys, positions, size, static_cast<std::size_t>(position));
            else if (!sift_up(heap_ids, heap_keys, positions, static_cast<std::size_t>(position)))
                sift_down(heap_ids, heap_keys, positions, size, static_cast<std::size_t>(position));
        } else if (opcode == 8 || opcode == 9 || opcode == 10) {
            if (element_id != 0 || key != 0) return -1;
            if (opcode == 8) {
                for (std::size_t index = 0; index < size; ++index) positions[heap_ids[index]] = -1;
                size = 0;
            } else if (opcode == 9) result_id = static_cast<std::int64_t>(size);
            else result_id = size == 0 ? 1 : 0;
        } else return -1;

        records[event_index][0] = status;
        records[event_index][1] = result_id;
        records[event_index][2] = result_key;
        records[event_index][3] = static_cast<std::int64_t>(size);
        records[event_index][4] = size == 0 ? 0 : heap_ids[0];
        records[event_index][5] = size == 0 ? 0 : heap_keys[0];
    }

    const auto required = event_count * 48;
    if (output == nullptr || output_capacity < required) return -2;
    for (std::size_t event = 0; event < event_count; ++event)
        for (std::size_t field = 0; field < 6; ++field)
            store_i64_le(output, event * 48 + field * 8, records[event][field]);
    return static_cast<std::int64_t>(required);
}
