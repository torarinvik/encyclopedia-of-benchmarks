#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_nodes = 64;
constexpr std::size_t max_operations = 64;
constexpr std::size_t max_record_fields = 5000;

void rotate_list(const std::int64_t *next, const std::int64_t *previous, std::int64_t &head,
                 std::int64_t size, std::int64_t places) {
    if (size == 0) return;
    places %= size;
    if (places < 0) places += size;
    if (places > size / 2) { places = size - places; for (std::int64_t i = 0; i < places; ++i) head = previous[head]; }
    else { for (std::int64_t i = 0; i < places; ++i) head = next[head]; }
}

bool delete_head(std::int64_t *values, std::int64_t *next, std::int64_t *previous,
                 std::int64_t &head, std::int64_t &size) {
    if (size == 0) return false;
    const auto current = head;
    if (size == 1) head = -1;
    else {
        const auto successor = next[current], predecessor = previous[current];
        next[predecessor] = successor; previous[successor] = predecessor; head = successor;
    }
    values[current] = 0; --size;
    return true;
}

void add_record(std::int64_t *records, std::size_t &field_count, std::int64_t value) { records[field_count++] = value; }
void put_i64(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t cyclic(const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 1 || input[0] < 0 || input[0] > static_cast<std::int64_t>(max_operations)) return -1;
    const auto operation_count = static_cast<std::size_t>(input[0]);
    if (length != 1 + 2 * operation_count) return -1;
    std::int64_t values[max_nodes] = {}, next[max_nodes] = {}, previous[max_nodes] = {};
    std::int64_t head = -1, size = 0, allocated = 0;
    std::int64_t records[max_record_fields];
    std::size_t record_fields = 0, query_count = 0;
    for (std::size_t index = 0; index < operation_count; ++index) {
        const auto operation = input[1 + 2 * index], argument = input[2 + 2 * index];
        if (operation < 0 || operation > 5) return -1;
        if (operation == 0) {
            if (argument < INT32_MIN || argument > INT32_MAX || allocated >= static_cast<std::int64_t>(max_nodes)) return -1;
            const auto node = allocated++; values[node] = argument;
            if (size == 0) { head = node; next[node] = node; previous[node] = node; }
            else { const auto tail = previous[head]; previous[node] = tail; next[node] = head; next[tail] = node; previous[head] = node; }
            ++size;
        } else if (operation == 1) {
            if (argument < -1000000 || argument > 1000000) return -1;
            rotate_list(next, previous, head, size, argument);
        } else if (operation == 2) {
            if (argument != 0) return -1;
            const auto deleted = delete_head(values, next, previous, head, size) ? 1 : 0;
            add_record(records, record_fields, static_cast<std::int64_t>(index)); add_record(records, record_fields, operation);
            add_record(records, record_fields, 1); add_record(records, record_fields, deleted); ++query_count;
        } else if (operation == 3) {
            if (argument != 0) return -1;
            add_record(records, record_fields, static_cast<std::int64_t>(index)); add_record(records, record_fields, operation); add_record(records, record_fields, size);
            auto cursor = head; for (std::int64_t i = 0; i < size; ++i) { add_record(records, record_fields, values[cursor]); cursor = next[cursor]; }
            ++query_count;
        } else if (operation == 4) {
            if (argument < -1000000 || argument > 1000000 || size == 0) return -1;
            while (size > 1) { rotate_list(next, previous, head, size, argument); (void)delete_head(values, next, previous, head, size); rotate_list(next, previous, head, size, -1); }
            const auto winner = values[head]; while (delete_head(values, next, previous, head, size)) {}
            add_record(records, record_fields, static_cast<std::int64_t>(index)); add_record(records, record_fields, operation);
            add_record(records, record_fields, 1); add_record(records, record_fields, winner); ++query_count;
        } else {
            if (argument != 0) return -1;
            while (delete_head(values, next, previous, head, size)) {}
        }
    }
    const auto required = (1 + record_fields + 1 + static_cast<std::size_t>(size)) * 8;
    if (output == nullptr || capacity < required) return -2;
    std::size_t field = 0; put_i64(output, field++ * 8, static_cast<std::int64_t>(query_count));
    for (std::size_t i = 0; i < record_fields; ++i) put_i64(output, field++ * 8, records[i]);
    put_i64(output, field++ * 8, size);
    auto cursor = head; for (std::int64_t i = 0; i < size; ++i) { put_i64(output, field++ * 8, values[cursor]); cursor = next[cursor]; }
    return static_cast<std::int64_t>(required);
}
