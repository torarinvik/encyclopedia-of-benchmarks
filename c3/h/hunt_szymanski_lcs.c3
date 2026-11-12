module hunt_szymanski_lcs;

// Return the LCS length through descending matching positions and an LIS frontier.
fn long hunt_szymanski_lcs(long* input, usz length) @export("hunt_szymanski_lcs")
{
    if (input == null || length < 2 || length > 131) return -1;
    long n_value = input[0];
    long m_value = input[1];
    if (n_value < 0 || n_value > 64 || m_value < 0 || m_value > 64 ||
        length != (usz)(2 + n_value + m_value)) return -1;
    usz n = (usz)n_value;
    usz m = (usz)m_value;
    for (usz i = 0; i < n + m; i++) {
        if (input[2 + i] < 0 || input[2 + i] > 127) return -1;
    }

    int[8192] right_positions;
    int[128] position_count;
    int[64] tails;
    for (usz i = 0; i < 128; i++) position_count[i] = 0;
    for (usz j = 0; j < m; j++) {
        usz symbol = (usz)input[2 + n + j];
        int count = position_count[symbol];
        right_positions[symbol * 64 + (usz)count] = (int)j;
        position_count[symbol] = count + 1;
    }

    int tail_count = 0;
    for (usz i = 0; i < n; i++) {
        usz symbol = (usz)input[2 + i];
        int count = position_count[symbol];
        while (count > 0) {
            count -= 1;
            int position = right_positions[symbol * 64 + (usz)count];
            int low = 0;
            int high = tail_count;
            while (low < high) {
                int middle = low + (high - low) / 2;
                if (tails[middle] >= position) high = middle;
                else low = middle + 1;
            }
            if (low == tail_count) {
                tails[tail_count] = position;
                tail_count += 1;
            } else {
                tails[low] = position;
            }
        }
    }
    return (long)tail_count;
}
