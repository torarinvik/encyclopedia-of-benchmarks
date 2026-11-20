#include <stddef.h>
#include <stdint.h>

enum {
    MAX_TEXT_LENGTH = 32,
    MAX_INPUT_LENGTH = MAX_TEXT_LENGTH + 2,
    PACKED_FIELD_WORDS = 4,
    PACKED_LIST_WORDS = 2
};

typedef struct { uint64_t word[PACKED_FIELD_WORDS]; } packed_fields;

static int field_get(const packed_fields *fields, int index)
{
    const int word_index = index / 9;
    const int shift = (index % 9) * 7;
    const int value = (int)((fields->word[word_index] >> shift) & UINT64_C(127));
    return value == 127 ? -1 : value;
}

static void field_set(packed_fields *fields, int index, int value)
{
    const int word_index = index / 9;
    const int shift = (index % 9) * 7;
    const uint64_t mask = UINT64_C(127) << shift;
    const uint64_t encoded = (uint64_t)(value < 0 ? 127 : value);
    fields->word[word_index] = (fields->word[word_index] & ~mask) | (encoded << shift);
}

static int list_get(const uint64_t list[PACKED_LIST_WORDS], int index)
{
    const int word_index = index / 10;
    const int shift = (index % 10) * 6;
    return (int)((list[word_index] >> shift) & UINT64_C(63));
}

static void list_set(uint64_t list[PACKED_LIST_WORDS], int index, int value)
{
    const int word_index = index / 10;
    const int shift = (index % 10) * 6;
    const uint64_t mask = UINT64_C(63) << shift;
    list[word_index] = (list[word_index] & ~mask) | ((uint64_t)value << shift);
}

static int bit_is_set(uint64_t bits, int index)
{
    return (int)((bits >> index) & UINT64_C(1));
}

static int bit_count(uint64_t bits)
{
    int count = 0;
    while (bits != 0) {
        bits &= bits - 1;
        ++count;
    }
    return count;
}

static int bits_below(uint64_t bits, int index)
{
    const uint64_t mask = index == 0 ? 0 : (UINT64_C(1) << index) - 1;
    return bit_count(bits & mask);
}

static int input_symbol(const int64_t *raw, const uint64_t *packed,
                        int raw_length, int index)
{
    if (raw != NULL) return index == raw_length ? 0 : (int)raw[index] + 1;
    /* Reduced LMS names already contain their zero sentinel at the end. */
    return list_get(packed, index);
}

static int64_t sa_get(const uint8_t *output, int index)
{
    uint64_t bits = 0;
    const size_t offset = (size_t)index * 8;
    for (size_t byte = 0; byte < 8; ++byte)
        bits |= (uint64_t)output[offset + byte] << (byte * 8);
    return (bits & (UINT64_C(1) << 63)) != 0 ? -1 : (int64_t)bits;
}

