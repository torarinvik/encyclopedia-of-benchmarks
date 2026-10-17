module shortest_common_supersequence;

// Construct the source-compatible shortest common supersequence.
fn long shortest_common_supersequence(long* input, usz length, char* output, usz capacity)
    @export("shortest_common_supersequence") {
    if (input == null || length < 2 || length > 130) return -1;
    long m_value = input[0];
    long n_value = input[1];
    if (m_value < 0 || m_value > 64 || n_value < 0 || n_value > 64) return -1;
    usz m = (usz)m_value;
    usz n = (usz)n_value;
    if (length != 2 + m + n) return -1;
    for (usz index = 0; index < m + n; index++) {
        if (input[2 + index] < 32 || input[2 + index] > 126) return -1;
    }

    long lcs[4225];
    for (usz index = 0; index < 4225; index++) lcs[index] = 0;
    for (usz i = 1; i <= m; i++) {
        for (usz j = 1; j <= n; j++) {
            usz cell = i * 65 + j;
            if (input[1 + i] == input[1 + m + j])
                lcs[cell] = lcs[(i - 1) * 65 + j - 1] + 1;
            else {
                long above = lcs[(i - 1) * 65 + j];
                long left = lcs[i * 65 + j - 1];
                lcs[cell] = above > left ? above : left;
            }
        }
    }

    char reversed[128];
    usz used = 0;
    usz i = m;
    usz j = n;
    while (i > 0 && j > 0) {
        if (input[1 + i] == input[1 + m + j]) {
            reversed[used++] = (char)input[1 + i];
            i--;
            j--;
        } else if (lcs[(i - 1) * 65 + j] > lcs[i * 65 + j - 1]) {
            reversed[used++] = (char)input[1 + i];
            i--;
        } else {
            // The pinned implementations choose Y when the LCS values tie.
            reversed[used++] = (char)input[1 + m + j];
            j--;
        }
    }
    while (i > 0) { reversed[used++] = (char)input[1 + i]; i--; }
    while (j > 0) { reversed[used++] = (char)input[1 + m + j]; j--; }

    if (output == null || capacity < used) return -2;
    for (usz index = 0; index < used; index++)
        output[index] = reversed[used - 1 - index];
    (long)used
}
