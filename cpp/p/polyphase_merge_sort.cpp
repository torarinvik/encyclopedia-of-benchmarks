#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_items = 256;
constexpr std::size_t run_size = 8;
constexpr std::size_t max_runs = 34;
using Tapes = std::array<std::array<std::int64_t, max_items>, 3>;
using RunTable = std::array<std::array<std::uint32_t, max_runs>, 3>;
using TapeCounts = std::array<std::uint32_t, 3>;

void place_run(const std::int64_t* input, std::size_t input_length, std::uint32_t run_index,
               std::uint32_t tape, Tapes& tapes, RunTable& starts, RunTable& lengths,
               TapeCounts& counts, TapeCounts& write_offsets) noexcept {
    const auto slot = counts[tape]++;
    const auto start = write_offsets[tape];
    const auto source = static_cast<std::size_t>(run_index) * run_size;
    const auto length = static_cast<std::uint32_t>(input_length - source < run_size
        ? input_length - source : run_size);
    for (std::uint32_t i = 0; i < length; ++i) tapes[tape][start + i] = input[source + i];
    for (std::uint32_t i = 1; i < length; ++i) {
        const auto value = tapes[tape][start + i];
        auto position = i;
        while (position > 0 && tapes[tape][start + position - 1] > value) {
            tapes[tape][start + position] = tapes[tape][start + position - 1];
            --position;
        }
        tapes[tape][start + position] = value;
    }
    starts[tape][slot] = start;
    lengths[tape][slot] = length;
    write_offsets[tape] += length;
}

void place_dummy(std::uint32_t tape, RunTable& starts, RunTable& lengths,
                 TapeCounts& counts, const TapeCounts& write_offsets) noexcept {
    const auto slot = counts[tape]++;
    starts[tape][slot] = write_offsets[tape];
    lengths[tape][slot] = 0;
}

void merge_run(Tapes& tapes, RunTable& starts, RunTable& lengths,
               TapeCounts& counts, TapeCounts& read_indices, TapeCounts& write_offsets,
               std::uint32_t left_tape, std::uint32_t right_tape,
               std::uint32_t output_tape) noexcept {
    const auto left_slot = read_indices[left_tape]++;
    const auto right_slot = read_indices[right_tape]++;
    const auto left_start = starts[left_tape][left_slot];
    const auto right_start = starts[right_tape][right_slot];
    const auto left_length = lengths[left_tape][left_slot];
    const auto right_length = lengths[right_tape][right_slot];
    const auto output_slot = counts[output_tape]++;
    const auto output_start = write_offsets[output_tape];
    std::uint32_t left = 0, right = 0, written = 0;
    while (left < left_length && right < right_length) {
        if (tapes[left_tape][left_start + left] <= tapes[right_tape][right_start + right])
            tapes[output_tape][output_start + written++] = tapes[left_tape][left_start + left++];
        else
            tapes[output_tape][output_start + written++] = tapes[right_tape][right_start + right++];
    }
    while (left < left_length)
        tapes[output_tape][output_start + written++] = tapes[left_tape][left_start + left++];
    while (right < right_length)
        tapes[output_tape][output_start + written++] = tapes[right_tape][right_start + right++];
    starts[output_tape][output_slot] = output_start;
    lengths[output_tape][output_slot] = written;
    write_offsets[output_tape] += written;
}
}

extern "C" void polyphase_merge_sort(std::int64_t* values, std::size_t length) noexcept {
    if (values == nullptr || length < 2 || length > max_items) return;
    Tapes tapes{};
    RunTable starts{}, run_lengths{};
    TapeCounts counts{}, read_indices{}, write_offsets{};
    const auto initial_runs = static_cast<std::uint32_t>((length + run_size - 1) / run_size);
    std::uint32_t quota_a = 1, quota_b = 0;
    while (quota_a + quota_b < initial_runs) {
        const auto next = quota_a + quota_b;
        quota_b = quota_a;
        quota_a = next;
    }
    std::uint32_t run = 0;
    for (std::uint32_t slot = 0; slot < quota_a; ++slot, ++run) {
        if (run < initial_runs) place_run(values, length, run, 0, tapes, starts, run_lengths, counts, write_offsets);
        else place_dummy(0, starts, run_lengths, counts, write_offsets);
    }
    for (std::uint32_t slot = 0; slot < quota_b; ++slot, ++run) {
        if (run < initial_runs) place_run(values, length, run, 1, tapes, starts, run_lengths, counts, write_offsets);
        else place_dummy(1, starts, run_lengths, counts, write_offsets);
    }

    std::uint32_t input_a = 0, input_b = 1, output = 2;
    auto remaining_total = counts[0] + counts[1];
    while (remaining_total > 1) {
        const auto available_a = counts[input_a] - read_indices[input_a];
        const auto available_b = counts[input_b] - read_indices[input_b];
        if (available_a == 0 || available_b == 0) break;
        counts[output] = 0;
        read_indices[output] = 0;
        write_offsets[output] = 0;
        const auto pairs = available_a < available_b ? available_a : available_b;
        for (std::uint32_t pair = 0; pair < pairs; ++pair)
            merge_run(tapes, starts, run_lengths, counts, read_indices, write_offsets,
                      input_a, input_b, output);
        remaining_total = counts[input_a] - read_indices[input_a]
            + counts[input_b] - read_indices[input_b] + counts[output];
        const auto left_a = counts[input_a] - read_indices[input_a];
        const auto left_b = counts[input_b] - read_indices[input_b];
        if (remaining_total <= 1 || (left_a == 0 && left_b == 0)) break;
        if (left_a > 0) {
            const auto exhausted = input_b;
            input_b = output;
            output = exhausted;
        } else {
            const auto exhausted = input_a;
            input_a = output;
            output = exhausted;
        }
    }
    for (std::uint32_t tape = 0; tape < 3; ++tape) {
        if (read_indices[tape] < counts[tape]) {
            const auto slot = read_indices[tape];
            if (run_lengths[tape][slot] == length) {
                const auto start = starts[tape][slot];
                for (std::size_t i = 0; i < length; ++i) values[i] = tapes[tape][start + i];
                return;
            }
        }
    }
}