static void sa_set(uint8_t *output, int index, int64_t value)
{
    const uint64_t bits = value < 0 ? UINT64_MAX : (uint64_t)value;
    const size_t offset = (size_t)index * 8;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

static void build_buckets(const int64_t *raw, const uint64_t *packed,
                          int raw_length, int length, int upper, uint64_t types,
                          packed_fields *heads, packed_fields *tails,
                          packed_fields *s_starts)
{
    packed_fields counts = {{0, 0, 0, 0}};
    packed_fields l_counts = {{0, 0, 0, 0}};
    int prefix = 0;
    for (int index = 0; index < length; ++index) {
        const int symbol = input_symbol(raw, packed, raw_length, index);
        field_set(&counts, symbol, field_get(&counts, symbol) + 1);
        if (!bit_is_set(types, index))
            field_set(&l_counts, symbol, field_get(&l_counts, symbol) + 1);
    }
    for (int symbol = 0; symbol <= upper; ++symbol) {
        const int count = field_get(&counts, symbol);
        field_set(heads, symbol, prefix);
        field_set(tails, symbol, prefix + count - 1);
        field_set(s_starts, symbol, prefix + field_get(&l_counts, symbol));
        prefix += count;
    }
}

static int same_lms_substring(const int64_t *raw, const uint64_t *packed,
                              int raw_length, int length, uint64_t types,
                              uint64_t lms, int left, int right)
{
    if (left == right) return 1;
    for (int offset = 0; offset < length; ++offset) {
        const int a = left + offset;
        const int b = right + offset;
        if (a >= length || b >= length ||
            input_symbol(raw, packed, raw_length, a) !=
                input_symbol(raw, packed, raw_length, b) ||
            bit_is_set(types, a) != bit_is_set(types, b)) return 0;
        if (offset > 0 && (bit_is_set(lms, a) || bit_is_set(lms, b)))
            return bit_is_set(lms, a) && bit_is_set(lms, b);
    }
    return 0;
}

static void induce(const int64_t *raw, const uint64_t *packed,
                   int raw_length, int length, int upper,
                   uint64_t types, uint64_t lms,
                   const uint64_t *seeds, int seed_count, int use_lms_mask,
                   uint8_t *output)
{
    packed_fields heads = {{0, 0, 0, 0}};
    packed_fields tails = {{0, 0, 0, 0}};
    packed_fields s_starts = {{0, 0, 0, 0}};
    packed_fields l_cursor = {{0, 0, 0, 0}};
    packed_fields s_cursor = {{0, 0, 0, 0}};
    build_buckets(raw, packed, raw_length, length, upper, types,
                  &heads, &tails, &s_starts);
    for (int i = 0; i < length; ++i) sa_set(output, i, -1);

    for (int symbol = 0; symbol <= upper; ++symbol)
        field_set(&s_cursor, symbol, field_get(&s_starts, symbol));
    if (use_lms_mask) {
        for (int position = 0; position < length; ++position) {
            if (!bit_is_set(lms, position)) continue;
            const int symbol = input_symbol(raw, packed, raw_length, position);
            const int slot = field_get(&s_cursor, symbol);
            sa_set(output, slot, position);
            field_set(&s_cursor, symbol, slot + 1);
        }
    } else {
        for (int item = 0; item < seed_count; ++item) {
            const int position = list_get(seeds, item);
            const int symbol = input_symbol(raw, packed, raw_length, position);
            const int slot = field_get(&s_cursor, symbol);
            sa_set(output, slot, position);
            field_set(&s_cursor, symbol, slot + 1);
        }
    }

    for (int symbol = 0; symbol <= upper; ++symbol) {
        field_set(&l_cursor, symbol, field_get(&heads, symbol));
        field_set(&s_cursor, symbol, field_get(&tails, symbol) + 1);
    }
    for (int slot = 0; slot < length; ++slot) {
        const int64_t position = sa_get(output, slot);
        if (position <= 0) continue;
        const int previous = (int)position - 1;
        if (bit_is_set(types, previous)) continue;
        const int symbol = input_symbol(raw, packed, raw_length, previous);
        const int target = field_get(&l_cursor, symbol);
        sa_set(output, target, previous);
        field_set(&l_cursor, symbol, target + 1);
    }
    for (int slot = length - 1; slot >= 0; --slot) {
        const int64_t position = sa_get(output, slot);
        if (position <= 0) continue;
        const int previous = (int)position - 1;
        if (!bit_is_set(types, previous)) continue;
        const int symbol = input_symbol(raw, packed, raw_length, previous);
        const int target = field_get(&s_cursor, symbol) - 1;
        sa_set(output, target, previous);
        field_set(&s_cursor, symbol, target);
    }
}

static void sais_readonly(const int64_t *raw, const uint64_t *packed,
                          int raw_length, int length, int upper,
                          uint8_t *output)
{
    if (length == 0) return;
    if (length == 1) {
        sa_set(output, 0, 0);
        return;
    }
    if (length == 2) {
        if (input_symbol(raw, packed, raw_length, 0) >=
            input_symbol(raw, packed, raw_length, 1)) {
            sa_set(output, 0, 1);
            sa_set(output, 1, 0);
        } else {
            sa_set(output, 0, 0);
            sa_set(output, 1, 1);
        }
        return;
    }

    uint64_t types = UINT64_C(1) << (length - 1);
    for (int index = length - 2; index >= 0; --index) {
        const int current = input_symbol(raw, packed, raw_length, index);
        const int next = input_symbol(raw, packed, raw_length, index + 1);
        if (current < next ||
            (current == next && bit_is_set(types, index + 1)))
            types |= UINT64_C(1) << index;
    }
    uint64_t lms = 0;
    uint64_t lms_positions[PACKED_LIST_WORDS] = {0, 0};
    int lms_count = 0;
    for (int index = 1; index < length; ++index) {
        if (!bit_is_set(types, index - 1) && bit_is_set(types, index)) {
            lms |= UINT64_C(1) << index;
            list_set(lms_positions, lms_count++, index);
        }
    }

    induce(raw, packed, raw_length, length, upper, types, lms,
           NULL, 0, 1, output);

    uint64_t reduced[PACKED_LIST_WORDS] = {0, 0};
    int name = 0;
    int sorted_count = 0;
    int previous_lms = -1;
    for (int slot = 0; slot < length; ++slot) {
        const int64_t candidate = sa_get(output, slot);
        if (candidate < 0 || !bit_is_set(lms, (int)candidate)) continue;
        const int position = (int)candidate;
        if (previous_lms >= 0 &&
            !same_lms_substring(raw, packed, raw_length, length, types, lms,
                                previous_lms, position)) ++name;
        list_set(reduced, bits_below(lms, position), name);
        previous_lms = position;
        ++sorted_count;
    }

    if (sorted_count != lms_count) return;
    if (name + 1 == lms_count) {
        for (int ordinal = 0; ordinal < lms_count; ++ordinal)
            sa_set(output, list_get(reduced, ordinal), ordinal);
    } else {
        sais_readonly(NULL, reduced, 0, lms_count, name, output);
    }

    uint64_t ordered_lms[PACKED_LIST_WORDS] = {0, 0};
    for (int item = 0; item < lms_count; ++item) {
        const int ordinal = (int)sa_get(output, item);
        list_set(ordered_lms, item, list_get(lms_positions, ordinal));
    }
    induce(raw, packed, raw_length, length, upper, types, lms,
           ordered_lms, lms_count, 0, output);
}

extern "C" int64_t suffix_array_inplace_readonly_integer(
    const int64_t *values, size_t length, uint8_t *output, size_t capacity)
{
    if (values == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t count_value = values[0];
    if (count_value < 0 || count_value > MAX_TEXT_LENGTH) return -1;
    const int count = (int)count_value;
    if (length != (size_t)count + 1) return -1;
    for (int index = 0; index < count; ++index)
        if (values[index + 1] < 0 || values[index + 1] >= count) return -1;

    const size_t workspace_bytes = (size_t)(count + 1) * 8;
    const size_t output_bytes = (size_t)count * 8;
    if (output == NULL || capacity < workspace_bytes) return -2;
    sais_readonly(values + 1, NULL, count, count + 1, count, output);
    for (int index = 0; index < count; ++index) {
        const int64_t position = sa_get(output, index + 1);
        sa_set(output, index, position);
    }
    return (int64_t)output_bytes;
}
