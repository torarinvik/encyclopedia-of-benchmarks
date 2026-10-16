#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t cursor_space_size = 100;
constexpr std::size_t max_operations = 64;

bool find_value(const std::int64_t elements[cursor_space_size], const bool occupied[cursor_space_size],
                const std::int64_t next[cursor_space_size], std::int64_t head, std::int64_t value,
                std::int64_t &previous, std::int64_t &found) {
    previous = -1;
    found = head;
    while (found != -1 && (!occupied[found] || elements[found] != value)) {
        previous = found;
        found = next[found];
    }
    return found != -1;
}

void free_node(std::int64_t elements[cursor_space_size], bool occupied[cursor_space_size],
               std::int64_t next[cursor_space_size], std::int64_t index) {
    const auto old_free_head = next[0];
    occupied[index] = false;
    elements[index] = 0;
    next[index] = old_free_head;
    next[0] = index;
}

bool remove_value(std::int64_t elements[cursor_space_size], bool occupied[cursor_space_size],
                  std::int64_t next[cursor_space_size], std::int64_t &head, std::int64_t &count,
                  std::int64_t value) {
    std::int64_t previous, current;
    if (head == -1 || !find_value(elements, occupied, next, head, value, previous, current)) return false;
    const auto successor = next[current];
    if (previous == -1) { free_node(elements, occupied, next, current); head = successor; }
    else { next[previous] = successor; free_node(elements, occupied, next, current); }
    --count;
    return true;
}

void put_i64(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t cursor_linked_list(const std::int64_t *input, std::size_t length,
                                              std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 1 || input[0] < 0 || input[0] > static_cast<std::int64_t>(max_operations)) return -1;
    const auto operation_count = static_cast<std::size_t>(input[0]);
    if (length != 1 + 2 * operation_count) return -1;
    std::int64_t elements[cursor_space_size] = {};
    std::int64_t next[cursor_space_size] = {};
    bool occupied[cursor_space_size] = {};
    for (std::size_t i = 0; i < cursor_space_size; ++i) next[i] = static_cast<std::int64_t>(i) + 1;
    next[cursor_space_size - 1] = 0;
    std::int64_t head = -1, count = 0;
    std::int64_t query_found[max_operations] = {}, query_values[max_operations] = {};
    std::size_t query_count = 0;
    for (std::size_t index = 0; index < operation_count; ++index) {
        const auto operation = input[1 + 2 * index], argument = input[2 + 2 * index];
        if (operation < 0 || operation > 4 || argument < INT32_MIN || argument > INT32_MAX) return -1;
        if (operation == 0) {
            const auto available = next[0];
            if (available == 0) return -1;
            next[0] = next[available]; next[available] = -1;
            elements[available] = argument; occupied[available] = true;
            if (head == -1) head = available;
            else { auto tail = head; while (next[tail] != -1) tail = next[tail]; next[tail] = available; }
            next[available] = -1; ++count;
        } else if (operation == 1) {
            if (!remove_value(elements, occupied, next, head, count, argument)) return -1;
        } else if (operation == 2) {
            if (argument < 0 || argument >= count) return -1;
            auto cursor = head; for (std::int64_t i = 0; i < argument; ++i) cursor = next[cursor];
            const auto value = elements[cursor];
            if (!remove_value(elements, occupied, next, head, count, value)) return -1;
        } else if (operation == 3) {
            if (argument >= 0 && argument < count) {
                auto cursor = head; for (std::int64_t i = 0; i < argument; ++i) cursor = next[cursor];
                query_found[query_count] = 1; query_values[query_count++] = elements[cursor];
            } else { query_found[query_count] = 0; query_values[query_count++] = 0; }
        } else {
            std::int64_t previous, found;
            if (find_value(elements, occupied, next, head, argument, previous, found)) {
                std::int64_t logical_index = 0, cursor = head;
                while (cursor != found) { cursor = next[cursor]; ++logical_index; }
                query_found[query_count] = 1; query_values[query_count++] = logical_index;
            } else { query_found[query_count] = 0; query_values[query_count++] = 0; }
        }
    }
    const std::size_t required = (1 + 2 * query_count + 2 + 3 * cursor_space_size) * 8;
    if (output == nullptr || capacity < required) return -2;
    std::size_t field = 0;
    put_i64(output, field++ * 8, static_cast<std::int64_t>(query_count));
    for (std::size_t i = 0; i < query_count; ++i) { put_i64(output, field++ * 8, query_found[i]); put_i64(output, field++ * 8, query_values[i]); }
    put_i64(output, field++ * 8, head); put_i64(output, field++ * 8, count);
    for (std::size_t i = 0; i < cursor_space_size; ++i) { put_i64(output, field++ * 8, occupied[i] ? 1 : 0); put_i64(output, field++ * 8, elements[i]); put_i64(output, field++ * 8, next[i]); }
    return static_cast<std::int64_t>(required);
}
