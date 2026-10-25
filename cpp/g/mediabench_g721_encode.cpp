/*
 * This source code is a product of Sun Microsystems, Inc. and is provided
 * for unrestricted use.  Users may copy or modify this source code without
 * charge.
 *
 * SUN SOURCE CODE IS PROVIDED AS IS WITH NO WARRANTIES OF ANY KIND INCLUDING
 * THE WARRANTIES OF DESIGN, MERCHANTIBILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE, OR ARISING FROM A COURSE OF DEALING, USAGE OR TRADE PRACTICE.
 *
 * Sun source code is provided with no support and without any obligation on
 * the part of Sun Microsystems, Inc. to assist in its use, correction,
 * modification or enhancement.
 *
 * SUN MICROSYSTEMS, INC. SHALL HAVE NO LIABILITY WITH RESPECT TO THE
 * INFRINGEMENT OF COPYRIGHTS, TRADE SECRETS OR ANY PATENTS BY THIS SOFTWARE
 * OR ANY PART THEREOF.
 *
 * In no event will Sun Microsystems, Inc. be liable for any lost revenue
 * or profits or other special, indirect and consequential damages, even if
 * Sun has been advised of the possibility of such damages.
 *
 * Sun Microsystems, Inc.
 * 2550 Garcia Avenue
 * Mountain View, California  94043
 */

#include <cstddef>
#include <cstdint>
#include <cstdlib>

