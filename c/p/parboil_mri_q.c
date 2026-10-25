#include <math.h>
#include <stddef.h>
#include <stdint.h>

/* Clean-room Parboil MRI-Q profile; Illinois Open Source License in package docs. */
enum { MAX_K = 4, MAX_INPUT_LENGTH = 24, OUTPUT_BYTES = 8 };
static const float PI_X_2 = 6.2831853071795864769252867665590058f;

static float decode_component(int64_t raw)
{
    return (float)raw / 1000000.0f;
}

static int32_t quantize_q(float value)
{
    const float scaled = value * 1000.0f;
    const float magnitude = scaled < 0.0f ? -scaled : scaled;
    int32_t whole = (int32_t)magnitude;
    const float fraction = magnitude - (float)whole;
    if (fraction >= 0.5f) ++whole;
    return scaled < 0.0f ? -whole : whole;
}

static void write_i32_le(uint8_t *output, size_t offset, int32_t value)
{
    const uint32_t bits = (uint32_t)value;
    output[offset] = (uint8_t)bits;
    output[offset + 1u] = (uint8_t)(bits >> 8);
    output[offset + 2u] = (uint8_t)(bits >> 16);
    output[offset + 3u] = (uint8_t)(bits >> 24);
}

int64_t parboil_mri_q(const int64_t *input, size_t input_length,
                      uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length < 9u || input_length > MAX_INPUT_LENGTH) return -1;
    const int64_t count_value = input[0];
    if (count_value < 1 || count_value > MAX_K) return -1;
    const size_t count = (size_t)count_value;
    if (input_length != 4u + 5u * count) return -1;
    for (size_t i = 1; i < input_length; ++i)
        if (input[i] < -1000000 || input[i] > 1000000) return -1;
    if (output == NULL || output_capacity < OUTPUT_BYTES) return -2;

    const float x = decode_component(input[1]);
    const float y = decode_component(input[2]);
    const float z = decode_component(input[3]);
    float phi_magnitudes[MAX_K];
    for (size_t k = 0; k < count; ++k) {
        const size_t offset = 4u + 5u * k;
        const float phi_real = decode_component(input[offset + 3u]);
        const float phi_imag = decode_component(input[offset + 4u]);
        const float real_square = phi_real * phi_real;
        const float imag_square = phi_imag * phi_imag;
        phi_magnitudes[k] = real_square + imag_square;
    }
    float qr = 0.0f;
    float qi = 0.0f;
    for (size_t k = 0; k < count; ++k) {
        const size_t offset = 4u + 5u * k;
        const float kx = decode_component(input[offset]);
        const float ky = decode_component(input[offset + 1u]);
        const float kz = decode_component(input[offset + 2u]);
        const float kx_x = kx * x;
        const float ky_y = ky * y;
        const float kz_z = kz * z;
        const float xy = kx_x + ky_y;
        const float xyz = xy + kz_z;
        const float phase = PI_X_2 * xyz;
        const float cos_phase = cosf(phase);
        const float sin_phase = sinf(phase);
        const float qr_term = phi_magnitudes[k] * cos_phase;
        const float qi_term = phi_magnitudes[k] * sin_phase;
        qr = qr + qr_term;
        qi = qi + qi_term;
    }
    write_i32_le(output, 0u, quantize_q(qr));
    write_i32_le(output, 4u, quantize_q(qi));
    return OUTPUT_BYTES;
}
