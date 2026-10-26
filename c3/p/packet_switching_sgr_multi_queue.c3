module packet_switching_sgr_multi_queue;

const usz MAX_QUEUES = 4;
const usz MAX_SLOTS = 8;
const usz MAX_INPUT = 36;
const usz MAX_OUTPUT_BYTES = 64;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long packet_switching_sgr_multi_queue(long* input, usz length, char* output,
        usz capacity) @export("packet_switching_sgr_multi_queue") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long queue_value = input[0], buffer = input[1], slot_value = input[2];
    if (queue_value < 2 || queue_value > (long)MAX_QUEUES || buffer < 1 || buffer > 4 ||
        slot_value < 1 || slot_value > (long)MAX_SLOTS) return -1;
    usz queues = (usz)queue_value, slots = (usz)slot_value;
    if (length != 3 + queues * slots) return -1;
    long[MAX_QUEUES] load = zeroed, peak = zeroed;
    long[MAX_SLOTS] schedule = zeroed;
    for (usz slot = 0; slot < slots; slot += 1) {
        for (usz queue = 0; queue < queues; queue += 1) {
            long arrivals = input[3 + slot * queues + queue];
            if (arrivals < 0 || arrivals > buffer) return -1;
            load[queue] += arrivals;
            if (load[queue] > buffer) load[queue] = buffer;
            if (load[queue] > peak[queue]) peak[queue] = load[queue];
        }
        bool has_large = false, has_nonempty = false, has_underfull_peak = false;
        for (usz queue = 0; queue < queues; queue += 1) {
            if (load[queue] > 0) {
                has_nonempty = true;
                if (load[queue] > buffer / 2) has_large = true;
                if (peak[queue] < buffer) has_underfull_peak = true;
            }
        }
        if (!has_nonempty) {
            schedule[slot] = -1;
            for (usz queue = 0; queue < queues; queue += 1) peak[queue] = 0;
            continue;
        }
        bool use_history = !has_large && has_underfull_peak;
        usz selected = queues;
        for (usz queue = 0; queue < queues; queue += 1) {
            if (load[queue] == 0 || (use_history && peak[queue] >= buffer)) continue;
            if (selected == queues || load[queue] > load[selected]) selected = queue;
        }
        schedule[slot] = selected.i64();
        load[selected] -= 1;
        bool any_left = false;
        for (usz queue = 0; queue < queues; queue += 1) if (load[queue] > 0) any_left = true;
        if (!any_left) for (usz queue = 0; queue < queues; queue += 1) peak[queue] = 0;
    }
    usz output_bytes = 8 * slots;
    if (output == null || capacity < output_bytes) return -2;
    char[MAX_OUTPUT_BYTES] staged = zeroed;
    for (usz slot = 0; slot < slots; slot += 1) store_i64_le(&staged[0], 8 * slot, schedule[slot]);
    for (usz byte = 0; byte < output_bytes; byte += 1) output[byte] = staged[byte];
    return output_bytes.i64();
}
