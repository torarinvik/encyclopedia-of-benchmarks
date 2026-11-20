/* Bounded cyclic-label order maintenance; deletion is outside this profile. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_elements = 64;
constexpr int max_operations = 128;
constexpr std::size_t max_input_length = 387;
constexpr std::int64_t label_modulus = 2'147'483'648;
constexpr std::int64_t label_ring = 4'294'967'296;

std::int64_t label_width(std::int64_t left, std::int64_t right) noexcept {
    auto difference = right - left;
    if (difference < 0) difference += label_ring;
    if (difference == 0) return label_modulus;
    return difference > label_modulus ? difference - label_modulus : difference;
}

void insert_after(int anchor, int new_id, std::int64_t* labels,
                  int* previous, int* following) noexcept {
    int successor = following[anchor];
    if (label_width(labels[anchor], labels[successor]) <= 1) {
        int middle = successor;
        int end = following[middle];
        std::int64_t required = 3;
        while (end != anchor && label_width(labels[anchor], labels[end]) <=
               4 * label_width(labels[anchor], labels[middle])) {
            ++required;
            end = following[end];
            if (end == anchor) break;
            ++required;
            end = following[end];
            middle = following[middle];
        }
        const std::int64_t interval = end == anchor ? label_modulus
            : label_width(labels[anchor], labels[end]);
        const std::int64_t spacing = interval / required;
        std::int64_t value = labels[end];
        int cursor = end;
        for (;;) {
            if (cursor == 0) {
                value += label_modulus;
                if (value >= label_ring) value -= label_ring;
            }
            cursor = previous[cursor];
            if (cursor == anchor) break;
            value -= spacing;
            if (value < 0) value += label_ring;
            labels[cursor] = value;
        }
    }
    successor = following[anchor];
    labels[new_id] = labels[anchor] + label_width(labels[anchor], labels[successor]) / 2;
    if (labels[new_id] >= label_ring) labels[new_id] -= label_ring;
    previous[new_id] = anchor;
    following[new_id] = successor;
    following[anchor] = new_id;
    previous[successor] = new_id;
}
}

extern "C" std::int64_t order_maintenance(const std::int64_t* input,
                                            std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    const auto capacity_value = input[0], operation_value = input[1];
    if (capacity_value < 0 || capacity_value > max_elements || operation_value < 0 ||
        operation_value > max_operations || length != 2 + 3 * static_cast<std::size_t>(operation_value))
        return -1;
    const int capacity = static_cast<int>(capacity_value);
    const int operation_count = static_cast<int>(operation_value);
    std::int64_t labels[max_elements + 1]{};
    int previous[max_elements + 1]{}, following[max_elements + 1]{};
    int inserted = 0;
    std::int64_t checksum = 0;
    for (int operation = 0; operation < operation_count; ++operation) {
        const auto offset = 2 + 3 * static_cast<std::size_t>(operation);
        const auto opcode = input[offset], first = input[offset + 1], second = input[offset + 2];
        if (opcode == 0) {
            if (inserted >= capacity || first < 0 || first > inserted || second != inserted + 1)
                return -1;
            ++inserted;
            insert_after(static_cast<int>(first), inserted, labels, previous, following);
        } else if (opcode == 1) {
            if (first < 1 || first > inserted || second < 1 || second > inserted) return -1;
            if (labels[first] < labels[second]) checksum += operation + 1;
        } else return -1;
    }
    return checksum;
}
