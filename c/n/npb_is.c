/* Integer Sort class-W port from NAS NPB-serial/is. */
#include <stddef.h>
#include <stdint.h>
#include <string.h>

enum {
    TOTAL_KEYS = 1 << 20,
    MAX_KEY = 1 << 16,
    NUM_BUCKETS = 1 << 10,
    MAX_ITERATIONS = 10,
    TEST_COUNT = 5,
    MAX_PASSES = 10
};

static const uint32_t test_indices[TEST_COUNT] = {
    357773u, 934767u, 875723u, 898999u, 404505u
};
static const uint32_t baseline_ranks[TEST_COUNT] = {
    1249u, 11698u, 1039987u, 1043896u, 1048018u
};
static uint32_t key_array[TOTAL_KEYS];
static uint32_t key_buff2[TOTAL_KEYS];
static uint32_t key_buff1[MAX_KEY];
static uint32_t bucket_size[NUM_BUCKETS];
static uint32_t bucket_ptrs[NUM_BUCKETS];

static uint64_t next_state(uint64_t state)
{
    const uint64_t two23 = UINT64_C(1) << 23;
    const uint64_t low_mask = two23 - 1;
    const uint64_t state_mask = (UINT64_C(1) << 46) - 1;
    const uint64_t multiplier_high = UINT64_C(1220703125) / two23;
    const uint64_t multiplier_low = UINT64_C(1220703125) % two23;
    const uint64_t x1 = state >> 23;
    const uint64_t x2 = state & low_mask;
    const uint64_t t1 = multiplier_high * x2 + multiplier_low * x1;
    const uint64_t z = t1 & low_mask;
    return ((z << 23) + multiplier_low * x2) & state_mask;
}

static void generate_keys(void)
{
    uint64_t state = UINT64_C(314159265);
    for (size_t index = 0; index < TOTAL_KEYS; ++index) {
        uint64_t four_state_sum = 0;
        for (int draw = 0; draw < 4; ++draw) {
            state = next_state(state);
            four_state_sum += state;
        }
        key_array[index] = (uint32_t)(four_state_sum >> 32);
    }
}

static uint32_t expected_rank(size_t index, uint32_t iteration)
{
    if (index < 2)
        return (uint32_t)((int64_t)baseline_ranks[index] + (int64_t)iteration - 2);
    return baseline_ranks[index] - iteration;
}

static size_t decimal_width(uint32_t value)
{
    size_t width = 1;
    while (value >= 10) {
        value /= 10;
        ++width;
    }
    return width;
}

static size_t append_decimal(uint32_t value, uint8_t *output, size_t position)
{
    uint8_t reversed[10];
    size_t count = 0;
    do {
        reversed[count++] = (uint8_t)('0' + value % 10);
        value /= 10;
    } while (value != 0);
    while (count > 0) output[position++] = reversed[--count];
    return position;
}

static void rank_pass(uint32_t iteration, uint32_t partials[TEST_COUNT])
{
    key_array[iteration] = iteration;
    key_array[iteration + MAX_ITERATIONS] = MAX_KEY - iteration;

    for (size_t bucket = 0; bucket < NUM_BUCKETS; ++bucket) bucket_size[bucket] = 0;
    for (size_t index = 0; index < TOTAL_KEYS; ++index)
        ++bucket_size[key_array[index] >> 6];

    bucket_ptrs[0] = 0;
    for (size_t bucket = 1; bucket < NUM_BUCKETS; ++bucket)
        bucket_ptrs[bucket] = bucket_ptrs[bucket - 1] + bucket_size[bucket - 1];
    for (size_t index = 0; index < TOTAL_KEYS; ++index) {
        uint32_t key = key_array[index];
        key_buff2[bucket_ptrs[key >> 6]++] = key;
    }

    for (size_t key = 0; key < MAX_KEY; ++key) key_buff1[key] = 0;
    for (size_t index = 0; index < TOTAL_KEYS; ++index) ++key_buff1[key_buff2[index]];
    for (size_t key = 1; key < MAX_KEY; ++key) key_buff1[key] += key_buff1[key - 1];

    for (size_t test = 0; test < TEST_COUNT; ++test) {
        uint32_t key = key_array[test_indices[test]];
        partials[test] = key == 0 ? 0 : key_buff1[key - 1];
    }
}

static int full_verify(void)
{
    for (size_t index = 0; index < TOTAL_KEYS; ++index) {
        uint32_t key = key_buff2[index];
        key_array[--key_buff1[key]] = key;
    }
    for (size_t index = 1; index < TOTAL_KEYS; ++index)
        if (key_array[index - 1] > key_array[index]) return 0;
    return 1;
}

int64_t npb_is(int64_t pass_count, uint8_t *output, size_t output_capacity)
{
    if (pass_count < 1 || pass_count > MAX_PASSES) return -1;
    if (output == NULL) return -2;

    uint8_t staged[353];
    generate_keys();
    uint32_t partials[TEST_COUNT];
    rank_pass(1, partials); /* Untimed source warm-up. */

    uint32_t passed_verification = 0;
    size_t position = 0;
    for (uint32_t iteration = 1; iteration <= (uint32_t)pass_count; ++iteration) {
        rank_pass(iteration, partials);
        size_t row_required = TEST_COUNT;
        for (size_t test = 0; test < TEST_COUNT; ++test)
            row_required += decimal_width(partials[test]);
        if (position + row_required > sizeof(staged)) return -2;
        for (size_t test = 0; test < TEST_COUNT; ++test) {
            if (partials[test] == expected_rank(test, iteration)) ++passed_verification;
            position = append_decimal(partials[test], staged, position);
            if (test + 1 < TEST_COUNT) staged[position++] = ',';
        }
        staged[position++] = '\n';
    }
    if (full_verify()) ++passed_verification;
    if (passed_verification != 5 * (uint32_t)pass_count + 1) passed_verification = 0;
    if (position + decimal_width(passed_verification) + 1 > sizeof(staged)) return -2;
    position = append_decimal(passed_verification, staged, position);
    staged[position++] = '\n';
    if (output_capacity < position) return -2;
    memcpy(output, staged, position);
    return (int64_t)position;
}
