/* Replay bounded random_graph edge decisions into a row-major adjacency matrix. */
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 64
#define MAX_PARSEABLE_INPUT_LENGTH 2020
#define MAX_OUTPUT_BYTES (MAX_VERTICES * MAX_VERTICES)
#define DRAW_SCALE INT64_C(9007199254740992)
#define MIN_PROBABILITY_UNITS (-DRAW_SCALE)
#define MAX_PROBABILITY_UNITS (INT64_C(2) * DRAW_SCALE)

int64_t random_graph_generator(const int64_t *input, size_t input_length,
                               uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length < 3 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_VERTICES ||
        (input[1] != 0 && input[1] != 1) ||
        input[2] < MIN_PROBABILITY_UNITS || input[2] > MAX_PROBABILITY_UNITS) return -1;

    const size_t vertex_count = (size_t)input[0];
    const int64_t directed = input[1];
    const int64_t probability_units = input[2];
    const size_t pair_count = vertex_count < 2 ? 0 : vertex_count * (vertex_count - 1) / 2;
    const size_t draw_count = probability_units > 0 && probability_units < DRAW_SCALE ? pair_count : 0;
    if (input_length != 3 + draw_count) return -1;
    for (size_t index = 0; index < draw_count; ++index)
        if (input[3 + index] < 0 || input[3 + index] >= DRAW_SCALE) return -1;

    uint8_t staged[MAX_OUTPUT_BYTES] = {0};
    if (probability_units >= DRAW_SCALE) {
        for (size_t source = 0; source < vertex_count; ++source)
            for (size_t target = 0; target < vertex_count; ++target)
                if (source != target) staged[source * vertex_count + target] = 1;
    } else if (probability_units > 0) {
        size_t draw_index = 0;
        for (size_t source = 0; source < vertex_count; ++source) {
            for (size_t target = source + 1; target < vertex_count; ++target) {
                if (input[3 + draw_index] < probability_units) {
                    staged[source * vertex_count + target] = 1;
                    if (directed == 0) staged[target * vertex_count + source] = 1;
                }
                ++draw_index;
            }
        }
    }

    const size_t output_bytes = vertex_count * vertex_count;
    if (output == NULL || output_capacity < output_bytes) return -2;
    for (size_t index = 0; index < output_bytes; ++index) output[index] = staged[index];
    return (int64_t)output_bytes;
}
