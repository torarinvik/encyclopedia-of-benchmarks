module sparse_table;

extern fn void* calloc(usz count, usz size);
extern fn void free(void* pointer);

const long MAX_N = 12_344;
const usz MAX_PARSEABLE_INPUT_LENGTH = 12_348;

fn long sparse_table(long* input, usz length) @export("sparse_table") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_N) return -1;
    usz n = (usz)input[0];
    if (length != n + 3 || input[n + 1] < 0 || input[n + 2] < input[n + 1] || input[n + 2] >= (long)n) return -1;
    usz left = (usz)input[n + 1];
    usz right = (usz)input[n + 2];

    usz levels = 1;
    usz span = 2;
    while (span <= n) { levels += 1; span *= 2; }
    long* table = (long*)calloc(levels * n, sizeof(long));
    if (table == null) return -1;
    long* logs = (long*)calloc(n + 1, sizeof(long));
    if (logs == null) { free(table); return -1; }

    long* values = input + 1;
    logs[0] = -1;
    for (usz i = 0; i < n; ++i) {
        table[i] = (long)i;
        logs[i + 1] = logs[i] + (((i & (i + 1)) == 0) ? 1 : 0);
    }
    span = 2;
    for (usz level = 1; level < levels; ++level, span *= 2) {
        usz half = span / 2;
        for (usz i = 0; i + span <= n; ++i) {
            usz x = (usz)table[(level - 1) * n + i];
            usz y = (usz)table[(level - 1) * n + i + half];
            table[level * n + i] = values[x] <= values[y] ? (long)x : (long)y;
        }
    }

    usz query_length = right - left + 1;
    usz level = (usz)logs[query_length];
    usz block = 1;
    for (usz bit = 0; bit < level; ++bit) block *= 2;
    usz x = (usz)table[level * n + left];
    usz y = (usz)table[level * n + right - block + 1];
    usz answer = values[x] <= values[y] ? x : y;
    free(logs);
    free(table);
    return (long)answer;
}
