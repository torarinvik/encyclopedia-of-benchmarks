#include <cstddef>
#include <cstdint>

namespace {
constexpr int MAX_N = 14;
constexpr int MAX_DIAGS = 2 * MAX_N - 1;
constexpr int EMPTY_OWNER = 101;
constexpr std::size_t MAX_OUTPUT_BYTES = 80;

struct QueensState {
    int n{};
    int queen[MAX_N]{};
    int file[MAX_N]{};
    int forward_diag[MAX_DIAGS]{};
    int backward_diag[MAX_DIAGS]{};
    std::uint64_t solutions{};
};

void find_solutions(QueensState &state, int level)
{
    if (level == state.n) {
        ++state.solutions;
        return;
    }
    for (int file = 0; file < state.n; ++file) {
        const int forward = file + level;
        const int backward = level - file + state.n - 1;
        if (state.file[file] >= level
                && state.forward_diag[forward] >= level
                && state.backward_diag[backward] >= level) {
            state.queen[level] = file;
            state.file[file] = level;
            state.forward_diag[forward] = level;
            state.backward_diag[backward] = level;
            find_solutions(state, level + 1);
            state.file[file] = EMPTY_OWNER;
            state.forward_diag[forward] = EMPTY_OWNER;
            state.backward_diag[backward] = EMPTY_OWNER;
        }
    }
}

std::size_t append_literal(std::uint8_t *output, std::size_t position, const char *text)
{
    while (*text != '\0') output[position++] = static_cast<std::uint8_t>(*text++);
    return position;
}

std::size_t append_unsigned(std::uint8_t *output, std::size_t position,
                            std::uint64_t value)
{
    std::uint8_t reversed[24];
    std::size_t count = 0;
    do {
        reversed[count++] = static_cast<std::uint8_t>('0' + value % 10u);
        value /= 10u;
    } while (value != 0);
    while (count > 0) output[position++] = reversed[--count];
    return position;
}

std::size_t render_output(int n, std::uint64_t solutions, std::uint8_t *output)
{
    std::size_t position = append_unsigned(output, 0, static_cast<std::uint64_t>(n));
    position = append_literal(output, position, n == 1 ? " queen on a " : " queens on a ");
    position = append_unsigned(output, position, static_cast<std::uint64_t>(n));
    output[position++] = static_cast<std::uint8_t>('x');
    position = append_unsigned(output, position, static_cast<std::uint64_t>(n));
    position = append_literal(output, position, " board...\n");
    if (solutions == 1) {
        position = append_literal(output, position, "...there is 1 solution\n");
    } else {
        position = append_literal(output, position, "...there are ");
        position = append_unsigned(output, position, solutions);
        position = append_literal(output, position, " solutions\n");
    }
    return position;
}
}

extern "C" std::int64_t queens(std::int64_t n, std::uint8_t *output,
                                std::size_t output_capacity) noexcept
{
    if (n < 1 || n > MAX_N) return -1;

    QueensState state{};
    state.n = static_cast<int>(n);
    for (int file = 0; file < MAX_N; ++file) state.file[file] = EMPTY_OWNER;
    for (int diagonal = 0; diagonal < MAX_DIAGS; ++diagonal) {
        state.forward_diag[diagonal] = EMPTY_OWNER;
        state.backward_diag[diagonal] = EMPTY_OWNER;
    }
    find_solutions(state, 0);

    std::uint8_t formatted[MAX_OUTPUT_BYTES];
    const std::size_t required = render_output(state.n, state.solutions, formatted);
    if (output == nullptr || output_capacity < required) return -2;
    for (std::size_t index = 0; index < required; ++index) output[index] = formatted[index];
    return static_cast<std::int64_t>(required);
}
