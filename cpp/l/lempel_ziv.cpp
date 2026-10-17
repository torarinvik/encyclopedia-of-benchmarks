#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t max_input_bits = 128;
constexpr std::size_t max_dictionary_entries = max_input_bits + 2;
constexpr std::size_t max_key_length = max_input_bits + 1;
constexpr std::size_t max_code_width = 8;
constexpr std::size_t max_output_bytes = 1032;
constexpr std::size_t max_parseable_input_length = max_input_bits + 2;

struct LexiconEntry {
    char key[max_key_length + 1];
    std::size_t key_length;
    char code[max_code_width + 1];
    std::size_t code_length;
};

std::size_t find_entry(const LexiconEntry *entries, std::size_t entry_count,
                       const char *key, std::size_t key_length) noexcept
{
    for (std::size_t i = 0; i < entry_count; ++i) {
        if (entries[i].key_length == key_length &&
            std::memcmp(entries[i].key, key, key_length) == 0) return i;
    }
    return entry_count;
}

bool set_code(LexiconEntry &entry, const char *code,
              std::size_t code_length) noexcept
{
    if (code_length > max_code_width) return false;
    std::memcpy(entry.code, code, code_length);
    entry.code[code_length] = '\0';
    entry.code_length = code_length;
    return true;
}

bool insert_or_update(LexiconEntry *entries, std::size_t &entry_count,
                      const char *key, std::size_t key_length,
                      const char *code, std::size_t code_length) noexcept
{
    const std::size_t existing = find_entry(entries, entry_count, key, key_length);
    if (existing != entry_count) return set_code(entries[existing], code, code_length);
    if (entry_count >= max_dictionary_entries || key_length > max_key_length)
        return false;
    LexiconEntry &entry = entries[entry_count];
    std::memcpy(entry.key, key, key_length);
    entry.key[key_length] = '\0';
    entry.key_length = key_length;
    if (!set_code(entry, code, code_length)) return false;
    ++entry_count;
    return true;
}

bool append_code(std::uint8_t *output, std::size_t &output_length,
                 const LexiconEntry &entry) noexcept
{
    if (output_length + entry.code_length > max_output_bytes) return false;
    for (std::size_t i = 0; i < entry.code_length; ++i)
        output[output_length++] = static_cast<std::uint8_t>(entry.code[i]);
    return true;
}

std::size_t make_binary_code(std::size_t value, char *code) noexcept
{
    char reversed[max_code_width];
    std::size_t length = 0;
    do {
        if (length >= max_code_width) return 0;
        reversed[length++] = static_cast<char>('0' + (value & 1u));
        value >>= 1u;
    } while (value != 0);

    for (std::size_t i = 0; i < length; ++i)
        code[i] = reversed[length - i - 1];
    code[length] = '\0';
    return length;
}

bool is_power_of_two(std::size_t value) noexcept
{
    return value != 0 && (value & (value - 1)) == 0;
}

bool compress_bits(const std::int64_t *input, std::size_t bit_count,
                   std::uint8_t *compressed, std::size_t &compressed_length) noexcept
{
    LexiconEntry entries[max_dictionary_entries]{};
    std::size_t entry_count = 2;
    entries[0].key[0] = '0';
    entries[0].key_length = 1;
    entries[0].code[0] = '0';
    entries[0].code_length = 1;
    entries[1].key[0] = '1';
    entries[1].key_length = 1;
    entries[1].code[0] = '1';
    entries[1].code_length = 1;

    char current[max_key_length + 1];
    std::size_t current_length = 0;
    std::size_t index = entry_count;
    std::size_t output_length = 0;

    for (std::size_t bit = 0; bit < bit_count; ++bit) {
        current[current_length++] = input[bit + 1] == 48 ? '0' : '1';
        current[current_length] = '\0';
        const std::size_t match = find_entry(entries, entry_count,
                                             current, current_length);
        if (match == entry_count) continue;

        char matched_code[max_code_width + 1];
        const std::size_t matched_code_length = entries[match].code_length;
        std::memcpy(matched_code, entries[match].code, matched_code_length);
        matched_code[matched_code_length] = '\0';
        if (output_length + matched_code_length > max_output_bytes) return false;
        std::memcpy(compressed + output_length, matched_code, matched_code_length);
        output_length += matched_code_length;

        for (std::size_t entry = match; entry + 1 < entry_count; ++entry)
            entries[entry] = entries[entry + 1];
        --entry_count;

        char child_zero[max_key_length + 1];
        if (current_length + 1 > max_key_length) return false;
        std::memcpy(child_zero, current, current_length);
        child_zero[current_length] = '0';
        child_zero[current_length + 1] = '\0';
        if (!insert_or_update(entries, entry_count, child_zero,
                              current_length + 1, matched_code,
                              matched_code_length)) return false;

        if (is_power_of_two(index)) {
            for (std::size_t entry = 0; entry < entry_count; ++entry) {
                if (entries[entry].code_length >= max_code_width) return false;
                std::memmove(entries[entry].code + 1, entries[entry].code,
                             entries[entry].code_length);
                entries[entry].code[0] = '0';
                ++entries[entry].code_length;
                entries[entry].code[entries[entry].code_length] = '\0';
            }
        }

        char child_one[max_key_length + 1];
        std::memcpy(child_one, current, current_length);
        child_one[current_length] = '1';
        child_one[current_length + 1] = '\0';
        char index_code[max_code_width + 1];
        const std::size_t index_code_length = make_binary_code(index, index_code);
        if (index_code_length == 0 ||
            !insert_or_update(entries, entry_count, child_one,
                              current_length + 1, index_code,
                              index_code_length)) return false;

        ++index;
        current_length = 0;
    }

    if (current_length > 0) {
        std::size_t max_key_length_in_dictionary = 0;
        for (std::size_t entry = 0; entry < entry_count; ++entry) {
            if (entries[entry].key_length > max_key_length_in_dictionary)
                max_key_length_in_dictionary = entries[entry].key_length;
        }
        for (;;) {
            const std::size_t match = find_entry(entries, entry_count,
                                                 current, current_length);
            if (match != entry_count) {
                if (!append_code(compressed, output_length, entries[match])) return false;
                break;
            }
            if (current_length >= max_key_length_in_dictionary ||
                current_length >= max_key_length) return false;
            current[current_length++] = '0';
            current[current_length] = '\0';
        }
    }

    compressed_length = output_length;
    return true;
}
}

extern "C" std::int64_t lempel_ziv(
    const std::int64_t *input, std::size_t input_length,
    std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || input_length < 1 ||
        input_length > max_parseable_input_length) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_input_bits)) return -1;
    const std::size_t bit_count = static_cast<std::size_t>(input[0]);
    if (input_length != 1 + bit_count) return -1;
    for (std::size_t bit = 0; bit < bit_count; ++bit) {
        if (input[bit + 1] != 48 && input[bit + 1] != 49) return -1;
    }

    std::uint8_t compressed[max_output_bytes];
    std::size_t compressed_length = 0;
    if (!compress_bits(input, bit_count, compressed, compressed_length)) return -1;
    if (output == nullptr || output_capacity < compressed_length) return -2;
    if (compressed_length > 0) std::memcpy(output, compressed, compressed_length);
    return static_cast<std::int64_t>(compressed_length);
}
