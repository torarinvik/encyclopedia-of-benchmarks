#include <stddef.h>
#include <stdint.h>

#define MAX_N 4
#define MAX_CELLS 64
#define MAX_MOVES 48
#define MAX_WORDS 66

typedef struct {
    size_t i, j, k, ip, jp, kp;
} Move;

static size_t at(size_t n, size_t i, size_t j, size_t k) {
    return (i * n + j) * n + k;
}

static int next_move(const int64_t *a, size_t n, size_t choice, Move *selected) {
    size_t defects = 0, pi = 0, pj = 0, pk = 0, count = 0;
    Move moves[MAX_MOVES];
    for (size_t i = 0; i < n; ++i) for (size_t j = 0; j < n; ++j) for (size_t k = 0; k < n; ++k) {
        if (a[at(n, i, j, k)] == -1) { ++defects; pi = i; pj = j; pk = k; }
    }
    if (defects > 1) return 0;
    if (defects == 1) {
        for (size_t ip = 0; ip < n; ++ip) for (size_t jp = 0; jp < n; ++jp) for (size_t kp = 0; kp < n; ++kp) {
            if (ip != pi && jp != pj && kp != pk && a[at(n, pi, pj, kp)] == 1 &&
                a[at(n, pi, jp, pk)] == 1 && a[at(n, ip, pj, pk)] == 1) {
                moves[count++] = (Move){pi, pj, pk, ip, jp, kp};
            }
        }
        if (count != 8) return 0;
    } else {
        for (size_t i = 0; i < n; ++i) for (size_t j = 0; j < n; ++j) for (size_t k = 0; k < n; ++k) {
            if (a[at(n, i, j, k)] != 0) continue;
            size_t ip = n, jp = n, kp = n;
            for (size_t x = 0; x < n; ++x) if (a[at(n, x, j, k)] == 1) ip = x;
            for (size_t x = 0; x < n; ++x) if (a[at(n, i, x, k)] == 1) jp = x;
            for (size_t x = 0; x < n; ++x) if (a[at(n, i, j, x)] == 1) kp = x;
            if (ip == n || jp == n || kp == n) return 0;
            moves[count++] = (Move){i, j, k, ip, jp, kp};
        }
        if (count != n * n * n - n * n) return 0;
    }
    if (choice >= count) return 0;
    *selected = moves[choice];
    return 1;
}

static int apply_choice(int64_t *a, size_t n, size_t choice) {
    Move m;
    if (!next_move(a, n, choice, &m)) return 0;
    a[at(n,m.i,m.j,m.k)]++;
    a[at(n,m.ip,m.jp,m.k)]++;
    a[at(n,m.ip,m.j,m.kp)]++;
    a[at(n,m.i,m.jp,m.kp)]++;
    a[at(n,m.ip,m.j,m.k)]--;
    a[at(n,m.i,m.jp,m.k)]--;
    a[at(n,m.i,m.j,m.kp)]--;
    a[at(n,m.ip,m.jp,m.kp)]--;
    return 1;
}

static void write_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t jacobson_matthews_latin_square_chain(const int64_t *input, size_t length,
                                             uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > 14) return -1;
    int64_t n_value = input[0], steps_value = input[1];
    if (n_value < 2 || n_value > MAX_N || steps_value < 0 || steps_value > 12 ||
        length != 2 + (size_t)steps_value) return -1;
    size_t n = (size_t)n_value, steps = (size_t)steps_value;
    int64_t tensor[MAX_CELLS] = {0};
    for (size_t i = 0; i < n; ++i) for (size_t j = 0; j < n; ++j)
        tensor[at(n, i, j, (i + j) % n)] = 1;
    for (size_t step = 0; step < steps; ++step) {
        if (input[2 + step] < 0 || (uint64_t)input[2 + step] >= MAX_MOVES ||
            !apply_choice(tensor, n, (size_t)input[2 + step])) return -1;
    }
    size_t words_count = 2 + n * n * n;
    size_t output_bytes = words_count * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    int64_t words[MAX_WORDS] = {0};
    words[0] = n_value;
    words[1] = steps_value;
    for (size_t i = 0; i < n * n * n; ++i) words[2 + i] = tensor[i];
    for (size_t i = 0; i < words_count; ++i) write_i64_le(output, i * 8, words[i]);
    return (int64_t)output_bytes;
}
