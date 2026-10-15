module shortest_coprime_segment;

const usz MAX_LENGTH = 128;

fn long gcd_positive(long a, long b) {
    while (b != 0) { long remainder = a % b; a = b; b = remainder; }
    return a;
}

fn void push(long value, long* items, long* aggregates, usz* length) {
    items[*length] = value;
    aggregates[*length] = *length == 0 ? value : gcd_positive(aggregates[*length - 1], value);
    *length += 1;
}

fn long shortest_coprime_segment(long* input, usz length, char* output, usz output_capacity)
    @export("shortest_coprime_segment") {
    if (length > MAX_LENGTH || (length != 0 && input == null)) return -1;
    for (usz i = 0; i < length; i++) if (input[i] < 1 || input[i] > 1000) return -1;
    long front[MAX_LENGTH], front_gcd[MAX_LENGTH], back[MAX_LENGTH], back_gcd[MAX_LENGTH];
    usz front_length = 0, back_length = 0, left = 0, best_start = 0, best_length = length + 1;
    for (usz right = 0; right < length; right++) {
        push(input[right], back, back_gcd, &back_length);
        long window_gcd = gcd_positive(front_length > 0 ? front_gcd[front_length - 1] : 0,
                                       back_length > 0 ? back_gcd[back_length - 1] : 0);
        while (window_gcd == 1) {
            usz current_length = right - left + 1;
            if (current_length < best_length) { best_length = current_length; best_start = left; }
            if (front_length == 0) {
                while (back_length > 0) {
                    long value = back[--back_length];
                    push(value, front, front_gcd, &front_length);
                }
            }
            --front_length;
            ++left;
            window_gcd = gcd_positive(front_length > 0 ? front_gcd[front_length - 1] : 0,
                                      back_length > 0 ? back_gcd[back_length - 1] : 0);
        }
    }
    if (best_length > length) return 0;
    usz byte_count = best_length * 8;
    if (output == null || output_capacity < byte_count) return -2;
    for (usz i = 0; i < best_length; i++) {
        ulong bits = (ulong)input[best_start + i];
        for (usz byte = 0; byte < 8; byte++) output[8 * i + byte] = (char)((bits >> (8 * byte)) & 255);
    }
    return (long)byte_count;
}
