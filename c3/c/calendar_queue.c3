module calendar_queue;

const int MAX_OPS = 128, MAX_LIVE = 64, MAX_BUCKETS = 64;
const long MAX_PRIORITY = 1000000;
const usz MAX_INPUT = 258;
const usz PRIORITY_BASE = 0, ID_BASE = 64, NEXT_BASE = 128, ACTIVE_BASE = 192;
const usz HEAD_BASE = 256, BUCKET_COUNT = 320, LIVE = 321, NEXT_ID = 322;
const usz LAST_PRIORITY = 323, LAST_BUCKET = 324, WIDTH_NUM = 325, WIDTH_DEN = 326;
const usz TOP_NUM = 327, TOP_DEN = 328, STATE_SIZE = 329;

fn bool cq_less(long* state, usz a, usz b) {
    long ap = state[PRIORITY_BASE + a], bp = state[PRIORITY_BASE + b];
    return ap < bp || (ap == bp && state[ID_BASE + a] < state[ID_BASE + b]);
}

fn long cq_gcd(long a, long b) {
    while (b != 0) { long r = a % b; a = b; b = r; }
    return a;
}

fn usz cq_virtual(long priority, long num, long den) {
    return (usz)(priority * den / num);
}

fn void cq_reset(long* state, long priority) {
    usz buckets = (usz)state[BUCKET_COUNT];
    usz virtual_index = cq_virtual(priority, state[WIDTH_NUM], state[WIDTH_DEN]);
    state[LAST_BUCKET] = (long)(virtual_index % buckets);
    state[TOP_NUM] = (2 * (long)virtual_index + 3) * state[WIDTH_NUM];
    state[TOP_DEN] = 2 * state[WIDTH_DEN];
}

fn void cq_insert(long* state, usz slot) {
    usz buckets = (usz)state[BUCKET_COUNT];
    usz bucket = cq_virtual(state[PRIORITY_BASE + slot], state[WIDTH_NUM], state[WIDTH_DEN]) % buckets;
    usz previous = MAX_LIVE, current = (usz)state[HEAD_BASE + bucket];
    while (current != MAX_LIVE && cq_less(state, current, slot)) {
        previous = current;
        current = (usz)state[NEXT_BASE + current];
    }
    state[NEXT_BASE + slot] = (long)current;
    if (previous == MAX_LIVE) state[HEAD_BASE + bucket] = (long)slot;
    else state[NEXT_BASE + previous] = (long)slot;
}

fn void cq_new_width(long* state, long* scratch) {
    long[64] ordered;
    usz count = 0;
    for (usz slot = 0; slot < MAX_LIVE; slot++) {
        if (state[ACTIVE_BASE + slot] == 0) continue;
        usz at = count;
        while (at > 0 && cq_less(state, slot, (usz)ordered[at-1])) { ordered[at] = ordered[at-1]; at--; }
        ordered[at] = (long)slot;
        count++;
    }
    if (count < 2) { scratch[64] = 1; scratch[65] = 1; return; }
    usz samples = count <= 5 ? count : 5 + count / 10;
    if (samples > 25) samples = 25;
    usz gaps = samples - 1;
    long sum = 0;
    for (usz i = 0; i < gaps; i++) sum += state[PRIORITY_BASE + (usz)ordered[i+1]] - state[PRIORITY_BASE + (usz)ordered[i]];
    if (sum == 0) { scratch[64] = 1; scratch[65] = 1; return; }
    long kept_sum = 0, kept = 0;
    for (usz i = 0; i < gaps; i++) {
        long gap = state[PRIORITY_BASE + (usz)ordered[i+1]] - state[PRIORITY_BASE + (usz)ordered[i]];
        if (gap * (long)gaps <= 2 * sum) { kept_sum += gap; kept++; }
    }
    if (kept_sum == 0 || kept == 0) { scratch[64] = 1; scratch[65] = 1; return; }
    long numerator = 3 * kept_sum, divisor = cq_gcd(numerator, kept);
    scratch[64] = numerator / divisor;
    scratch[65] = kept / divisor;
}

fn void cq_resize(long* state, long* scratch, usz buckets) {
    cq_new_width(state, scratch);
    state[BUCKET_COUNT] = (long)buckets;
    state[WIDTH_NUM] = scratch[64];
    state[WIDTH_DEN] = scratch[65];
    for (usz i = 0; i < MAX_BUCKETS; i++) state[HEAD_BASE + i] = MAX_LIVE;
    cq_reset(state, state[LAST_PRIORITY]);
    for (usz slot = 0; slot < MAX_LIVE; slot++) if (state[ACTIVE_BASE + slot] != 0) cq_insert(state, slot);
}

