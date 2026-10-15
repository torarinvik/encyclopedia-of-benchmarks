/* Timing runner for byte-output algorithms over a signed 64-bit input array. */
#include <errno.h>
#include <float.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#ifndef BENCHMARK_FUNCTION
#error "Compile with -DBENCHMARK_FUNCTION=<exported function symbol>"
#endif

#define MAX_INPUT_LENGTH 100002
#define MAX_OUTPUT_BYTES 400004
typedef int64_t (*output_fn)(const int64_t *, size_t, uint8_t *, size_t);
extern int64_t BENCHMARK_FUNCTION(const int64_t *values, size_t length,
                                 uint8_t *output, size_t output_capacity);
static output_fn volatile run_algorithm = BENCHMARK_FUNCTION;

static int parse_u64(const char *text, uint64_t *value)
{
    char *end = NULL;
    unsigned long long parsed;
    if (text[0] == '-' || text[0] == '\0') return 0;
    errno = 0;
    parsed = strtoull(text, &end, 10);
    if (errno == ERANGE || end == text || *end != '\0') return 0;
    *value = (uint64_t)parsed;
    return 1;
}

static int parse_i64(const char *text, int64_t *value)
{
    char *end = NULL;
    long long parsed;
    if (text[0] == '\0') return 0;
    errno = 0;
    parsed = strtoll(text, &end, 10);
    if (errno == ERANGE || end == text || *end != '\0') return 0;
    *value = (int64_t)parsed;
    return 1;
}

static int decode_hex(const char *text, uint8_t *output, size_t bytes)
{
    if (bytes == 0) return strcmp(text, "-") == 0;
    if (strlen(text) != bytes * 2) return 0;
    for (size_t index = 0; index < bytes; ++index) {
        const char high_char = text[2 * index], low_char = text[2 * index + 1];
        const int high = high_char >= '0' && high_char <= '9' ? high_char - '0' :
                         high_char >= 'a' && high_char <= 'f' ? high_char - 'a' + 10 :
                         high_char >= 'A' && high_char <= 'F' ? high_char - 'A' + 10 : -1;
        const int low = low_char >= '0' && low_char <= '9' ? low_char - '0' :
                        low_char >= 'a' && low_char <= 'f' ? low_char - 'a' + 10 :
                        low_char >= 'A' && low_char <= 'F' ? low_char - 'A' + 10 : -1;
        if (high < 0 || low < 0) return 0;
        output[index] = (uint8_t)((high << 4) | low);
    }
    return 1;
}

static int read_expected_from_stdin(uint8_t *output, size_t bytes)
{
    int first;
    do { first = getchar(); } while (first != EOF && (first == ' ' || first == '\t' || first == '\n' || first == '\r'));
    if (bytes == 0) {
        if (first != '-') return 0;
    } else {
        int current = first;
        for (size_t index = 0; index < bytes; ++index) {
            int high_char = index == 0 ? current : getchar();
            int low_char = getchar();
            const int high = high_char >= '0' && high_char <= '9' ? high_char - '0' :
                             high_char >= 'a' && high_char <= 'f' ? high_char - 'a' + 10 :
                             high_char >= 'A' && high_char <= 'F' ? high_char - 'A' + 10 : -1;
            const int low = low_char >= '0' && low_char <= '9' ? low_char - '0' :
                            low_char >= 'a' && low_char <= 'f' ? low_char - 'a' + 10 :
                            low_char >= 'A' && low_char <= 'F' ? low_char - 'A' + 10 : -1;
            if (high < 0 || low < 0) return 0;
            output[index] = (uint8_t)((high << 4) | low);
        }
        first = getchar();
        if (first != EOF && first != ' ' && first != '\t' && first != '\n' && first != '\r') return 0;
        return 1;
    }
    first = getchar();
    return first == EOF || first == ' ' || first == '\t' || first == '\n' || first == '\r';
}

