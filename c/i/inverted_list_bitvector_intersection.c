#include <stddef.h>
#include <stdint.h>

#define MAX_DOMAIN 1024
#define MAX_LISTS 16
#define MAX_WORDS 16

static void write_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t inverted_list_bitvector_intersection(const int64_t *input, size_t length,
                                              uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > 258) return -1;
    const int64_t domain_value = input[0];
    const int64_t list_count_value = input[1];
    if (domain_value < 1 || domain_value > MAX_DOMAIN ||
        list_count_value < 1 || list_count_value > MAX_LISTS) return -1;

    const size_t domain = (size_t)domain_value;
    const size_t list_count = (size_t)list_count_value;
    const size_t words_per_list = (domain + 63) / 64;
    if (length != 2 + list_count * words_per_list) return -1;

    const size_t remainder = domain % 64;
    if (remainder != 0) {
        const uint64_t valid_mask = (UINT64_C(1) << remainder) - 1;
        for (size_t list = 0; list < list_count; ++list) {
            const size_t index = 2 + list * words_per_list + words_per_list - 1;
            const uint64_t final_word = (uint64_t)input[index];
            if ((final_word & ~valid_mask) != 0) return -1;
        }
    }

    uint64_t intersection[MAX_WORDS] = {0};
    for (size_t word = 0; word < words_per_list; ++word) {
        uint64_t combined = UINT64_MAX;
        for (size_t list = 0; list < list_count; ++list)
            combined &= (uint64_t)input[2 + list * words_per_list + word];
        intersection[word] = combined;
    }

    int64_t results[MAX_DOMAIN];
    size_t result_count = 0;
    for (size_t document_id = 0; document_id < domain; ++document_id) {
        const uint64_t bit = UINT64_C(1) << (document_id % 64);
        if ((intersection[document_id / 64] & bit) != 0)
            results[result_count++] = (int64_t)document_id;
    }

    const size_t output_bytes = (result_count + 1) * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    write_i64_le(output, 0, (int64_t)result_count);
    for (size_t index = 0; index < result_count; ++index)
        write_i64_le(output, (index + 1) * 8, results[index]);
    return (int64_t)output_bytes;
}
