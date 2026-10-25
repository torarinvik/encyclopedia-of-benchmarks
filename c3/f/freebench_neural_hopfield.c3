module freebench_neural_hopfield;

const usz PATTERN_COUNT = 10;
const usz MAX_NEURONS = 8;
extern fn double exp(double value);
extern fn double fabs(double value);

fn float activation(float value) {
    double x = (double)value;
    if (x > 200.0) x = 200.0;
    if (x < -200.0) x = -200.0;
    double e = exp(-x);
    return (float)((1.0 - e) / (1.0 + e));
}

fn int run_cont(float* weights, long* source, usz neurons, long* dest) {
    float[MAX_NEURONS] temp_a;
    long[MAX_NEURONS] temp_c;
    for (usz neuron = 0; neuron < neurons; neuron++) {
        dest[neuron] = source[neuron];
        temp_a[neuron] = (float)source[neuron];
    }
    int stable = 0, threshold = 0, iterations = 0;
    while (stable == 0 && iterations < 500) {
        int threshold_iterations = 0;
        for (usz row = 0; row < neurons; row++) {
            float sum = 0.0f;
            for (usz neuron = 0; neuron < neurons; neuron++) sum += weights[row * neurons + neuron] * (float)source[neuron];
            temp_a[row] = activation(sum);
        }
        while (threshold == 0 && threshold_iterations < 50) {
            threshold = 1;
            for (usz row = 0; row < neurons; row++) {
                if (fabs((double)temp_a[row]) < 0.7) {
                    float sum = 0.0f;
                    for (usz neuron = 0; neuron < neurons; neuron++) sum += weights[row * neurons + neuron] * temp_a[neuron];
                    temp_a[row] = activation(sum);
                    if (temp_a[row] < 0.7f) threshold = 0;
                }
            }
            threshold_iterations++;
        }
        int same = 1;
        for (usz neuron = 0; neuron < neurons; neuron++) {
            temp_c[neuron] = temp_a[neuron] > 0.0f ? 1 : -1;
            if (dest[neuron] != temp_c[neuron]) same = 0;
        }
        if (same != 0) stable = 1;
        else {
            for (usz neuron = 0; neuron < neurons; neuron++) {
                if (dest[neuron] != temp_c[neuron]) { dest[neuron] = temp_c[neuron]; break; }
            }
            for (usz neuron = 0; neuron < neurons; neuron++) temp_a[neuron] = (float)dest[neuron];
        }
        iterations++;
    }
    return iterations == 500 ? -1 : iterations;
}

long freebench_neural_hopfield(long* input, usz length) @export("freebench_neural_hopfield") {
    if (input == null || length < 3 || length > 94) return -1;
    long width = input[0], height = input[1], pattern_count = input[2];
    if (width < 1 || width > 8 || height < 1 || height > 8 || pattern_count != PATTERN_COUNT.long()) return -1;
    usz neurons = (width * height).usz();
    if (neurons < 2 || neurons > MAX_NEURONS || length != 3 + PATTERN_COUNT * (1 + neurons)) return -1;
    long[MAX_NEURONS * PATTERN_COUNT] patterns;
    usz offset = 3;
    for (usz pattern = 0; pattern < PATTERN_COUNT; pattern++) {
        long label = input[offset++];
        if (label < 65 || label > 90) return -1;
        for (usz neuron = 0; neuron < neurons; neuron++) {
            long cell = input[offset++];
            if (cell != -1 && cell != 1) return -1;
            patterns[pattern * MAX_NEURONS + neuron] = cell;
            if (pattern != 0 && cell != patterns[neuron]) return -1;
        }
    }
    long hamming_warnings = 0;
    for (usz first = 0; first < PATTERN_COUNT; first++) {
        for (usz second = first + 1; second < PATTERN_COUNT; second++) {
            long normal = 0, complement = 0;
            for (usz neuron = 0; neuron < neurons; neuron++) {
                if (patterns[first * MAX_NEURONS + neuron] != patterns[second * MAX_NEURONS + neuron]) normal++;
                if (patterns[first * MAX_NEURONS + neuron] != -patterns[second * MAX_NEURONS + neuron]) complement++;
            }
            if (normal < 2) hamming_warnings++;
            if (complement < 2) hamming_warnings++;
        }
    }
    (void)hamming_warnings;
    float[MAX_NEURONS * MAX_NEURONS] weights;
    for (usz row = 0; row < neurons; row++) {
        for (usz column = 0; column < neurons; column++) weights[row * neurons + column] = 0.0f;
    }
    for (usz pattern = 0; pattern < PATTERN_COUNT; pattern++) {
        for (usz row = 0; row < neurons; row++) {
            for (usz column = 0; column < neurons; column++) {
                if (row == column) weights[row * neurons + column] = 0.0f;
                else weights[row * neurons + column] += (float)(patterns[pattern * MAX_NEURONS + row] * patterns[pattern * MAX_NEURONS + column]);
            }
        }
    }
    int converged = 0;
    for (usz pass = 0; pass < 1; pass++) {
        int status = 1;
        for (usz pattern = 0; pattern < PATTERN_COUNT; pattern++) {
            long[MAX_NEURONS] recalled;
            if (run_cont(&weights[0], &patterns[pattern * MAX_NEURONS], neurons, &recalled[0]) < 0) return -2;
            float[MAX_NEURONS] correction;
            for (usz neuron = 0; neuron < neurons; neuron++) {
                correction[neuron] = (float)(patterns[pattern * MAX_NEURONS + neuron] - recalled[neuron]) * 0.5f;
                if (correction[neuron] != 0.0f) status = 0;
            }
            for (usz row = 0; row < neurons; row++) {
                for (usz column = 0; column < neurons; column++) {
                    if (row == column) weights[row * neurons + column] = 0.0f;
                    else weights[row * neurons + column] += correction[row] * (float)patterns[pattern * MAX_NEURONS + column];
                }
            }
        }
        if (status != 0) { converged = 1; break; }
    }
    if (converged == 0) return -2;
    long stored_count = 0;
    for (usz pattern = 0; pattern < PATTERN_COUNT; pattern++) {
        long[MAX_NEURONS] recalled;
        if (run_cont(&weights[0], &patterns[pattern * MAX_NEURONS], neurons, &recalled[0]) < 0) return -2;
        int stored = 1;
        for (usz neuron = 0; neuron < neurons; neuron++) if (patterns[pattern * MAX_NEURONS + neuron] != recalled[neuron]) stored = 0;
        if (stored != 0) stored_count++;
    }
    return stored_count;
}
