module parboil_mri_q;

extern fn float cosf(float value);
extern fn float sinf(float value);

const int MAX_K = 4;
const int MAX_INPUT_LENGTH = 24;
const float PI_X_2 = 6.2831853071795864769252867665590058f;

/* Clean-room Parboil MRI-Q profile; Illinois Open Source License in package docs. */
fn float decode_component(long raw) { return raw.float() / 1000000.0f; }

fn int quantize_q(float value) {
    float scaled = value * 1000.0f;
    float magnitude = if scaled < 0.0f then -scaled else scaled;
    int whole = (int)magnitude;
    float fraction = magnitude - whole.float();
    if (fraction >= 0.5f) whole++;
    return if scaled < 0.0f then -whole else whole;
}

fn void write_i32_le(uchar* output, usz offset, int value) {
    uint bits = (uint)value;
    output[offset] = (uchar)bits;
    output[offset + 1] = (uchar)(bits >> 8);
    output[offset + 2] = (uchar)(bits >> 16);
    output[offset + 3] = (uchar)(bits >> 24);
}

fn long parboil_mri_q(long* input, usz input_length, uchar* output, usz output_capacity)
    @export("parboil_mri_q") {
    if (input == null || input_length < 9 || input_length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_K) return -1;
    usz count = input[0].usz();
    if (input_length != 4 + 5 * count) return -1;
    for (usz i = 1; i < input_length; i++)
        if (input[i] < -1000000 || input[i] > 1000000) return -1;
    if (output == null || output_capacity < 8) return -2;

    float x = decode_component(input[1]);
    float y = decode_component(input[2]);
    float z = decode_component(input[3]);
    [MAX_K]float phi_magnitudes = zeroed;
    for (usz k = 0; k < count; k++) {
        usz offset = 4 + 5 * k;
        float phi_real = decode_component(input[offset + 3]);
        float phi_imag = decode_component(input[offset + 4]);
        float real_square = phi_real * phi_real;
        float imag_square = phi_imag * phi_imag;
        phi_magnitudes[k] = real_square + imag_square;
    }
    float qr = 0.0f, qi = 0.0f;
    for (usz k = 0; k < count; k++) {
        usz offset = 4 + 5 * k;
        float kx = decode_component(input[offset]);
        float ky = decode_component(input[offset + 1]);
        float kz = decode_component(input[offset + 2]);
        float kx_x = kx * x;
        float ky_y = ky * y;
        float kz_z = kz * z;
        float xy = kx_x + ky_y;
        float xyz = xy + kz_z;
        float phase = PI_X_2 * xyz;
        float cos_phase = cosf(phase);
        float sin_phase = sinf(phase);
        float qr_term = phi_magnitudes[k] * cos_phase;
        float qi_term = phi_magnitudes[k] * sin_phase;
        qr = qr + qr_term;
        qi = qi + qi_term;
    }
    write_i32_le(output, 0, quantize_q(qr));
    write_i32_le(output, 4, quantize_q(qi));
    return 8;
}
