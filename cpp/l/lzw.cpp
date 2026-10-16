#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_ITEMS = 4096;
constexpr std::size_t MAX_CODES = 4352;
constexpr std::size_t MAX_OUTPUT = 65536;
constexpr std::uint64_t FNV_OFFSET = UINT64_C(14695981039346656037);
constexpr std::uint64_t FNV_PRIME = UINT64_C(1099511628211);
constexpr std::uint64_t HASH_MASK = UINT64_C(0x7fffffffffffffff);

std::uint64_t hash_i64(std::uint64_t hash, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (unsigned shift = 0; shift < 64; shift += 8) {
        hash = (hash ^ static_cast<std::uint8_t>(bits >> shift)) * FNV_PRIME;
    }
    return hash;
}

std::int64_t hash_record(std::int64_t mode, std::size_t count, const std::int64_t *values) {
    auto hash = hash_i64(FNV_OFFSET, mode);
    hash = hash_i64(hash, static_cast<std::int64_t>(count));
    for (std::size_t i = 0; i < count; ++i) hash = hash_i64(hash, values[i]);
    return static_cast<std::int64_t>(hash & HASH_MASK);
}

bool expand_code(int code, int dictionary_size, const std::int32_t *prefix,
                 const std::uint8_t *suffix, std::uint8_t *phrase,
                 std::size_t capacity, std::size_t &phrase_length) {
    std::size_t length = 0;
    int current = code;
    while (current >= 256) {
        if (current >= dictionary_size || length >= capacity) return false;
        phrase[length++] = suffix[current];
        current = prefix[current];
        if (current < 0) return false;
    }
    if (current < 0 || current > 255 || length >= capacity) return false;
    phrase[length++] = static_cast<std::uint8_t>(current);
    for (std::size_t left = 0, right = length - 1; left < right; ++left, --right) {
        const auto byte = phrase[left]; phrase[left] = phrase[right]; phrase[right] = byte;
    }
    phrase_length = length;
    return true;
}
}

extern "C" std::int64_t lzw(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 2 || length > MAX_ITEMS + 2) return -1;
    const auto mode = input[0], count64 = input[1];
    if ((mode != 0 && mode != 1) || count64 < 0 || count64 > static_cast<std::int64_t>(MAX_ITEMS) ||
        length != static_cast<std::size_t>(count64) + 2) return -1;
    const auto count = static_cast<std::size_t>(count64);

    std::int32_t prefix[MAX_CODES];
    std::int32_t next_sibling[MAX_CODES];
    std::int32_t first_child[MAX_CODES];
    std::uint8_t suffix[MAX_CODES];
    std::uint8_t first_symbol[MAX_CODES];
    for (std::size_t i = 0; i < MAX_CODES; ++i) {
        prefix[i] = next_sibling[i] = first_child[i] = -1;
        suffix[i] = first_symbol[i] = 0;
    }
    for (int code = 0; code < 256; ++code) {
        suffix[code] = static_cast<std::uint8_t>(code);
        first_symbol[code] = static_cast<std::uint8_t>(code);
    }

    if (mode == 0) {
        for (std::size_t i = 0; i < count; ++i) if (input[2 + i] < 0 || input[2 + i] > 127) return -1;
        std::int64_t codes[MAX_ITEMS];
        std::size_t code_count = 0;
        if (count > 0) {
            int dictionary_size = 256;
            int current = static_cast<int>(input[2]);
            for (std::size_t i = 1; i < count; ++i) {
                const auto byte = static_cast<int>(input[2 + i]);
                int match = first_child[current];
                while (match >= 0 && suffix[match] != static_cast<std::uint8_t>(byte)) match = next_sibling[match];
                if (match >= 0) current = match;
                else {
                    codes[code_count++] = current;
                    if (dictionary_size >= static_cast<int>(MAX_CODES)) return -1;
                    prefix[dictionary_size] = current;
                    suffix[dictionary_size] = static_cast<std::uint8_t>(byte);
                    first_symbol[dictionary_size] = first_symbol[current];
                    next_sibling[dictionary_size] = first_child[current];
                    first_child[current] = dictionary_size++;
                    current = byte;
                }
            }
            codes[code_count++] = current;
        }
        return hash_record(0, code_count, codes);
    }

    for (std::size_t i = 0; i < count; ++i) if (input[2 + i] < 0 || input[2 + i] >= static_cast<std::int64_t>(MAX_CODES)) return -1;
    if (count == 0) return hash_record(1, 0, nullptr);
    const int first_code = static_cast<int>(input[2]);
    if (first_code > 127) return -1;

    std::uint8_t decoded[MAX_OUTPUT];
    std::uint8_t phrase[MAX_CODES];
    std::size_t decoded_length = 1;
    decoded[0] = static_cast<std::uint8_t>(first_code);
    int dictionary_size = 256;
    int previous = first_code;
    for (std::size_t i = 1; i < count; ++i) {
        const int code = static_cast<int>(input[2 + i]);
        std::size_t phrase_length = 0;
        if (code < dictionary_size) {
            if (!expand_code(code, dictionary_size, prefix, suffix, phrase, MAX_CODES, phrase_length)) return -1;
        } else if (code == dictionary_size) {
            if (!expand_code(previous, dictionary_size, prefix, suffix, phrase, MAX_CODES, phrase_length) || phrase_length >= MAX_CODES) return -1;
            phrase[phrase_length++] = first_symbol[previous];
        } else return -1;

        if (decoded_length > MAX_OUTPUT - phrase_length) return -1;
        for (std::size_t j = 0; j < phrase_length; ++j) if (phrase[j] > 127) return -1;
        for (std::size_t j = 0; j < phrase_length; ++j) decoded[decoded_length++] = phrase[j];

        if (dictionary_size >= static_cast<int>(MAX_CODES)) return -1;
        const auto next_byte = static_cast<std::uint8_t>(code == dictionary_size ? first_symbol[previous] : first_symbol[code]);
        prefix[dictionary_size] = previous;
        suffix[dictionary_size] = next_byte;
        first_symbol[dictionary_size] = first_symbol[previous];
        ++dictionary_size;
        previous = code;
    }
    auto hash = hash_i64(FNV_OFFSET, 1);
    hash = hash_i64(hash, static_cast<std::int64_t>(decoded_length));
    for (std::size_t i = 0; i < decoded_length; ++i) hash = hash_i64(hash, decoded[i]);
    return static_cast<std::int64_t>(hash & HASH_MASK);
}