static uint64_t hash_output(const uint8_t *output, size_t length)
{
    uint64_t hash = UINT64_C(14695981039346656037);
    for (size_t index = 0; index < length; ++index)
        hash = (hash ^ output[index]) * UINT64_C(1099511628211);
    return hash;
}

static double decode_little_endian_f64(const uint8_t *bytes)
{
    uint64_t bits = 0;
    double value;
    for (size_t index = 0; index < 8; ++index)
        bits |= (uint64_t)bytes[index] << (8 * index);
    memcpy(&value, &bits, sizeof(value));
    return value;
}

static int finite_f64(double value)
{
    return value == value && value <= DBL_MAX && value >= -DBL_MAX;
}

static int buffer_matches(int64_t observed_count, uint8_t *output,
                          int64_t expected_count, const uint8_t *expected, size_t expected_length,
                          int float64_vector, double absolute_tolerance, double relative_tolerance)
{
    if (observed_count != expected_count) return 0;
    if (!float64_vector)
        return expected_length == 0 || memcmp(output, expected, expected_length) == 0;
    if (expected_length % 8 != 0 ||
        (expected_count >= 0 && expected_count != (int64_t)(expected_length / 8) &&
         expected_count != (int64_t)expected_length)) return 0;
    for (size_t offset = 0; offset < expected_length; offset += 8) {
        const double actual = decode_little_endian_f64(output + offset);
        const double reference = decode_little_endian_f64(expected + offset);
        const double difference = actual >= reference ? actual - reference : reference - actual;
        const double allowed = absolute_tolerance + relative_tolerance *
                               (reference >= 0.0 ? reference : -reference);
        if (!finite_f64(actual) || !finite_f64(reference) || !finite_f64(difference) ||
            !finite_f64(allowed) || difference > allowed) return 0;
    }
    return 1;
}

static int output_matches(const int64_t *values, size_t length, uint8_t *output, size_t capacity,
                          int64_t expected_count, const uint8_t *expected, size_t expected_length,
                          int float64_vector, double absolute_tolerance, double relative_tolerance)
{
    const int64_t observed_count = run_algorithm(values, length, output, capacity);
    return buffer_matches(observed_count, output, expected_count, expected, expected_length,
                          float64_vector, absolute_tolerance, relative_tolerance);
}

