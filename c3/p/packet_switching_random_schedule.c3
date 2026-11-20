module packet_switching_random_schedule;

const usz MAX_QUEUES = 4;
const usz MAX_BUFFER = 4;
const usz MAX_SLOTS = 8;
const usz MAX_PARSEABLE_INPUT = 68;
const usz MAX_OUTPUT_BYTES = 64;
const long MAX_PRIORITY = 4294967295;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long packet_switching_random_schedule(long* input, usz length, char* output,
        usz capacity) @export("packet_switching_random_schedule") {
    if (input == null || length < 3 || length > MAX_PARSEABLE_INPUT) return -1;
    long m_value = input[0], b_value = input[1], t_value = input[2];
    if (m_value < 2 || m_value > (long)MAX_QUEUES || b_value < 1 || b_value > (long)MAX_BUFFER ||
        t_value < 1 || t_value > (long)MAX_SLOTS) return -1;
    usz m = (usz)m_value, b = (usz)b_value, slots = (usz)t_value;
    usz cells = m * slots;
    if (length != 3 + 2 * cells) return -1;
    for (usz cell = 0; cell < cells; cell += 1) {
        long flag = input[3 + cell], priority = input[3 + cells + cell];
        if (flag < 0 || flag > 1 || priority < 0 || priority > MAX_PRIORITY) return -1;
    }
    usz[MAX_QUEUES] load = zeroed, count = zeroed;
    long[MAX_QUEUES][MAX_BUFFER] priorities = zeroed;
    bool[MAX_QUEUES][MAX_BUFFER] marked = zeroed;
    long[MAX_SLOTS] trace = zeroed;
    for (usz slot = 0; slot < slots; slot += 1) {
        for (usz q = 0; q < m; q += 1) {
            usz cell = slot * m + q;
            if (input[3 + cell] == 0 || load[q] == b) continue;
            if (count[q] == b) {
                for (usz i = 1; i < count[q]; i += 1) {
                    priorities[q][i - 1] = priorities[q][i];
                    marked[q][i - 1] = marked[q][i];
                }
                count[q] -= 1;
            }
            priorities[q][count[q]] = input[3 + cells + cell];
            marked[q][count[q]] = false;
            count[q] += 1;
            load[q] += 1;
        }
        usz best_q = m, best_i = 0;
        long best_priority = -1;
        for (usz q = 0; q < m; q += 1) for (usz i = 0; i < count[q]; i += 1) {
            if (marked[q][i]) continue;
            if (best_q == m || priorities[q][i] > best_priority) {
                best_q = q; best_i = i; best_priority = priorities[q][i];
            }
        }
        if (best_q != m) marked[best_q][best_i] = true;
        else {
            best_q = m;
            for (usz q = 0; q < m; q += 1) if (load[q] != 0) { best_q = q; break; }
        }
        if (best_q == m) trace[slot] = -1;
        else { trace[slot] = best_q.i64(); load[best_q] -= 1; }
    }
    usz output_bytes = 8 * slots;
    if (output == null || capacity < output_bytes) return -2;
    char[MAX_OUTPUT_BYTES] staged = zeroed;
    for (usz slot = 0; slot < slots; slot += 1) store_i64_le(&staged[0], 8 * slot, trace[slot]);
    for (usz byte = 0; byte < output_bytes; byte += 1) output[byte] = staged[byte];
    return output_bytes.i64();
}
