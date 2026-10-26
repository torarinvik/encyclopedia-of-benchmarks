module packet_switching_single_buffer;

const usz MAX_PACKETS = 16;
const usz MAX_SLOTS = 8;
const usz MAX_INPUT = 38;
const usz MAX_OUTPUT_BYTES = 64;
const long BETA = 15;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn void erase_packet(long* ids, long* values, usz* count, usz index) {
    for (usz position = index; position + 1 < *count; position += 1) {
        ids[position] = ids[position + 1];
        values[position] = values[position + 1];
    }
    *count -= 1;
}

long packet_switching_single_buffer(long* input, usz length, char* output,
        usz capacity) @export("packet_switching_single_buffer") {
    if (input == null || length < 5 || length > MAX_INPUT) return -1;
    long mode = input[0], buffer = input[1], beta = input[2], slots_value = input[3], count_value = input[4];
    if (mode < 0 || mode > 2 || buffer < 1 || buffer > 4 || slots_value < 1 || slots_value > (long)MAX_SLOTS ||
        count_value < 0 || count_value > (long)MAX_PACKETS || length != 5 + 2 * (usz)count_value ||
        (mode == 0 ? beta != 0 : beta != BETA)) return -1;
    usz slots = (usz)slots_value, packet_count = (usz)count_value;
    long[MAX_PACKETS] arrival = zeroed, packet_value = zeroed;
    long previous_slot = -1;
    for (usz packet = 0; packet < packet_count; packet += 1) {
        arrival[packet] = input[5 + 2 * packet]; packet_value[packet] = input[6 + 2 * packet];
        if (arrival[packet] < 0 || arrival[packet] >= slots_value || arrival[packet] < previous_slot ||
            packet_value[packet] < 1 || packet_value[packet] > 100) return -1;
        previous_slot = arrival[packet];
    }
    long[MAX_PACKETS] resident_id = zeroed, resident_value = zeroed;
    long[MAX_SLOTS] schedule = zeroed;
    usz resident_count = 0, next_packet = 0;
    for (usz slot = 0; slot < slots; slot += 1) {
        while (next_packet < packet_count && arrival[next_packet] == slot.i64()) {
            long value = packet_value[next_packet];
            usz preempt = resident_count;
            if (mode == 1) {
                for (usz index = 0; index < resident_count; index += 1) {
                    if (resident_value[index] * BETA <= value) { preempt = index; break; }
                }
            } else if (mode == 2) {
                for (usz index = 0; index < resident_count; index += 1) {
                    bool following_ok = index + 1 == resident_count || resident_value[index] <= resident_value[index + 1];
                    if (resident_value[index] * BETA < value && following_ok) { preempt = index; break; }
                }
            }
            if (preempt < resident_count) {
                erase_packet(&resident_id[0], &resident_value[0], &resident_count, preempt);
                resident_id[resident_count] = next_packet.i64(); resident_value[resident_count] = value; resident_count += 1;
            } else if (resident_count < (usz)buffer) {
                resident_id[resident_count] = next_packet.i64(); resident_value[resident_count] = value; resident_count += 1;
            } else {
                long smallest = resident_value[0];
                for (usz index = 1; index < resident_count; index += 1) if (resident_value[index] < smallest) smallest = resident_value[index];
                if (value > smallest) {
                    usz evict = 0;
                    while (resident_value[evict] != smallest) evict += 1;
                    erase_packet(&resident_id[0], &resident_value[0], &resident_count, evict);
                    resident_id[resident_count] = next_packet.i64(); resident_value[resident_count] = value; resident_count += 1;
                }
            }
            next_packet += 1;
        }
        if (resident_count > 0) {
            schedule[slot] = resident_id[0];
            erase_packet(&resident_id[0], &resident_value[0], &resident_count, 0);
        } else schedule[slot] = -1;
    }
    usz output_bytes = 8 * slots;
    if (output == null || capacity < output_bytes) return -2;
    char[MAX_OUTPUT_BYTES] staged = zeroed;
    for (usz slot = 0; slot < slots; slot += 1) store_i64_le(&staged[0], 8 * slot, schedule[slot]);
    for (usz byte = 0; byte < output_bytes; byte += 1) output[byte] = staged[byte];
    return output_bytes.i64();
}
