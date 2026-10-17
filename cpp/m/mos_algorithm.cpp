#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 256;
constexpr std::size_t MAX_Q = 256;
constexpr std::size_t MAX_INPUT_LENGTH = 4 + MAX_N + 3 * MAX_Q + 1;
constexpr std::uint64_t FNV_OFFSET = UINT64_C(14695981039346656037);
constexpr std::uint64_t FNV_PRIME = UINT64_C(1099511628211);

std::uint64_t hash_byte(std::uint64_t hash, std::uint8_t byte) {
    return (hash ^ byte) * FNV_PRIME;
}

bool query_before(std::size_t a, std::size_t b, const std::int32_t *lefts,
                  const std::int32_t *rights, std::size_t block_size) {
    const auto block_a = lefts[a] / static_cast<std::int32_t>(block_size);
    const auto block_b = lefts[b] / static_cast<std::int32_t>(block_size);
    if (block_a != block_b) return block_a < block_b;
    if ((block_a & 1) != 0) return rights[a] < rights[b];
    return rights[a] > rights[b];
}
}

extern "C" std::int64_t mos_algorithm(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    const auto operation = input[0];
    const auto n64 = input[1];
    const auto q64 = input[2];
    const auto target64 = input[3];
    if ((operation != 0 && operation != 1) || n64 < 1 || n64 > static_cast<std::int64_t>(MAX_N)
        || q64 < 0 || q64 > static_cast<std::int64_t>(MAX_Q)
        || target64 < -1'000'000 || target64 > 1'000'000
        || length != 4 + static_cast<std::size_t>(n64) + 3 * static_cast<std::size_t>(q64)) return -1;
    const auto n = static_cast<std::size_t>(n64);
    const auto q = static_cast<std::size_t>(q64);
    const auto target = static_cast<std::int32_t>(target64);

    std::int32_t values[MAX_N];
    for (std::size_t index = 0; index < n; ++index) {
        const auto value = input[4 + index];
        if (value < -1'000'000 || value > 1'000'000) return -1;
        values[index] = static_cast<std::int32_t>(value);
    }

    std::int32_t lefts[MAX_Q], rights[MAX_Q], indices[MAX_Q];
    std::size_t order[MAX_Q];
    bool seen[MAX_Q]{};
    const auto query_offset = 4 + n;
    for (std::size_t query = 0; query < q; ++query) {
        const auto left = input[query_offset + 3 * query];
        const auto right = input[query_offset + 3 * query + 1];
        const auto index = input[query_offset + 3 * query + 2];
        if (left < 0 || right < left || right >= n64 || index < 0 || index >= q64 || seen[index]) return -1;
        lefts[query] = static_cast<std::int32_t>(left);
        rights[query] = static_cast<std::int32_t>(right);
        indices[query] = static_cast<std::int32_t>(index);
        seen[index] = true;
        order[query] = query;
    }

    std::size_t block_size = 1;
    while ((block_size + 1) * (block_size + 1) <= n) ++block_size;
    for (std::size_t query = 1; query < q; ++query) {
        const auto current = order[query];
        auto position = query;
        while (position > 0 && query_before(current, order[position - 1], lefts, rights, block_size)) {
            order[position] = order[position - 1];
            --position;
        }
        order[position] = current;
    }

    std::int32_t results[MAX_Q];
    std::int32_t current_left = 0, current_right = -1, aggregate = 0;
    for (std::size_t sorted = 0; sorted < q; ++sorted) {
        const auto query = order[sorted];
        const auto left = lefts[query];
        const auto right = rights[query];
        if (operation == 0) {
            while (current_right < right) aggregate += values[static_cast<std::size_t>(++current_right)];
            while (current_right > right) aggregate -= values[static_cast<std::size_t>(current_right--)];
            while (current_left < left) aggregate -= values[static_cast<std::size_t>(current_left++)];
            while (current_left > left) aggregate += values[static_cast<std::size_t>(--current_left)];
        } else {
            while (current_right < right) if (values[static_cast<std::size_t>(++current_right)] == target) ++aggregate;
            while (current_right > right) {
                if (values[static_cast<std::size_t>(current_right)] == target) --aggregate;
                --current_right;
            }
            while (current_left < left) {
                if (values[static_cast<std::size_t>(current_left)] == target) --aggregate;
                ++current_left;
            }
            while (current_left > left) {
                --current_left;
                if (values[static_cast<std::size_t>(current_left)] == target) ++aggregate;
            }
        }
        results[static_cast<std::size_t>(indices[query])] = aggregate;
    }

    auto hash = hash_byte(hash_byte(FNV_OFFSET, static_cast<std::uint8_t>(operation)), static_cast<std::uint8_t>(q));
    hash = hash_byte(hash, static_cast<std::uint8_t>(q >> 8));
    for (std::size_t index = 0; index < q; ++index) {
        const auto bits = static_cast<std::uint32_t>(results[index]);
        for (unsigned shift = 0; shift < 32; shift += 8) hash = hash_byte(hash, static_cast<std::uint8_t>(bits >> shift));
    }
    return static_cast<std::int64_t>(hash & UINT64_C(0x7fffffffffffffff));
}
