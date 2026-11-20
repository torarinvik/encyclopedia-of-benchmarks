#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int generations = 4;
constexpr int buckets = 8;
constexpr int max_keys = 32;
constexpr int max_operations = 64;
constexpr std::size_t max_words = 1 + 3 * max_operations + 1;
constexpr std::int64_t miss = INT64_C(-2147483648);

using BucketHeads = std::array<std::array<std::int16_t, buckets>, generations>;
using Records = std::array<std::array<std::int16_t, max_keys>, generations>;

int find_in_table(const BucketHeads& heads, const Records& keys,
                  const Records& links, int table, int key) {
    int node = heads[table][key % buckets];
    while (node >= 0) {
        if (keys[table][node] == key) return node;
        node = links[table][node];
    }
    return -1;
}

int find_key(const BucketHeads& heads, const Records& keys,
             const Records& links, int newest, int key, int& found_table) {
    for (int age = 0; age < generations; ++age) {
        const int table = (newest + age) % generations;
        const int node = find_in_table(heads, keys, links, table, key);
        if (node >= 0) {
            found_table = table;
            return node;
        }
    }
    found_table = -1;
    return -1;
}

void put(BucketHeads& heads, Records& keys, Records& values, Records& links,
         std::array<std::int16_t, generations>& used, int newest,
         int key, int value) {
    int node = find_in_table(heads, keys, links, newest, key);
    if (node >= 0) {
        values[newest][node] = static_cast<std::int16_t>(value);
        return;
    }
    for (node = 0; node < max_keys && keys[newest][node] >= 0; ++node) { }
    if (node >= max_keys) return;
    ++used[newest];
    const int bucket = key % buckets;
    keys[newest][node] = static_cast<std::int16_t>(key);
    values[newest][node] = static_cast<std::int16_t>(value);
    links[newest][node] = heads[newest][bucket];
    heads[newest][bucket] = static_cast<std::int16_t>(node);
}

void remove(BucketHeads& heads, Records& keys, Records& values, Records& links,
            std::array<std::int16_t, generations>& used, int table, int key, int target) {
    const int bucket = key % buckets;
    int previous = -1;
    int node = heads[table][bucket];
    while (node >= 0 && node != target) {
        previous = node;
        node = links[table][node];
    }
    if (node < 0) return;
    if (previous < 0) heads[table][bucket] = links[table][node];
    else links[table][previous] = links[table][node];
    keys[table][node] = -1;
    values[table][node] = 0;
    links[table][node] = -1;
    --used[table];
}

void write_i64_le(std::uint8_t* output, std::size_t index, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (int byte = 0; byte < 8; ++byte)
        output[index * 8 + static_cast<std::size_t>(byte)] =
            static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t hashbelt_aging_hash_table(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > max_words) return -1;
    const auto count_value = input[0];
    if (count_value < 0 || count_value > max_operations) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != 1 + 3 * count) return -1;
    for (std::size_t op = 0; op < count; ++op) {
        const auto opcode = input[1 + 3 * op];
        const auto key = input[2 + 3 * op];
        const auto argument = input[3 + 3 * op];
        if (opcode == 0) {
            if (key < 0 || key >= max_keys || argument < -1000 || argument > 1000) return -1;
        } else if (opcode == 1) {
            if (key < 0 || key >= max_keys || argument != 0) return -1;
        } else if (opcode == 2) {
            if (key != 0 || argument != 0) return -1;
        } else {
            return -1;
        }
    }
    const auto required = count * 8;
    if (output == nullptr || capacity < required) return -2;

    BucketHeads heads{};
    for (auto& row : heads) row.fill(-1);
    Records keys{}, values{}, links{};
    for (auto& row : keys) row.fill(-1);
    std::array<std::int16_t, generations> used{};
    std::array<std::int64_t, max_operations> trace{};
    int newest = 0;
    for (std::size_t op = 0; op < count; ++op) {
        const int opcode = static_cast<int>(input[1 + 3 * op]);
        const int key = static_cast<int>(input[2 + 3 * op]);
        const int argument = static_cast<int>(input[3 + 3 * op]);
        if (opcode == 0) {
            int found_table;
            const int node = find_key(heads, keys, links, newest, key, found_table);
            trace[op] = found_table < 0 ? 1 : 0;
            if (found_table >= 0 && found_table != newest)
                remove(heads, keys, values, links, used, found_table, key, node);
            put(heads, keys, values, links, used, newest, key, argument);
        } else if (opcode == 1) {
            int found_table;
            const int node = find_key(heads, keys, links, newest, key, found_table);
            if (node < 0) trace[op] = miss;
            else {
                trace[op] = values[found_table][node];
                if (found_table != newest) {
                    remove(heads, keys, values, links, used, found_table, key, node);
                    put(heads, keys, values, links, used, newest, key,
                        static_cast<int>(trace[op]));
                }
            }
        } else {
            const int oldest = (newest + generations - 1) % generations;
            trace[op] = used[oldest];
            heads[oldest].fill(-1);
            keys[oldest].fill(-1);
            used[oldest] = 0;
            newest = oldest;
        }
    }
    for (std::size_t op = 0; op < count; ++op) write_i64_le(output, op, trace[op]);
    return static_cast<std::int64_t>(required);
}
