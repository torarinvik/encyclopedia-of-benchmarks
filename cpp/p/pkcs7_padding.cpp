/* Bounded AddPadding, RemovePadding, and GetPaddingCount source extraction. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t pkcs7_padding(const std::int64_t *input, std::size_t length,
                                      std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 5 || length > 69) return -1;
    const std::int64_t operation = input[0], block_arg = input[1], offset_arg = input[2], data_arg = input[3];
    if (operation < 0 || operation > 2 || block_arg < 1 || block_arg > 16 ||
        data_arg < 1 || data_arg > 64 ||
        (operation == 0 && (offset_arg < 0 || offset_arg > data_arg)) ||
        length != static_cast<std::size_t>(data_arg) + 4) return -1;
    const std::size_t block_size = static_cast<std::size_t>(block_arg);
    const std::size_t offset = operation == 0 ? static_cast<std::size_t>(offset_arg) : 0;
    const std::size_t data_length = static_cast<std::size_t>(data_arg);
    for (std::size_t i = 0; i < data_length; ++i)
        if (input[4 + i] < 0 || input[4 + i] > 255) return -1;

    std::size_t padding_count, output_length;
    if (operation == 0) {
        padding_count = block_size - data_length % block_size;
        if (offset + padding_count > data_length) return -1;
        output_length = data_length + 1;
    } else if (operation == 1) {
        if (data_length % block_size != 0) return -1;
        padding_count = static_cast<std::size_t>(input[3 + data_length]);
        if (padding_count == 0 || padding_count > block_size) return -1;
        for (std::size_t i = data_length - padding_count; i < data_length; ++i)
            if (static_cast<std::size_t>(input[4 + i]) != padding_count) return -1;
        output_length = data_length - padding_count;
    } else {
        padding_count = static_cast<std::size_t>(input[3 + data_length]);
        const std::int64_t padding_start = static_cast<std::int64_t>(data_length)
            - static_cast<std::int64_t>(padding_count);
        const std::int64_t invalid_bits = padding_start | (static_cast<std::int64_t>(padding_count) - 1);
        std::int64_t padding_check_failed = -static_cast<std::int64_t>(
            static_cast<std::uint32_t>(static_cast<std::int32_t>(invalid_bits)) >> 31);
        for (std::size_t i = 0; i < data_length; ++i) {
            const std::int64_t difference = static_cast<std::int64_t>(i) - padding_start;
            const std::uint32_t negative_bit =
                static_cast<std::uint32_t>(static_cast<std::int32_t>(difference)) >> 31;
            const std::int64_t mask = -static_cast<std::int64_t>(1u - negative_bit);
            padding_check_failed |= (input[4 + i] ^ static_cast<std::int64_t>(padding_count)) & mask;
        }
        if (padding_check_failed != 0) return -1;
        output_length = 1;
    }
    if (output == nullptr || output_capacity < output_length) return -2;
    if (operation == 0) {
        output[0] = static_cast<std::uint8_t>(padding_count);
        for (std::size_t i = 0; i < data_length; ++i) {
            const std::size_t out_index = i + 1;
            output[out_index] = i >= offset && i < offset + padding_count
                ? static_cast<std::uint8_t>(padding_count)
                : static_cast<std::uint8_t>(input[4 + i]);
        }
    } else if (operation == 1) {
        for (std::size_t i = 0; i < output_length; ++i)
            output[i] = static_cast<std::uint8_t>(input[4 + i]);
    } else {
        output[0] = static_cast<std::uint8_t>(padding_count);
    }
    return static_cast<std::int64_t>(output_length);
}
