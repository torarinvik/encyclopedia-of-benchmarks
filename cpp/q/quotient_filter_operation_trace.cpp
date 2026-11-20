#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kSlots = 8;
constexpr std::size_t kMaxOps = 32;
constexpr std::size_t kMaxItems = 6;

std::size_t next_slot(std::size_t i) { return (i + 1) % kSlots; }
std::size_t prev_slot(std::size_t i) { return (i + kSlots - 1) % kSlots; }

bool empty_slot(std::size_t i, const std::array<std::uint8_t, kSlots>& rem,
        const std::array<bool, kSlots>& occ, const std::array<bool, kSlots>& cont,
        const std::array<bool, kSlots>& shifted) {
    return rem[i] == 0 && !occ[i] && !cont[i] && !shifted[i];
}

int find_run(std::size_t q, const std::array<bool, kSlots>& occ,
        const std::array<bool, kSlots>& cont, const std::array<bool, kSlots>& shifted,
        std::size_t& result) {
    if (!occ[q]) return 0;
    std::size_t bucket = q, steps = 0;
    while (shifted[bucket] && steps < kSlots) { bucket = prev_slot(bucket); ++steps; }
    if (steps >= kSlots) return -1;
    std::size_t slot = bucket;
    while (bucket != q) {
        slot = next_slot(slot);
        steps = 0;
        while (cont[slot] && steps < kSlots) { slot = next_slot(slot); ++steps; }
        if (steps >= kSlots) return -1;
        bucket = next_slot(bucket);
        steps = 0;
        while (!occ[bucket] && steps < kSlots) { bucket = next_slot(bucket); ++steps; }
        if (steps >= kSlots) return -1;
    }
    result = slot;
    return 1;
}

bool find_insert_position(std::size_t q, const std::array<bool, kSlots>& occ,
        const std::array<bool, kSlots>& cont, const std::array<bool, kSlots>& shifted,
        std::size_t& result) {
    std::size_t bucket = q, steps = 0;
    while (shifted[bucket] && steps < kSlots) { bucket = prev_slot(bucket); ++steps; }
    if (steps >= kSlots) return false;
    std::size_t slot = bucket;
    while (bucket != q) {
        steps = 0;
        do { slot = next_slot(slot); ++steps; } while (cont[slot] && steps < kSlots);
        if (steps >= kSlots) return false;
        bucket = next_slot(bucket);
        steps = 0;
        while (bucket != q && !occ[bucket] && steps < kSlots) {
            bucket = next_slot(bucket); ++steps;
        }
        if (steps >= kSlots) return false;
    }
    result = slot;
    return true;
}

bool next_occupied(std::size_t q, const std::array<bool, kSlots>& occ,
        std::size_t& result) {
    std::size_t bucket = next_slot(q);
    for (std::size_t i = 0; i < kSlots; ++i) {
        if (occ[bucket]) { result = bucket; return true; }
        bucket = next_slot(bucket);
    }
    return false;
}

bool insert_at(std::size_t position, std::size_t q, std::uint8_t r, bool has_run,
        std::size_t run_start, std::array<std::uint8_t, kSlots>& rem,
        std::array<bool, kSlots>& occ, std::array<bool, kSlots>& cont,
        std::array<bool, kSlots>& shifted) {
    const bool new_cont = has_run && position != run_start;
    if (has_run && position == run_start) cont[position] = true;
    std::size_t empty = position;
    bool found_empty = false;
    for (std::size_t i = 0; i < kSlots; ++i) {
        if (empty_slot(empty, rem, occ, cont, shifted)) { found_empty = true; break; }
        empty = next_slot(empty);
    }
    if (!found_empty) return false;
    std::size_t slot = empty;
    while (slot != position) {
        const std::size_t previous = prev_slot(slot);
        rem[slot] = rem[previous];
        cont[slot] = cont[previous];
        shifted[slot] = true;
        slot = previous;
    }
    rem[position] = r;
    cont[position] = new_cont;
    shifted[position] = position != q;
    occ[q] = true;
    return true;
}
} // namespace

