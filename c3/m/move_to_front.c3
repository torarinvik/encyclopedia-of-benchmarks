module move_to_front;

const usz MAX_ALPHABET_LENGTH = 32;
const usz MAX_TEXT_LENGTH = 128;

fn long move_to_front(long* values, usz length, char* output, usz capacity) @export("move_to_front") {
    if (values == null || length < 3 || length > 164) return -1;
    long mode = values[0];
    long alphabet_length = values[1];
    long text_length = values[2];
    if ((mode != 0 && mode != 1) || alphabet_length < 0 || alphabet_length > 32 ||
        text_length < 0 || text_length > 128 || length != 3 + (usz)alphabet_length + (usz)text_length) return -1;
    long[32] alphabet;
    char[128] result;
    for (usz i = 0; i < (usz)alphabet_length; i++) {
        long symbol = values[3 + i];
        if (symbol < 0 || symbol > 127) return -1;
        for (usz j = 0; j < i; j++) if (alphabet[j] == symbol) return -1;
        alphabet[i] = symbol;
    }
    usz result_length = 0;
    if (mode == 0) {
        if (text_length > 0 && alphabet_length == 0) return -1;
        for (usz i = 0; i < (usz)text_length; i++) {
            long symbol = values[3 + (usz)alphabet_length + i];
            if (symbol < 0 || symbol > 127) return -1;
            usz position = 0;
            while (position < (usz)alphabet_length && alphabet[position] != symbol) position++;
            if (position == (usz)alphabet_length) return -1;
            result[result_length] = (char)position; result_length++;
            while (position > 0) { alphabet[position] = alphabet[position - 1]; position--; }
            alphabet[0] = symbol;
        }
    } else if (alphabet_length > 0) {
        for (usz i = 0; i < (usz)text_length; i++) {
            long index = values[3 + (usz)alphabet_length + i];
            if (index < 0 || index >= alphabet_length) return -1;
            long symbol = alphabet[(usz)index];
            result[result_length] = (char)symbol; result_length++;
            usz position = (usz)index;
            while (position > 0) { alphabet[position] = alphabet[position - 1]; position--; }
            alphabet[0] = symbol;
        }
    }
    if (capacity < result_length || (result_length > 0 && output == null)) return -2;
    for (usz i = 0; i < result_length; i++) output[i] = result[i];
    return (long)result_length;
}
