module npb_is;

const usz TOTAL_KEYS = 1 << 20;
const usz MAX_KEY = 1 << 16;
const usz NUM_BUCKETS = 1 << 10;
const uint MAX_ITERATIONS = 10;
const usz TEST_COUNT = 5;
const long MAX_PASSES = 10;

uint[1048576] key_array;
uint[1048576] key_buff2;
uint[65536] key_buff1;
uint[1024] bucket_size;
uint[1024] bucket_ptrs;
uint[5] test_indices = {357773, 934767, 875723, 898999, 404505};
uint[5] baseline_ranks = {1249, 11698, 1039987, 1043896, 1048018};

fn ulong next_state(ulong state) {
    ulong two23 = 1ul << 23;
    ulong low_mask = two23 - 1;
    ulong state_mask = (1ul << 46) - 1;
    ulong multiplier_high = 1220703125ul / two23;
    ulong multiplier_low = 1220703125ul % two23;
    ulong x1 = state >> 23;
    ulong x2 = state & low_mask;
    ulong t1 = multiplier_high * x2 + multiplier_low * x1;
    ulong z = t1 & low_mask;
    return ((z << 23) + multiplier_low * x2) & state_mask;
}

fn void generate_keys() {
    ulong state = 314159265ul;
    for (usz index = 0; index < TOTAL_KEYS; index++) {
        ulong four_state_sum = 0;
        for (usz draw = 0; draw < 4; draw++) {
            state = next_state(state);
            four_state_sum += state;
        }
        key_array[index] = (uint)(four_state_sum >> 32);
    }
}

fn uint expected_rank(usz index, uint iteration) {
    if (index < 2) return (uint)((long)baseline_ranks[index] + (long)iteration - 2);
    return baseline_ranks[index] - iteration;
}

fn usz decimal_width(uint value) {
    usz width = 1;
    while (value >= 10) { value /= 10; width++; }
    return width;
}

fn usz append_decimal(uint value, char* output, usz position) {
    char[10] reversed;
    usz count = 0;
    do {
        reversed[count++] = (char)(48 + value % 10);
        value /= 10;
    } while (value != 0);
    while (count > 0) output[position++] = reversed[--count];
    return position;
}

fn usz required_output_bytes(uint pass_count) {
    usz required = 0;
    for (uint iteration = 1; iteration <= pass_count; iteration++) {
        for (usz index = 0; index < TEST_COUNT; index++)
            required += decimal_width(expected_rank(index, iteration));
        required += TEST_COUNT;
    }
    return required + decimal_width(5 * pass_count + 1) + 1;
}

fn void rank_pass(uint iteration, uint[5]* partials) {
    key_array[iteration] = iteration;
    key_array[iteration + MAX_ITERATIONS] = (uint)MAX_KEY - iteration;
    for (usz bucket = 0; bucket < NUM_BUCKETS; bucket++) bucket_size[bucket] = 0;
    for (usz index = 0; index < TOTAL_KEYS; index++) bucket_size[key_array[index] >> 6]++;
    bucket_ptrs[0] = 0;
    for (usz bucket = 1; bucket < NUM_BUCKETS; bucket++)
        bucket_ptrs[bucket] = bucket_ptrs[bucket - 1] + bucket_size[bucket - 1];
    for (usz index = 0; index < TOTAL_KEYS; index++) {
        uint key = key_array[index];
        key_buff2[bucket_ptrs[key >> 6]++] = key;
    }
    for (usz key = 0; key < MAX_KEY; key++) key_buff1[key] = 0;
    for (usz index = 0; index < TOTAL_KEYS; index++) key_buff1[key_buff2[index]]++;
    for (usz key = 1; key < MAX_KEY; key++) key_buff1[key] += key_buff1[key - 1];
    for (usz test = 0; test < TEST_COUNT; test++) {
        uint key = key_array[test_indices[test]];
        (*partials)[test] = key == 0 ? 0 : key_buff1[key - 1];
    }
}

fn bool full_verify() {
    for (usz index = 0; index < TOTAL_KEYS; index++) {
        uint key = key_buff2[index];
        key_array[--key_buff1[key]] = key;
    }
    for (usz index = 1; index < TOTAL_KEYS; index++)
        if (key_array[index - 1] > key_array[index]) return false;
    return true;
}

fn long npb_is(long pass_count, char* output, usz output_capacity) @export("npb_is") {
    if (pass_count < 1 || pass_count > MAX_PASSES) return -1;
    uint passes = (uint)pass_count;
    usz required = required_output_bytes(passes);
    if (output == null || output_capacity < required) return -2;

    generate_keys();
    uint[5] partials;
    rank_pass(1, &partials);
    uint passed_verification = 0;
    usz position = 0;
    for (uint iteration = 1; iteration <= passes; iteration++) {
        rank_pass(iteration, &partials);
        for (usz test = 0; test < TEST_COUNT; test++) {
            if (partials[test] == expected_rank(test, iteration)) passed_verification++;
            position = append_decimal(partials[test], output, position);
            if (test + 1 < TEST_COUNT) output[position++] = ',';
        }
        output[position++] = '\n';
    }
    if (full_verify()) passed_verification++;
    if (passed_verification != 5 * passes + 1) passed_verification = 0;
    position = append_decimal(passed_verification, output, position);
    output[position++] = '\n';
    return (long)position;
}
