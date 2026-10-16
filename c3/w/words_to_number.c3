module words_to_number;

const usz MAX_INPUT = 128;
const usz MAX_TOKENS = 128;
const int E_NULL = -3;
const int E_UNKNOWN = -4;
const int E_UNEXPECTED = -5;
const int E_AFTER_POINT = -6;
const int E_MISSING_DECIMAL = -7;
const int E_MULTI_NEGATIVE = -8;
const int E_NEGATIVE = -9;
const int E_CONJUNCTION = -10;

fn bool matches(long* input, usz start, usz end, char* word) {
    usz i = 0;
    while (word[i] != 0) {
        if (start + i >= end) return false;
        int ch = (int)input[1 + start + i];
        if (ch >= 'A' && ch <= 'Z') ch += 32;
        if (ch != (int)word[i]) return false;
        i++;
    }
    return start + i == end;
}
fn int word_id(long* input, usz start, usz end) {
    if (matches(input,start,end,"zero")) return 1;
    if (matches(input,start,end,"one")) return 2;
    if (matches(input,start,end,"two")) return 3;
    if (matches(input,start,end,"three")) return 4;
    if (matches(input,start,end,"four")) return 5;
    if (matches(input,start,end,"five")) return 6;
    if (matches(input,start,end,"six")) return 7;
    if (matches(input,start,end,"seven")) return 8;
    if (matches(input,start,end,"eight")) return 9;
    if (matches(input,start,end,"nine")) return 10;
    if (matches(input,start,end,"ten")) return 11;
    if (matches(input,start,end,"eleven")) return 12;
    if (matches(input,start,end,"twelve")) return 13;
    if (matches(input,start,end,"thirteen")) return 14;
    if (matches(input,start,end,"fourteen")) return 15;
    if (matches(input,start,end,"fifteen")) return 16;
    if (matches(input,start,end,"sixteen")) return 17;
    if (matches(input,start,end,"seventeen")) return 18;
    if (matches(input,start,end,"eighteen")) return 19;
    if (matches(input,start,end,"nineteen")) return 20;
    if (matches(input,start,end,"twenty")) return 21;
    if (matches(input,start,end,"thirty")) return 22;
    if (matches(input,start,end,"forty")) return 23;
    if (matches(input,start,end,"fifty")) return 24;
    if (matches(input,start,end,"sixty")) return 25;
    if (matches(input,start,end,"seventy")) return 26;
    if (matches(input,start,end,"eighty")) return 27;
    if (matches(input,start,end,"ninety")) return 28;
    if (matches(input,start,end,"hundred")) return 29;
    if (matches(input,start,end,"thousand")) return 30;
    if (matches(input,start,end,"million")) return 31;
    if (matches(input,start,end,"billion")) return 32;
    if (matches(input,start,end,"trillion")) return 33;
    if (matches(input,start,end,"and")) return 34;
    if (matches(input,start,end,"point")) return 35;
    if (matches(input,start,end,"negative")) return 36;
    return 0;
}
fn int number_value(int id) { if (id >= 1 && id <= 20) return id - 1; if (id >= 21 && id <= 28) return (id - 19) * 10; return -1; }
fn int digits10(long value) { int n = 1; while (value >= 10) { value /= 10; n++; } return n; }
fn usz append_uint(char* out, usz at, long value) {
    char[24] reversed; usz n = 0;
    while (true) { reversed[n++] = (char)('0' + value % 10); value /= 10; if (value == 0) break; }
    while (n > 0) { n--; out[at++] = reversed[n]; }
    return at;
}
fn bool separator(long c) { return c == 32 || c == 44 || c == 45; }
fn int format_number(long* input, usz byte_count, char* text, usz* text_length) {
    int[MAX_TOKENS] tokens; usz count = 0; usz start = MAX_INPUT + 1;
    for (usz i = 0; i < byte_count; i++) {
        long ch = input[i + 1]; if (ch < 32 || ch > 126) return -1;
        if (separator(ch)) { if (start != MAX_INPUT + 1) { if (count >= MAX_TOKENS) return -1; tokens[count++] = word_id(input,start,i); start = MAX_INPUT + 1; } }
        else if (start == MAX_INPUT + 1) start = i;
    }
    if (start != MAX_INPUT + 1) { if (count >= MAX_TOKENS) return -1; tokens[count++] = word_id(input,start,byte_count); }
    if (count == 0) return E_NULL;
    bool negative = tokens[0] == 36; usz pos = negative ? 1 : 0;
    long[MAX_TOKENS] chunks; usz chunk_count = 0; long current = 0; bool prev_hundred = false; bool prev_scale = false;
    char[16] fraction; usz fraction_len = 0; bool has_point = false;
    for (usz i = pos; i < count; i++) {
        int id = tokens[i];
        if (id == 34) {
            if (i + 1 >= count) return E_CONJUNCTION;
            int next = tokens[i + 1]; int value = number_value(next); int after = i + 2 < count ? tokens[i + 2] : -1;
            if ((!prev_hundred && !prev_scale) || value < 0 || !(value >= 10 || after == -1 || after == 35)) return E_CONJUNCTION;
            continue;
        }
        if (id == 29) { if (current >= 10 || prev_scale) return E_UNEXPECTED; if (current == 0) current = 1; current *= 100; prev_hundred = true; continue; }
        prev_hundred = false;
        if (id >= 30 && id <= 33) {
            if (current == 0 || prev_scale) return E_UNEXPECTED;
            long scale = id == 30 ? 1000 : id == 31 ? 1000000 : id == 32 ? 1000000000 : 1000000000000;
            long next = current * scale;
            if (chunk_count > 0 && digits10(chunks[chunk_count - 1]) <= digits10(next)) return E_UNEXPECTED;
            chunks[chunk_count++] = next; current = 0; prev_scale = true; continue;
        }
        prev_scale = false;
        int value = number_value(id);
        if (value >= 0) { if (value == 0 && !(current == 0 && chunk_count == 0)) return E_UNEXPECTED; if (current != 0 && digits10(current) <= digits10(value)) return E_UNEXPECTED; current += value; continue; }
        if (id == 35) {
            if (current != 0) chunks[chunk_count++] = current;
            current = 0; has_point = true; usz words = 0;
            for (usz j = i + 1; j < count; j++) {
                int digit = number_value(tokens[j]); if (digit < 0) return E_AFTER_POINT;
                words++; if (words > 3) return -1;
                fraction_len = append_uint(fraction,fraction_len,digit);
            }
            if (words == 0) return E_MISSING_DECIMAL;
            break;
        }
        if (id == 36) return negative ? E_MULTI_NEGATIVE : E_NEGATIVE;
        return E_UNKNOWN;
    }
    if (current != 0) chunks[chunk_count++] = current;
    long total = 0; for (usz i = 0; i < chunk_count; i++) total += chunks[i];
    usz out = 0; bool fraction_nonzero = false; for (usz i = 0; i < fraction_len; i++) if (fraction[i] != '0') fraction_nonzero = true;
    if (negative && (total != 0 || fraction_nonzero)) text[out++] = '-';
    out = append_uint(text,out,total);
    if (has_point) { text[out++] = '.'; for (usz i = 0; i < fraction_len; i++) text[out++] = fraction[i]; }
    *text_length = out; return 0;
}
fn long words_to_number(long* input, usz length, char* output, usz capacity) @export("words_to_number") {
    if (input == null || length < 1 || length > MAX_INPUT + 1) return -1;
    long n = input[0]; if (n < 0 || n > MAX_INPUT || length != (usz)n + 1) return -1;
    char[64] text; usz text_length = 0; int status = format_number(input,(usz)n,&text[0],&text_length);
    if (status != 0) return status;
    if (output == null || capacity < text_length) return -2;
    for (usz i = 0; i < text_length; i++) output[i] = text[i];
    return (long)text_length;
}