extern "C" std::int64_t quotient_filter_operation_trace(const std::int64_t* input,
        std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > 66) return -1;
    const std::int64_t raw_count = input[0];
    if (raw_count < 0 || raw_count > static_cast<std::int64_t>(kMaxOps)) return -1;
    const std::size_t count = static_cast<std::size_t>(raw_count);
    if (length != 1 + 2 * count) return -1;
    for (std::size_t op = 0; op < count; ++op) {
        const std::int64_t opcode = input[1 + 2 * op], fingerprint = input[2 + 2 * op];
        if (opcode < 0 || opcode > 2 || fingerprint < 0 || fingerprint > 255) return -1;
    }
    if (output == nullptr || capacity < count) return -2;

    std::array<std::uint8_t, kSlots> rem{};
    std::array<bool, kSlots> occ{}, cont{}, shifted{};
    std::array<std::uint8_t, kMaxOps> statuses{};
    std::size_t total = 0;

    for (std::size_t op = 0; op < count; ++op) {
        const std::int64_t opcode = input[1 + 2 * op], fp = input[2 + 2 * op];
        const std::size_t q = static_cast<std::size_t>(fp) >> 5;
        const std::uint8_t r = static_cast<std::uint8_t>(fp & 31);
        if (opcode == 0) {
            if (total == kMaxItems) { statuses[op] = 2; continue; }
            std::size_t position = 0;
            const int has_run = find_run(q, occ, cont, shifted, position);
            if (has_run < 0) return -1;
            const std::size_t run_start = position;
            if (has_run) {
                for (std::size_t n = 0; n < kSlots; ++n) {
                    if (rem[position] > r) break;
                    const std::size_t next = next_slot(position);
                    position = next;
                    if (!cont[next]) break;
                }
            } else if (!empty_slot(q, rem, occ, cont, shifted)) {
                if (!find_insert_position(q, occ, cont, shifted, position)) return -1;
            } else position = q;
            if (!insert_at(position, q, r, has_run != 0, run_start,
                    rem, occ, cont, shifted)) return -1;
            ++total;
            statuses[op] = 1;
        } else if (opcode == 1) {
            std::size_t position = 0;
            const int has_run = find_run(q, occ, cont, shifted, position);
            if (has_run < 0) return -1;
            bool found = false;
            if (has_run) for (std::size_t n = 0; n < kSlots; ++n) {
                if (rem[position] == r) { found = true; break; }
                if (rem[position] > r) break;
                const std::size_t next = next_slot(position);
                if (!cont[next]) break;
                position = next;
            }
            statuses[op] = found ? 1 : 0;
        } else {
            std::size_t position = 0;
            const int has_run = find_run(q, occ, cont, shifted, position);
            if (has_run < 0) return -1;
            bool removed = false;
            if (has_run) for (std::size_t n = 0; n < kSlots; ++n) {
                if (rem[position] == r) { removed = true; break; }
                if (rem[position] > r) break;
                const std::size_t next = next_slot(position);
                if (!cont[next]) break;
                position = next;
            }
            if (!removed) { statuses[op] = 0; continue; }
            const bool was_run_start = !cont[position];
            const std::size_t following = next_slot(position);
            const bool has_more_same = !empty_slot(following, rem, occ, cont, shifted)
                    && cont[following];
            if (was_run_start && !has_more_same) occ[q] = false;
            rem[position] = 0; cont[position] = false; shifted[position] = false;
            std::size_t hole = position;
            std::size_t current_q = q;
            bool first_shift = true;
            for (std::size_t n = 0; n < kSlots - 1; ++n) {
                const std::size_t next = next_slot(hole);
                if (empty_slot(next, rem, occ, cont, shifted) || !shifted[next]) break;
                const bool source_cont = cont[next];
                const bool promote = first_shift && was_run_start && has_more_same;
                if (!source_cont && !promote && !next_occupied(current_q, occ, current_q)) return -1;
                rem[hole] = rem[next];
                cont[hole] = promote ? false : source_cont;
                shifted[hole] = cont[hole] || hole != current_q;
                rem[next] = 0; cont[next] = false; shifted[next] = false;
                hole = next;
                first_shift = false;
            }
            rem[hole] = 0; cont[hole] = false; shifted[hole] = false;
            --total;
            statuses[op] = 1;
        }
    }
    for (std::size_t i = 0; i < count; ++i) output[i] = statuses[i];
    return static_cast<std::int64_t>(count);
}
