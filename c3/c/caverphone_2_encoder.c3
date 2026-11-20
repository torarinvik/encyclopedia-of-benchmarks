module caverphone_2_encoder;

const usz MAX_TEXT = 64;
const usz SCRATCH = 128;
const usz CODE_BYTES = 10;

fn bool replace_all(char* text, usz* length, char* old, usz old_len, char* replacement, usz replacement_len) {
    char[SCRATCH] next;
    usz out = 0;
    for (usz i = 0; i < *length;) {
        usz j = 0;
        while (j < old_len && i + j < *length && text[i + j] == old[j]) j++;
        if (j == old_len) {
            if (out + replacement_len >= SCRATCH) return false;
            for (j = 0; j < replacement_len; j++) next[out++] = replacement[j];
            i += old_len;
        } else {
            if (out + 1 >= SCRATCH) return false;
            next[out++] = text[i++];
        }
    }
    for (usz i = 0; i < out; i++) text[i] = next[i];
    *length = out;
    return true;
}

fn void replace_prefix(char* text, usz* length, char* old, usz old_len, char* replacement, usz replacement_len) {
    if (*length < old_len) return;
    for (usz i = 0; i < old_len; i++) if (text[i] != old[i]) return;
    usz tail = *length - old_len;
    for (usz i = tail; i > 0; i--) text[replacement_len + i - 1] = text[old_len + i - 1];
    for (usz i = 0; i < replacement_len; i++) text[i] = replacement[i];
    *length = replacement_len + tail;
}

fn void replace_suffix(char* text, usz* length, char* old, usz old_len, char* replacement, usz replacement_len) {
    if (*length < old_len) return;
    usz start = *length - old_len;
    for (usz i = 0; i < old_len; i++) if (text[start + i] != old[i]) return;
    for (usz i = 0; i < replacement_len; i++) text[start + i] = replacement[i];
    *length = start + replacement_len;
}

fn void replace_char(char* text, usz length, char old, char replacement) {
    for (usz i = 0; i < length; i++) if (text[i] == old) text[i] = replacement;
}

fn void squeeze(char* text, usz* length, char letter, char marker) {
    usz out = 0;
    for (usz i = 0; i < *length; i++) {
        if (text[i] == letter && out > 0 && text[out - 1] == marker) continue;
        text[out++] = text[i] == letter ? marker : text[i];
    }
    *length = out;
}

fn void encode(long* input, char* result) {
    char[SCRATCH] text;
    usz n = (usz)input[0];
    for (usz i = 0; i < n; i++) {
        long c = input[i + 1];
        text[i] = (char)(c >= 'A' && c <= 'Z' ? c + ('a' - 'A') : c);
    }
    if (n == 0) { for (usz i = 0; i < CODE_BYTES; i++) result[i] = '1'; return; }
    if (text[n - 1] == 'e') n--;
    replace_prefix(&text[0], &n, "cough", 5, "cou2f", 5);
    replace_prefix(&text[0], &n, "rough", 5, "rou2f", 5);
    replace_prefix(&text[0], &n, "tough", 5, "tou2f", 5);
    replace_prefix(&text[0], &n, "enough", 6, "enou2f", 6);
    replace_prefix(&text[0], &n, "trough", 6, "trou2f", 6);
    replace_prefix(&text[0], &n, "gn", 2, "2n", 2);
    replace_suffix(&text[0], &n, "mb", 2, "m2", 2);
    replace_all(&text[0], &n, "cq", 2, "2q", 2); replace_all(&text[0], &n, "ci", 2, "si", 2);
    replace_all(&text[0], &n, "ce", 2, "se", 2); replace_all(&text[0], &n, "cy", 2, "sy", 2);
    replace_all(&text[0], &n, "tch", 3, "2ch", 3);
    replace_char(&text[0], n, 'c', 'k'); replace_char(&text[0], n, 'q', 'k');
    replace_char(&text[0], n, 'x', 'k'); replace_char(&text[0], n, 'v', 'f');
    replace_all(&text[0], &n, "dg", 2, "2g", 2); replace_all(&text[0], &n, "tio", 3, "sio", 3);
    replace_all(&text[0], &n, "tia", 3, "sia", 3); replace_char(&text[0], n, 'd', 't');
    replace_all(&text[0], &n, "ph", 2, "fh", 2); replace_char(&text[0], n, 'b', 'p');
    replace_all(&text[0], &n, "sh", 2, "s2", 2); replace_char(&text[0], n, 'z', 's');
    if (n > 0 && (text[0]=='a'||text[0]=='e'||text[0]=='i'||text[0]=='o'||text[0]=='u')) text[0] = 'A';
    for (usz i = 0; i < n; i++) if (text[i]=='a'||text[i]=='e'||text[i]=='i'||text[i]=='o'||text[i]=='u') text[i]='3';
    replace_char(&text[0], n, 'j', 'y'); replace_prefix(&text[0], &n, "y3", 2, "Y3", 2);
    replace_prefix(&text[0], &n, "y", 1, "A", 1); replace_char(&text[0], n, 'y', '3');
    replace_all(&text[0], &n, "3gh3", 4, "3kh3", 4); replace_all(&text[0], &n, "gh", 2, "22", 2);
    replace_char(&text[0], n, 'g', 'k');
    squeeze(&text[0], &n, 's', 'S'); squeeze(&text[0], &n, 't', 'T'); squeeze(&text[0], &n, 'p', 'P');
    squeeze(&text[0], &n, 'k', 'K'); squeeze(&text[0], &n, 'f', 'F'); squeeze(&text[0], &n, 'm', 'M'); squeeze(&text[0], &n, 'n', 'N');
    replace_all(&text[0], &n, "w3", 2, "W3", 2); replace_all(&text[0], &n, "wh3", 3, "Wh3", 3);
    replace_suffix(&text[0], &n, "w", 1, "3", 1); replace_char(&text[0], n, 'w', '2');
    replace_prefix(&text[0], &n, "h", 1, "A", 1); replace_char(&text[0], n, 'h', '2');
    replace_all(&text[0], &n, "r3", 2, "R3", 2); replace_suffix(&text[0], &n, "r", 1, "3", 1); replace_char(&text[0], n, 'r', '2');
    replace_all(&text[0], &n, "l3", 2, "L3", 2); replace_suffix(&text[0], &n, "l", 1, "3", 1); replace_char(&text[0], n, 'l', '2');
    usz out = 0; for (usz i = 0; i < n; i++) if (text[i] != '2') text[out++] = text[i]; n = out;
    replace_suffix(&text[0], &n, "3", 1, "A", 1);
    out = 0; for (usz i = 0; i < n; i++) if (text[i] != '3') text[out++] = text[i]; n = out;
    for (usz i = 0; i < CODE_BYTES; i++) result[i] = i < n ? text[i] : '1';
}

fn long caverphone_2_encoder(long* input, usz length, char* output, usz output_capacity)
    @export("caverphone_2_encoder")
{
    if (input == null || length < 1 || length > MAX_TEXT + 1) return -1;
    long count = input[0];
    if (count < 0 || count > (long)MAX_TEXT || length != (usz)count + 1) return -1;
    for (usz i = 0; i < (usz)count; i++) {
        long c = input[i + 1];
        if (!((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z'))) return -1;
    }
    if (output == null || output_capacity < CODE_BYTES) return -2;
    char[CODE_BYTES] result;
    encode(input, &result[0]);
    for (usz i = 0; i < CODE_BYTES; i++) output[i] = result[i];
    return (long)CODE_BYTES;
}
