/* Bounded command trace for the pinned C# Timeline<TValue> collection. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_INITIAL_EVENTS = 16;
constexpr std::size_t MAX_COMMANDS = 32;
constexpr std::size_t MAX_EVENTS = MAX_INITIAL_EVENTS + MAX_COMMANDS;
constexpr std::size_t MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_INITIAL_EVENTS + 3 * MAX_COMMANDS;
constexpr std::size_t MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1;
constexpr std::size_t MAX_OUTPUT_WORDS = 691;

void push_word(std::array<std::int64_t, MAX_OUTPUT_WORDS>& words,
               std::size_t& count, std::int64_t value) {
    words[count++] = value;
}
}  // namespace

extern "C" std::int64_t timeline(const std::int64_t* input, std::size_t input_length,
                                  std::uint8_t* output, std::size_t output_capacity) {
    if (input == nullptr || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(MAX_INITIAL_EVENTS)) return -1;
    const auto initial_count = static_cast<std::size_t>(input[0]);
    const std::size_t command_count_index = 1 + 2 * initial_count;
    if (command_count_index >= input_length || input[command_count_index] < 0 ||
        input[command_count_index] > static_cast<std::int64_t>(MAX_COMMANDS)) return -1;
    const auto command_count = static_cast<std::size_t>(input[command_count_index]);
    if (input_length != 2 + 2 * initial_count + 3 * command_count) return -1;

    std::array<std::int64_t, MAX_EVENTS> event_times{};
    std::array<std::int64_t, MAX_EVENTS> event_values{};
    std::array<std::int64_t, MAX_COMMANDS> operations{};
    std::array<std::int64_t, MAX_COMMANDS> first_arguments{};
    std::array<std::int64_t, MAX_COMMANDS> second_arguments{};
    std::size_t event_count = initial_count;
    for (std::size_t index = 0; index < initial_count; ++index) {
        const auto time = input[1 + 2 * index];
        const auto value = input[2 + 2 * index];
        if (time < 0 || time > 1000000 || value < -32 || value > 32) return -1;
        event_times[index] = time;
        event_values[index] = value;
    }
    // Stable insertion sort matches the constructor's OrderBy.
    for (std::size_t index = 1; index < initial_count; ++index) {
        const auto time = event_times[index];
        const auto value = event_values[index];
        std::size_t position = index;
        while (position > 0 && event_times[position - 1] > time) {
            event_times[position] = event_times[position - 1];
            event_values[position] = event_values[position - 1];
            --position;
        }
        event_times[position] = time;
        event_values[position] = value;
    }

    std::size_t offset = command_count_index + 1;
    for (std::size_t index = 0; index < command_count; ++index) {
        const auto opcode = input[offset];
        const auto first = input[offset + 1];
        const auto second = input[offset + 2];
        if (opcode < 0 || opcode > 14) return -1;
        if (opcode <= 2) {
            if (first < 0 || first > 1000000 || second < -32 || second > 32) return -1;
        } else if (opcode == 3 || opcode == 4 || opcode == 5 || opcode == 6 || opcode == 8) {
            if (first < 0 || first > 1000000 || second != 0) return -1;
        } else if (opcode == 7 || opcode == 9) {
            if (first < -32 || first > 32 || second != 0) return -1;
        } else if (first != 0 || second != 0) return -1;
        operations[index] = opcode;
        first_arguments[index] = first;
        second_arguments[index] = second;
        offset += 3;
    }

    std::array<std::int64_t, MAX_OUTPUT_WORDS> words{};
    std::size_t word_count = 0;
    for (std::size_t command = 0; command < command_count; ++command) {
        const auto opcode = operations[command];
        const auto first = first_arguments[command];
        const auto second = second_arguments[command];
        const std::size_t count_index = word_count + 1;
        push_word(words, word_count, opcode);
        push_word(words, word_count, 0);

        if (opcode == 0) {
            event_times[event_count] = first;
            event_values[event_count++] = second;
        } else if (opcode == 1) {
            bool found = false;
            for (std::size_t index = 0; index < event_count; ++index)
                if (event_times[index] == first && event_values[index] == second) found = true;
            push_word(words, word_count, found ? 1 : 0);
        } else if (opcode == 2) {
            std::size_t found = event_count;
            for (std::size_t index = 0; index < event_count; ++index)
                if (event_times[index] == first && event_values[index] == second) { found = index; break; }
            if (found < event_count) {
                for (std::size_t index = found + 1; index < event_count; ++index) {
                    event_times[index - 1] = event_times[index];
                    event_values[index - 1] = event_values[index];
                }
                --event_count;
                push_word(words, word_count, 1);
            } else push_word(words, word_count, 0);
        } else if (opcode == 3) {
            for (std::size_t index = 0; index < event_count; ++index)
                if (event_times[index] == first) push_word(words, word_count, event_values[index]);
        } else if (opcode == 4 || opcode == 5 || opcode == 10 || opcode == 12) {
            std::array<std::int64_t, MAX_EVENTS> unique{};
            std::size_t unique_count = 0;
            for (std::size_t index = 0; index < event_count; ++index) {
                bool seen = false;
                for (std::size_t prior = 0; prior < index; ++prior)
                    if (event_times[prior] == event_times[index]) seen = true;
                if (!seen && (opcode == 10 || opcode == 12 ||
                    (opcode == 4 && event_times[index] < first) ||
                    (opcode == 5 && event_times[index] > first))) unique[unique_count++] = event_times[index];
            }
            if (opcode == 4 || opcode == 5) {
                for (std::size_t index = 1; index < unique_count; ++index) {
                    const auto value = unique[index];
                    std::size_t position = index;
                    while (position > 0 && unique[position - 1] > value) {
                        unique[position] = unique[position - 1];
                        --position;
                    }
                    unique[position] = value;
                }
            }
            if (opcode == 12) push_word(words, word_count, static_cast<std::int64_t>(unique_count));
            else for (std::size_t index = 0; index < unique_count; ++index) push_word(words, word_count, unique[index]);
        } else if (opcode == 6 || opcode == 7) {
            const bool by_time = opcode == 6;
            bool existed = false;
            std::size_t write = 0;
            for (std::size_t index = 0; index < event_count; ++index) {
                const bool matches = by_time ? event_times[index] == first : event_values[index] == first;
                if (matches) existed = true;
                else {
                    event_times[write] = event_times[index];
                    event_values[write++] = event_values[index];
                }
            }
            event_count = write;
            push_word(words, word_count, existed ? 1 : 0);
        } else if (opcode == 8 || opcode == 9) {
            bool found = false;
            for (std::size_t index = 0; index < event_count; ++index)
                if ((opcode == 8 && event_times[index] == first) ||
                    (opcode == 9 && event_values[index] == first)) found = true;
            push_word(words, word_count, found ? 1 : 0);
        } else if (opcode == 11) {
            for (std::size_t index = 0; index < event_count; ++index) push_word(words, word_count, event_values[index]);
        } else if (opcode == 13) push_word(words, word_count, static_cast<std::int64_t>(event_count));
        else event_count = 0;

        words[count_index] = static_cast<std::int64_t>(word_count - count_index - 1);
    }

    push_word(words, word_count, -1);
    push_word(words, word_count, static_cast<std::int64_t>(event_count));
    for (std::size_t index = 0; index < event_count; ++index) {
        push_word(words, word_count, event_times[index]);
        push_word(words, word_count, event_values[index]);
    }
    const std::size_t output_bytes = word_count * 8;
    if (output == nullptr || output_capacity < output_bytes) return -2;
    for (std::size_t index = 0; index < word_count; ++index) {
        const auto bits = static_cast<std::uint64_t>(words[index]);
        for (std::size_t byte = 0; byte < 8; ++byte)
            output[index * 8 + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
    }
    return static_cast<std::int64_t>(output_bytes);
}
