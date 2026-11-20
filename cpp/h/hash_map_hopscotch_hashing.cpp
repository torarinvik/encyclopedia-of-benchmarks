#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kSlots = 16;
constexpr int kNeighborhood = 4;
constexpr int kMaxOperations = 32;
constexpr std::size_t kMaxWords = 1 + 3 * kMaxOperations;

int distance(int from, int to) {
    return (to - from + kSlots) % kSlots;
}

bool contains(const std::array<std::int16_t, kSlots>& keys,
              const std::array<std::uint8_t, kSlots>& hops,
              int key, int home) {
    for (int offset = 0; offset < kNeighborhood; ++offset) {
        if ((hops[home] & (1u << offset)) != 0 &&
            keys[(home + offset) % kSlots] == key) return true;
    }
    return false;
}

std::uint8_t insert(std::array<std::int16_t, kSlots>& keys,
                    std::array<std::uint8_t, kSlots>& homes,
                    std::array<std::uint8_t, kSlots>& hops,
                    int key, int home) {
    if (contains(keys, hops, key, home)) return 2;
    int hole = -1;
    for (int step = 0; step < kSlots; ++step) {
        const int slot = (home + step) % kSlots;
        if (keys[slot] < 0) { hole = slot; break; }
    }
    if (hole < 0) return 0;

    int new_distance = distance(home, hole);
    while (new_distance >= kNeighborhood) {
        bool shifted = false;
        for (int back = kNeighborhood - 1; back > 0 && !shifted; --back) {
            const int bucket = (hole - back + kSlots) % kSlots;
            const int bucket_to_hole = distance(bucket, hole);
            if (distance(home, bucket) >= new_distance) continue;
            for (int old_distance = 0; old_distance < bucket_to_hole; ++old_distance) {
                if ((hops[bucket] & (1u << old_distance)) == 0) continue;
                const int old_slot = (bucket + old_distance) % kSlots;
                if (keys[old_slot] < 0 || homes[old_slot] != bucket ||
                    distance(home, old_slot) >= new_distance) continue;
                keys[hole] = keys[old_slot];
                homes[hole] = homes[old_slot];
                keys[old_slot] = -1;
                homes[old_slot] = 0;
                hops[bucket] &= static_cast<std::uint8_t>(~(1u << old_distance));
                hops[bucket] |= static_cast<std::uint8_t>(1u << bucket_to_hole);
                hole = old_slot;
                new_distance = distance(home, hole);
                shifted = true;
                break;
            }
        }
        if (!shifted) return 0;
    }
    keys[hole] = static_cast<std::int16_t>(key);
    homes[hole] = static_cast<std::uint8_t>(home);
    hops[home] |= static_cast<std::uint8_t>(1u << new_distance);
    return 1;
}
}

extern "C" std::int64_t hash_map_hopscotch_hashing(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > kMaxWords) return -1;
    if (input[0] < 0 || input[0] > kMaxOperations) return -1;
    const auto count = static_cast<std::size_t>(input[0]);
    if (length != 1 + 3 * count) return -1;

    std::array<std::int8_t, 64> known_home;
    known_home.fill(-1);
    for (std::size_t op = 0; op < count; ++op) {
        const auto opcode = input[1 + 3 * op];
        const auto key = input[2 + 3 * op];
        const auto home = input[3 + 3 * op];
        if ((opcode != 1 && opcode != 2) || key < 0 || key >= 64 || home < 0 || home >= kSlots)
            return -1;
        if (known_home[static_cast<std::size_t>(key)] >= 0 &&
            known_home[static_cast<std::size_t>(key)] != home) return -1;
        known_home[static_cast<std::size_t>(key)] = static_cast<std::int8_t>(home);
    }

    const std::size_t required = count + 2 * kSlots;
    if (output == nullptr || capacity < required) return -2;
    std::array<std::int16_t, kSlots> keys;
    keys.fill(-1);
    std::array<std::uint8_t, kSlots> homes{};
    std::array<std::uint8_t, kSlots> hops{};
    std::array<std::uint8_t, kMaxOperations> statuses{};
    for (std::size_t op = 0; op < count; ++op) {
        const int opcode = static_cast<int>(input[1 + 3 * op]);
        const int key = static_cast<int>(input[2 + 3 * op]);
        const int home = static_cast<int>(input[3 + 3 * op]);
        statuses[op] = opcode == 1
            ? insert(keys, homes, hops, key, home)
            : static_cast<std::uint8_t>(contains(keys, hops, key, home));
    }
    std::size_t cursor = 0;
    for (std::size_t op = 0; op < count; ++op) output[cursor++] = statuses[op];
    for (const auto key : keys) output[cursor++] = key < 0 ? 0 : static_cast<std::uint8_t>(key + 1);
    for (const auto mask : hops) output[cursor++] = mask;
    return static_cast<std::int64_t>(required);
}
