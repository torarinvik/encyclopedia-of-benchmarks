#include <stddef.h>
#include <stdint.h>

enum { MAX_R = 8, MAX_H = 8, MAX_INPUT = 154, MAX_OUTPUT = 64 };

static void put64(uint8_t *output, size_t position, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[position + byte] = (uint8_t)(bits >> (8u * byte));
}

int64_t hospitals_residents_rgs(const int64_t *input, size_t length,
                                uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 5u || length > MAX_INPUT) return -1;
    int64_t r64 = input[0], h64 = input[1];
    if (r64 < 1 || r64 > MAX_R || h64 < 1 || h64 > MAX_H) return -1;
    size_t r = (size_t)r64, h = (size_t)h64;
    size_t expected = 2u + 2u * h + r + 2u * r * h;
    if (length != expected) return -1;
    size_t cap_offset = 2u;
    size_t rlen_offset = cap_offset + h;
    size_t rpref_offset = rlen_offset + r;
    size_t hlen_offset = rpref_offset + r * h;
    size_t hpref_offset = hlen_offset + h;
    int64_t capacities[MAX_H], resident_length[MAX_R];
    int64_t resident_pref[MAX_R][MAX_H];
    int64_t hospital_length[MAX_H], hospital_rank[MAX_H][MAX_R];
    int64_t assignment[MAX_R], next_choice[MAX_R], occupancy[MAX_H] = {0};
    for (size_t hospital = 0; hospital < h; ++hospital) {
        capacities[hospital] = input[cap_offset + hospital];
        if (capacities[hospital] < 1 || capacities[hospital] > r64) return -1;
        hospital_length[hospital] = input[hlen_offset + hospital];
        if (hospital_length[hospital] < 0 || hospital_length[hospital] > r64) return -1;
        for (size_t resident = 0; resident < r; ++resident) hospital_rank[hospital][resident] = -1;
    }
    for (size_t resident = 0; resident < r; ++resident) {
        resident_length[resident] = input[rlen_offset + resident];
        if (resident_length[resident] < 0 || resident_length[resident] > h64) return -1;
        int seen[MAX_H] = {0};
        for (size_t slot = 0; slot < h; ++slot) {
            int64_t value = input[rpref_offset + resident * h + slot];
            if (slot < (size_t)resident_length[resident]) {
                if (value < 0 || value >= h64 || seen[(size_t)value]) return -1;
                seen[(size_t)value] = 1;
                resident_pref[resident][slot] = value;
            } else {
                if (value != -1) return -1;
                resident_pref[resident][slot] = -1;
            }
        }
        assignment[resident] = -1;
        next_choice[resident] = 0;
    }
    for (size_t hospital = 0; hospital < h; ++hospital) {
        int seen[MAX_R] = {0};
        for (size_t slot = 0; slot < r; ++slot) {
            int64_t value = input[hpref_offset + hospital * r + slot];
            if (slot < (size_t)hospital_length[hospital]) {
                if (value < 0 || value >= r64 || seen[(size_t)value]) return -1;
                seen[(size_t)value] = 1;
                hospital_rank[hospital][(size_t)value] = (int64_t)slot;
            } else if (value != -1) return -1;
        }
    }
    for (size_t resident = 0; resident < r; ++resident)
        for (size_t hospital = 0; hospital < h; ++hospital) {
            int resident_accepts = 0;
            for (size_t slot = 0; slot < (size_t)resident_length[resident]; ++slot)
                if (resident_pref[resident][slot] == (int64_t)hospital) resident_accepts = 1;
            if (resident_accepts != (hospital_rank[hospital][resident] >= 0)) return -1;
        }

    size_t output_bytes = 8u * r;
    if (output == NULL || capacity < output_bytes) return -2;
    while (1) {
        size_t proposer = r;
        for (size_t resident = 0; resident < r; ++resident)
            if (assignment[resident] == -1 && next_choice[resident] < resident_length[resident]) {
                proposer = resident;
                break;
            }
        if (proposer == r) break;
        size_t hospital = (size_t)resident_pref[proposer][(size_t)next_choice[proposer]++];
        if (occupancy[hospital] < capacities[hospital]) {
            assignment[proposer] = (int64_t)hospital;
            ++occupancy[hospital];
            continue;
        }
        size_t worst = r;
        for (size_t resident = 0; resident < r; ++resident)
            if (assignment[resident] == (int64_t)hospital &&
                (worst == r || hospital_rank[hospital][resident] > hospital_rank[hospital][worst]))
                worst = resident;
        if (worst == r) return -1;
        if (hospital_rank[hospital][proposer] < hospital_rank[hospital][worst]) {
            assignment[worst] = -1;
            assignment[proposer] = (int64_t)hospital;
        }
    }

    uint8_t staged[MAX_OUTPUT];
    for (size_t resident = 0; resident < r; ++resident) put64(staged, 8u * resident, assignment[resident]);
    for (size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return (int64_t)output_bytes;
}
