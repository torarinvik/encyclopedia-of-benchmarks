module lfsr;
const usz MAX_TAPS = 63;
const usz MAX_CLOCKS = 256;
fn void put_i64(char* output, usz slot, long value) { ulong bits = (ulong)value; for (usz i = 0; i < 8; i++) output[slot * 8 + i] = (char)(bits >> (i * 8)); }
fn ulong feedback(ulong state, long* taps, usz count) { ulong bit = 0; for (usz i = 0; i < count; i++) bit ^= (state >> (usz)taps[i]) & 1; return bit; }
fn ulong step(ulong* state, usz width, ulong mask, long* taps, usz count) { ulong out = (*state >> (width - 1)) & 1; *state = ((*state << 1) | feedback(*state, taps, count)) & mask; return out; }
fn long lfsr(long* input, usz length, char* output, usz capacity) @export("lfsr") {
 if (input == null || length < 6 || input[0] < 1 || input[0] > 63 || input[1] < 0 || input[1] >= input[0] || input[2] < 0 || input[2] > 63 || input[3] < 0 || input[3] > 256 || input[5] < 0 || input[5] > 4194303) return -1;
 usz width = (usz)input[0], count = (usz)input[2], clocks = (usz)input[3]; if (length != 6 + count) return -1; long* taps = input + 6; for (usz i = 0; i < count; i++) if (taps[i] < 0 || (usz)taps[i] >= width) return -1;
 ulong mask = (((ulong)1) << width) - 1, state = 0, key = (ulong)input[4], frame = (ulong)input[5]; for (long bit = 63; bit >= 0; bit--) state = ((state << 1) | ((((key >> (usz)bit) & 1) ^ feedback(state, taps, count)) & 1)) & mask; for (long bit = 21; bit >= 0; bit--) state = ((state << 1) | ((((frame >> (usz)bit) & 1) ^ feedback(state, taps, count)) & 1)) & mask;
 usz bytes = (clocks + 2) * 8; if (output == null || capacity < bytes) return -2; put_i64(output, 0, (long)clocks); for (usz i = 0; i < clocks; i++) put_i64(output, 1 + i, (long)step(&state, width, mask, taps, count)); put_i64(output, 1 + clocks, (long)state); return (long)bytes;
}
