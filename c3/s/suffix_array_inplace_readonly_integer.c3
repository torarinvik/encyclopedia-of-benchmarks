module suffix_array_inplace_readonly_integer;

const usz MAX_TEXT_LENGTH = 32;
const usz MAX_INPUT_LENGTH = 34;
const int PACKED_FIELD_WORDS = 4;
const int PACKED_LIST_WORDS = 2;

struct PackedFields { ulong[PACKED_FIELD_WORDS] word; }

fn int field_get(PackedFields* fields, int index) {
    int word_index = index / 9;
    int shift = (index % 9) * 7;
    int value = (int)((fields.word[word_index] >> shift) & 127);
    return value == 127 ? -1 : value;
}

fn void field_set(PackedFields* fields, int index, int value) {
    int word_index = index / 9;
    int shift = (index % 9) * 7;
    ulong mask = (ulong)127 << shift;
    ulong encoded = (ulong)(value < 0 ? 127 : value);
    fields.word[word_index] = (fields.word[word_index] & ~mask) | (encoded << shift);
}

fn int list_get(ulong* list, int index) {
    int word_index = index / 10;
    int shift = (index % 10) * 6;
    return (int)((list[word_index] >> shift) & 63);
}

fn void list_set(ulong* list, int index, int value) {
    int word_index = index / 10;
    int shift = (index % 10) * 6;
    ulong mask = (ulong)63 << shift;
    list[word_index] = (list[word_index] & ~mask) | ((ulong)value << shift);
}

fn bool bit_is_set(ulong bits, int index) {
    return ((bits >> index) & 1) != 0;
}

fn int bit_count(ulong bits) {
    int count = 0;
    while (bits != 0) { bits &= bits - 1; count += 1; }
    return count;
}

fn int bits_below(ulong bits, int index) {
    ulong mask = index == 0 ? 0 : ((ulong)1 << index) - 1;
    return bit_count(bits & mask);
}

fn int input_symbol(long* raw, ulong* packed, int raw_length, int index) {
    if (raw != null) return index == raw_length ? 0 : (int)raw[index] + 1;
    // The reduced LMS-name string already stores its zero sentinel at the end.
    return list_get(packed, index);
}

fn long sa_get(char* output, int index) {
    ulong bits = 0;
    usz offset = (usz)index * 8;
    for (usz byte = 0; byte < 8; byte++)
        bits |= (ulong)(uchar)output[offset + byte] << (byte * 8);
    return (bits & ((ulong)1 << 63)) != 0 ? -1 : (long)bits;
}

fn void sa_set(char* output, int index, long value) {
    ulong bits = value < 0 ? ~(ulong)0 : (ulong)value;
    usz offset = (usz)index * 8;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (byte * 8));
}

fn void build_buckets(long* raw, ulong* packed, int raw_length,
        int length, int upper, ulong types, PackedFields* heads,
        PackedFields* tails, PackedFields* s_starts) {
    PackedFields counts = zeroed;
    PackedFields l_counts = zeroed;
    int prefix = 0;
    for (int index = 0; index < length; index++) {
        int symbol = input_symbol(raw, packed, raw_length, index);
        field_set(&counts, symbol, field_get(&counts, symbol) + 1);
        if (!bit_is_set(types, index))
            field_set(&l_counts, symbol, field_get(&l_counts, symbol) + 1);
    }
    for (int symbol = 0; symbol <= upper; symbol++) {
        int count = field_get(&counts, symbol);
        field_set(heads, symbol, prefix);
        field_set(tails, symbol, prefix + count - 1);
        field_set(s_starts, symbol, prefix + field_get(&l_counts, symbol));
        prefix += count;
    }
}

fn bool same_lms_substring(long* raw, ulong* packed, int raw_length,
        int length, ulong types, ulong lms, int left, int right) {
    if (left == right) return true;
    for (int offset = 0; offset < length; offset++) {
        int a = left + offset;
        int b = right + offset;
        if (a >= length || b >= length ||
            input_symbol(raw, packed, raw_length, a) != input_symbol(raw, packed, raw_length, b) ||
            bit_is_set(types, a) != bit_is_set(types, b)) return false;
        if (offset > 0 && (bit_is_set(lms, a) || bit_is_set(lms, b)))
            return bit_is_set(lms, a) && bit_is_set(lms, b);
    }
    return false;
}

