#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define IN 35
#define MID 8
#define OUT 8
#define SCALE 1000000.0

static void put_i64(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) out[offset + i] = (uint8_t)(bits >> (8 * i));
}

int64_t nbench_neural_network(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length != 1 || input[0] < 1 || input[0] > 8) return -1;
    if (output == NULL || capacity < 88) return -2;
    static const double pattern[IN] = {
        0,1,1,1,0, 1,0,0,0,1, 1,0,0,0,1, 1,0,0,0,1, 1,0,0,0,1,
        1,0,0,0,0, 0,1,1,1,0
    };
    static const double target[OUT] = {0,1,0,0,1,1,1,1};
    double mw[MID][IN], ow[OUT][MID], mc[MID][IN] = {{0}}, oc[OUT][MID] = {{0}};
    double mm[MID][IN] = {{0}}, om[OUT][MID] = {{0}}, mout[MID], oout[OUT];
    for (int n = 0; n < MID; ++n) for (int w = 0; w < IN; ++w)
        mw[n][w] = (double)(((n * 17 + w * 7) % 101) - 50) / 1000.0;
    for (int n = 0; n < OUT; ++n) for (int w = 0; w < MID; ++w)
        ow[n][w] = (double)(((n * 13 + w * 5) % 71) - 35) / 1000.0;

    for (int pass = 0; pass < input[0]; ++pass) {
        for (int n = 0; n < MID; ++n) for (int w = 0; w < IN; ++w) { mc[n][w] = mm[n][w]; mm[n][w] = 0; }
        for (int n = 0; n < OUT; ++n) for (int w = 0; w < MID; ++w) { oc[n][w] = om[n][w]; om[n][w] = 0; }
        for (int forward = 0; forward < 2; ++forward) for (int n = 0; n < MID; ++n) {
            double sum = 0;
            for (int w = 0; w < IN; ++w) sum += mw[n][w] * pattern[w];
            mout[n] = 1.0 / (1.0 + exp(-sum));
        }
        for (int n = 0; n < OUT; ++n) {
            double sum = 0;
            for (int w = 0; w < MID; ++w) sum += ow[n][w] * mout[w];
            oout[n] = 1.0 / (1.0 + exp(-sum));
        }
        double oe[OUT], me[MID];
        for (int n = 0; n < OUT; ++n) oe[n] = target[n] - oout[n];
        for (int n = 0; n < MID; ++n) {
            double sum = 0;
            for (int i = 0; i < OUT; ++i) sum += ow[i][n] * oe[i];
            me[n] = mout[n] * (1.0 - mout[n]) * sum;
        }
        for (int n = 0; n < OUT; ++n) for (int w = 0; w < MID; ++w) {
            double delta = 0.09 * oe[n] * mout[w]; delta += 0.09 * oc[n][w];
            ow[n][w] += delta; om[n][w] += delta;
        }
        for (int n = 0; n < MID; ++n) for (int w = 0; w < IN; ++w) {
            double delta = 0.09 * me[n] * pattern[w]; delta += 0.09 * mc[n][w];
            mw[n][w] += delta; mm[n][w] += delta;
        }
    }
    int64_t result[11]; result[0] = input[0];
    for (int i = 0; i < OUT; ++i) result[i + 1] = (int64_t)(oout[i] * SCALE);
    double ms = 0, os = 0;
    for (int n = 0; n < MID; ++n) for (int w = 0; w < IN; ++w) ms += mw[n][w];
    for (int n = 0; n < OUT; ++n) for (int w = 0; w < MID; ++w) os += ow[n][w];
    result[9] = (int64_t)(ms * SCALE); result[10] = (int64_t)(os * SCALE);
    for (size_t i = 0; i < 11; ++i) put_i64(output, i * 8, result[i]);
    return 88;
}