static int run_benchmark(int64_t *values, size_t length, int64_t expected_count,
                         const uint8_t *expected, size_t expected_length, size_t output_capacity,
                         uint64_t samples_arg, uint64_t warmups_arg, uint64_t repetitions_arg,
                         int float64_vector, double absolute_tolerance, double relative_tolerance)
{
    if (expected_count < -2 || expected_count > 100000 ||
        samples_arg == 0 || samples_arg > 10000 || warmups_arg > 100000 ||
        repetitions_arg == 0 || repetitions_arg > 1000000000 ||
        expected_length > output_capacity || output_capacity > MAX_OUTPUT_BYTES ||
        (float64_vector && (expected_length % 8 != 0 ||
         (expected_count >= 0 && expected_count != (int64_t)(expected_length / 8) &&
          expected_count != (int64_t)expected_length) ||
         !finite_f64(absolute_tolerance) || absolute_tolerance < 0.0 ||
         !finite_f64(relative_tolerance) || relative_tolerance < 0.0))) {
        fprintf(stderr, "invalid expected result, output, or timing settings\n"); free(values); return 2;
    }
    uint8_t *output = malloc(output_capacity == 0 ? 1 : output_capacity);
    if (output == NULL) {
        fprintf(stderr, "unable to allocate output buffer\n"); free(values); return 2;
    }
    const size_t sample_count = (size_t)samples_arg;
    const size_t warmup_count = (size_t)warmups_arg;
    const size_t repetitions = (size_t)repetitions_arg;
    uint64_t *sample_ns = malloc(sample_count * sizeof(*sample_ns));
    if (sample_ns == NULL) {
        fprintf(stderr, "unable to allocate sample data\n");
        free(values); free(output); return 2;
    }
    if (!output_matches(values, length, output, output_capacity, expected_count, expected,
                        expected_length, float64_vector, absolute_tolerance, relative_tolerance)) {
        fprintf(stderr, "correctness mismatch for input array\n");
        free(values); free(output); free(sample_ns); return 3;
    }
    volatile uint64_t warmup_observer = 0;
    for (size_t warmup = 0; warmup < warmup_count; ++warmup) {
        int64_t observed_count = 0;
        for (size_t repetition = 0; repetition < repetitions; ++repetition)
            observed_count = run_algorithm(values, length, output, output_capacity);
        if (!buffer_matches(observed_count, output, expected_count, expected, expected_length,
                            float64_vector, absolute_tolerance, relative_tolerance)) {
            fprintf(stderr, "output changed during warmup\n");
            free(values); free(output); free(sample_ns); return 3;
        }
        warmup_observer ^= hash_output(output, expected_length);
    }
    uint64_t total_checksum = 0;
    int64_t observed_count = expected_count;
    for (size_t sample = 0; sample < sample_count; ++sample) {
        const clock_t before = clock();
        if (before == (clock_t)-1) {
            fprintf(stderr, "clock() failed before a sample\n");
            free(values); free(expected); free(output); free(sample_ns); return 4;
        }
        for (size_t repetition = 0; repetition < repetitions; ++repetition)
            observed_count = run_algorithm(values, length, output, output_capacity);
        const clock_t after = clock();
        if (after == (clock_t)-1 || after < before ||
            !buffer_matches(observed_count, output, expected_count, expected, expected_length,
                            float64_vector, absolute_tolerance, relative_tolerance)) {
            fprintf(stderr, "clock() or output check failed during a sample\n");
            free(values); free(output); free(sample_ns); return 4;
        }
        total_checksum += hash_output(output, expected_length) * repetitions;
        const long double elapsed_ns =
            ((long double)(after - before) * 1000000000.0L) / (long double)CLOCKS_PER_SEC;
        sample_ns[sample] = (uint64_t)(elapsed_ns + 0.5L);
    }
    printf("{\"observed_result\":%" PRId64 ",\"samples_ns\":[", observed_count);
    for (size_t sample = 0; sample < sample_count; ++sample)
        printf("%s%" PRIu64, sample == 0 ? "" : ",", sample_ns[sample]);
    printf("],\"result_checksum\":%" PRIu64 ",\"timer_resolution_ns\":%.3Lf}\n",
           total_checksum, 1000000000.0L / (long double)CLOCKS_PER_SEC);
    (void)warmup_observer;
    free(values); free(output); free(sample_ns);
    return 0;
}