fn bool cq_enqueue(long* state, long* scratch, long priority) {
    if (priority < 0 || priority > MAX_PRIORITY || priority < state[LAST_PRIORITY] || state[LIVE] == MAX_LIVE) return false;
    usz slot = MAX_LIVE;
    for (usz i = 0; i < MAX_LIVE; i++) if (state[ACTIVE_BASE + i] == 0) { slot = i; break; }
    if (slot == MAX_LIVE) return false;
    state[PRIORITY_BASE + slot] = priority;
    state[ID_BASE + slot] = state[NEXT_ID];
    state[NEXT_ID]++;
    state[NEXT_BASE + slot] = MAX_LIVE;
    state[ACTIVE_BASE + slot] = 1;
    state[LIVE]++;
    cq_insert(state, slot);
    if (state[LIVE] > 2 * state[BUCKET_COUNT]) cq_resize(state, scratch, (usz)(2 * state[BUCKET_COUNT]));
    return true;
}

fn bool cq_dequeue(long* state, long* scratch, long* result) {
    if (state[LIVE] == 0) return false;
    usz bucket = (usz)state[LAST_BUCKET], buckets = (usz)state[BUCKET_COUNT];
    while (true) {
        usz slot = (usz)state[HEAD_BASE + bucket];
        if (slot != MAX_LIVE && state[PRIORITY_BASE + slot] * state[TOP_DEN] < state[TOP_NUM]) {
            result[0] = state[ID_BASE + slot];
            result[1] = state[PRIORITY_BASE + slot];
            state[HEAD_BASE + bucket] = state[NEXT_BASE + slot];
            state[ACTIVE_BASE + slot] = 0;
            state[LIVE]--;
            state[LAST_BUCKET] = (long)bucket;
            state[LAST_PRIORITY] = result[1];
            if (buckets > 2 && state[LIVE] < (long)(buckets / 2) - 2) cq_resize(state, scratch, buckets / 2);
            return true;
        }
        bucket = (bucket + 1) % buckets;
        state[TOP_NUM] += 2 * state[WIDTH_NUM];
        if (bucket == (usz)state[LAST_BUCKET]) {
            usz minimum = MAX_LIVE;
            for (usz i = 0; i < buckets; i++) {
                usz head = (usz)state[HEAD_BASE + i];
                if (head != MAX_LIVE && (minimum == MAX_LIVE || cq_less(state, head, minimum))) minimum = head;
            }
            if (minimum == MAX_LIVE) return false;
            state[LAST_PRIORITY] = state[PRIORITY_BASE + minimum];
            cq_reset(state, state[LAST_PRIORITY]);
            bucket = (usz)state[LAST_BUCKET];
        }
    }
}

fn void cq_put_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (char)(bits & 255ul); bits >>= 8; }
}

fn long calendar_queue(long* input, usz length, char* output, usz capacity)
    @export("calendar_queue") {
    if (input == null || length < 1 || length > MAX_INPUT) return -1;
    long count0 = input[0];
    if (count0 < 0 || count0 > MAX_OPS || length != (usz)(1 + 2 * count0)) return -1;
    usz count = (usz)count0;
    long[329] state = {0}; long[66] scratch = {0}; long[256] trace = {0};
    state[BUCKET_COUNT] = 2; state[WIDTH_NUM] = 1; state[WIDTH_DEN] = 1;
    state[TOP_NUM] = 3; state[TOP_DEN] = 2;
    for (usz i = 0; i < MAX_BUCKETS; i++) state[HEAD_BASE + i] = MAX_LIVE;
    usz dequeued = 0;
    for (usz step = 0; step < count; step++) {
        long opcode = input[1 + 2 * step], argument = input[2 + 2 * step];
        if (opcode == 1) {
            if (!cq_enqueue(&state[0], &scratch[0], argument)) return -1;
        } else if (opcode == 2) {
            if (argument != 0) return -1;
            long[2] event;
            if (!cq_dequeue(&state[0], &scratch[0], &event[0])) return -1;
            trace[2 * dequeued] = event[0]; trace[2 * dequeued + 1] = event[1]; dequeued++;
        } else return -1;
    }
    usz bytes = (1 + 2 * dequeued) * 8;
    if (output == null || capacity < bytes) return -2;
    cq_put_i64(output, 0, (long)dequeued);
    for (usz word = 0; word < 2 * dequeued; word++) cq_put_i64(output, (word + 1) * 8, trace[word]);
    return (long)bytes;
}
