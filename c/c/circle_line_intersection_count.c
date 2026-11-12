#include <stddef.h>
#include <stdint.h>

#define MAX_Q 32u
#define MAX_INPUT_LENGTH (4u + 3u * MAX_Q + 1u)
#define MAX_OUTPUT_BYTES (8u * MAX_Q)

static void write_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0u; byte < 8u; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8u * byte));
}

int64_t circle_line_intersection_count(const int64_t *input, size_t length,
                                       uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 4u || length > MAX_INPUT_LENGTH) return -1;
    const int64_t center_x = input[0], center_y = input[1];
    const int64_t radius = input[2], query_value = input[3];
    if (center_x < -1000 || center_x > 1000 || center_y < -1000 || center_y > 1000 ||
        radius < 0 || radius > 1000 || query_value < 0 || query_value > (int64_t)MAX_Q) return -1;
    const size_t query_count = (size_t)query_value;
    if (length != 4u + 3u * query_count) return -1;

    int64_t a_values[MAX_Q], b_values[MAX_Q], c_values[MAX_Q];
    for (size_t query = 0u; query < query_count; ++query) {
        const int64_t a = input[4u + 3u * query];
        const int64_t b = input[5u + 3u * query];
        const int64_t c = input[6u + 3u * query];
        if (a < -100 || a > 100 || b < -100 || b > 100 || (a == 0 && b == 0) ||
            c < -200000 || c > 200000) return -1;
        a_values[query] = a;
        b_values[query] = b;
        c_values[query] = c;
    }
    const size_t needed = 8u * query_count;
    if (needed > 0u && (output == NULL || capacity < needed)) return -2;

    uint8_t staged[MAX_OUTPUT_BYTES];
    for (size_t query = 0u; query < query_count; ++query) {
        const int64_t a = a_values[query], b = b_values[query], c = c_values[query];
        const int64_t offset = a * center_x + b * center_y + c;
        const int64_t normal_squared = a * a + b * b;
        const int64_t discriminant = radius * radius * normal_squared - offset * offset;
        const int64_t count = discriminant > 0 ? 2 : (discriminant == 0 ? 1 : 0);
        write_i64_le(staged, 8u * query, count);
    }
    for (size_t byte = 0u; byte < needed; ++byte) output[byte] = staged[byte];
    return (int64_t)needed;
}
