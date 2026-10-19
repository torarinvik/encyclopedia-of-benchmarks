/* Integer Sort class-W port from NAS NPB-serial/is. */
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t TOTAL_KEYS = 1u << 20;
constexpr std::size_t MAX_KEY = 1u << 16;
constexpr std::size_t NUM_BUCKETS = 1u << 10;
constexpr std::uint32_t MAX_ITERATIONS = 10;
constexpr std::size_t TEST_COUNT = 5;
constexpr std::int64_t MAX_PASSES = 10;
constexpr std::uint32_t TEST_INDICES[TEST_COUNT] = {
    357773u, 934767u, 875723u, 898999u, 404505u
};
constexpr std::uint32_t BASELINE_RANKS[TEST_COUNT] = {
    1249u, 11698u, 1039987u, 1043896u, 1048018u
};
std::uint32_t key_array[TOTAL_KEYS];
std::uint32_t key_buff2[TOTAL_KEYS];
std::uint32_t key_buff1[MAX_KEY];
std::uint32_t bucket_size[NUM_BUCKETS];
std::uint32_t bucket_ptrs[NUM_BUCKETS];

std::uint64_t next_state(std::uint64_t state)
{
    constexpr std::uint64_t two23 = std::uint64_t{1} << 23;
    constexpr std::uint64_t low_mask = two23 - 1;
    constexpr std::uint64_t state_mask = (std::uint64_t{1} << 46) - 1;
    constexpr std::uint64_t multiplier_high = 1220703125u / two23;
    constexpr std::uint64_t multiplier_low = 1220703125u % two23;
    const std::uint64_t x1 = state >> 23;
    const std::uint64_t x2 = state & low_mask;
    const std::uint64_t t1 = multiplier_high * x2 + multiplier_low * x1;
    const std::uint64_t z = t1 & low_mask;
    return ((z << 23) + multiplier_low * x2) & state_mask;
}

void generate_keys()
{
    std::uint64_t state = 314159265u;
    for (std::size_t index = 0; index < TOTAL_KEYS; ++index) {
        std::uint64_t four_state_sum = 0;
        for (int draw = 0; draw < 4; ++draw) {
            state = next_state(state);
            four_state_sum += state;
        }
        key_array[index] = static_cast<std::uint32_t>(four_state_sum >> 32);
    }
}

std::uint32_t expected_rank(std::size_t index, std::uint32_t iteration)
{
    if (index < 2)
        return static_cast<std::uint32_t>(static_cast<std::int64_t>(BASELINE_RANKS[index]) + iteration - 2);
    return BASELINE_RANKS[index] - iteration;
}

std::size_t decimal_width(std::uint32_t value)
{
    std::size_t width = 1;
    while (value >= 10) { value /= 10; ++width; }
    return width;
}

std::size_t append_decimal(std::uint32_t value, std::uint8_t *output, std::size_t position)
{
    std::uint8_t reversed[10];
    std::size_t count = 0;
    do { reversed[count++] = static_cast<std::uint8_t>('0' + value % 10); value /= 10; }
    while (value != 0);
    while (count > 0) output[position++] = reversed[--count];
    return position;
}

void rank_pass(std::uint32_t iteration, std::uint32_t partials[TEST_COUNT])
{
    key_array[iteration] = iteration;
    key_array[iteration + MAX_ITERATIONS] = static_cast<std::uint32_t>(MAX_KEY) - iteration;
    for (std::size_t bucket = 0; bucket < NUM_BUCKETS; ++bucket) bucket_size[bucket] = 0;
    for (std::size_t index = 0; index < TOTAL_KEYS; ++index) ++bucket_size[key_array[index] >> 6];
    bucket_ptrs[0] = 0;
    for (std::size_t bucket = 1; bucket < NUM_BUCKETS; ++bucket)
        bucket_ptrs[bucket] = bucket_ptrs[bucket - 1] + bucket_size[bucket - 1];
    for (std::size_t index = 0; index < TOTAL_KEYS; ++index) {
        const std::uint32_t key = key_array[index];
        key_buff2[bucket_ptrs[key >> 6]++] = key;
    }
    for (std::size_t key = 0; key < MAX_KEY; ++key) key_buff1[key] = 0;
    for (std::size_t index = 0; index < TOTAL_KEYS; ++index) ++key_buff1[key_buff2[index]];
    for (std::size_t key = 1; key < MAX_KEY; ++key) key_buff1[key] += key_buff1[key - 1];
    for (std::size_t test = 0; test < TEST_COUNT; ++test) {
        const std::uint32_t key = key_array[TEST_INDICES[test]];
        partials[test] = key == 0 ? 0 : key_buff1[key - 1];
    }
}

bool full_verify()
{
    for (std::size_t index = 0; index < TOTAL_KEYS; ++index) {
        const std::uint32_t key = key_buff2[index];
        key_array[--key_buff1[key]] = key;
    }
    for (std::size_t index = 1; index < TOTAL_KEYS; ++index)
        if (key_array[index - 1] > key_array[index]) return false;
    return true;
}
}

extern "C" std::int64_t npb_is(std::int64_t pass_count, std::uint8_t *output,
                                 std::size_t output_capacity) noexcept
{
    if (pass_count < 1 || pass_count > MAX_PASSES) return -1;
    const auto passes = static_cast<std::uint32_t>(pass_count);
    if (output == nullptr) return -2;

    std::uint8_t staged[353];
    generate_keys();
    std::uint32_t partials[TEST_COUNT];
    rank_pass(1, partials);
    std::uint32_t passed_verification = 0;
    std::size_t position = 0;
    for (std::uint32_t iteration = 1; iteration <= passes; ++iteration) {
        rank_pass(iteration, partials);
        std::size_t row_required = TEST_COUNT;
        for (std::size_t test = 0; test < TEST_COUNT; ++test)
            row_required += decimal_width(partials[test]);
        if (position + row_required > sizeof(staged)) return -2;
        for (std::size_t test = 0; test < TEST_COUNT; ++test) {
            if (partials[test] == expected_rank(test, iteration)) ++passed_verification;
            position = append_decimal(partials[test], staged, position);
            if (test + 1 < TEST_COUNT) staged[position++] = ',';
        }
        staged[position++] = '\n';
    }
    if (full_verify()) ++passed_verification;
    if (passed_verification != 5 * passes + 1) passed_verification = 0;
    if (position + decimal_width(passed_verification) + 1 > sizeof(staged)) return -2;
    position = append_decimal(passed_verification, staged, position);
    staged[position++] = '\n';
    if (output_capacity < position) return -2;
    std::memcpy(output, staged, position);
    return static_cast<std::int64_t>(position);
}
