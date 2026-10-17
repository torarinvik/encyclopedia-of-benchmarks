#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t max_input_bits = 128;
constexpr std::size_t max_dictionary_entries = max_input_bits + 2;
constexpr std::size_t max_key_length = 16;
constexpr std::size_t max_value_length = max_input_bits + 1;
constexpr std::size_t max_output_bytes = max_input_bits * (max_input_bits + 1) / 2;
constexpr std::size_t max_parseable_input_length = max_input_bits + 2;

struct LexiconEntry {
    char key[max_key_length + 1];
    std::size_t key_length;
    char value[max_value_length + 1];
    std::size_t value_length;
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

bool set_value_with_suffix(LexiconEntry &entry, const char *value,
                           std::size_t value_length, char suffix) noexcept
{
    if (value_length > max_value_length - 1) return false;
    std::memcpy(entry.value, value, value_length);
    entry.value[value_length] = suffix;
    entry.value[value_length + 1] = '\0';
    entry.value_length = value_length + 1;
    return true;
}

std::size_t make_binary_key(std::size_t value, char *key) noexcept
{
    char reversed[max_key_length];
    std::size_t length = 0;
    do {
        if (length >= max_key_length) return 0;
        reversed[length++] = static_cast<char>('0' + (value & 1u));
        value >>= 1u;
    } while (value != 0);

    for (std::size_t i = 0; i < length; ++i)
        key[i] = reversed[length - i - 1];
    key[length] = '\0';
    return length;
}

bool is_power_of_two(std::size_t value) noexcept
{
    return value != 0 && (value & (value - 1)) == 0;
}

bool decode_bits(const std::int64_t *input, std::size_t bit_count,
                 std::uint8_t *decoded, std::size_t &decoded_length) noexcept
{
    LexiconEntry entries[max_dictionary_entries]{};
    std::size_t entry_count = 2;
    entries[0].key[0] = '0';
    entries[0].key_length = 1;
    entries[0].value[0] = '0';
    entries[0].value_length = 1;
    entries[1].key[0] = '1';
    entries[1].key_length = 1;
    entries[1].value[0] = '1';
    entries[1].value_length = 1;

    char current[max_input_bits + 1];
    std::size_t current_length = 0;
    std::size_t index = entry_count;
    std::size_t output_length = 0;

    for (std::size_t bit = 0; bit < bit_count; ++bit) {
        current[current_length++] = input[bit + 1] == 48 ? '0' : '1';
        current[current_length] = '\0';
        const std::size_t match = find_entry(entries, entry_count,
                                             current, current_length);
        if (match == entry_count) continue;

        char last_match[max_value_length + 1];
        const std::size_t last_match_length = entries[match].value_length;
        if (output_length + last_match_length > max_output_bytes) return false;
        std::memcpy(last_match, entries[match].value, last_match_length);
        last_match[last_match_length] = '\0';
        std::memcpy(decoded + output_length, last_match, last_match_length);
        output_length += last_match_length;

        if (!set_value_with_suffix(entries[match], last_match,
                                   last_match_length, '0')) return false;

        if (is_power_of_two(index)) {
            for (std::size_t entry = 0; entry < entry_count; ++entry) {
                if (entries[entry].key_length >= max_key_length) return false;
                std::memmove(entries[entry].key + 1, entries[entry].key,
                             entries[entry].key_length);
                entries[entry].key[0] = '0';
                ++entries[entry].key_length;
                entries[entry].key[entries[entry].key_length] = '\0';
            }
        }

        char index_key[max_key_length + 1];
        const std::size_t index_key_length = make_binary_key(index, index_key);
        if (index_key_length == 0) return false;
        const std::size_t existing = find_entry(entries, entry_count,
                                                index_key, index_key_length);
        if (existing == entry_count) {
            if (entry_count >= max_dictionary_entries) return false;
            entries[entry_count].key_length = index_key_length;
            std::memcpy(entries[entry_count].key, index_key, index_key_length + 1);
            if (!set_value_with_suffix(entries[entry_count], last_match,
                                       last_match_length, '1')) return false;
            ++entry_count;
        } else if (!set_value_with_suffix(entries[existing], last_match,
                                          last_match_length, '1')) {
            return false;
        }

        ++index;
        current_length = 0;
    }

    decoded_length = output_length;
    return true;
}
}

extern "C" std::int64_t lempel_ziv_decompress(
    const std::int64_t *input, std::size_t input_length,
    std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || input_length < 1 ||
        input_length > max_parseable_input_length) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_input_bits)) return -1;
    const std::size_t bit_count = static_cast<std::size_t>(input[0]);
    if (input_length != 1 + bit_count) return -1;
    for (std::size_t i = 0; i < bit_count; ++i) {
        if (input[i + 1] != 48 && input[i + 1] != 49) return -1;
    }

    std::uint8_t decoded[max_output_bytes];
    std::size_t decoded_length = 0;
    if (!decode_bits(input, bit_count, decoded, decoded_length)) return -1;
    if (output == nullptr || output_capacity < decoded_length) return -2;
    if (decoded_length > 0) std::memcpy(output, decoded, decoded_length);
    return static_cast<std::int64_t>(decoded_length);
}
