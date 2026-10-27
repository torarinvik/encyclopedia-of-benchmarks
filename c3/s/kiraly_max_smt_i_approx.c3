module kiraly_max_smt_i_approx;
const usz MAX_M = 6; const usz MAX_W = 6; const usz MAX_INPUT = 74; const usz MAX_OUTPUT = 48; const usz MAX_STEPS = 121;

fn void put64(char* output, usz position, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[position + byte] = (char)(bits & 255); bits >>= 8; }
}

long kiraly_max_smt_i_approx(long* input, usz length, char* output, usz capacity) @export("kiraly_max_smt_i_approx") {
    if (input == null || length < 4 || length > MAX_INPUT) return -1;
    long m64 = input[0], w64 = input[1];
    if (m64 < 1 || m64 > (long)MAX_M || w64 < 1 || w64 > (long)MAX_W) return -1;
    usz m = (usz)m64, w = (usz)w64;
    if (length != 2 + 2 * m * w) return -1;
    long[MAX_M][MAX_W] men_rank = zeroed;
    long[MAX_W][MAX_M] women_rank = zeroed;
    bool[MAX_M][MAX_W] live = zeroed;
    long[MAX_M] assignment = zeroed;
    long[MAX_W] woman_partner = zeroed;
    long[MAX_M] status = zeroed; // 0 lad, 1 bachelor, 2 old bachelor
    for (usz man = 0; man < m; man += 1) {
        assignment[man] = -1;
        for (usz woman = 0; woman < w; woman += 1) {
            long rank = input[2 + man * w + woman];
            if (rank < -1 || rank >= (long)MAX_W) return -1;
            men_rank[man][woman] = rank;
        }
    }
    for (usz woman = 0; woman < w; woman += 1) {
        woman_partner[woman] = -1;
        for (usz man = 0; man < m; man += 1) {
            long rank = input[2 + m * w + woman * m + man];
            if (rank < -1 || rank >= (long)MAX_M) return -1;
            women_rank[woman][man] = rank;
        }
    }
    for (usz man = 0; man < m; man += 1)
        for (usz woman = 0; woman < w; woman += 1) {
            bool ma = men_rank[man][woman] >= 0, wa = women_rank[woman][man] >= 0;
            if (ma != wa) return -1;
            live[man][woman] = ma;
        }
    usz output_bytes = 8 * m;
    if (output == null || capacity < output_bytes) return -2;
    usz steps = 0;
    while (true) {
        steps += 1;
        if (steps > MAX_STEPS) return -1;
        usz man = m;
        for (usz x = 0; x < m; x += 1)
            if (status[x] != 2 && assignment[x] == -1) { man = x; break; }
        if (man == m) break;
        usz woman = w;
        for (usz x = 0; x < w; x += 1) if (live[man][x]) {
            bool better = woman == w;
            if (!better) {
                if (men_rank[man][x] < men_rank[man][woman]) better = true;
                else if (men_rank[man][x] == men_rank[man][woman]) {
                    bool x_maiden = woman_partner[x] == -1, old_maiden = woman_partner[woman] == -1;
                    if (x_maiden != old_maiden) better = x_maiden;
                    else better = x < woman;
                }
            }
            if (better) woman = x;
        }
        if (woman == w) {
            if (status[man] == 0) {
                status[man] = 1;
                for (usz x = 0; x < w; x += 1) live[man][x] = men_rank[man][x] >= 0;
            } else status[man] = 2;
            continue;
        }
        long incumbent64 = woman_partner[woman];
        if (incumbent64 < 0) {
            assignment[man] = (long)woman; woman_partner[woman] = (long)man; continue;
        }
        usz incumbent = (usz)incumbent64;
        bool old_uncertain = false;
        if (status[incumbent] == 0 && assignment[incumbent] >= 0) {
            usz fiance = (usz)assignment[incumbent];
            for (usz x = 0; x < w; x += 1) if (live[incumbent][x] && x != fiance) {
                bool preferred = men_rank[incumbent][x] < men_rank[incumbent][fiance];
                if (men_rank[incumbent][x] == men_rank[incumbent][fiance]) {
                    bool x_maiden = woman_partner[x] == -1, fiance_maiden = woman_partner[fiance] == -1;
                    if (x_maiden != fiance_maiden) preferred = x_maiden;
                }
                if (preferred) { old_uncertain = true; break; }
            }
        }
        bool accept = old_uncertain;
        if (!accept) {
            if (women_rank[woman][man] < women_rank[woman][incumbent]) accept = true;
            else if (women_rank[woman][man] == women_rank[woman][incumbent]) {
                if (status[man] != status[incumbent]) accept = status[man] > status[incumbent];
                else accept = man < incumbent;
            }
        }
        if (accept) {
            assignment[incumbent] = -1; woman_partner[woman] = -1;
            if (!old_uncertain) live[incumbent][woman] = false;
            assignment[man] = (long)woman; woman_partner[woman] = (long)man;
        } else live[man][woman] = false;
    }
    char[MAX_OUTPUT] staged = zeroed;
    for (usz man = 0; man < m; man += 1) put64(&staged[0], 8 * man, assignment[man]);
    for (usz byte = 0; byte < output_bytes; byte += 1) output[byte] = staged[byte];
    return (long)output_bytes;
}
