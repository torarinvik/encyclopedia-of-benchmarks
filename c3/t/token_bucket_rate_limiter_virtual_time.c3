module token_bucket_rate_limiter_virtual_time;

const long MAX_CAPACITY = 64L;
const long MAX_RATE = 32L;
const long MAX_REQUESTS = 63L;
const long MAX_TICKS = 256L;
const long MAX_INPUT = 66L;

fn long token_bucket_rate_limiter_virtual_time(long* input, usz length) @export("token_bucket_rate_limiter_virtual_time") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long capacity = input[0], rate = input[1], request_count = input[2];
    if (capacity < 0 || capacity > MAX_CAPACITY || rate < 0 || rate > MAX_RATE ||
        request_count < 0 || request_count > MAX_REQUESTS || length != 3 + (usz)request_count) return -1;
    usz q = (usz)request_count;
    for (usz i = 0; i < q; i++)
        if (input[3 + i] < 0 || input[3 + i] > MAX_TICKS) return -1;

    long tokens = capacity;
    ulong allowed = 0;
    for (usz i = 0; i < q; i++) {
        tokens += input[3 + i] * rate;
        if (tokens > capacity) tokens = capacity;
        if (tokens > 0) {
            allowed |= 1ul << i;
            tokens--;
        }
    }
    return (long)allowed;
}
