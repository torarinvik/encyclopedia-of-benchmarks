// Clean-room port of SIM's documented first-best local affine score.
module ptrdist_sim_local_affine_alignment;

const usz MAX_LENGTH = 64;
const usz STRIDE = 65;
const usz CELLS = STRIDE * STRIDE;

fn long ptrdist_sim_local_affine_alignment(long* input, usz length) @export("ptrdist_sim_local_affine_alignment") {
    if (input == null || length < 4 || length > 130 || input[0] < 1 || input[0] > 64) return -1;
    usz left = (usz)input[0], right_pos = 1 + left;
    if (right_pos >= length || input[right_pos] < 1 || input[right_pos] > 64) return -1;
    usz right = (usz)input[right_pos];
    if (length != right_pos + 1 + right) return -1;
    for (usz i = 0; i < left; i++) {
        long c = input[1+i];
        if (c != 65 && c != 67 && c != 71 && c != 84) return -1;
    }
    for (usz j = 0; j < right; j++) {
        long c = input[right_pos+1+j];
        if (c != 65 && c != 67 && c != 71 && c != 84) return -1;
    }
    long[CELLS] h = zeroed, d = zeroed, f = zeroed;
    for (usz j = 1; j <= right; j++) d[j] = -60;
    for (usz i = 1; i <= left; i++) f[i*STRIDE] = -60;
    long best = 0;
    for (usz i = 1; i <= left; i++) for (usz j = 1; j <= right; j++) {
        usz p = i*STRIDE+j;
        long d_open = h[p-STRIDE]-62, d_extend = d[p-STRIDE]-2;
        d[p] = d_open > d_extend ? d_open : d_extend;
        long f_open = h[p-1]-62, f_extend = f[p-1]-2;
        f[p] = f_open > f_extend ? f_open : f_extend;
        long score = h[p-STRIDE-1] + (input[i] == input[right_pos+j] ? 10 : -10);
        if (score < 0) score = 0;
        if (d[p] > score) score = d[p];
        if (f[p] > score) score = f[p];
        h[p] = score;
        if (score > best) best = score;
    }
    return best;
}