fn void induce(long* raw, ulong* packed, int raw_length, int length,
        int upper, ulong types, ulong lms, ulong* seeds, int seed_count,
        bool use_lms_mask, char* output) {
    PackedFields heads = zeroed;
    PackedFields tails = zeroed;
    PackedFields s_starts = zeroed;
    PackedFields l_cursor = zeroed;
    PackedFields s_cursor = zeroed;
    build_buckets(raw, packed, raw_length, length, upper, types,
                  &heads, &tails, &s_starts);
    for (int i = 0; i < length; i++) sa_set(output, i, -1);
    for (int symbol = 0; symbol <= upper; symbol++)
        field_set(&s_cursor, symbol, field_get(&s_starts, symbol));
    if (use_lms_mask) {
        for (int position = 0; position < length; position++) {
            if (!bit_is_set(lms, position)) continue;
            int symbol = input_symbol(raw, packed, raw_length, position);
            int slot = field_get(&s_cursor, symbol);
            sa_set(output, slot, position);
            field_set(&s_cursor, symbol, slot + 1);
        }
    } else {
        for (int item = 0; item < seed_count; item++) {
            int position = list_get(seeds, item);
            int symbol = input_symbol(raw, packed, raw_length, position);
            int slot = field_get(&s_cursor, symbol);
            sa_set(output, slot, position);
            field_set(&s_cursor, symbol, slot + 1);
        }
    }
    for (int symbol = 0; symbol <= upper; symbol++) {
        field_set(&l_cursor, symbol, field_get(&heads, symbol));
        field_set(&s_cursor, symbol, field_get(&tails, symbol) + 1);
    }
    for (int slot = 0; slot < length; slot++) {
        long position = sa_get(output, slot);
        if (position <= 0) continue;
        int previous = (int)position - 1;
        if (bit_is_set(types, previous)) continue;
        int symbol = input_symbol(raw, packed, raw_length, previous);
        int target = field_get(&l_cursor, symbol);
        sa_set(output, target, previous);
        field_set(&l_cursor, symbol, target + 1);
    }
    for (int slot = length - 1; slot >= 0; slot--) {
        long position = sa_get(output, slot);
        if (position <= 0) continue;
        int previous = (int)position - 1;
        if (!bit_is_set(types, previous)) continue;
        int symbol = input_symbol(raw, packed, raw_length, previous);
        int target = field_get(&s_cursor, symbol) - 1;
        sa_set(output, target, previous);
        field_set(&s_cursor, symbol, target);
    }
}

fn void sais_readonly(long* raw, ulong* packed, int raw_length,
        int length, int upper, char* output) {
    if (length == 0) return;
    if (length == 1) { sa_set(output, 0, 0); return; }
    if (length == 2) {
        if (input_symbol(raw, packed, raw_length, 0) >= input_symbol(raw, packed, raw_length, 1)) {
            sa_set(output, 0, 1); sa_set(output, 1, 0);
        } else { sa_set(output, 0, 0); sa_set(output, 1, 1); }
        return;
    }
    ulong types = (ulong)1 << (length - 1);
    for (int index = length - 2; index >= 0; index--) {
        int current = input_symbol(raw, packed, raw_length, index);
        int next = input_symbol(raw, packed, raw_length, index + 1);
        if (current < next || (current == next && bit_is_set(types, index + 1)))
            types |= (ulong)1 << index;
    }
    ulong lms = 0;
    ulong lms_positions[PACKED_LIST_WORDS] = zeroed;
    int lms_count = 0;
    for (int index = 1; index < length; index++) {
        if (!bit_is_set(types, index - 1) && bit_is_set(types, index)) {
            lms |= (ulong)1 << index;
            list_set(&lms_positions[0], lms_count++, index);
        }
    }
    induce(raw, packed, raw_length, length, upper, types, lms,
           null, 0, true, output);
    ulong reduced[PACKED_LIST_WORDS] = zeroed;
    int name = 0, sorted_count = 0, previous_lms = -1;
    for (int slot = 0; slot < length; slot++) {
        long candidate = sa_get(output, slot);
        if (candidate < 0 || !bit_is_set(lms, (int)candidate)) continue;
        int position = (int)candidate;
        if (previous_lms >= 0 && !same_lms_substring(raw, packed, raw_length,
                length, types, lms, previous_lms, position)) name++;
        list_set(&reduced[0], bits_below(lms, position), name);
        previous_lms = position;
        sorted_count++;
    }
    if (sorted_count != lms_count) return;
    if (name + 1 == lms_count) {
        for (int ordinal = 0; ordinal < lms_count; ordinal++)
            sa_set(output, list_get(&reduced[0], ordinal), ordinal);
    } else {
        sais_readonly(null, &reduced[0], 0, lms_count, name, output);
    }
    ulong ordered_lms[PACKED_LIST_WORDS] = zeroed;
    for (int item = 0; item < lms_count; item++) {
        int ordinal = (int)sa_get(output, item);
        list_set(&ordered_lms[0], item, list_get(&lms_positions[0], ordinal));
    }
    induce(raw, packed, raw_length, length, upper, types, lms,
           &ordered_lms[0], lms_count, false, output);
}

fn long suffix_array_inplace_readonly_integer(long* values, usz length,
        char* output, usz capacity) @export("suffix_array_inplace_readonly_integer") {
    if (values == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long count_value = values[0];
    if (count_value < 0 || count_value > MAX_TEXT_LENGTH) return -1;
    int count = (int)count_value;
    if (length != (usz)count + 1) return -1;
    for (int i = 0; i < count; i++) if (values[i + 1] < 0 || values[i + 1] >= count) return -1;
    usz workspace_bytes = (usz)(count + 1) * 8;
    usz output_bytes = (usz)count * 8;
    if (output == null || capacity < workspace_bytes) return -2;
    sais_readonly(&values[1], null, count, count + 1, count, output);
    for (int i = 0; i < count; i++) {
        long position = sa_get(output, i + 1);
        sa_set(output, i, position);
    }
    return (long)output_bytes;
}
