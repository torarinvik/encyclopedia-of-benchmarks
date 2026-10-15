module baconian_cipher;

const usz MAX_PAYLOAD = 1024;

fn int python_code_for_letter(int upper) {
    if (upper >= 'A' && upper <= 'I') return upper - 'A';
    if (upper == 'J') return 28;
    if (upper >= 'K' && upper <= 'U') return upper - 'A' - 1;
    if (upper == 'V') return 29;
    if (upper >= 'W' && upper <= 'Z') return upper - 'A' - 2;
    return -1;
}

fn int python_letter_for_code(int code) {
    if (code >= 0 && code <= 8) return 'a' + code;
    if (code == 28) return 'j';
    if (code == 29) return 'v';
    if (code >= 9 && code <= 19) return 'a' + code + 1;
    if (code >= 20 && code <= 23) return 'a' + code + 2;
    return -1;
}

fn int decode_code(long* payload, usz start) {
    int code = 0;
    for (usz bit = 0; bit < 5; bit++) code = (code << 1) | (payload[start + bit] == 'B');
    return code;
}

fn usz write_code(char* output, usz position, int code) {
    for (int bit = 4; bit >= 0; bit--) {
        output[position] = (char)(((code >> bit) & 1) != 0 ? 'B' : 'A');
        position++;
    }
    return position;
}

fn long python_decode_length(long* payload, usz length) {
    usz words = 0; usz letters = 0; usz i = 0; usz used = 0;
    int code = 0; bool in_word = false;
    while (i < length) {
        long value = payload[i];
        if (value == ' ') {
            if (used != 0) return -1;
            if (in_word) { words++; in_word = false; }
        } else {
            if (value != 'A' && value != 'B') return -1;
            in_word = true;
            code = (code << 1) | (value == 'B');
            used++;
            if (used == 5) {
                if (python_letter_for_code(code) < 0) return -1;
                letters++; used = 0; code = 0;
            }
        }
        i++;
    }
    if (used != 0) return -1;
    if (in_word) words++;
    return (long)(letters + (words == 0 ? 0 : words - 1));
}

fn long baconian_cipher(long* values, usz length, char* output, usz output_capacity)
        @export("baconian_cipher") {
    if (values == null || length < 2 || length > MAX_PAYLOAD + 2) return -1;
    long mode = values[0]; long dialect = values[1];
    if ((mode != 0 && mode != 1) || dialect < 0 || dialect > 2) return -1;
    usz n = length - 2; long* payload = values + 2;
    for (usz i = 0; i < n; i++) if (payload[i] < 0 || payload[i] > 127) return -1;

    usz output_length = 0;
    if (mode == 0) {
        for (usz i = 0; i < n; i++) {
            int upper = payload[i] >= 'a' && payload[i] <= 'z' ? (int)payload[i] - 32 : (int)payload[i];
            bool is_letter = upper >= 'A' && upper <= 'Z';
            if (dialect == 0) { if (is_letter) output_length += 5; }
            else if (dialect == 1) {
                if (payload[i] == ' ') output_length++;
                else if (is_letter) output_length += 5;
                else return -1;
            } else {
                if (is_letter) { if (upper > 'X') return -1; output_length += 5; }
                else output_length++;
            }
        }
    } else if (dialect == 0) {
        if (n % 5 != 0) return -1;
        for (usz i = 0; i < n; i++) if (payload[i] != 'A' && payload[i] != 'B') return -1;
        for (usz i = 0; i < n; i += 5) if (decode_code(payload, i) > 25) return -1;
        output_length = n / 5;
    } else if (dialect == 1) {
        long decoded_length = python_decode_length(payload, n);
        if (decoded_length < 0) return -1;
        output_length = (usz)decoded_length;
    } else output_length = (n + 4) / 5;
    if (output_capacity < output_length || (output_length > 0 && output == null)) return -2;

    usz write = 0;
    if (mode == 0) {
        for (usz i = 0; i < n; i++) {
            int upper = payload[i] >= 'a' && payload[i] <= 'z' ? (int)payload[i] - 32 : (int)payload[i];
            if (dialect == 0) {
                if (upper >= 'A' && upper <= 'Z') write = write_code(output, write, upper == 'I' ? 9 : upper - 'A');
            } else if (dialect == 1) {
                if (payload[i] == ' ') { output[write] = ' '; write++; }
                else write = write_code(output, write, python_code_for_letter(upper));
            } else {
                if (upper >= 'A' && upper <= 'Z') write = write_code(output, write, upper - 'A');
                else { output[write] = (char)payload[i]; write++; }
            }
        }
    } else if (dialect == 0) {
        for (usz i = 0; i < n; i += 5) {
            int code = decode_code(payload, i);
            output[write] = (char)(code == 8 || code == 9 ? 'I' : 'A' + code); write++;
        }
    } else if (dialect == 1) {
        usz i = 0; bool first_word = true;
        while (i < n) {
            while (i < n && payload[i] == ' ') i++;
            if (i == n) break;
            if (!first_word) { output[write] = ' '; write++; }
            first_word = false;
            while (i < n && payload[i] != ' ') {
                output[write] = (char)python_letter_for_code(decode_code(payload, i));
                write++; i += 5;
            }
        }
    } else {
        usz i = 0;
        while (i < n) {
            if (n - i < 5) { output[write] = ' '; write++; break; }
            int code = 0; bool valid = true;
            for (usz bit = 0; bit < 5; bit++) {
                long value = payload[i + bit];
                if (value != 'A' && value != 'B') valid = false;
                code = (code << 1) | (value == 'B');
            }
            output[write] = (char)(valid && code < 24 ? 'A' + code : ' ');
            write++; i += 5;
        }
    }
    return (long)output_length;
}
