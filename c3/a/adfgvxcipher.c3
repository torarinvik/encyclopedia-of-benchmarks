module adfgvxcipher;

const usz MAX_PLAINTEXT = 256;
const usz MAX_CIPHERTEXT = 512;
const usz MAX_KEY = 16;
const usz MAX_ROWS = 512;
const char[6] LABELS = {'A','D','F','G','V','X'};
const char[36] SQUARE = {
    'N','A','1','C','3','H', '8','T','B','2','O','M',
    'E','5','W','R','P','D', '4','F','6','G','7','I',
    '9','J','0','K','L','Q', 'S','U','V','X','Y','Z'
};

fn int polybius_cell(char value) {
    for (int cell = 0; cell < 36; cell++) if (SQUARE[cell] == value) return cell;
    return -1;
}

fn int label_index(char value) {
    for (int index = 0; index < 6; index++) if (LABELS[index] == value) return index;
    return -1;
}

fn long adfgvxcipher(long* input, usz length, char* output, usz output_capacity)
        @export("adfgvxcipher") {
    if (input == null || length < 3) return -1;
    long mode = input[0], text_length_value = input[1], key_length_value = input[2];
    if ((mode != 0 && mode != 1) || text_length_value < 0 || key_length_value < 1 || key_length_value > (long)MAX_KEY)
        return -1;
    usz text_length = (usz)text_length_value;
    usz key_length = (usz)key_length_value;
    if ((mode == 0 && text_length > MAX_PLAINTEXT) || (mode == 1 && text_length > MAX_CIPHERTEXT) ||
        length != 3 + text_length + key_length) return -1;
    for (usz i = 0; i < text_length; i++) {
        if (input[3 + i] < 0 || input[3 + i] > 127) return -1;
        if (mode == 1 && label_index((char)input[3 + i]) < 0) return -1;
    }
    if (mode == 1 && (text_length & 1) != 0) return -1;
    usz key_start = 3 + text_length;
    for (usz i = 0; i < key_length; i++) {
        if (input[key_start + i] < 'A' || input[key_start + i] > 'Z') return -1;
        for (usz j = 0; j < i; j++) if (input[key_start + i] == input[key_start + j]) return -1;
    }

    usz[MAX_KEY] order;
    for (usz i = 0; i < key_length; i++) order[i] = i;
    for (usz i = 1; i < key_length; i++) {
        usz current = order[i];
        usz position = i;
        while (position > 0 && input[key_start + order[position - 1]] > input[key_start + current]) {
            order[position] = order[position - 1];
            position--;
        }
        order[position] = current;
    }
    char[MAX_CIPHERTEXT] result;
    usz result_length = 0;
    if (mode == 0) {
        char[MAX_CIPHERTEXT] fractionated;
        usz fractionated_length = 0;
        for (usz i = 0; i < text_length; i++) {
            char value = (char)input[3 + i];
            if (value >= 'a' && value <= 'z') value = (char)(value - 'a' + 'A');
            if (!((value >= 'A' && value <= 'Z') || (value >= '0' && value <= '9'))) continue;
            int cell = polybius_cell(value);
            if (cell < 0) return -1;
            fractionated[fractionated_length++] = LABELS[cell / 6];
            fractionated[fractionated_length++] = LABELS[cell % 6];
        }
        usz rows = (fractionated_length + key_length - 1) / key_length;
        char[MAX_ROWS][MAX_KEY] table;
        for (usz row = 0; row < rows; row++)
            for (usz column = 0; column < key_length; column++) table[row][column] = '_';
        for (usz i = 0; i < fractionated_length; i++) table[i / key_length][i % key_length] = fractionated[i];
        for (usz position = 0; position < key_length; position++) {
            usz column = order[position];
            for (usz row = 0; row < rows; row++)
                if (table[row][column] != '_') result[result_length++] = table[row][column];
        }
    } else {
        usz rows = (text_length + key_length - 1) / key_length;
        char[MAX_ROWS][MAX_KEY] table;
        usz source_index = 0;
        for (usz position = 0; position < key_length; position++) {
            usz column = order[position];
            for (usz row = 0; row < rows; row++) {
                if (source_index < text_length) table[row][column] = (char)input[3 + source_index++];
                else table[row][column] = '_';
            }
        }
        char[MAX_CIPHERTEXT] fractionated;
        usz fractionated_length = 0;
        for (usz row = 0; row < rows; row++)
            for (usz column = 0; column < key_length; column++)
                if (table[row][column] != '_') fractionated[fractionated_length++] = table[row][column];
        for (usz i = 0; i < fractionated_length; i += 2) {
            int row = label_index(fractionated[i]);
            int column = label_index(fractionated[i + 1]);
            if (row < 0 || column < 0) return -1;
            result[result_length++] = SQUARE[row * 6 + column];
        }
    }
    if (output_capacity < result_length || (result_length != 0 && output == null)) return -2;
    for (usz i = 0; i < result_length; i++) output[i] = result[i];
    return (long)result_length;
}
