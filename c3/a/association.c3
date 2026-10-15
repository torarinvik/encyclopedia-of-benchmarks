module association;

const usz MAX_ITEMS = 11;
fn usz popcount(uint value) { usz count = 0; while (value != 0) { count += (usz)(value & 1); value >>= 1; } return count; }
fn void put_i64_le(long value, char* output, usz offset) { ulong bits = @bitcast(ulong, value); for (usz b = 0; b < 8; b++) { output[offset+b] = (char)(bits & 255); bits >>= 8; } }

fn long association(long* input, usz length, char* output, usz capacity) @export("association") {
    if (input == null || length < 2 || input[0] < 1 || input[0] > 64 || input[1] < 1 || input[1] > 11) return -1;
    usz transactions = (usz)input[0], items = (usz)input[1];
    if (length != 2 + transactions) return -1;
    uint limit = 1 << items, valid_bits = limit - 1;
    for (usz t = 0; t < transactions; t++) if (input[2+t] < 0 || (ulong)input[2+t] > valid_bits) return -1;
    bool frequent[2048] = {0};
    ulong masks[2047]; long supports[2047]; usz count = 0;
    for (usz size = 1; size <= items; size++) for (uint mask = 1; mask < limit; mask++) {
        if (popcount(mask) != size) continue;
        if (size > 1) { bool ok = true; for (usz bit = 0; bit < items; bit++) if ((mask & (1 << bit)) != 0 && !frequent[mask ^ (1 << bit)]) ok = false; if (!ok) continue; }
        long support = 0; for (usz t = 0; t < transactions; t++) if (((uint)input[2+t] & mask) == mask) support++;
        if (support > 0) { frequent[mask] = true; masks[count] = mask; supports[count] = support; count++; }
    }
    usz required = count * 16;
    if (capacity < required || (required != 0 && output == null)) return -2;
    for (usz i = 0; i < count; i++) { put_i64_le((long)masks[i], output, i*16); put_i64_le(supports[i], output, i*16+8); }
    return (long)required;
}
