module graph_centrality;
fn void put64(char* out, usz at, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) out[at * 8 + b] = (char)((bits >> (b * 8)) & 255);
}
fn long graph_centrality(long* input, usz length, char* output, usz capacity) @export("graph_centrality") {
    if (input == null || length < 2) return -1;
    long nn = input[0]; long ee = input[1];
    if (nn < 1 || nn > 16 || ee < 0 || ee > nn * (nn - 1) || length != (usz)(2 + 3 * ee)) return -1;
    long[16][16] d; long inf = 9223372036854775807;
    for (usz i = 0; i < (usz)nn; i++) for (usz j = 0; j < (usz)nn; j++) { d[i][j] = inf; if (i == j) d[i][j] = 0; }
    for (usz z = 0; z < (usz)ee; z++) {
        long a = input[2 + 3*z]; long b = input[3 + 3*z]; long w = input[4 + 3*z];
        if (a < 0 || a >= nn || b < 0 || b >= nn || a == b || w < 1 || w > 1000000 || d[(usz)a][(usz)b] != inf) return -1;
        d[(usz)a][(usz)b] = w;
    }
    for (usz k = 0; k < (usz)nn; k++) for (usz i = 0; i < (usz)nn; i++) {
        if (d[i][k] == inf) continue;
        for (usz j = 0; j < (usz)nn; j++) if (d[k][j] != inf && d[i][k] + d[k][j] < d[i][j]) d[i][j] = d[i][k] + d[k][j];
    }
    long central = -1; long median = -1; long best_e = inf; double best_h = -1.0;
    if (nn == 1) { central = 0; median = 0; } else { for (usz i = 0; i < (usz)nn; i++) {
        bool reachable = false; long eccentricity = 0; double harmonic = 0.0;
        for (usz j = 0; j < (usz)nn; j++) if (i != j && d[i][j] != inf) { reachable = true; if (d[i][j] > eccentricity) eccentricity = d[i][j]; harmonic += 1.0 / (double)d[i][j]; }
        if (reachable && eccentricity < best_e) { best_e = eccentricity; central = (long)i; }
        if (reachable && harmonic > best_h) { best_h = harmonic; median = (long)i; }
    } }
    if (output == null || capacity < 16) return -2;
    put64(output, 0, central); put64(output, 1, median); return 16;
}
