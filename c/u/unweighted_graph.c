#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum {
    MAX_INITIAL_NODES = 12,
    MAX_OPERATIONS = 16,
    MAX_KNOWN_IDS = MAX_INITIAL_NODES + 2 * MAX_OPERATIONS,
    MAX_VALID_INPUT_LENGTH = 63,
    MAX_PARSEABLE_INPUT_LENGTH = 64,
    MAX_OUTPUT_WORDS = 81,
    MAX_OUTPUT_BYTES = 648
};

static int find_id(const int64_t ids[MAX_KNOWN_IDS], size_t count, int64_t id)
{
    for (size_t index = 0; index < count; ++index)
        if (ids[index] == id) return (int)index;
    return -1;
}

static int64_t ensure_id(int64_t ids[MAX_KNOWN_IDS], bool declared[MAX_KNOWN_IDS],
                         size_t *count, int64_t id)
{
    int found = find_id(ids, *count, id);
    if (found >= 0) return found;
    if (*count >= MAX_KNOWN_IDS) return -1;
    size_t index = (*count)++;
    ids[index] = id;
    declared[index] = false;
    return (int64_t)index;
}

static bool is_i32(int64_t value)
{
    return value >= INT32_MIN && value <= INT32_MAX;
}

static void write_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (unsigned int byte = 0; byte < 8u; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(0xff));
        bits >>= 8u;
    }
}

int64_t unweighted_graph(const int64_t *input, size_t input_length,
                         uint8_t *output, size_t capacity)
{
    if (input == NULL || input_length < 3u || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if ((input[0] != 0 && input[0] != 1) || input[1] < 0 || input[1] > MAX_INITIAL_NODES ||
        input[2] < 0 || input[2] > MAX_OPERATIONS) return -1;
    bool directed = input[0] == 1;
    size_t initial_count = (size_t)input[1];
    size_t operation_count = (size_t)input[2];
    if (input_length != 3u + initial_count + operation_count * 3u) return -1;

    int64_t ids[MAX_KNOWN_IDS] = {0};
    bool declared[MAX_KNOWN_IDS] = {false};
    bool adjacency[MAX_KNOWN_IDS][MAX_KNOWN_IDS] = {{false}};
    size_t known_count = 0;
    for (size_t index = 0; index < initial_count; ++index) {
        int64_t node = input[3u + index];
        if (!is_i32(node) || find_id(ids, known_count, node) >= 0) return -1;
        int slot = (int)ensure_id(ids, declared, &known_count, node);
        if (slot < 0) return -1;
        declared[slot] = true;
    }

    int64_t result[MAX_OUTPUT_WORDS] = {0};
    size_t result_count = 0;
    size_t operations_offset = 3u + initial_count;
    for (size_t index = 0; index < operation_count; ++index) {
        size_t offset = operations_offset + index * 3u;
        int64_t op = input[offset];
        int64_t first = input[offset + 1u];
        int64_t second = input[offset + 2u];
        if (!is_i32(first) || !is_i32(second)) return -1;
        if (op == 0) {
            if (second != 0) return -1;
            int existing = find_id(ids, known_count, first);
            if (existing >= 0 && declared[existing]) return -1;
            int slot = (int)ensure_id(ids, declared, &known_count, first);
            if (slot < 0) return -1;
            declared[slot] = true;
        } else if (op == 1) {
            int from = find_id(ids, known_count, first);
            if (from < 0 || !declared[from]) return -1;
            int to = find_id(ids, known_count, second);
            if (!directed && (to < 0 || !declared[to])) return -1;
            if (to < 0) to = (int)ensure_id(ids, declared, &known_count, second);
            if (to < 0 || adjacency[from][to]) return -1;
            adjacency[from][to] = true;
            if (!directed) adjacency[to][from] = true;
        } else if (op == 2) {
            if (second != 0) return -1;
            int node = find_id(ids, known_count, first);
            if (node < 0 || !declared[node]) return -1;
            int64_t sorted[MAX_KNOWN_IDS];
            size_t neighbor_count = 0;
            for (size_t neighbor = 0; neighbor < known_count; ++neighbor) {
                if (adjacency[node][neighbor]) sorted[neighbor_count++] = ids[neighbor];
            }
            for (size_t left = 1; left < neighbor_count; ++left) {
                int64_t value = sorted[left];
                size_t right = left;
                while (right > 0 && sorted[right - 1u] > value) {
                    sorted[right] = sorted[right - 1u];
                    --right;
                }
                sorted[right] = value;
            }
            if (result_count + 2u + neighbor_count > MAX_OUTPUT_WORDS) return -1;
            result[result_count++] = first;
            result[result_count++] = (int64_t)neighbor_count;
            for (size_t neighbor = 0; neighbor < neighbor_count; ++neighbor)
                result[result_count++] = sorted[neighbor];
        } else {
            return -1;
        }
    }

    size_t output_bytes = result_count * 8u;
    if (output_bytes > MAX_OUTPUT_BYTES) return -1;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t index = 0; index < result_count; ++index)
        write_i64_le(output, index * 8u, result[index]);
    return (int64_t)output_bytes;
}
