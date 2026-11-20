module spatial_motif_different_type_contact_pmf;

const int MAX_LENGTH = 10;
const int MAX_SUPPORT = 11;

fn long choose_value(int total, int selected0) {
    if (total < 0 || selected0 < 0 || selected0 > total) return 0;
    int selected = selected0;
    if (selected > total - selected) selected = total - selected;
    long result = 1;
    for (int factor = 1; factor <= selected; factor++)
        result = result * (long)(total - selected + factor) / (long)factor;
    return result;
}

fn long multinomial3(int total, int first, int second) {
    if (total < 0 || first < 0 || second < 0 || first > total || second > total ||
        first + second > total) return 0;
    return choose_value(total, first) * choose_value(total - first, second);
}

fn long gcd_value(long left0, long right0) {
    long left = left0, right = right0;
    while (right != 0) { long remainder = left % right; left = right; right = remainder; }
    return left;
}

fn void put_i64(char* output, usz word, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++)
        output[word * 8 + byte] = (char)((bits >> (byte * 8)) & 255);
}

fn long spatial_motif_different_type_contact_pmf(long* input, usz input_length,
        char* output, usz output_capacity) @export("spatial_motif_different_type_contact_pmf") {
    if (input == null || input_length != 5) return -1;
    long n0 = input[0], x10 = input[1], y10 = input[2], x20 = input[3], y20 = input[4];
    if (n0 < 1 || n0 > MAX_LENGTH || x10 < 0 || y10 < 0 || x20 < 0 || y20 < 0 ||
        x10 > n0 || y10 > n0 || x20 > n0 || y20 > n0) return -1;
    if (x10 + y10 > n0 || x20 + y20 > n0) return -1;

    int n = (int)n0, x1 = (int)x10, y1 = (int)y10, x2 = (int)x20, y2 = (int)y20;
    int neither1 = n - x1 - y1;
    long denominator = multinomial3(n, x2, y2);
    long[MAX_SUPPORT] numerators = {0};
    for (int m = 0; m <= n; m++) {
        for (int h = 0; h <= x1; h++) {
            for (int i = 0; i <= x1 - h; i++) {
                int j = m - i;
                if (j < 0 || j > y1) continue;
                for (int k = 0; k <= y1 - j; k++) {
                    numerators[m] += multinomial3(x1, h, i)
                        * multinomial3(y1, j, k)
                        * multinomial3(neither1, x2 - h - j, y2 - i - k);
                }
            }
        }
    }

    long expected_num = 0;
    for (int m = 0; m <= n; m++) expected_num += (long)m * numerators[m];
    long expected_den = denominator, divisor = gcd_value(expected_num, expected_den);
    expected_num /= divisor; expected_den /= divisor;
    usz bytes = (usz)(n + 5) * 8;
    if (output == null || output_capacity < bytes) return -2;
    put_i64(output, 0, (long)n); put_i64(output, 1, denominator);
    for (int m = 0; m <= n; m++) put_i64(output, (usz)(m + 2), numerators[m]);
    put_i64(output, (usz)(n + 3), expected_num);
    put_i64(output, (usz)(n + 4), expected_den);
    return (long)bytes;
}
