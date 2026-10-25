module parboil_tpacf_cross_correlation;

extern fn double cos(double value);
extern fn double log10(double value);
extern fn double pow(double base, double exponent);
const int NUM_BINS = 20;
const int MAX_POINTS = 4;
const int MAX_INPUT_LENGTH = 26;
const double PI_VALUE = 3.141592653589793238462643383279502884;

/* Parboil TPACF, Illinois Open Source License; see package LICENSE.txt. */
fn float coordinate(long* input, usz offset) {
    return input[offset].float() / 1000000.0f;
}

fn long parboil_tpacf_cross_correlation(long* input, usz input_length,
        uchar* output, usz output_capacity)
    @export("parboil_tpacf_cross_correlation") {
    if (input == null || input_length < 8 || input_length > MAX_INPUT_LENGTH) return -1;
    long data_value = input[0];
    long random_value = input[1];
    if (data_value < 1 || data_value > MAX_POINTS || random_value < 1 || random_value > MAX_POINTS) return -1;
    usz data_count = data_value.usz();
    usz random_count = random_value.usz();
    if (input_length != 2 + 3 * (data_count + random_count)) return -1;
    for (usz i = 2; i < input_length; i++) if (input[i] < -1000000 || input[i] > 1000000) return -1;
    if (output == null || output_capacity < NUM_BINS) return -2;

    [NUM_BINS + 1]float boundaries = zeroed;
    for (int k = 0; k <= NUM_BINS; k++) {
        double exponent = log10(1.0) + (double)k * 1.0 / 5.0;
        double arcminutes = pow(10.0, exponent);
        double radians = arcminutes / 60.0 * (PI_VALUE / 180.0);
        boundaries[k] = cos(radians).float();
    }
    [NUM_BINS]uchar histogram = zeroed;
    usz random_base = 2 + 3 * data_count;
    for (usz j = 0; j < random_count; j++) {
        float rx = coordinate(input, random_base + 3 * j);
        float ry = coordinate(input, random_base + 3 * j + 1);
        float rz = coordinate(input, random_base + 3 * j + 2);
        for (usz i = 0; i < data_count; i++) {
            float dx = coordinate(input, 2 + 3 * i);
            float dy = coordinate(input, 2 + 3 * i + 1);
            float dz = coordinate(input, 2 + 3 * i + 2);
            float px = dx * rx;
            float py = dy * ry;
            float pz = dz * rz;
            float xy = px + py;
            float distance = xy + pz;
            int min = 0, max = NUM_BINS;
            while (max > min + 1) {
                int middle = (min + max) / 2;
                if (distance >= boundaries[middle]) max = middle;
                else min = middle;
            }
            if (distance < boundaries[min] && distance >= boundaries[max]) histogram[max - 1]++;
        }
    }
    for (usz bin = 0; bin < NUM_BINS; bin++) output[bin] = histogram[bin];
    return NUM_BINS;
}
