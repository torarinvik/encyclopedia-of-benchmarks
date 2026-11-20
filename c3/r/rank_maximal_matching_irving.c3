module rank_maximal_matching_irving;

const usz MAX_A = 4;
const usz MAX_P = 4;
const usz MAX_V = 8;
const usz MAX_RANK = 4;
const usz MAX_INPUT = 52;
const usz MAX_OUTPUT = 40;

fn void put64(char* output, usz at, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b += 1) { output[at+b] = (char)(bits & 255); bits >>= 8; }
}

fn bool lex_less(usz[MAX_A] left, usz[MAX_A] right, usz count) {
    for (usz i = 0; i < count; i += 1) if (left[i] != right[i]) return left[i] < right[i];
    return false;
}

fn void maximum_matching(usz applicants, usz posts, usz phase,
                         long[MAX_A][MAX_P]& rank, bool[MAX_A][MAX_P]& blocked,
                         long[MAX_A]& mate_a, long[MAX_P]& mate_p) {
    usz limit = 1;
    for (usz a = 0; a < applicants; a += 1) limit *= posts+1;
    usz[MAX_A] best = zeroed;
    long best_size = -1;
    for (usz code = 0; code < limit; code += 1) {
        usz value = code;
        usz[MAX_A] candidate = zeroed;
        uint used = 0;
        long size = 0;
        bool valid = true;
        for (usz a = 0; a < applicants; a += 1) {
            usz p = value%(posts+1); value /= posts+1; candidate[a] = p;
            if (p == posts) continue;
            if (rank[a][p] == 0 || rank[a][p] > (long)phase || blocked[a][p] || (used & (1u << p)) != 0) { valid = false; break; }
            used |= 1u << p; size += 1;
        }
        if (valid && (size > best_size || (size == best_size && lex_less(candidate,best,applicants)))) { best_size = size; best = candidate; }
    }
    for (usz a = 0; a < MAX_A; a += 1) mate_a[a] = -1;
    for (usz p = 0; p < MAX_P; p += 1) mate_p[p] = -1;
    for (usz a = 0; a < applicants; a += 1) if (best[a] < posts) { mate_a[a] = (long)best[a]; mate_p[best[a]] = (long)a; }
}

fn void classify(usz applicants, usz posts, usz phase,
                 long[MAX_A][MAX_P]& rank, bool[MAX_A][MAX_P]& blocked,
                 long[MAX_A]& mate_a, long[MAX_P]& mate_p, long[MAX_V]& classes) {
    usz[MAX_V] queue = zeroed;
    usz head = 0, tail = 0;
    for (usz v = 0; v < applicants+posts; v += 1) classes[v] = 2;
    for (usz a = 0; a < applicants; a += 1) if (mate_a[a] < 0) { classes[a] = 0; queue[tail++] = a; }
    for (usz p = 0; p < posts; p += 1) if (mate_p[p] < 0) { usz v = applicants+p; classes[v] = 0; queue[tail++] = v; }
    while (head < tail) {
        usz v = queue[head++];
        if (v < applicants) {
            usz a = v;
            if (classes[v] == 0) {
                for (usz p = 0; p < posts; p += 1) {
                    usz w = applicants+p;
                    if (rank[a][p] > 0 && rank[a][p] <= (long)phase && !blocked[a][p] && mate_a[a] != (long)p && classes[w] == 2) { classes[w] = 1; queue[tail++] = w; }
                }
            } else if (mate_a[a] >= 0) {
                usz w = applicants+(usz)mate_a[a];
                if (classes[w] == 2) { classes[w] = 0; queue[tail++] = w; }
            }
        } else {
            usz p = v-applicants;
            if (classes[v] == 0) {
                for (usz a = 0; a < applicants; a += 1) if (rank[a][p] > 0 && rank[a][p] <= (long)phase && !blocked[a][p] && mate_a[a] != (long)p && classes[a] == 2) { classes[a] = 1; queue[tail++] = a; }
            } else if (mate_p[p] >= 0) {
                usz a = (usz)mate_p[p];
                if (classes[a] == 2) { classes[a] = 0; queue[tail++] = a; }
            }
        }
    }
}

fn long rank_maximal_matching_irving(long* input, usz length, char* output, usz capacity)
        @export("rank_maximal_matching_irving") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long a64 = input[0], p64 = input[1], e64 = input[2];
    if (a64 < 1 || a64 > (long)MAX_A || p64 < 1 || p64 > (long)MAX_P) return -1;
    usz applicants = (usz)a64, posts = (usz)p64;
    if (e64 < a64 || e64 > (long)(applicants*posts)) return -1;
    usz edges = (usz)e64;
    if (edges > 16 || length != 3+3*edges) return -1;
    long[MAX_A][MAX_P] rank = zeroed;
    usz[MAX_A] degree = zeroed;
    usz max_rank = 0;
    for (usz e = 0; e < edges; e += 1) {
        usz at = 3+3*e;
        long av = input[at], pv = input[at+1], rv = input[at+2];
        if (av < 0 || av >= a64 || pv < 0 || pv >= p64 || rv < 1 || rv > (long)MAX_RANK) return -1;
        usz a = (usz)av, p = (usz)pv;
        if (rank[a][p] != 0) return -1;
        rank[a][p] = rv; degree[a] += 1;
        if ((usz)rv > max_rank) max_rank = (usz)rv;
    }
    for (usz a = 0; a < applicants; a += 1) if (degree[a] == 0) return -1;
    bool[MAX_A][MAX_P] blocked = zeroed;
    long[MAX_A] mate_a = { -1, -1, -1, -1 };
    long[MAX_P] mate_p = { -1, -1, -1, -1 };
    for (usz phase = 1; phase <= max_rank; phase += 1) {
        maximum_matching(applicants,posts,phase,rank,blocked,mate_a,mate_p);
        long[MAX_V] classes = zeroed;
        classify(applicants,posts,phase,rank,blocked,mate_a,mate_p,classes);
        for (usz a = 0; a < applicants; a += 1) for (usz p = 0; p < posts; p += 1) {
            if (rank[a][p] == 0 || blocked[a][p]) continue;
            long ca = classes[a], cp = classes[applicants+p];
            if (rank[a][p] <= (long)phase) {
                if ((ca == 1 && cp != 0) || (cp == 1 && ca != 0)) blocked[a][p] = true;
            } else if (ca != 0 || cp != 0) blocked[a][p] = true;
        }
    }
    long[MAX_RANK] signature = zeroed;
    for (usz a = 0; a < applicants; a += 1) if (mate_a[a] >= 0) signature[(usz)rank[a][(usz)mate_a[a]]-1] += 1;
    usz output_bytes = 8*(max_rank+1);
    if (output == null || capacity < output_bytes) return -2;
    char[MAX_OUTPUT] staged = zeroed;
    put64(&staged[0],0,(long)max_rank);
    for (usz r = 0; r < max_rank; r += 1) put64(&staged[0],8*(r+1),signature[r]);
    for (usz b = 0; b < output_bytes; b += 1) output[b] = staged[b];
    return (long)output_bytes;
}
