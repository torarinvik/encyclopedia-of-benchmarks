#include <cmath>
#include <cstddef>
#include <cstdint>

/* Clean-room Parboil MRI-Q profile; Illinois Open Source License in package docs. */
namespace {
constexpr std::size_t MAX_INPUT_LENGTH = 24;
constexpr std::size_t OUTPUT_BYTES = 8;
constexpr float PI_X_2 = 6.2831853071795864769252867665590058f;

float decode_component(std::int64_t raw) { return static_cast<float>(raw) / 1000000.0f; }
std::int32_t quantize_q(float value)
{
    const float scaled = value * 1000.0f;
    const float magnitude = scaled < 0.0f ? -scaled : scaled;
    std::int32_t whole = static_cast<std::int32_t>(magnitude);
    const float fraction = magnitude - static_cast<float>(whole);
    if (fraction >= 0.5f) ++whole;
    return scaled < 0.0f ? -whole : whole;
}
void write_i32_le(std::uint8_t *output, std::size_t offset, std::int32_t value)
{
    const std::uint32_t bits = static_cast<std::uint32_t>(value);
    output[offset] = static_cast<std::uint8_t>(bits);
    output[offset + 1] = static_cast<std::uint8_t>(bits >> 8);
    output[offset + 2] = static_cast<std::uint8_t>(bits >> 16);
    output[offset + 3] = static_cast<std::uint8_t>(bits >> 24);
}
}

extern "C" std::int64_t parboil_mri_q(const std::int64_t *input, std::size_t input_length,
                                      std::uint8_t *output, std::size_t output_capacity)
{
    if (input == nullptr || input_length < 9 || input_length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > 4) return -1;
    const std::size_t count = static_cast<std::size_t>(input[0]);
    if (input_length != 4 + 5 * count) return -1;
    for (std::size_t i = 1; i < input_length; ++i)
        if (input[i] < -1000000 || input[i] > 1000000) return -1;
    if (output == nullptr || output_capacity < OUTPUT_BYTES) return -2;

    const float x = decode_component(input[1]);
    const float y = decode_component(input[2]);
    const float z = decode_component(input[3]);
    float phi_magnitudes[4];
    for (std::size_t k = 0; k < count; ++k) {
        const std::size_t offset = 4 + 5 * k;
        const float phi_real = decode_component(input[offset + 3]);
        const float phi_imag = decode_component(input[offset + 4]);
        const float real_square = phi_real * phi_real;
        const float imag_square = phi_imag * phi_imag;
        phi_magnitudes[k] = real_square + imag_square;
    }
    float qr = 0.0f, qi = 0.0f;
    for (std::size_t k = 0; k < count; ++k) {
        const std::size_t offset = 4 + 5 * k;
        const float kx = decode_component(input[offset]);
        const float ky = decode_component(input[offset + 1]);
        const float kz = decode_component(input[offset + 2]);
        const float kx_x = kx * x;
        const float ky_y = ky * y;
        const float kz_z = kz * z;
        const float xy = kx_x + ky_y;
        const float xyz = xy + kz_z;
        const float phase = PI_X_2 * xyz;
        const float cos_phase = ::cosf(phase);
        const float sin_phase = ::sinf(phase);
        const float qr_term = phi_magnitudes[k] * cos_phase;
        const float qi_term = phi_magnitudes[k] * sin_phase;
        qr = qr + qr_term;
        qi = qi + qi_term;
    }
    write_i32_le(output, 0, quantize_q(qr));
    write_i32_le(output, 4, quantize_q(qi));
    return static_cast<std::int64_t>(OUTPUT_BYTES);
}