namespace {
constexpr std::size_t kMaxSamples = 16;
constexpr std::int64_t kPower2[15] = {1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384};
constexpr std::int64_t kQtab[7] = {-124,80,178,246,300,349,400};
constexpr std::int64_t kDqlntab[16] = {-2048,4,135,213,273,323,373,425,425,373,323,273,213,135,4,-2048};
constexpr std::int64_t kWitab[16] = {-12,18,41,64,112,198,355,1122,1122,355,198,112,64,41,18,-12};
constexpr std::int64_t kFitab[16] = {0,0,0,512,512,512,1536,3584,3584,1536,512,512,512,0,0,0};

struct State {
    std::int64_t yl, yu, dms, dml, ap;
    std::int64_t a[2], b[6], pk[2], dq[6], sr[2], td;
};

std::int64_t wrap16(std::int64_t value) {
    const std::uint64_t low = static_cast<std::uint64_t>(value) & UINT64_C(0xffff);
    return low >= UINT64_C(0x8000) ? static_cast<std::int64_t>(low) - 65536 : static_cast<std::int64_t>(low);
}
std::int64_t quant_table(std::int64_t value, const std::int64_t *table, int count) {
    int i = 0;
    for (; i < count && value >= table[i]; ++i) {}
    return i;
}
std::int64_t fmult(std::int64_t coefficient, std::int64_t encoded) {
    const std::int64_t magnitude = coefficient > 0 ? coefficient : ((-coefficient) & 0x1fff);
    const std::int64_t exponent = quant_table(magnitude, kPower2, 15) - 6;
    const std::int64_t mantissa = magnitude == 0 ? 32 : (exponent >= 0 ? magnitude >> exponent : magnitude << -exponent);
    const std::int64_t product_exponent = exponent + ((encoded >> 6) & 15) - 13;
    const std::int64_t product_mantissa = (mantissa * (encoded & 077) + 0x30) >> 4;
    const std::int64_t result = product_exponent >= 0 ? ((product_mantissa << product_exponent) & 0x7fff) : (product_mantissa >> -product_exponent);
    return ((coefficient ^ encoded) < 0) ? -result : result;
}
std::int64_t predictor_zero(const State &s) {
    std::int64_t sum = fmult(s.b[0] >> 2, s.dq[0]);
    for (int i = 1; i < 6; ++i) sum += fmult(s.b[i] >> 2, s.dq[i]);
    return sum;
}
std::int64_t predictor_pole(const State &s) {
    return fmult(s.a[1] >> 2, s.sr[1]) + fmult(s.a[0] >> 2, s.sr[0]);
}
std::int64_t step_size(const State &s) {
    if (s.ap >= 256) return s.yu;
    std::int64_t y = s.yl >> 6;
    const std::int64_t difference = s.yu - y;
    const std::int64_t weight = s.ap >> 2;
    if (difference > 0) y += (difference * weight) >> 6;
    else if (difference < 0) y += (difference * weight + 0x3f) >> 6;
    return y;
}
std::int64_t quantize(std::int64_t difference, std::int64_t step) {
    const std::int64_t magnitude = difference < 0 ? -difference : difference;
    const std::int64_t exponent = quant_table(magnitude >> 1, kPower2, 15);
    const std::int64_t mantissa = ((magnitude << 7) >> exponent) & 0x7f;
    const std::int64_t normalized = ((exponent << 7) + mantissa) - (step >> 2);
    const std::int64_t index = quant_table(normalized, kQtab, 7);
    return difference < 0 ? 15 - index : (index == 0 ? 15 : index);
}
std::int64_t reconstruct(std::int64_t sign, std::int64_t log_difference, std::int64_t step) {
    const std::int64_t log_value = log_difference + (step >> 2);
    if (log_value < 0) return sign ? -32768 : 0;
    const std::int64_t exponent = (log_value >> 7) & 15;
    const std::int64_t mantissa = 128 + (log_value & 127);
    const std::int64_t value = (mantissa << 7) >> (14 - exponent);
    return sign ? value - 32768 : value;
}
void update_state(std::int64_t step, std::int64_t wi, std::int64_t fi, std::int64_t dq,
                  std::int64_t sr, std::int64_t dqsez, State &s) {
    const std::int64_t magnitude = dq & 0x7fff;
    const std::int64_t ylint = s.yl >> 15;
    const std::int64_t ylfrac = (s.yl >> 10) & 0x1f;
    const std::int64_t threshold1 = (32 + ylfrac) << ylint;
    const std::int64_t threshold2 = ylint > 9 ? 31 << 10 : threshold1;
    const std::int64_t dq_threshold = (threshold2 + (threshold2 >> 1)) >> 1;
    const bool transition = s.td != 0 && magnitude > dq_threshold;
    s.yu = wrap16(step + ((wi - step) >> 5));
    if (s.yu < 544) s.yu = 544; else if (s.yu > 5120) s.yu = 5120;
    s.yl += s.yu + ((-s.yl) >> 6);
    if (transition) {
        s.a[0] = s.a[1] = 0;
        for (int i = 0; i < 6; ++i) s.b[i] = 0;
    } else {
        const std::int64_t pk0 = dqsez < 0 ? 1 : 0;
        const std::int64_t pks1 = pk0 ^ s.pk[0];
        std::int64_t a2p = s.a[1] - (s.a[1] >> 7);
        if (dqsez != 0) {
            const std::int64_t fa1 = pks1 ? s.a[0] : -s.a[0];
            if (fa1 < -8191) a2p -= 0x100;
            else if (fa1 > 8191) a2p += 0xff;
            else a2p += fa1 >> 5;
            if (pk0 ^ s.pk[1]) {
                if (a2p <= -12160) a2p = -12288;
                else if (a2p >= 12416) a2p = 12288;
                else a2p -= 0x80;
            } else {
                if (a2p <= -12416) a2p = -12288;
                else if (a2p >= 12160) a2p = 12288;
                else a2p += 0x80;
            }
        }
        a2p = wrap16(a2p);
        s.a[1] = a2p;
        s.a[0] = wrap16(s.a[0] - (s.a[0] >> 8));
        if (dqsez != 0) s.a[0] = wrap16(s.a[0] + (pks1 == 0 ? 192 : -192));
        const std::int64_t limit = 15360 - a2p;
        if (s.a[0] < -limit) s.a[0] = -limit; else if (s.a[0] > limit) s.a[0] = limit;
        s.a[0] = wrap16(s.a[0]);
        for (int i = 0; i < 6; ++i) {
            s.b[i] = wrap16(s.b[i] - (s.b[i] >> 8));
            if (dq & 0x7fff) s.b[i] = wrap16(s.b[i] + (((dq ^ s.dq[i]) >= 0) ? 128 : -128));
        }
    }
    for (int i = 5; i > 0; --i) s.dq[i] = s.dq[i - 1];
    if (magnitude == 0) s.dq[0] = dq >= 0 ? 0x20 : wrap16(0xfc20);
    else {
        const std::int64_t exponent = quant_table(magnitude, kPower2, 15);
        const std::int64_t encoded = (exponent << 6) + ((magnitude << 6) >> exponent);
        s.dq[0] = wrap16(dq >= 0 ? encoded : encoded - 0x400);
    }
    s.sr[1] = s.sr[0];
    if (sr == 0) s.sr[0] = 0x20;
    else if (sr > 0) {
        const std::int64_t exponent = quant_table(sr, kPower2, 15);
        s.sr[0] = wrap16((exponent << 6) + ((sr << 6) >> exponent));
    } else if (sr > -32768) {
        const std::int64_t absolute = -sr;
        const std::int64_t exponent = quant_table(absolute, kPower2, 15);
        s.sr[0] = wrap16((exponent << 6) + ((absolute << 6) >> exponent) - 0x400);
    } else s.sr[0] = wrap16(0xfc20);
    s.pk[1] = s.pk[0];
    s.pk[0] = dqsez < 0 ? 1 : 0;
    s.td = transition ? 0 : (s.a[1] < -11776 ? 1 : 0);
    s.dms = wrap16(s.dms + ((fi - s.dms) >> 5));
    s.dml = wrap16(s.dml + (((fi << 2) - s.dml) >> 7));
    if (transition) s.ap = 256;
    else if (step < 1536 || s.td == 1 || std::llabs((s.dms << 2) - s.dml) >= (s.dml >> 3))
        s.ap = wrap16(s.ap + ((0x200 - s.ap) >> 4));
    else s.ap = wrap16(s.ap + ((-s.ap) >> 4));
}
void init_state(State &s) {
    s.yl = 34816; s.yu = 544; s.dms = s.dml = s.ap = 0; s.td = 0;
    for (int i = 0; i < 2; ++i) { s.a[i] = s.pk[i] = 0; s.sr[i] = 32; }
    for (int i = 0; i < 6; ++i) { s.b[i] = 0; s.dq[i] = 32; }
}
std::int64_t ulaw_to_linear(std::int64_t input) {
    const std::int64_t value = (~input) & 0xff;
    std::int64_t sample = ((value & 15) << 3) + 0x84;
    sample <<= (value & 0x70) >> 4;
    return (value & 0x80) ? 0x84 - sample : sample - 0x84;
}
std::int64_t encode_one(std::int64_t input, State &s) {
    const std::int64_t sample = ulaw_to_linear(input) >> 2;
    const std::int64_t sezi = wrap16(predictor_zero(s));
    const std::int64_t sez = sezi >> 1;
    const std::int64_t se = wrap16((sezi + predictor_pole(s)) >> 1);
    const std::int64_t difference = wrap16(sample - se);
    const std::int64_t step = wrap16(step_size(s));
    const std::int64_t code = quantize(difference, step);
    const std::int64_t dq = wrap16(reconstruct(code & 8, kDqlntab[code], step));
    const std::int64_t sr = wrap16(dq < 0 ? se - (dq & 0x3fff) : se + dq);
    const std::int64_t dqsez = wrap16(sr + sez - se);
    update_state(step, kWitab[code] << 5, kFitab[code], dq, sr, dqsez, s);
    return code;
}
}

extern "C" std::int64_t mediabench_g721_encode(const std::int64_t *input, std::size_t input_length,
                                                std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || input_length < 1 || input_length > kMaxSamples + 1) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(kMaxSamples)) return -1;
    const std::size_t count = static_cast<std::size_t>(input[0]);
    if (input_length != count + 1) return -1;
    for (std::size_t i = 0; i < count; ++i) if (input[i + 1] < 0 || input[i + 1] > 255) return -1;
    const std::size_t required = (count + 1) / 2;
    if (required == 0) return 0;
    if (output == nullptr || output_capacity < required) return -2;
    State state{};
    init_state(state);
    for (std::size_t i = 0; i < count; ++i) {
        const auto code = static_cast<std::uint8_t>(encode_one(input[i + 1], state));
        if ((i & 1u) == 0) output[i / 2] = code;
        else output[i / 2] |= static_cast<std::uint8_t>(code << 4);
    }
    return static_cast<std::int64_t>(required);
}
