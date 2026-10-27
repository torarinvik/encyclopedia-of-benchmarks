module ranked_matching_popular_matching;

const usz MAX_A = 4;
const usz MAX_P = 4;
const usz MAX_POSTS = 8;
const usz MAX_NODES = 12;
const usz MAX_INPUT = 51;
const usz MAX_OUTPUT = 40;

fn void put64(char* output, usz at, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[at+byte] = (char)(bits & 255); bits >>= 8; }
}

fn bool lex_less(usz[MAX_A] left, usz[MAX_A] right, usz count) {
    for (usz index = 0; index < count; index += 1) {
        if (left[index] != right[index]) return left[index] < right[index];
    }
    return false;
}

long ranked_matching_popular_matching(long* input, usz length, char* output, usz capacity)
        @export("ranked_matching_popular_matching") {
    if (input == null || length < 6 || length > MAX_INPUT) return -1;
    long a64 = input[0], p64 = input[1], e64 = input[2];
    if (a64 < 1 || a64 > (long)MAX_A || p64 < 1 || p64 > (long)MAX_P) return -1;
    usz applicants = (usz)a64, posts = (usz)p64;
    if (e64 < a64 || e64 > (long)(applicants*posts)) return -1;
    usz edges = (usz)e64;
    if (length != 3 + 3*edges) return -1;
    usz post_count = posts + applicants, node_count = applicants + post_count;
    usz output_bytes = 8*(applicants+1);
    long[MAX_A][MAX_P] rank = zeroed;
    bool[MAX_A][MAX_P+1] rank_seen = zeroed;
    usz[MAX_A] max_rank = zeroed;
    for (usz edge = 0; edge < edges; edge += 1) {
        usz at = 3 + 3*edge;
        long av = input[at], pv = input[at+1], rv = input[at+2];
        if (av < 0 || av >= a64 || pv < 0 || pv >= p64 || rv < 1 || rv > p64) return -1;
        usz a = (usz)av, p = (usz)pv, r = (usz)rv;
        if (rank[a][p] != 0) return -1;
        rank[a][p] = rv;
        rank_seen[a][r] = true;
        if (r > max_rank[a]) max_rank[a] = r;
    }
    for (usz a = 0; a < applicants; a += 1) {
        if (max_rank[a] == 0) return -1;
        for (usz r = 1; r <= max_rank[a]; r += 1) if (!rank_seen[a][r]) return -1;
    }
    usz[MAX_A] best_m1 = zeroed;
    long best_m1_size = -1;
    usz m1_limit = 1;
    for (usz i = 0; i < applicants; i += 1) m1_limit *= posts+1;
    for (usz code = 0; code < m1_limit; code += 1) {
        usz value = code;
        usz[MAX_A] candidate = zeroed;
        uint used = 0;
        long count = 0;
        bool valid = true;
        for (usz a = 0; a < applicants; a += 1) {
            usz p = value%(posts+1); value /= posts+1; candidate[a] = p;
            if (p == posts) continue;
            if (rank[a][p] != 1 || (used & (1u << p)) != 0) { valid = false; break; }
            used |= 1u << p; count += 1;
        }
        if (valid && (count > best_m1_size || (count == best_m1_size && lex_less(candidate,best_m1,applicants)))) {
            best_m1_size = count; best_m1 = candidate;
        }
    }
    long[MAX_A] mate_a = zeroed, mate_p = zeroed;
    for (usz a = 0; a < applicants; a += 1) mate_a[a] = -1;
    for (usz p = 0; p < posts; p += 1) mate_p[p] = -1;
    for (usz a = 0; a < applicants; a += 1) if (best_m1[a] < posts) { mate_a[a] = (long)best_m1[a]; mate_p[best_m1[a]] = (long)a; }
    long[MAX_NODES] parity = zeroed;
    for (usz n = 0; n < node_count; n += 1) parity[n] = -1;
    usz[MAX_NODES] queue = zeroed;
    usz head = 0, tail = 0;
    for (usz a = 0; a < applicants; a += 1) if (mate_a[a] < 0) { parity[a] = 0; queue[tail++] = a; }
    for (usz p = 0; p < posts; p += 1) if (mate_p[p] < 0) { usz node = applicants+p; parity[node] = 0; queue[tail++] = node; }
    for (usz p = posts; p < post_count; p += 1) { usz node = applicants+p; parity[node] = 0; queue[tail++] = node; }
    while (head < tail) {
        usz node = queue[head++];
        if (node < applicants) {
            usz a = node;
            if (parity[node] == 0) {
                for (usz p = 0; p < posts; p += 1) if (rank[a][p] == 1 && mate_a[a] != (long)p && parity[applicants+p] < 0) { parity[applicants+p] = 1; queue[tail++] = applicants+p; }
            } else if (mate_a[a] >= 0 && parity[applicants+(usz)mate_a[a]] < 0) { parity[applicants+(usz)mate_a[a]] = 0; queue[tail++] = applicants+(usz)mate_a[a]; }
        } else {
            usz p = node-applicants;
            if (p < posts) {
                if (parity[node] == 0) {
                    for (usz a = 0; a < applicants; a += 1) if (rank[a][p] == 1 && mate_a[a] != (long)p && parity[a] < 0) { parity[a] = 1; queue[tail++] = a; }
                } else if (mate_p[p] >= 0 && parity[(usz)mate_p[p]] < 0) { parity[(usz)mate_p[p]] = 0; queue[tail++] = (usz)mate_p[p]; }
            }
        }
    }
    long[MAX_NODES] class_of = zeroed;
    for (usz n = 0; n < node_count; n += 1) class_of[n] = parity[n] < 0 ? 2 : parity[n];
    bool[MAX_A][MAX_POSTS] reduced = zeroed, allowed = zeroed;
    for (usz a = 0; a < applicants; a += 1) {
        usz best_even_rank = posts+1;
        for (usz p = 0; p < posts; p += 1) {
            if (rank[a][p] == 1) reduced[a][p] = true;
            if (rank[a][p] > 0 && class_of[applicants+p] == 0 && (usz)rank[a][p] < best_even_rank) best_even_rank = (usz)rank[a][p];
        }
        usz last_rank = max_rank[a]+1;
        if (class_of[applicants+posts+a] == 0 && last_rank < best_even_rank) best_even_rank = last_rank;
        for (usz p = 0; p < posts; p += 1) if (rank[a][p] > 0 && (usz)rank[a][p] == best_even_rank && class_of[applicants+p] == 0) reduced[a][p] = true;
        if (last_rank == best_even_rank && class_of[applicants+posts+a] == 0) reduced[a][posts+a] = true;
        for (usz p = 0; p < post_count; p += 1) { long ca = class_of[a], cp = class_of[applicants+p]; if (reduced[a][p] && !((ca == 1 && (cp == 1 || cp == 2)) || (ca == 2 && cp == 1))) allowed[a][p] = true; }
    }
    usz[MAX_A] best = zeroed;
    bool found = false;
    usz full_limit = 1;
    for (usz i = 0; i < applicants; i += 1) full_limit *= post_count;
    for (usz code = 0; code < full_limit; code += 1) {
        usz value = code;
        usz[MAX_A] candidate = zeroed;
        uint used = 0;
        long first_count = 0;
        bool valid = true;
        for (usz a = 0; a < applicants; a += 1) {
            usz p = value%post_count; value /= post_count; candidate[a] = p;
            if (!allowed[a][p] || (used & (1u << p)) != 0) { valid = false; break; }
            used |= 1u << p;
            if (p < posts && rank[a][p] == 1) first_count += 1;
        }
        if (valid && first_count == best_m1_size && (!found || lex_less(candidate,best,applicants))) { found = true; best = candidate; }
    }
    if (output == null || capacity < output_bytes) return -2;
    char[MAX_OUTPUT] staged = zeroed;
    put64(&staged[0], 0, found ? 1 : 0);
    for (usz a = 0; a < applicants; a += 1) put64(&staged[0], 8*(a+1), found ? (long)best[a] : -1);
    for (usz b = 0; b < output_bytes; b += 1) output[b] = staged[b];
    return (long)output_bytes;
}
