module transposition_rust;

const MAX_KEYS = 4;
const MAX_KEY_LENGTH = 32;
const MAX_MESSAGE_LENGTH = 256;
const MAX_INPUT_LENGTH = 3 + MAX_KEYS + MAX_KEYS * MAX_KEY_LENGTH + MAX_MESSAGE_LENGTH;
const MAX_OUTPUT_LENGTH = 2 * MAX_MESSAGE_LENGTH - 1;
const FNV_OFFSET = 14695981039346656037u64;
const FNV_PRIME = 1099511628211u64;
const LOW63_MASK = 0x7fffffffffffffff.u64();

fn bool is_ascii_letter(long value) {
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z');
}

fn usz normalize(char* input, usz length, char* output) {
    usz count = 0;
    for (usz i = 0; i < length; i++) {
        char ch = input[i];
        if (ch >= 'a' && ch <= 'z') ch = (char)(ch - ('a' - 'A'));
        if (ch >= 'A' && ch <= 'Z') { output[count] = ch; count++; }
    }
    return count;
}

fn void column_order(char* key, usz key_length, usz* order) {
    for (usz i = 0; i < key_length; i++) order[i] = i;
    for (usz i = 1; i < key_length; i++) {
        usz column = order[i];
        usz position = i;
        while (position > 0 && key[order[position - 1]] > key[column]) {
            order[position] = order[position - 1];
            position--;
        }
        order[position] = column;
    }
}

fn usz encrypt_round(char* text, usz text_length, char* key, usz key_length, char* output) {
    usz[MAX_KEY_LENGTH] order;
    char[MAX_MESSAGE_LENGTH] columns;
    column_order(key, key_length, &order[0]);
    usz ordered_length = 0;
    for (usz rank = 0; rank < key_length; rank++) {
        for (usz position = order[rank]; position < text_length; position += key_length) {
            columns[ordered_length] = text[position];
            ordered_length++;
        }
    }
    usz group_size = (text_length + key_length - 1) / key_length;
    usz output_length = 0;
    for (usz i = 0; i < ordered_length; i++) {
        output[output_length] = columns[i];
        output_length++;
        if ((i + 1) % group_size == 0 && i + 1 < ordered_length) {
            output[output_length] = ' ';
            output_length++;
        }
    }
    return output_length;
}

fn usz decrypt_round(char* text, usz text_length, char* key, usz key_length, char* output) {
    usz[MAX_KEY_LENGTH] order;
    char[MAX_KEY_LENGTH][MAX_MESSAGE_LENGTH] columns = zeroed;
    usz[MAX_KEY_LENGTH] column_lengths = zeroed;
    column_order(key, key_length, &order[0]);
    usz short_length = text_length / key_length;
    usz longer_columns = text_length % key_length;
    usz cursor = 0;
    for (usz rank = 0; rank < key_length; rank++) {
        usz column = order[rank];
        usz column_length = short_length + (column < longer_columns ? 1 : 0);
        column_lengths[column] = column_length;
        for (usz row = 0; row < column_length; row++) {
            columns[column][row] = text[cursor];
            cursor++;
        }
    }
    usz row_count = short_length + (longer_columns > 0 ? 1 : 0);
    usz output_length = 0;
    for (usz row = 0; row < row_count; row++) {
        for (usz column = 0; column < key_length; column++) {
            if (row < column_lengths[column]) {
                output[output_length] = columns[column][row];
                output_length++;
            }
        }
    }
    return output_length;
}

fn u64 feed_value(u64 hash, u64 value, usz width) {
    for (usz byte = 0; byte < width; byte++) {
        hash = (hash ^ (value & 255u64)) * FNV_PRIME;
        value >>= 8;
    }
    return hash;
}

fn long transposition_rust(long* input, usz length) @export("transposition_rust") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long mode = input[0];
    long key_count_value = input[1];
    if ((mode != 0 && mode != 1) || key_count_value < 1 || key_count_value > MAX_KEYS) return -1;
    usz key_count = (usz)key_count_value;

    char[MAX_KEYS][MAX_KEY_LENGTH] keys = zeroed;
    usz[MAX_KEYS] key_lengths = zeroed;
    usz longest_key = 0;
    usz cursor = 2;
    for (usz key_index = 0; key_index < key_count; key_index++) {
        if (cursor >= length) return -1;
        long key_length_value = input[cursor];
        cursor++;
        if (key_length_value < 1 || key_length_value > MAX_KEY_LENGTH) return -1;
        usz key_length = (usz)key_length_value;
        if (key_length > length - cursor) return -1;
        for (usz i = 0; i < key_length; i++) {
            long value = input[cursor + i];
            if (!is_ascii_letter(value)) return -1;
            char ch = (char)value;
            if (ch >= 'a' && ch <= 'z') ch = (char)(ch - ('a' - 'A'));
            keys[key_index][i] = ch;
        }
        cursor += key_length;
        key_lengths[key_index] = key_length;
        if (key_length > longest_key) longest_key = key_length;
    }
    if (cursor >= length) return -1;
    long message_length_value = input[cursor];
    cursor++;
    if (message_length_value < 1 || message_length_value > MAX_MESSAGE_LENGTH) return -1;
    usz message_length = (usz)message_length_value;
    if (message_length != length - cursor) return -1;

    char[MAX_MESSAGE_LENGTH] message;
    for (usz i = 0; i < message_length; i++) {
        long value = input[cursor + i];
        if (value < 0 || value > 127) return -1;
        message[i] = (char)value;
    }
    char[MAX_OUTPUT_LENGTH] current = zeroed;
    char[MAX_MESSAGE_LENGTH] filtered = zeroed;
    char[MAX_OUTPUT_LENGTH] next = zeroed;
    usz current_length = normalize(&message[0], message_length, &current[0]);
    if (current_length < longest_key) return -1;
    for (usz pass = 0; pass < key_count; pass++) {
        usz key_index = mode == 0 ? pass : key_count - 1 - pass;
        usz filtered_length = normalize(&current[0], current_length, &filtered[0]);
        usz next_length;
        if (mode == 0) {
            next_length = encrypt_round(&filtered[0], filtered_length, &keys[key_index][0], key_lengths[key_index], &next[0]);
        } else {
            next_length = decrypt_round(&filtered[0], filtered_length, &keys[key_index][0], key_lengths[key_index], &next[0]);
        }
        for (usz i = 0; i < next_length; i++) current[i] = next[i];
        current_length = next_length;
    }

    u64 hash = feed_value(FNV_OFFSET, (u64)current_length, 8);
    for (usz i = 0; i < current_length; i++) hash = feed_value(hash, (u64)(uchar)current[i], 4);
    return (long)(hash & LOW63_MASK);
}
