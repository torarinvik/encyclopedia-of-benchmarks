#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxInitialNodes = 12;
constexpr std::size_t MaxOperations = 16;
constexpr std::size_t MaxKnownIds = MaxInitialNodes + 2 * MaxOperations;
constexpr std::size_t MaxParseableInputLength = 64;
constexpr std::size_t MaxOutputWords = 81;
constexpr std::size_t MaxOutputBytes = 648;

int find_id(const std::array<std::int64_t, MaxKnownIds>& ids, std::size_t count, std::int64_t id)
{
    for (std::size_t index = 0; index < count; ++index)
        if (ids[index] == id) return static_cast<int>(index);
    return -1;
}

int ensure_id(std::array<std::int64_t, MaxKnownIds>& ids,
              std::array<bool, MaxKnownIds>& declared, std::size_t& count, std::int64_t id)
{
    const int found = find_id(ids, count, id);
    if (found >= 0) return found;
    if (count >= MaxKnownIds) return -1;
    const std::size_t index = count++;
    ids[index] = id;
    declared[index] = false;
    return static_cast<int>(index);
}

bool is_i32(std::int64_t value)
{
    return value >= INT32_MIN && value <= INT32_MAX;
}

void write_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value)
{
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (unsigned int byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 0xffu);
        bits >>= 8u;
    }
}
}

extern "C" std::int64_t unweighted_graph(const std::int64_t* input, std::size_t input_length,
                                          std::uint8_t* output, std::size_t capacity)
{
    if (input == nullptr || input_length < 3 || input_length > MaxParseableInputLength) return -1;
    if ((input[0] != 0 && input[0] != 1) || input[1] < 0 || input[1] > static_cast<std::int64_t>(MaxInitialNodes) ||
        input[2] < 0 || input[2] > static_cast<std::int64_t>(MaxOperations)) return -1;
    const bool directed = input[0] == 1;
    const std::size_t initial_count = static_cast<std::size_t>(input[1]);
    const std::size_t operation_count = static_cast<std::size_t>(input[2]);
    if (input_length != 3 + initial_count + operation_count * 3) return -1;

    std::array<std::int64_t, MaxKnownIds> ids{};
    std::array<bool, MaxKnownIds> declared{};
    std::array<std::array<bool, MaxKnownIds>, MaxKnownIds> adjacency{};
    std::size_t known_count = 0;
    for (std::size_t index = 0; index < initial_count; ++index) {
        const std::int64_t node = input[3 + index];
        if (!is_i32(node) || find_id(ids, known_count, node) >= 0) return -1;
        const int slot = ensure_id(ids, declared, known_count, node);
        if (slot < 0) return -1;
        declared[static_cast<std::size_t>(slot)] = true;
    }

    std::array<std::int64_t, MaxOutputWords> result{};
    std::size_t result_count = 0;
    const std::size_t operations_offset = 3 + initial_count;
    for (std::size_t index = 0; index < operation_count; ++index) {
        const std::size_t offset = operations_offset + index * 3;
        const std::int64_t op = input[offset];
        const std::int64_t first = input[offset + 1];
        const std::int64_t second = input[offset + 2];
        if (!is_i32(first) || !is_i32(second)) return -1;
        if (op == 0) {
            if (second != 0) return -1;
            const int existing = find_id(ids, known_count, first);
            if (existing >= 0 && declared[static_cast<std::size_t>(existing)]) return -1;
            const int slot = ensure_id(ids, declared, known_count, first);
            if (slot < 0) return -1;
            declared[static_cast<std::size_t>(slot)] = true;
        } else if (op == 1) {
            const int from = find_id(ids, known_count, first);
            if (from < 0 || !declared[static_cast<std::size_t>(from)]) return -1;
            int to = find_id(ids, known_count, second);
            if (!directed && (to < 0 || !declared[static_cast<std::size_t>(to)])) return -1;
            if (to < 0) to = ensure_id(ids, declared, known_count, second);
            if (to < 0 || adjacency[static_cast<std::size_t>(from)][static_cast<std::size_t>(to)]) return -1;
            adjacency[static_cast<std::size_t>(from)][static_cast<std::size_t>(to)] = true;
            if (!directed) adjacency[static_cast<std::size_t>(to)][static_cast<std::size_t>(from)] = true;
        } else if (op == 2) {
            if (second != 0) return -1;
            const int node = find_id(ids, known_count, first);
            if (node < 0 || !declared[static_cast<std::size_t>(node)]) return -1;
            std::array<std::int64_t, MaxKnownIds> sorted{};
            std::size_t neighbor_count = 0;
            for (std::size_t neighbor = 0; neighbor < known_count; ++neighbor)
                if (adjacency[static_cast<std::size_t>(node)][neighbor]) sorted[neighbor_count++] = ids[neighbor];
            for (std::size_t left = 1; left < neighbor_count; ++left) {
                const std::int64_t value = sorted[left];
                std::size_t right = left;
                while (right > 0 && sorted[right - 1] > value) {
                    sorted[right] = sorted[right - 1];
                    --right;
                }
                sorted[right] = value;
            }
            if (result_count + 2 + neighbor_count > MaxOutputWords) return -1;
            result[result_count++] = first;
            result[result_count++] = static_cast<std::int64_t>(neighbor_count);
            for (std::size_t neighbor = 0; neighbor < neighbor_count; ++neighbor)
                result[result_count++] = sorted[neighbor];
        } else {
            return -1;
        }
    }

    const std::size_t output_bytes = result_count * 8;
    if (output_bytes > MaxOutputBytes) return -1;
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t index = 0; index < result_count; ++index)
        write_i64_le(output, index * 8, result[index]);
    return static_cast<std::int64_t>(output_bytes);
}
