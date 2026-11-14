module wavelet_matrix;

struct Matrix { int[715] prefix; int[11] zeros; }

fn int less(Matrix* matrix, int left, int right, int key) {
    int result = 0;
    for (int level = 0; level < 11; level++) {
        int zl = matrix.prefix[level * 65 + left], zr = matrix.prefix[level * 65 + right];
        if ((key & (1 << (10 - level))) != 0) {
            result += zr - zl;
            left = matrix.zeros[level] + left - zl;
            right = matrix.zeros[level] + right - zr;
        } else { left = zl; right = zr; }
    }
    return result;
}

fn int quantile(Matrix* matrix, int left, int right, int rank) {
    int key = 0;
    for (int level = 0; level < 11; level++) {
        int zl = matrix.prefix[level * 65 + left], zr = matrix.prefix[level * 65 + right];
        if (rank < zr - zl) { left = zl; right = zr; }
        else {
            rank -= zr - zl;
            key |= 1 << (10 - level);
            left = matrix.zeros[level] + left - zl;
            right = matrix.zeros[level] + right - zr;
        }
    }
    return key - 1000;
}

fn long wavelet_matrix(long* input, usz length) @export("wavelet_matrix") {
    if (input == null || length < 2 || length > 706 || input[0] < 1 || input[0] > 64) return -1;
    int n = (int)input[0];
    if (length < (usz)(n + 2)) return -1;
    for (int i = 0; i < n; i++) if (input[1+i] < -1000 || input[1+i] > 1000) return -1;
    long q = input[n+1];
    if (q < 0 || q > 128 || length != (usz)(n + 2 + 5*q)) return -1;
    Matrix matrix = {};
    int[64] current, scratch;
    for (int i = 0; i < n; i++) current[i] = (int)input[1+i] + 1000;
    for (int level = 0; level < 11; level++) {
        int bit = 10 - level;
        for (int i = 0; i < n; i++) {
            int add = (current[i] & (1 << bit)) == 0 ? 1 : 0;
            matrix.prefix[level*65+i+1] = matrix.prefix[level*65+i] + add;
        }
        int z = 0, o = matrix.prefix[level*65+n];
        matrix.zeros[level] = o;
        for (int i = 0; i < n; i++) {
            if ((current[i] & (1 << bit)) == 0) scratch[z++] = current[i];
            else scratch[o++] = current[i];
        }
        for (int i = 0; i < n; i++) current[i] = scratch[i];
    }
    long total = 0;
    for (int j = 0; j < q; j++) {
        int at = n + 2 + 5*j;
        long op = input[at], a = input[at+1], b = input[at+2], c = input[at+3], d = input[at+4];
        int answer;
        if (op == 0) {
            if (a < -1000 || a > 1000 || b < -1 || b >= n) return -1;
            answer = less(&matrix, 0, (int)b+1, (int)a+1001) - less(&matrix, 0, (int)b+1, (int)a+1000);
        } else if (op == 1) {
            if (a < 0 || a > b || b >= n || c < 0 || c > b-a) return -1;
            answer = quantile(&matrix, (int)a, (int)b+1, (int)c);
        } else if (op == 2) {
            if (a < 0 || a > b || b >= n || c < -1000 || c > d || d > 1000) return -1;
            answer = less(&matrix, (int)a, (int)b+1, (int)d+1001) - less(&matrix, (int)a, (int)b+1, (int)c+1000);
        } else return -1;
        total += (long)(j+1) * (answer + 1000001);
    }
    return total;
}