int main(int argc, char **argv)
{
    uint64_t length_arg, samples_arg, warmups_arg, repetitions_arg;
    if (argc == 5 && strcmp(argv[1], "--stdin") == 0) {
        uint64_t expected_arg, capacity_arg;
        int64_t expected_count;
        if (!parse_u64(argv[2], &samples_arg) || !parse_u64(argv[3], &warmups_arg) ||
            !parse_u64(argv[4], &repetitions_arg) ||
            scanf("%" SCNu64 " %" SCNd64 " %" SCNu64 " %" SCNu64,
                  &length_arg, &expected_count, &expected_arg, &capacity_arg) != 4 ||
            length_arg > MAX_INPUT_LENGTH || expected_arg > capacity_arg || capacity_arg > MAX_OUTPUT_BYTES) {
            fprintf(stderr, "invalid streaming byte-output input header\n"); return 2;
        }
        const size_t length = (size_t)length_arg;
        const size_t expected_length = (size_t)expected_arg;
        const size_t output_capacity = (size_t)capacity_arg;
        int64_t *values = length == 0 ? NULL : malloc(length * sizeof(*values));
        uint8_t *expected = malloc(expected_length == 0 ? 1 : expected_length);
        if ((length != 0 && values == NULL) || expected == NULL) {
            fprintf(stderr, "unable to allocate streaming buffers\n"); free(values); free(expected); return 2;
        }
        for (size_t index = 0; index < length; ++index) {
            if (scanf("%" SCNd64, &values[index]) != 1) {
                fprintf(stderr, "truncated streaming input values\n"); free(values); free(expected); return 2;
            }
        }
        if (!read_expected_from_stdin(expected, expected_length)) {
            fprintf(stderr, "invalid streaming expected output encoding\n"); free(values); free(expected); return 2;
        }
        int float64_vector = 0;
        double absolute_tolerance = 0.0, relative_tolerance = 0.0;
        char comparison_mode[32], extra[2];
        const int mode_result = scanf("%31s", comparison_mode);
        if (mode_result == 1) {
            if (strcmp(comparison_mode, "float64_vector") != 0 ||
                scanf("%lf %lf", &absolute_tolerance, &relative_tolerance) != 2 ||
                scanf("%1s", extra) == 1) {
                fprintf(stderr, "invalid streaming comparison mode\n");
                free(values); free(expected); return 2;
            }
            float64_vector = 1;
        } else if (mode_result != EOF) {
            fprintf(stderr, "invalid streaming comparison mode\n");
            free(values); free(expected); return 2;
        }
        const int status = run_benchmark(values, length, expected_count, expected,
                                         expected_length, output_capacity,
                                         samples_arg, warmups_arg, repetitions_arg,
                                         float64_vector, absolute_tolerance, relative_tolerance);
        free(expected);
        return status;
    }

    if (argc < 7 || !parse_u64(argv[1], &length_arg) || length_arg > MAX_INPUT_LENGTH ||
        (uint64_t)argc != length_arg + 7) {
        fprintf(stderr, "usage: i64_array_bytes_output_runner LENGTH VALUES... COUNT OUTPUT_HEX SAMPLES WARMUPS REPETITIONS\n");
        return 2;
    }
    const size_t length = (size_t)length_arg;
    int64_t *values = length == 0 ? NULL : malloc(length * sizeof(*values));
    int64_t expected_count;
    const size_t expected_hex_index = length + 3;
    const size_t samples_index = length + 4;
    const size_t warmups_index = length + 5;
    const size_t repetitions_index = length + 6;
    const size_t encoded_length = strlen(argv[expected_hex_index]);
    if (length != 0 && values == NULL) { fprintf(stderr, "unable to allocate input values\n"); return 2; }
    for (size_t index = 0; index < length; ++index) {
        if (!parse_i64(argv[index + 2], &values[index])) {
            fprintf(stderr, "invalid signed 64-bit input value\n"); free(values); return 2;
        }
    }
    if (!parse_i64(argv[length + 2], &expected_count) ||
        !parse_u64(argv[samples_index], &samples_arg) ||
        !parse_u64(argv[warmups_index], &warmups_arg) ||
        !parse_u64(argv[repetitions_index], &repetitions_arg) ||
        encoded_length > MAX_OUTPUT_BYTES * 2) {
        fprintf(stderr, "invalid expected result, output, or timing settings\n"); free(values); return 2;
    }
    const size_t output_length = encoded_length / 2;
    uint8_t *expected = malloc(output_length == 0 ? 1 : output_length);
    if (expected == NULL || encoded_length % 2 != (output_length == 0 ? 1 : 0) ||
        !decode_hex(argv[expected_hex_index], expected, output_length)) {
        fprintf(stderr, "invalid expected output encoding\n"); free(values); free(expected); return 2;
    }
    const int status = run_benchmark(values, length, expected_count, expected,
                                     output_length, output_length,
                                     samples_arg, warmups_arg, repetitions_arg, 0, 0.0, 0.0);
    free(expected);
    return status;
}
