#include <cstddef>
#include <cstdint>

namespace {
constexpr int MAX_LISTS = 4, MAX_INITIAL_LENGTH = 4, MAX_ITERATIONS = 16;
constexpr int MAX_NODES = 36;

void store_le_i64(std::uint8_t *output, std::size_t offset, std::int64_t value)
{
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8u * byte));
}
}

extern "C" std::int64_t llubenchmark_list_traversal_growth(
    const std::int64_t *input, std::size_t input_length,
    std::uint8_t *output, std::size_t output_capacity)
{
    if (input == nullptr || input_length != 3) return -1;
    const auto list_value = input[0], initial_value = input[1], iteration_value = input[2];
    if (list_value < 1 || list_value > MAX_LISTS ||
        initial_value < 1 || initial_value > MAX_INITIAL_LENGTH ||
        iteration_value < 0 || iteration_value > MAX_ITERATIONS) return -1;
    if (output == nullptr || output_capacity < 16) return -2;

    const int list_count = static_cast<int>(list_value);
    const int initial_length = static_cast<int>(initial_value);
    const int iterations = static_cast<int>(iteration_value);
    std::int64_t next[MAX_NODES], count[MAX_NODES], head[MAX_LISTS], tail[MAX_LISTS];
    for (int i = 0; i < MAX_NODES; ++i) { next[i] = -1; count[i] = 0; }
    for (int i = 0; i < MAX_LISTS; ++i) { head[i] = -1; tail[i] = -1; }
    int allocated = 0;
    for (int level = 0; level < initial_length; ++level) {
        for (int list = 0; list < list_count; ++list) {
            const int node = allocated++;
            next[node] = head[list]; head[list] = node;
            if (tail[list] == -1) tail[list] = node;
        }
    }
    std::int64_t accumulate = 0;
    int growth_milli = 0;
    for (int pass = 0; pass < iterations; ++pass) {
        for (int list = 0; list < list_count; ++list) {
            std::int64_t node = head[list];
            while (node != -1) {
                accumulate += count[node]; ++count[node]; node = next[node];
            }
        }
        growth_milli += 333;
        const int insertions = growth_milli / 1000;
        growth_milli -= insertions * 1000;
        for (int ordinal = insertions; ordinal > 0; --ordinal) {
            for (int list = 0; list < list_count; ++list) {
                const int node = allocated++;
                count[node] = list + ordinal; next[node] = -1;
                next[tail[list]] = node; tail[list] = node;
            }
        }
    }
    store_le_i64(output, 0, accumulate);
    store_le_i64(output, 8, allocated);
    return 2;
}
