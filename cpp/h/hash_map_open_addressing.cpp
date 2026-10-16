#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_operations = 256, max_keys = 64, max_capacity = 1024;
constexpr std::int64_t value_offset = 1000001;
struct Entry { int state = 0; std::int64_t key = 0, value = 0; };

void place(Entry* table, std::size_t capacity, std::int64_t key, std::int64_t value) {
    std::size_t index = static_cast<std::size_t>(key % static_cast<std::int64_t>(capacity));
    for (std::size_t probe = 0; probe < capacity; ++probe) {
        if (table[index].state != 1) { table[index] = {1, key, value}; return; }
        if (table[index].key == key) { table[index].value = value; return; }
        index = (index + 1) % capacity;
    }
}
void resize_table(Entry* table, std::size_t& capacity, std::size_t next, std::size_t& size) {
    Entry old[max_capacity]{};
    const std::size_t old_capacity = capacity;
    for (std::size_t i = 0; i < old_capacity; ++i) old[i] = table[i];
    for (std::size_t i = 0; i < next; ++i) table[i] = {};
    capacity = next; size = 0;
    for (std::size_t i = 0; i < old_capacity; ++i)
        if (old[i].state == 1) { place(table, next, old[i].key, old[i].value); ++size; }
}
std::size_t find_key(const Entry* table, std::size_t capacity, std::int64_t key,
                     std::size_t& tomb, bool& tomb_before) {
    std::size_t index = static_cast<std::size_t>(key % static_cast<std::int64_t>(capacity));
    tomb = capacity; tomb_before = false;
    for (std::size_t probe = 0; probe < capacity; ++probe) {
        if (table[index].state == 0) return capacity;
        if (table[index].state == 2) { if (tomb == capacity) tomb = index; }
        else if (table[index].key == key) { tomb_before = tomb != capacity; return index; }
        index = (index + 1) % capacity;
    }
    return capacity;
}
}

extern "C" std::int64_t hash_map_open_addressing(const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 1 || length > 769) return -1;
    const std::int64_t q = input[0];
    if (q < 0 || q > static_cast<std::int64_t>(max_operations) || length != 1 + 3 * static_cast<std::size_t>(q)) return -1;
    Entry table[max_capacity]{};
    std::size_t capacity = 8, size = 0;
    std::int64_t query_sum = 0, query_index = 0;
    for (std::size_t opi = 0; opi < static_cast<std::size_t>(q); ++opi) {
        const auto opcode = input[1 + 3 * opi], key = input[2 + 3 * opi], value = input[3 + 3 * opi];
        if (opcode == 0) {
            if (key < 0 || key > 1000000 || value < -1000000 || value > 1000000) return -1;
            std::size_t tomb; bool tomb_before;
            const auto before = find_key(table, capacity, key, tomb, tomb_before);
            if (before == capacity && size >= max_keys) return -1;
            if (size >= capacity * 3 / 4) {
                if (capacity * 2 > max_capacity) return -1;
                resize_table(table, capacity, capacity * 2, size);
            }
            const auto found = find_key(table, capacity, key, tomb, tomb_before);
            if (found != capacity) {
                if (tomb_before) return -1;
                table[found].value = value;
            } else {
                std::size_t index = static_cast<std::size_t>(key % static_cast<std::int64_t>(capacity));
                std::size_t target = tomb;
                for (std::size_t probe = 0; probe < capacity; ++probe) {
                    if (table[index].state == 0) { if (target == capacity) target = index; break; }
                    index = (index + 1) % capacity;
                }
                if (target == capacity) return -1;
                table[target] = {1, key, value}; ++size;
            }
        } else if (opcode == 1 || opcode == 2 || opcode == 3) {
            if (key < 0 || key > 1000000 || value != 0) return -1;
            std::size_t tomb; bool tomb_before;
            const auto found = find_key(table, capacity, key, tomb, tomb_before);
            if ((opcode == 1 || opcode == 2) && found == capacity) return -1;
            if (opcode == 1) { ++query_index; query_sum += query_index * (table[found].value + value_offset); }
            else if (opcode == 2) {
                table[found].state = 2; --size;
                if (capacity > 8 && size < capacity * 3 / 8)
                    resize_table(table, capacity, capacity / 2, size);
            } else { ++query_index; query_sum += query_index * (static_cast<std::int64_t>(found != capacity) + value_offset); }
        } else if (opcode == 4) {
            if (key != 0 || value != 0) return -1;
            ++query_index; query_sum += query_index * (static_cast<std::int64_t>(size) + value_offset);
        } else return -1;
    }
    std::int64_t keys[max_keys], values[max_keys]; std::size_t count = 0;
    for (std::size_t i = 0; i < capacity; ++i) if (table[i].state == 1) {
        std::size_t at = count++;
        while (at > 0 && keys[at - 1] > table[i].key) { keys[at] = keys[at - 1]; values[at] = values[at - 1]; --at; }
        keys[at] = table[i].key; values[at] = table[i].value;
    }
    std::int64_t final_state = 0;
    for (std::size_t i = 0; i < count; ++i) final_state += static_cast<std::int64_t>(i + 1) * (keys[i] + 1) * (values[i] + value_offset);
    return query_sum + final_state + static_cast<std::int64_t>(size);
}
