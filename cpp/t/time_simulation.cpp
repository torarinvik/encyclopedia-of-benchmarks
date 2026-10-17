#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_actions = 4096, max_events = 1024;
constexpr std::uint64_t max_event_id = UINT64_C(4294967295);
std::uint64_t hash_word(std::uint64_t hash, std::uint64_t word) noexcept {
    for (unsigned shift = 0; shift < 64; shift += 8) { hash ^= (word >> shift) & 255u; hash *= UINT64_C(1099511628211); }
    return hash;
}
}
extern "C" std::int64_t time_simulation(const std::int64_t* values, std::size_t length) noexcept {
    if (values == nullptr || length < 1 || length > 8194) return -1;
    const auto count = values[0];
    if (count < 0 || count > static_cast<std::int64_t>(max_actions) || length != 1 + 2 * static_cast<std::size_t>(count)) return -1;
    auto hash = hash_word(UINT64_C(14695981039346656037), static_cast<std::uint64_t>(count));
    std::int64_t now = 0; std::uint64_t next_id = 1;
    std::size_t active_count = 0, total_processed = 0, fired_count = 0;
    bool active[max_events]{}; std::int64_t timestamps[max_events]{}; std::uint64_t event_ids[max_events]{};
    // Reused queue slots can fire repeatedly, so trace storage spans all actions.
    std::uint64_t fired_ids[max_actions]{}; std::int64_t fired_times[max_actions]{};
    for (std::size_t action = 0; action < static_cast<std::size_t>(count); ++action) {
        const auto opcode = values[1 + 2 * action], operand = values[2 + 2 * action];
        std::uint64_t result = 0;
        if (opcode == 0) {
            if (operand < 0 || operand < now) return -1;
            if (active_count < max_events) {
                std::size_t slot = 0; while (active[slot]) ++slot;
                event_ids[slot] = next_id; timestamps[slot] = operand; active[slot] = true; ++active_count;
                result = next_id++; if (next_id > max_event_id) next_id = 1;
            }
        } else if (opcode == 1) {
            if (operand < 1 || static_cast<std::uint64_t>(operand) > max_event_id) return -1;
            for (std::size_t slot = 0; slot < max_events; ++slot) if (active[slot] && event_ids[slot] == static_cast<std::uint64_t>(operand)) { active[slot] = false; --active_count; result = 1; break; }
        } else if (opcode == 2) {
            if (operand < 0 || operand < now) return -1;
            std::size_t processed = 0;
            for (;;) {
                std::size_t chosen = max_events; std::int64_t earliest = 0;
                for (std::size_t slot = 0; slot < max_events; ++slot) if (active[slot] && timestamps[slot] <= operand && (chosen == max_events || timestamps[slot] < earliest)) { chosen = slot; earliest = timestamps[slot]; }
                if (chosen == max_events) break;
                now = timestamps[chosen]; active[chosen] = false; --active_count;
                fired_ids[fired_count] = event_ids[chosen]; fired_times[fired_count] = timestamps[chosen]; ++fired_count;
                ++processed; ++total_processed;
            }
            now = operand; result = processed;
        } else if (opcode == 3) { if (operand != 0) return -1; result = static_cast<std::uint64_t>(now); }
        else if (opcode == 4) { if (operand != 0) return -1; result = active_count == 0 ? 1 : 0; }
        else return -1;
        hash = hash_word(hash, result);
    }
    hash = hash_word(hash, fired_count);
    for (std::size_t i = 0; i < fired_count; ++i) { hash = hash_word(hash, fired_ids[i]); hash = hash_word(hash, static_cast<std::uint64_t>(fired_times[i])); }
    hash = hash_word(hash, static_cast<std::uint64_t>(now)); hash = hash_word(hash, active_count); hash = hash_word(hash, total_processed);
    return static_cast<std::int64_t>(hash & UINT64_C(0x7FFFFFFFFFFFFFFF));
}
