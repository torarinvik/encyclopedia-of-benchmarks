#include <cstddef>
#include <cstdint>

static void store_i64(std::uint8_t *out, std::size_t offset, std::int64_t value) {
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        out[offset + byte] = static_cast<std::uint8_t>(bits & 255u);
        bits >>= 8;
    }
}

extern "C" std::int64_t maximum_frequency_stack(const std::int64_t *input,
        std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > 130) return -1;
    const std::int64_t count = input[0];
    if (count < 0 || count > 64 || length != 1u + 2u * static_cast<std::size_t>(count)) return -1;
    int frequency[17]{};
    int bucket_top[65];
    for (int &entry : bucket_top) entry = -1;
    int node_value[64]{}, node_next[64]{};
    std::int64_t popped[64]{};
    std::size_t nodes = 0, pop_count = 0, position = 1;
    int maximum_frequency = 0;
    for (std::int64_t operation = 0; operation < count; ++operation) {
        const auto opcode = input[position++];
        const auto argument = input[position++];
        if (opcode == 0) {
            if (argument < -8 || argument > 8) return -1;
            const int index = static_cast<int>(argument) + 8;
            const int next_frequency = ++frequency[index];
            node_value[nodes] = static_cast<int>(argument);
            node_next[nodes] = bucket_top[next_frequency];
            bucket_top[next_frequency] = static_cast<int>(nodes++);
            if (next_frequency > maximum_frequency) maximum_frequency = next_frequency;
        } else if (opcode == 1 && argument == 0) {
            if (maximum_frequency == 0 || bucket_top[maximum_frequency] < 0) return -1;
            const int node = bucket_top[maximum_frequency];
            bucket_top[maximum_frequency] = node_next[node];
            const int value = node_value[node];
            popped[pop_count++] = value;
            --frequency[value + 8];
            if (bucket_top[maximum_frequency] < 0) --maximum_frequency;
        } else return -1;
    }
    const std::size_t needed = pop_count * 8;
    if (needed != 0 && (output == nullptr || capacity < needed)) return -2;
    for (std::size_t i = 0; i < pop_count; ++i) store_i64(output, i * 8, popped[i]);
    return static_cast<std::int64_t>(needed);
}
