module sqrt_tree_constant_time;

const usz MAX_N = 64;
const usz MAX_Q = 64;
const usz MAX_LEVELS = 4;
const usz MAX_INPUT = 195;
const long VALUE_LIMIT = 1000000000;
const long INF = 9223372036854775807;

struct SqrtState {
    long[64] values;
    long[4][64] prefix;
    long[4][64] suffix;
    long[4][64] between;
    usz[65] floor_log;
    usz padded;
    usz layer_count;
    usz[4] segment_bits;
    usz[4] block_bits;
    int[7] layer_for_diff;
}

fn long min_value(long a, long b) { return a < b ? a : b; }

fn void build(SqrtState* state, long* input, usz n) {
    usz padded = 1;
    while (padded < n) padded *= 2;
    state.padded = padded;
    for (usz i = 0; i < n; ++i) state.values[i] = input[2 + i];
    for (usz i = n; i < padded; ++i) state.values[i] = INF;
    state.floor_log[0] = 0; state.floor_log[1] = 0;
    for (usz i = 2; i <= padded; ++i) state.floor_log[i] = state.floor_log[i / 2] + 1;
    for (usz i = 0; i < 7; ++i) state.layer_for_diff[i] = -1;
    usz bits = state.floor_log[padded];
    while (bits > 1) {
        usz level = state.layer_count++;
        usz block_bits = (bits + 1) / 2;
        state.segment_bits[level] = bits;
        state.block_bits[level] = block_bits;
        for (usz bit = block_bits; bit < bits; ++bit) state.layer_for_diff[bit] = (int)level;
        bits = block_bits;
    }
    for (usz level = 0; level < state.layer_count; ++level) {
        usz seg_bits = state.segment_bits[level], blk_bits = state.block_bits[level];
        usz segment_size = (usz)1 << seg_bits, block_size = (usz)1 << blk_bits;
        usz block_count = segment_size / block_size, pair_count = block_count * block_count;
        for (usz base = 0; base < padded; base += segment_size) {
            usz segment_index = base / segment_size;
            for (usz block = 0; block < block_count; ++block) {
                usz start = base + block * block_size, end = start + block_size;
                state.prefix[level][start] = state.values[start];
                for (usz i = start + 1; i < end; ++i)
                    state.prefix[level][i] = min_value(state.prefix[level][i - 1], state.values[i]);
                state.suffix[level][end - 1] = state.values[end - 1];
                usz i = end - 1;
                while (i > start) { --i; state.suffix[level][i] = min_value(state.values[i], state.suffix[level][i + 1]); }
            }
            for (usz left = 0; left < block_count; ++left) {
                long aggregate = INF;
                for (usz right = left; right < block_count; ++right) {
                    usz start = base + right * block_size;
                    aggregate = min_value(aggregate, state.suffix[level][start]);
                    usz slot = segment_index * pair_count + left * block_count + right;
                    state.between[level][slot] = aggregate;
                }
            }
        }
    }
}

fn long query(SqrtState* state, usz left, usz right) {
    if (left == right) return state.values[left];
    usz bit = state.floor_log[left ^ right];
    if (bit == 0) return min_value(state.values[left], state.values[right]);
    usz level = (usz)state.layer_for_diff[bit];
    usz seg_bits = state.segment_bits[level], blk_bits = state.block_bits[level];
    usz segment_size = (usz)1 << seg_bits, block_size = (usz)1 << blk_bits;
    usz base = (left / segment_size) * segment_size, segment_index = base / segment_size;
    usz block_count = segment_size / block_size;
    usz left_block = (left - base) / block_size, right_block = (right - base) / block_size;
    long answer = min_value(state.suffix[level][left], state.prefix[level][right]);
    if (left_block + 1 < right_block) {
        usz pair_count = block_count * block_count;
        usz slot = segment_index * pair_count + (left_block + 1) * block_count + right_block - 1;
        answer = min_value(answer, state.between[level][slot]);
    }
    return answer;
}

fn void put_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; ++byte) { output[offset + byte] = (char)(bits & 255ul); bits >>= 8; }
}

fn long sqrt_tree_constant_time(long* input, usz length, char* output, usz capacity)
    @export("sqrt_tree_constant_time") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > (long)MAX_N || q_value < 0 || q_value > (long)MAX_Q) return -1;
    usz n = (usz)n_value, q = (usz)q_value;
    if (length != 2 + n + 2 * q) return -1;
    for (usz i = 0; i < n; ++i) if (input[2 + i] < -VALUE_LIMIT || input[2 + i] > VALUE_LIMIT) return -1;
    usz query_offset = 2 + n;
    for (usz i = 0; i < q; ++i) {
        long left = input[query_offset + 2 * i], right = input[query_offset + 2 * i + 1];
        if (left < 0 || right < left || right >= n_value) return -1;
    }
    usz required = 8 * q;
    if (capacity < required || (required != 0 && output == null)) return -2;
    SqrtState state = {};
    build(&state, input, n);
    for (usz i = 0; i < q; ++i) {
        usz left = (usz)input[query_offset + 2 * i], right = (usz)input[query_offset + 2 * i + 1];
        put_i64(output, 8 * i, query(&state, left, right));
    }
    return (long)required;
}
