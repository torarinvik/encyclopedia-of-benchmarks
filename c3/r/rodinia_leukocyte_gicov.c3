// Clean-room bounded GICOV recurrence; complete applicable notice in package LICENSE.txt.
module rodinia_leukocyte_gicov;

const usz GICOV_ELLIPSES = 7;
const usz GICOV_MAX_POINTS = 16;
const double GICOV_INVALID = -1.0e300;

fn float decode(long raw) { return (float)raw / 1000000.0f; }
fn float addf(float a, float b) { return a + b; }
fn float subf(float a, float b) { return a - b; }
fn float mulf(float a, float b) { return a * b; }
fn float divf(float a, float b) { return a / b; }

double rodinia_leukocyte_gicov(long* input, usz length) @export("rodinia_leukocyte_gicov") {
    if (input == null || length < 1) return GICOV_INVALID;
    if (input[0] < 2 || input[0] > (long)GICOV_MAX_POINTS) return GICOV_INVALID;
    usz points = (usz)input[0];
    if (length != 1 + GICOV_ELLIPSES * points) return GICOV_INVALID;
    for (usz i = 1; i < length; i++)
        if (input[i] < -1000000 || input[i] > 1000000) return GICOV_INVALID;

    float maximum = 0.0f;
    for (usz ellipse = 0; ellipse < GICOV_ELLIPSES; ellipse++) {
        float sum = 0.0f, mean = 0.0f, m2 = 0.0f;
        usz base = 1 + ellipse * points;
        for (usz n = 0; n < points; n++) {
            float p = decode(input[base + n]);
            sum = addf(sum, p);
            float delta = subf(p, mean);
            mean = addf(mean, divf(delta, (float)(n + 1)));
            m2 = addf(m2, mulf(delta, subf(p, mean)));
        }
        mean = divf(sum, (float)points);
        float variance = divf(m2, (float)(points - 1));
        if (!(variance > 0.0f)) return GICOV_INVALID;
        float score = divf(mulf(mean, mean), variance);
        if (score > maximum) maximum = score;
    }
    return (double)maximum;
}
