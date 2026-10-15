#include <cstddef>
#include <cstdint>

static constexpr std::size_t MAX_INPUT_LENGTH = 100000;
static constexpr std::size_t MAX_VALUE = 100000;
static constexpr std::size_t REQUIRED_WORKSPACE = 4 * (MAX_VALUE + 1);

static std::int32_t read_state(const std::uint8_t *workspace, std::size_t value)
{
    const std::size_t position = 4 * value;
    const std::uint32_t encoded = static_cast<std::uint32_t>(workspace[position]) |
        (static_cast<std::uint32_t>(workspace[position + 1]) << 8) |
        (static_cast<std::uint32_t>(workspace[position + 2]) << 16) |
        (static_cast<std::uint32_t>(workspace[position + 3]) << 24);
    return static_cast<std::int32_t>(encoded);
}

static void write_state(std::uint8_t *workspace, std::size_t value, std::int32_t state)
{
    const auto encoded = static_cast<std::uint32_t>(state);
    const std::size_t position = 4 * value;
    workspace[position] = static_cast<std::uint8_t>(encoded);
    workspace[position + 1] = static_cast<std::uint8_t>(encoded >> 8);
    workspace[position + 2] = static_cast<std::uint8_t>(encoded >> 16);
    workspace[position + 3] = static_cast<std::uint8_t>(encoded >> 24);
}

static std::int64_t streak_from(std::uint8_t *workspace, std::size_t value)
{
    const std::int32_t state = read_state(workspace, value);
    if (state > 1) return static_cast<std::int64_t>(state - 1);
    std::int64_t length = 1;
    const std::uint64_t square = static_cast<std::uint64_t>(value) * value;
    if (square <= MAX_VALUE && read_state(workspace, static_cast<std::size_t>(square)) != 0)
        length += streak_from(workspace, static_cast<std::size_t>(square));
    write_state(workspace, value, static_cast<std::int32_t>(length + 1));
    return length;
}

extern "C" std::int64_t longest_square_streak(const std::int64_t *values, std::size_t length,
                                               std::uint8_t *workspace,
                                               std::size_t workspace_capacity)
{
    if (values == nullptr || length < 3 || length > MAX_INPUT_LENGTH + 1 ||
        values[0] < 2 || values[0] > static_cast<std::int64_t>(MAX_INPUT_LENGTH) ||
        length != static_cast<std::size_t>(values[0]) + 1) return -1;
    const std::size_t count = static_cast<std::size_t>(values[0]);
    for (std::size_t index = 0; index < count; ++index)
        if (values[index + 1] < 2 || values[index + 1] > static_cast<std::int64_t>(MAX_VALUE)) return -1;
    if (workspace == nullptr || workspace_capacity < REQUIRED_WORKSPACE) return -2;

    for (std::size_t byte_index = 0; byte_index < REQUIRED_WORKSPACE; ++byte_index)
        workspace[byte_index] = 0;
    for (std::size_t index = 0; index < count; ++index)
        write_state(workspace, static_cast<std::size_t>(values[index + 1]), 1);
    std::int64_t longest = 1;
    for (std::size_t index = 0; index < count; ++index) {
        const auto length_from_value = streak_from(workspace, static_cast<std::size_t>(values[index + 1]));
        if (length_from_value > longest) longest = length_from_value;
    }
    return longest >= 2 ? longest : -1;
}
