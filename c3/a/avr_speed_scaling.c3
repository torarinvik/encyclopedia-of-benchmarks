module avr_speed_scaling;

const usz AVR_MAX_JOBS = 8;
const usz AVR_MAX_TIME = 8;
const usz AVR_MAX_INPUT = 25;
const usz AVR_MAX_OUTPUT_VALUES = 79;
const usz AVR_MAX_OUTPUT_BYTES = 632;
const long AVR_DENSITY_SCALE = 840;

fn long avr_gcd(long a, long b) {
    while (b != 0) { long r = a % b; a = b; b = r; }
    return a < 0 ? -a : a;
}

fn void avr_store_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long avr_speed_scaling(long* input, usz length, char* output, usz capacity)
        @export("avr_speed_scaling") {
    if (input == null || length < 4 || length > AVR_MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > (long)AVR_MAX_JOBS ||
        length != 1 + 3 * (usz)input[0]) return -1;

    usz jobs = (usz)input[0];
    long[AVR_MAX_JOBS] release = zeroed, deadline = zeroed, remaining = zeroed;
    long[AVR_MAX_TIME + 1] changes = zeroed;
    bool[AVR_MAX_TIME + 1] points = zeroed;
    long[AVR_MAX_JOBS] finish_num = zeroed, finish_den = zeroed;
    bool[AVR_MAX_JOBS] finished = zeroed;

    for (usz j = 0; j < jobs; j += 1) {
        long r = input[1 + 3 * j], d = input[2 + 3 * j], w = input[3 + 3 * j];
        if (r < 0 || r >= d || d > (long)AVR_MAX_TIME || w < 1 || w > 8) return -1;
        release[j] = r; deadline[j] = d;
        long scaled_density = w * (AVR_DENSITY_SCALE / (d - r));
        changes[(usz)r] += scaled_density;
        changes[(usz)d] -= scaled_density;
        points[(usz)r] = true; points[(usz)d] = true;
        remaining[j] = w * AVR_DENSITY_SCALE;
    }

    long[AVR_MAX_OUTPUT_VALUES] values = zeroed;
    usz segment_count = 0;
    long energy_scaled = 0, speed_scaled = 0;
    for (long start = 0; start < (long)AVR_MAX_TIME; start += 1) {
        speed_scaled += changes[(usz)start];
        if (!points[(usz)start]) continue;
        long end = start + 1;
        while (end <= (long)AVR_MAX_TIME && !points[(usz)end]) end += 1;
        if (end > (long)AVR_MAX_TIME || speed_scaled <= 0) continue;

        energy_scaled += speed_scaled * speed_scaled * speed_scaled * (end - start);
        long speed_gcd = avr_gcd(speed_scaled, AVR_DENSITY_SCALE);
        long speed_num = speed_scaled / speed_gcd;
        long speed_den = AVR_DENSITY_SCALE / speed_gcd;
        if (segment_count > 0) {
            usz last = 3 + 4 * (segment_count - 1);
            if (values[last + 1] == start && values[last + 2] == speed_num &&
                values[last + 3] == speed_den) {
                values[last + 1] = end;
            } else {
                usz at = 3 + 4 * segment_count;
                segment_count += 1;
                values[at] = start; values[at + 1] = end;
                values[at + 2] = speed_num; values[at + 3] = speed_den;
            }
        } else {
            usz at = 3 + 4 * segment_count;
            segment_count += 1;
            values[at] = start; values[at + 1] = end;
            values[at + 2] = speed_num; values[at + 3] = speed_den;
        }

        long cursor_scaled = start * speed_scaled;
        long end_scaled = end * speed_scaled;
        while (cursor_scaled < end_scaled) {
            usz selected = jobs;
            for (usz j = 0; j < jobs; j += 1) {
                if (finished[j] || remaining[j] <= 0 || release[j] > start || deadline[j] <= start) continue;
                if (selected == jobs || deadline[j] < deadline[selected]) selected = j;
            }
            if (selected == jobs) break;
            if (cursor_scaled + remaining[selected] <= end_scaled) {
                cursor_scaled += remaining[selected];
                remaining[selected] = 0;
                long common = avr_gcd(cursor_scaled, speed_scaled);
                finish_num[selected] = cursor_scaled / common;
                finish_den[selected] = speed_scaled / common;
                finished[selected] = true;
            } else {
                remaining[selected] -= end_scaled - cursor_scaled;
                cursor_scaled = end_scaled;
            }
        }
    }

    for (usz j = 0; j < jobs; j += 1) if (!finished[j]) return -1;
    long energy_denominator = AVR_DENSITY_SCALE * AVR_DENSITY_SCALE * AVR_DENSITY_SCALE;
    long energy_gcd = avr_gcd(energy_scaled, energy_denominator);
    usz segment_end = 3 + 4 * segment_count;
    values[0] = (long)segment_count;
    values[1] = energy_scaled / energy_gcd;
    values[2] = energy_denominator / energy_gcd;
    usz output_values = segment_end;
    for (usz j = 0; j < jobs; j += 1) {
        values[output_values] = finish_num[j]; output_values += 1;
        values[output_values] = finish_den[j]; output_values += 1;
    }

    usz output_bytes = 8 * output_values;
    if (output == null || capacity < output_bytes) return -2;
    char[AVR_MAX_OUTPUT_BYTES] staged = zeroed;
    for (usz i = 0; i < output_values; i += 1) avr_store_i64(&staged[0], 8 * i, values[i]);
    for (usz i = 0; i < output_bytes; i += 1) output[i] = staged[i];
    return (long)output_bytes;
}
