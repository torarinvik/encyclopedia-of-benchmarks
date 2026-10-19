module deriche;

extern fn double exp(double value);
extern fn double pow(double base, double exponent);

const usz MAX_WIDTH = 32;
const usz MAX_HEIGHT = 32;
const usz MAX_PIXELS = MAX_WIDTH * MAX_HEIGHT;
const double INVALID_RESULT = -1e300;

fn void filter_once(usz width, usz height, float* image, float* output, float* y1, float* y2) {
    float alpha = 0.25f;
    float exp_neg_alpha = (float)exp(-(double)alpha);
    float difference = 1.0f - exp_neg_alpha;
    float numerator = difference * difference;
    float denominator_left = 1.0f + 2.0f * alpha * exp_neg_alpha;
    float k = numerator / (denominator_left - (float)exp(2.0 * (double)alpha));
    float a1 = k;
    float a2 = k * exp_neg_alpha * (alpha - 1.0f);
    float a3 = k * exp_neg_alpha * (alpha + 1.0f);
    float a4 = -k * (float)exp(-2.0 * (double)alpha);
    float a5 = k, a6 = a2, a7 = a3, a8 = a4;
    float b1 = (float)pow(2.0, -(double)alpha);
    float b2 = -(float)exp(-2.0 * (double)alpha);
    for (usz i = 0; i < width; i++) {
        float ym1 = 0.0f, ym2 = 0.0f, xm1 = 0.0f;
        for (usz j = 0; j < height; j++) {
            usz at = i * height + j;
            float value = a1 * image[at] + a2 * xm1;
            value = value + b1 * ym1; value = value + b2 * ym2; y1[at] = value;
            xm1 = image[at]; ym2 = ym1; ym1 = value;
        }
    }
    for (usz i = 0; i < width; i++) {
        float yp1 = 0.0f, yp2 = 0.0f, xp1 = 0.0f, xp2 = 0.0f;
        for (usz j = height; j > 0;) {
            j--;
            usz at = i * height + j;
            float value = a3 * xp1 + a4 * xp2;
            value = value + b1 * yp1; value = value + b2 * yp2; y2[at] = value;
            xp2 = xp1; xp1 = image[at]; yp2 = yp1; yp1 = value;
        }
    }
    for (usz i = 0; i < width; i++) for (usz j = 0; j < height; j++) {
        usz at = i * height + j; output[at] = 1.0f * (y1[at] + y2[at]);
    }
    for (usz j = 0; j < height; j++) {
        float tm1 = 0.0f, ym1 = 0.0f, ym2 = 0.0f;
        for (usz i = 0; i < width; i++) {
            usz at = i * height + j;
            float value = a5 * output[at] + a6 * tm1;
            value = value + b1 * ym1; value = value + b2 * ym2; y1[at] = value;
            tm1 = output[at]; ym2 = ym1; ym1 = value;
        }
    }
    for (usz j = 0; j < height; j++) {
        float tp1 = 0.0f, tp2 = 0.0f, yp1 = 0.0f, yp2 = 0.0f;
        for (usz i = width; i > 0;) {
            i--;
            usz at = i * height + j;
            float value = a7 * tp1 + a8 * tp2;
            value = value + b1 * yp1; value = value + b2 * yp2; y2[at] = value;
            tp2 = tp1; tp1 = output[at]; yp2 = yp1; yp1 = value;
        }
    }
    for (usz at = 0; at < width * height; at++) output[at] = 1.0f * (y1[at] + y2[at]);
}

double deriche(long* values, ulong length) @export("deriche") {
    if (values == null || length != 3 || values[0] < 1 || values[0] > (long)MAX_WIDTH ||
        values[1] < 1 || values[1] > (long)MAX_HEIGHT || values[2] < 1 || values[2] > 4)
        return INVALID_RESULT;
    usz width = (usz)values[0], height = (usz)values[1];
    float[MAX_PIXELS] image = {};
    float[MAX_PIXELS] output = {};
    float[MAX_PIXELS] y1 = {};
    float[MAX_PIXELS] y2 = {};
    for (usz i = 0; i < width; i++) for (usz j = 0; j < height; j++)
        image[i * height + j] = (float)((313 * i + 991 * j) % 65536) / 65535.0f;
    for (long pass = 0; pass < values[2]; pass++) {
        filter_once(width, height, &image[0], &output[0], &y1[0], &y2[0]);
        for (usz at = 0; at < width * height; at++) image[at] = output[at];
    }
    double checksum = 0.0;
    for (usz at = 0; at < width * height; at++) checksum += (double)output[at];
    return checksum;
}
