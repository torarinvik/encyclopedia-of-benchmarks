/* Bounded port of the pinned C hash set's ASCII-key insertion and lookup. */
#include <array>
#include <cstddef>
#include <cstdint>
#include <initializer_list>

namespace {
constexpr std::int64_t kMaxIds = 64;
constexpr std::size_t kMaxInputLength = 130;
constexpr std::size_t kCapacity = 1024;
constexpr std::uint64_t kFnvOffset = UINT64_C(14695981039346656037);
constexpr std::uint64_t kFnvPrime = UINT64_C(1099511628211);

std::uint64_t adler_key(std::int64_t id) noexcept {
    std::uint64_t a = 1, b = 0;
    for (const std::uint64_t byte : {UINT64_C(107), UINT64_C(101), UINT64_C(121)}) {
        a = (a + byte) % UINT64_C(65521);
        b = (b + a) % UINT64_C(65521);
    }
    if (id >= 10) {
        a = (a + static_cast<std::uint64_t>(id / 10 + '0')) % UINT64_C(65521);
        b = (b + a) % UINT64_C(65521);
    }
    a = (a + static_cast<std::uint64_t>(id % 10 + '0')) % UINT64_C(65521);
    b = (b + a) % UINT64_C(65521);
    return (b << 16) | a;
}

std::size_t bucket_for_id(std::int64_t id) noexcept {
    const auto hash = adler_key(id);
    return static_cast<std::size_t>((kCapacity - 1) & (hash ^ (hash >> 12)));
}

std::uint64_t fnv_word(std::uint64_t hash, std::int64_t word) noexcept {
    const auto bits = static_cast<std::uint64_t>(word);
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (bits >> (8 * byte)) & UINT64_C(0xff);
        hash *= kFnvPrime;
    }
    return hash;
}
}

extern "C" std::int64_t hash_set(const std::int64_t *input,
                                  std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > kMaxInputLength) return -1;
    const auto add_count_value = input[0];
    if (add_count_value < 0 || add_count_value > kMaxIds) return -1;
    const auto add_count = static_cast<std::size_t>(add_count_value);
    const auto query_count_index = 1 + add_count;
    if (query_count_index >= length) return -1;
    const auto query_count_value = input[query_count_index];
    if (query_count_value < 0 || query_count_value > kMaxIds) return -1;
    const auto query_count = static_cast<std::size_t>(query_count_value);
    if (length != 2 + add_count + query_count) return -1;

    for (std::size_t i = 0; i < add_count; ++i)
        if (input[1 + i] < 0 || input[1 + i] >= kMaxIds) return -1;
    for (std::size_t i = 0; i < query_count; ++i)
        if (input[query_count_index + 1 + i] < 0 || input[query_count_index + 1 + i] >= kMaxIds) return -1;

    std::array<bool, kCapacity> occupied{};
    std::array<std::int64_t, kCapacity> slot_ids{};
    std::int64_t set_length = 0;
    for (std::size_t i = 0; i < add_count; ++i) {
        const auto id = input[1 + i];
        const auto bucket = bucket_for_id(id);
        if (!occupied[bucket]) {
            occupied[bucket] = true;
            slot_ids[bucket] = id;
            ++set_length;
        } else if (slot_ids[bucket] != id) {
            return -1;
        }
    }

    auto result = fnv_word(kFnvOffset, set_length);
    for (std::size_t i = 0; i < query_count; ++i) {
        const auto id = input[query_count_index + 1 + i];
        const auto bucket = bucket_for_id(id);
        const std::int64_t contains = occupied[bucket] && slot_ids[bucket] == id ? 1 : 0;
        result = fnv_word(result, contains);
    }
    return static_cast<std::int64_t>(result & static_cast<std::uint64_t>(INT64_MAX));
}
