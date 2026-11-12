module runenumerate;

const usz MAX_N = 24;
const usz MAX_RUNS = 144;

struct Run { int period; int left; int right; }

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long runenumerate(long* input, usz length, char* output, usz capacity)
    @export("runenumerate") {
    if (input == null || length < 2 || length > MAX_N + 1) return -1;
    long n_value = input[0];
    if (n_value < 1 || n_value > (long)MAX_N || length != (usz)n_value + 1) return -1;
    int n = (int)n_value;
    int[MAX_N] text;
    for (int i = 0; i < n; i += 1) {
        if (input[i + 1] < 0 || input[i + 1] >= 26) return -1;
        text[i] = (int)input[i + 1];
    }
    if (output == null) return -2;

    int[MAX_N + 1][MAX_N + 1] lcp = zeroed;
    for (int i = n - 1; i >= 0; i -= 1)
        for (int j = n - 1; j > i; j -= 1)
            if (text[i] == text[j]) lcp[i][j] = 1 + lcp[i + 1][j + 1];

    Run[MAX_RUNS] runs;
    int count = 0;
    for (int period = 1; period <= n / 2; period += 1) {
        int i = period;
        while (i < n) {
            if (text[i] != text[i - period]) { i += 1; continue; }
            int first = i;
            while (i < n && text[i] == text[i - period]) i += 1;
            int left = first - period;
            int right = i;
            if (right - left < 2 * period) continue;
            bool minimal = true;
            for (int smaller = 1; smaller < period; smaller += 1)
                if (lcp[left][left + smaller] >= right - left - smaller) {
                    minimal = false;
                    break;
                }
            if (minimal && count < (int)MAX_RUNS) {
                runs[count].period = period;
                runs[count].left = left;
                runs[count].right = right;
                count += 1;
            }
        }
    }
    for (int i = 1; i < count; i += 1) {
        Run value = runs[i];
        int j = i;
        while (j > 0 && (runs[j - 1].period > value.period ||
               (runs[j - 1].period == value.period && runs[j - 1].left > value.left) ||
               (runs[j - 1].period == value.period && runs[j - 1].left == value.left && runs[j - 1].right > value.right))) {
            runs[j] = runs[j - 1];
            j -= 1;
        }
        runs[j] = value;
    }
    usz needed = 8 + 24 * (usz)count;
    if (capacity < needed) return -2;
    store_i64_le(output, 0, (long)count);
    for (int i = 0; i < count; i += 1) {
        usz offset = 8 + 24 * (usz)i;
        store_i64_le(output, offset, (long)runs[i].period);
        store_i64_le(output, offset + 8, (long)runs[i].left);
        store_i64_le(output, offset + 16, (long)runs[i].right);
    }
    return (long)needed;
}
