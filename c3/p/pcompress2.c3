module pcompress2;

// Independent port of the bounded FreeBench pcompress2 algorithm; upstream license grant not found.

const usz MAX_LENGTH = 32;
const usz MAX_OUTPUT = 8 + MAX_LENGTH * 16;
const int SYMBOLS = 257;

struct BitWriter { u8* bytes; usz length; uint buffer; int bits_to_go; }

fn bool rotation_less(u8* input, usz n, usz left, usz right) {
    for (usz offset = 0; offset < n; offset++) {
        u8 a = input[(left + offset) % n]; u8 b = input[(right + offset) % n];
        if (a != b) return a < b;
    }
    return left < right;
}
fn void output_bit(BitWriter* writer, int bit) {
    writer.buffer >>= 1; if (bit != 0) writer.buffer |= 0x80;
    writer.bits_to_go--;
    if (writer.bits_to_go == 0) { writer.bytes[writer.length++] = (u8)writer.buffer; writer.bits_to_go = 8; }
}
fn void bit_plus_follow(BitWriter* writer, int bit, int* follow) {
    output_bit(writer, bit);
    while (*follow > 0) { output_bit(writer, 1 - bit); (*follow)--; }
}
fn void encode_symbol(int symbol, int* cum, uint* low, uint* high, int* follow, BitWriter* writer) {
    ulong span = (ulong)(*high - *low) + 1;
    uint old_low = *low;
    *high = old_low + (uint)(span * (ulong)cum[symbol - 1] / (ulong)cum[0]) - 1;
    *low = old_low + (uint)(span * (ulong)cum[symbol] / (ulong)cum[0]);
    while (true) {
        if (*high < 32768) bit_plus_follow(writer, 0, follow);
        else if (*low >= 32768) { bit_plus_follow(writer, 1, follow); *low -= 32768; *high -= 32768; }
        else if (*low >= 16384 && *high < 49152) { (*follow)++; *low -= 16384; *high -= 16384; }
        else break;
        *low *= 2; *high = *high * 2 + 1;
    }
}
fn void update_model(int symbol, int* char_to_index, u8* index_to_char, int* freq, int* cum) {
    if (cum[0] == 16383) {
        int total = 0;
        for (int i = SYMBOLS; i >= 0; i--) { freq[i] = (freq[i] + 1) / 2; cum[i] = total; total += freq[i]; }
    }
    int i = symbol; while (freq[i] == freq[i - 1]) i--;
    if (i < symbol) {
        u8 a = index_to_char[i]; u8 b = index_to_char[symbol];
        index_to_char[i] = b; index_to_char[symbol] = a; char_to_index[(usz)a] = symbol; char_to_index[(usz)b] = i;
    }
    freq[i]++;
    while (i > 0) { i--; cum[i]++; }
}
fn usz arithmetic_encode(u8* data, usz count, u8* encoded) {
    int[256] char_to_index; u8[258] index_to_char; int[258] freq; int[258] cum;
    for (int i = 0; i < 256; i++) { char_to_index[i] = i + 1; index_to_char[i + 1] = (u8)i; }
    for (int i = 0; i <= SYMBOLS; i++) { freq[i] = 1; cum[i] = SYMBOLS - i; } freq[0] = 0;
    BitWriter writer = {encoded, 0, 0, 8}; uint low = 0; uint high = 65535; int follow = 0;
    for (usz i = 0; i < count; i++) { int symbol = char_to_index[(usz)data[i]]; encode_symbol(symbol, cum.ptr, &low, &high, &follow, &writer); update_model(symbol, char_to_index.ptr, index_to_char.ptr, freq.ptr, cum.ptr); }
    encode_symbol(257, cum.ptr, &low, &high, &follow, &writer); follow++;
    bit_plus_follow(&writer, low < 16384 ? 0 : 1, &follow);
    writer.bytes[writer.length++] = (u8)(writer.buffer >> writer.bits_to_go);
    return writer.length;
}
fn usz compress_bounded(u8* input, usz n, u8* output) {
    usz[MAX_LENGTH] order; u8[MAX_LENGTH] last; u8[MAX_LENGTH * 2] rle; usz rle_length = 0;
    for (usz i = 0; i < n; i++) order[i] = i;
    for (usz i = 1; i < n; i++) { usz key = order[i]; usz j = i; while (j > 0 && rotation_less(input, n, key, order[j - 1])) { order[j] = order[j - 1]; j--; } order[j] = key; }
    usz primary = 0;
    for (usz row = 0; row < n; row++) { if (order[row] == 0) primary = row; last[row] = input[(order[row] + n - 1) % n]; }
    for (usz i = 0; i < n;) {
        usz count = 1; u8 value = last[i];
        while (i + count < n && last[i + count] == value && count < 127) count++;
        if (count == 1) {
            while (i + count < n && last[i + count - 1] != last[i + count] && (i + count + 1 == n || last[i + count] != last[i + count + 1])) count++;
            rle[rle_length++] = (u8)(count & 0x7f); for (usz j = 0; j < count; j++) rle[rle_length++] = last[i + j]; i += count;
        } else { rle[rle_length++] = (u8)(count | 0x80); rle[rle_length++] = value; i += count; }
    }
    output[0] = (u8)n; output[1] = 0; output[2] = 0; output[3] = 0; output[4] = (u8)primary; output[5] = 0; output[6] = 0; output[7] = 0;
    return 8 + arithmetic_encode(rle.ptr, rle_length, output + 8);
}

fn long pcompress2(long* values, usz length, u8* output, usz output_capacity) @export("pcompress2") {
    if (values == null || length < 2 || values[0] < 1 || (usz)values[0] > MAX_LENGTH) return -1;
    usz n = (usz)values[0]; if (length != n + 1) return -1;
    u8[MAX_LENGTH] input;
    for (usz i = 0; i < n; i++) { if (values[i + 1] < 0 || values[i + 1] > 255) return -1; input[i] = (u8)values[i + 1]; }
    u8[MAX_OUTPUT] encoded; usz encoded_length = compress_bounded(input.ptr, n, encoded.ptr);
    if (output == null || output_capacity < encoded_length) return -2;
    for (usz i = 0; i < encoded_length; i++) output[i] = encoded[i];
    return (long)encoded_length;
}
