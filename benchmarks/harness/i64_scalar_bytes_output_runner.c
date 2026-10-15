/* Timing runner for signed scalar algorithms that write bytes to a caller buffer. */
#include <errno.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#ifndef BENCHMARK_FUNCTION
#error "Compile with -DBENCHMARK_FUNCTION=<exported function symbol>"
#endif

#define MAX_OUTPUT_BYTES 8192
typedef int64_t (*output_fn)(int64_t, uint8_t *, size_t);
extern int64_t BENCHMARK_FUNCTION(int64_t value, uint8_t *output, size_t output_capacity);
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

static int hex_value(char value)
{
    if (value >= '0' && value <= '9') return value - '0';
    if (value >= 'a' && value <= 'f') return value - 'a' + 10;
    if (value >= 'A' && value <= 'F') return value - 'A' + 10;
    return -1;
}

static uint64_t hash_output(const uint8_t *output, size_t length)
{
    uint64_t hash = UINT64_C(14695981039346656037);
    for (size_t index = 0; index < length; ++index)
        hash = (hash ^ output[index]) * UINT64_C(1099511628211);
    return hash;
}

int main(int argc, char **argv)
{
    int64_t input, expected_result;
    uint64_t capacity_arg, samples_arg, warmups_arg, repetitions_arg;
    if (argc != 8 || !parse_i64(argv[1], &input) || !parse_i64(argv[2], &expected_result) ||
        !parse_u64(argv[4], &capacity_arg) || capacity_arg > MAX_OUTPUT_BYTES ||
        !parse_u64(argv[5], &samples_arg) || !parse_u64(argv[6], &warmups_arg) ||
        !parse_u64(argv[7], &repetitions_arg) || samples_arg == 0 || samples_arg > 10000 ||
        warmups_arg > 100000 || repetitions_arg == 0 || repetitions_arg > 1000000000) {
        fprintf(stderr, "usage: i64_scalar_bytes_output_runner INPUT RESULT OUTPUT_HEX CAPACITY SAMPLES WARMUPS REPETITIONS\n");
        return 2;
    }

    const size_t encoded_length = strlen(argv[3]);
    const size_t output_length = encoded_length == 1 && argv[3][0] == '-' ? 0 : encoded_length / 2;
    uint8_t expected[MAX_OUTPUT_BYTES], output[MAX_OUTPUT_BYTES];
    if (output_length > MAX_OUTPUT_BYTES ||
        (output_length == 0 && !(encoded_length == 1 && argv[3][0] == '-')) ||
        (output_length > 0 && encoded_length % 2 != 0)) {
        fprintf(stderr, "invalid expected output encoding\n");
        return 2;
    }
    for (size_t index = 0; index < output_length; ++index) {
        const int high = hex_value(argv[3][index * 2]);
        const int low = hex_value(argv[3][index * 2 + 1]);
        if (high < 0 || low < 0) {
            fprintf(stderr, "expected output encoding is not hexadecimal\n");
            return 2;
        }
        expected[index] = (uint8_t)((high << 4) | low);
    }

    memset(output, UINT8_C(0xA5), sizeof(output));
    const size_t capacity = (size_t)capacity_arg;
    const int64_t initial = run_algorithm(input, output, capacity);
    if (initial != expected_result ||
        (output_length > 0 && memcmp(output, expected, output_length) != 0)) {
        fprintf(stderr, "correctness mismatch for scalar byte-output input\n");
        return 3;
    }

    const size_t sample_count = (size_t)samples_arg;
    const size_t warmup_count = (size_t)warmups_arg;
    const size_t repetitions = (size_t)repetitions_arg;
    uint64_t *sample_ns = malloc(sample_count * sizeof(*sample_ns));
    if (sample_ns == NULL) {
        fprintf(stderr, "unable to allocate sample data\n");
        return 2;
    }
    volatile uint64_t warmup_observer = 0;
    for (size_t warmup = 0; warmup < warmup_count; ++warmup) {
        int64_t observed = 0;
        for (size_t repetition = 0; repetition < repetitions; ++repetition)
            observed = run_algorithm(input, output, capacity);
        if (observed != expected_result ||
            (output_length > 0 && memcmp(output, expected, output_length) != 0)) {
            fprintf(stderr, "output changed during warmup\n");
            free(sample_ns);
            return 3;
        }
        warmup_observer ^= hash_output(output, output_length);
    }

    uint64_t total_checksum = 0;
    int64_t observed = expected_result;
    for (size_t sample = 0; sample < sample_count; ++sample) {
        const clock_t before = clock();
        if (before == (clock_t)-1) {
            fprintf(stderr, "clock() failed before a sample\n");
            free(sample_ns);
            return 4;
        }
        for (size_t repetition = 0; repetition < repetitions; ++repetition)
            observed = run_algorithm(input, output, capacity);
        const clock_t after = clock();
        if (after == (clock_t)-1 || after < before || observed != expected_result ||
            (output_length > 0 && memcmp(output, expected, output_length) != 0)) {
            fprintf(stderr, "clock() or output check failed during a sample\n");
            free(sample_ns);
            return 4;
        }
        total_checksum += hash_output(output, output_length) * repetitions;
        const long double elapsed_ns =
            ((long double)(after - before) * 1000000000.0L) / (long double)CLOCKS_PER_SEC;
        sample_ns[sample] = (uint64_t)(elapsed_ns + 0.5L);
    }

    printf("{\"observed_result\":%" PRId64 ",\"samples_ns\":[", observed);
    for (size_t sample = 0; sample < sample_count; ++sample)
        printf("%s%" PRIu64, sample == 0 ? "" : ",", sample_ns[sample]);
    printf("],\"result_checksum\":%" PRIu64 ",\"timer_resolution_ns\":%.3Lf}\n",
           total_checksum, 1000000000.0L / (long double)CLOCKS_PER_SEC);
    (void)warmup_observer;
    free(sample_ns);
    return 0;
}
