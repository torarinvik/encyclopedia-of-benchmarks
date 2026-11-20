module belady_optimal_paging;

const int MAX_CAPACITY = 8;
const int MAX_REQUESTS = 64;
const int PAGE_COUNT = 16;
const usz MAX_INPUT_LENGTH = 67;
const long CHECKSUM_RADIX = 33281;

fn long belady_optimal_paging(long* input, usz length) @export("belady_optimal_paging") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long capacity_value = input[0], count_value = input[1];
    if (capacity_value < 1 || capacity_value > MAX_CAPACITY || count_value < 0 || count_value > MAX_REQUESTS || length != (usz)(2 + count_value)) return -1;
    usz capacity = (usz)capacity_value, count = (usz)count_value;
    int[MAX_REQUESTS] requests = zeroed;
    for (usz time = 0; time < count; time++) {
        if (input[2 + time] < 0 || input[2 + time] >= PAGE_COUNT) return -1;
        requests[time] = (int)input[2 + time];
    }
    long[MAX_REQUESTS * PAGE_COUNT] next_after = zeroed;
    long[PAGE_COUNT] next_position = zeroed;
    for (int page = 0; page < PAGE_COUNT; page++) next_position[page] = (long)count;
    for (usz time = count; time > 0; time--) {
        usz index = time - 1;
        for (int page = 0; page < PAGE_COUNT; page++) next_after[index * PAGE_COUNT + (usz)page] = next_position[page];
        next_position[requests[index]] = (long)index;
    }

    bool[PAGE_COUNT] resident = zeroed;
    usz resident_count = 0;
    long misses = 0, eviction_checksum = 0;
    for (usz time = 0; time < count; time++) {
        int requested = requests[time];
        if (resident[requested]) continue;
        misses++;
        if (resident_count == capacity) {
            int victim = -1;
            long farthest = -1;
            for (int page = 0; page < PAGE_COUNT; page++) {
                if (!resident[page]) continue;
                long following = next_after[time * PAGE_COUNT + (usz)page];
                if (following > farthest) { victim = page; farthest = following; }
            }
            resident[victim] = false;
            resident_count--;
            eviction_checksum += (long)(time + 1) * (long)(victim + 1);
        }
        resident[requested] = true;
        resident_count++;
    }
    return misses * CHECKSUM_RADIX + eviction_checksum;
}
