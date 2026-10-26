#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_R = 8, MAX_H = 8, MAX_INPUT = 154, MAX_OUTPUT = 64;
void put64(std::uint8_t* output, std::size_t position, std::int64_t value) {
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[position + byte] = static_cast<std::uint8_t>(bits >> (8U * byte));
}
}

extern "C" std::int64_t hospitals_residents_rgs(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 5 || length > MAX_INPUT) return -1;
    const auto r64 = input[0], h64 = input[1];
    if (r64 < 1 || r64 > static_cast<std::int64_t>(MAX_R) || h64 < 1 || h64 > static_cast<std::int64_t>(MAX_H)) return -1;
    const auto r = static_cast<std::size_t>(r64), h = static_cast<std::size_t>(h64);
    const auto expected = 2 + 2 * h + r + 2 * r * h;
    if (length != expected) return -1;
    const std::size_t cap_offset = 2, rlen_offset = cap_offset + h;
    const std::size_t rpref_offset = rlen_offset + r, hlen_offset = rpref_offset + r * h;
    const std::size_t hpref_offset = hlen_offset + h;
    std::int64_t capacities[MAX_H]{}, hospital_length[MAX_H]{}, occupancy[MAX_H]{};
    std::int64_t resident_length[MAX_R]{}, assignment[MAX_R]{}, next_choice[MAX_R]{};
    std::int64_t resident_pref[MAX_R][MAX_H]{}, hospital_rank[MAX_H][MAX_R]{};
    for (std::size_t hospital = 0; hospital < h; ++hospital) {
        capacities[hospital] = input[cap_offset + hospital];
        hospital_length[hospital] = input[hlen_offset + hospital];
        if (capacities[hospital] < 1 || capacities[hospital] > r64 || hospital_length[hospital] < 0 || hospital_length[hospital] > r64) return -1;
        for (std::size_t resident = 0; resident < r; ++resident) hospital_rank[hospital][resident] = -1;
    }
    for (std::size_t resident = 0; resident < r; ++resident) {
        resident_length[resident] = input[rlen_offset + resident];
        if (resident_length[resident] < 0 || resident_length[resident] > h64) return -1;
        bool seen[MAX_H]{};
        for (std::size_t slot = 0; slot < h; ++slot) {
            const auto value = input[rpref_offset + resident * h + slot];
            if (slot < static_cast<std::size_t>(resident_length[resident])) {
                if (value < 0 || value >= h64 || seen[static_cast<std::size_t>(value)]) return -1;
                seen[static_cast<std::size_t>(value)] = true;
                resident_pref[resident][slot] = value;
            } else {
                if (value != -1) return -1;
                resident_pref[resident][slot] = -1;
            }
        }
        assignment[resident] = -1;
    }
    for (std::size_t hospital = 0; hospital < h; ++hospital) {
        bool seen[MAX_R]{};
        for (std::size_t slot = 0; slot < r; ++slot) {
            const auto value = input[hpref_offset + hospital * r + slot];
            if (slot < static_cast<std::size_t>(hospital_length[hospital])) {
                if (value < 0 || value >= r64 || seen[static_cast<std::size_t>(value)]) return -1;
                seen[static_cast<std::size_t>(value)] = true;
                hospital_rank[hospital][static_cast<std::size_t>(value)] = static_cast<std::int64_t>(slot);
            } else if (value != -1) return -1;
        }
    }
    for (std::size_t resident = 0; resident < r; ++resident)
        for (std::size_t hospital = 0; hospital < h; ++hospital) {
            bool accepts = false;
            for (std::size_t slot = 0; slot < static_cast<std::size_t>(resident_length[resident]); ++slot)
                if (resident_pref[resident][slot] == static_cast<std::int64_t>(hospital)) accepts = true;
            if (accepts != (hospital_rank[hospital][resident] >= 0)) return -1;
        }
    const auto output_bytes = 8 * r;
    if (output == nullptr || capacity < output_bytes) return -2;

    while (true) {
        std::size_t proposer = r;
        for (std::size_t resident = 0; resident < r; ++resident)
            if (assignment[resident] == -1 && next_choice[resident] < resident_length[resident]) { proposer = resident; break; }
        if (proposer == r) break;
        const auto hospital = static_cast<std::size_t>(resident_pref[proposer][static_cast<std::size_t>(next_choice[proposer]++)]);
        if (occupancy[hospital] < capacities[hospital]) {
            assignment[proposer] = static_cast<std::int64_t>(hospital);
            ++occupancy[hospital];
            continue;
        }
        std::size_t worst = r;
        for (std::size_t resident = 0; resident < r; ++resident)
            if (assignment[resident] == static_cast<std::int64_t>(hospital) &&
                (worst == r || hospital_rank[hospital][resident] > hospital_rank[hospital][worst])) worst = resident;
        if (worst == r) return -1;
        if (hospital_rank[hospital][proposer] < hospital_rank[hospital][worst]) {
            assignment[worst] = -1;
            assignment[proposer] = static_cast<std::int64_t>(hospital);
        }
    }
    std::uint8_t staged[MAX_OUTPUT]{};
    for (std::size_t resident = 0; resident < r; ++resident) put64(staged, 8 * resident, assignment[resident]);
    for (std::size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return static_cast<std::int64_t>(output_bytes);
}
