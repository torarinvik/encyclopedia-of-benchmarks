/* Deterministic bounded two-level FKS static perfect hashing. */
#include <cstddef>
#include <cstdint>

static std::size_t hash_index(std::size_t a, std::size_t b, std::size_t modulus,
                              std::int64_t key) noexcept
{
    return ((a * static_cast<std::size_t>(key) + b) % 257) % modulus;
}

extern "C" std::int64_t fks_static_perfect_hash(const std::int64_t *input,
                                                  std::size_t length) noexcept
{
    if (input == nullptr || length < 2 || length > 19) return -1;
    if (input[0] < 0 || input[0] > 8 || input[1] < 0 || input[1] > 8) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto q = static_cast<std::size_t>(input[1]);
    if (length != 2 + n + q) return -1;
    for (std::size_t i = 0; i < n + q; ++i)
        if (input[2 + i] < 0 || input[2 + i] > 255) return -1;
    for (std::size_t i = 0; i < n; ++i)
        for (std::size_t j = i + 1; j < n; ++j)
            if (input[2 + i] == input[2 + j]) return -1;

    std::size_t bucket_of[8]{};
    std::size_t bucket_sizes[8]{};
    std::size_t first_a = 0, first_b = 0;
    bool first_found = n == 0;
    for (std::size_t a = 1; a <= 256 && !first_found; ++a) {
        for (std::size_t b = 0; b <= 256 && !first_found; ++b) {
            std::size_t counts[8]{};
            for (std::size_t i = 0; i < n; ++i)
                ++counts[hash_index(a, b, n, input[2 + i])];
            std::size_t square_sum = 0;
            for (std::size_t bucket = 0; bucket < n; ++bucket)
                square_sum += counts[bucket] * counts[bucket];
            if (square_sum <= 4 * n) {
                first_a = a;
                first_b = b;
                first_found = true;
            }
        }
    }
    if (!first_found) return -1;
    for (std::size_t i = 0; i < n; ++i) {
        bucket_of[i] = hash_index(first_a, first_b, n, input[2 + i]);
        ++bucket_sizes[bucket_of[i]];
    }

    std::int64_t slot_keys[8][64]{};
    bool occupied[8][64]{};
    std::size_t local_a[8]{}, local_b[8]{};
    for (std::size_t bucket = 0; bucket < n; ++bucket) {
        const std::size_t count = bucket_sizes[bucket];
        if (count == 0) continue;
        const std::size_t capacity = count * count;
        bool local_found = false;
        for (std::size_t a = 1; a <= 256 && !local_found; ++a) {
            for (std::size_t b = 0; b <= 256 && !local_found; ++b) {
                bool used[64]{};
                bool collision = false;
                for (std::size_t i = 0; i < n; ++i) if (bucket_of[i] == bucket) {
                    const auto position = hash_index(a, b, capacity, input[2 + i]);
                    if (used[position]) { collision = true; break; }
                    used[position] = true;
                }
                if (!collision) {
                    local_a[bucket] = a;
                    local_b[bucket] = b;
                    for (std::size_t i = 0; i < n; ++i) if (bucket_of[i] == bucket) {
                        const auto position = hash_index(a, b, capacity, input[2 + i]);
                        slot_keys[bucket][position] = input[2 + i];
                        occupied[bucket][position] = true;
                    }
                    local_found = true;
                }
            }
        }
        if (!local_found) return -1;
    }

    std::int64_t result = 0;
    for (std::size_t i = 0; i < q; ++i) {
        bool present = false;
        if (n > 0) {
            const auto query = input[2 + n + i];
            const auto bucket = hash_index(first_a, first_b, n, query);
            const std::size_t count = bucket_sizes[bucket];
            if (count > 0) {
                const auto position = hash_index(local_a[bucket], local_b[bucket], count * count, query);
                present = occupied[bucket][position] && slot_keys[bucket][position] == query;
            }
        }
        if (present) result |= std::int64_t{1} << i;
    }
    return result;
}
