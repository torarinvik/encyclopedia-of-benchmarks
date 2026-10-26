#include <stddef.h>
#include <stdint.h>

#define MAX_RAYS 5
#define MAX_ROUNDS 32
#define MAX_INPUT 11

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 255U);
        bits >>= 8;
    }
}

int64_t randomized_ray_search(const int64_t *input, size_t length,
                              uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 5 || length > MAX_INPUT) return -1;
    const int64_t rays_raw = input[0], growth = input[1], initial = input[2];
    if (rays_raw < 2 || rays_raw > MAX_RAYS || growth < 2 || growth > 4
        || initial < 1000 || initial >= growth * 1000 || length != (size_t)rays_raw + 5) return -1;
    const int rays = (int)rays_raw;
    int permutation[MAX_RAYS], seen[MAX_RAYS] = {0};
    for (int i = 0; i < rays; ++i) {
        const int64_t ray = input[3 + i];
        if (ray < 0 || ray >= rays || seen[ray]) return -1;
        permutation[i] = (int)ray;
        seen[ray] = 1;
    }
    const int64_t target_raw = input[3 + rays], target_distance = input[4 + rays];
    if (target_raw < 0 || target_raw >= rays || target_distance < 1 || target_distance > 1000000000) return -1;
    int64_t distance = initial, total = 0, staged[2];
    int64_t attempts = 0;
    int found = 0;
    for (int round = 0; round < MAX_ROUNDS; ++round) {
        const int ray = permutation[round % rays];
        ++attempts;
        if (ray == target_raw && target_distance <= distance) {
            total += target_distance;
            found = 1;
            break;
        }
        total += 2 * distance;
        distance *= growth;
    }
    if (!found) return -1;
    staged[0] = attempts; staged[1] = total;
    if (output == NULL || capacity < 16) return -2;
    for (size_t word = 0; word < 2; ++word) store_i64_le(output, word * 8, staged[word]);
    return 16;
}
