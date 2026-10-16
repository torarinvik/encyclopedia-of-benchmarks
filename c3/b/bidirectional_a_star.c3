module bidirectional_a_star;
const usz MAX_CELLS = 400;
const long INF_COST = 1000000;
fn long heuristic(usz a, usz b, usz cols) { long dy = (long)(a / cols) - (long)(b / cols), dx = (long)(a % cols) - (long)(b % cols); long h = 0; while ((h + 1) * (h + 1) <= dy * dy + dx * dx) h++; return h; }
fn void put_i64(char* output, usz slot, long value) { ulong bits = (ulong)value; for (usz i = 0; i < 8; i++) output[slot * 8 + i] = (char)(bits >> (i * 8)); }
fn long bidirectional_a_star(long* input, usz length, char* output, usz capacity) @export("bidirectional_a_star") {
 if (input == null || length < 6 || input[0] < 1 || input[0] > 20 || input[1] < 1 || input[1] > 20) return -1;
 usz rows = (usz)input[0], cols = (usz)input[1], cells = rows * cols;
 if (input[2] < 0 || (usz)input[2] >= rows || input[3] < 0 || (usz)input[3] >= cols || input[4] < 0 || (usz)input[4] >= rows || input[5] < 0 || (usz)input[5] >= cols || length != 6 + cells) return -1;
 usz start = (usz)input[2] * cols + (usz)input[3], goal = (usz)input[4] * cols + (usz)input[5]; bool[MAX_CELLS] blocked;
 for (usz i = 0; i < cells; i++) { if (input[6 + i] != 0 && input[6 + i] != 1) return -1; blocked[i] = input[6 + i] == 1; } if (blocked[start] || blocked[goal]) return -1;
 long[2][MAX_CELLS] g, parent, order; bool[2][MAX_CELLS] opened, closed; long[2] seq;
 for (usz s = 0; s < 2; s++) for (usz i = 0; i < cells; i++) { g[s][i] = INF_COST; parent[s][i] = -1; }
 g[0][start] = 0; g[1][goal] = 0; opened[0][start] = true; opened[1][goal] = true; seq[0] = 1; seq[1] = 1;
 long[4] dr = {-1, 0, 1, 0}, dc = {0, -1, 0, 1}; long best = INF_COST, meet = -1;
 while (true) {
  long[2] min_g = {INF_COST, INF_COST}; for (usz s = 0; s < 2; s++) for (usz v = 0; v < cells; v++) if (opened[s][v] && g[s][v] < min_g[s]) min_g[s] = g[s][v];
  if (best < INF_COST && (min_g[0] == INF_COST || min_g[1] == INF_COST || min_g[0] + min_g[1] >= best)) break;
  for (usz s = 0; s < 2; s++) {
   usz target = s == 0 ? goal : start; long chosen = -1, best_f = INF_COST;
   for (usz v = 0; v < cells; v++) if (opened[s][v]) { long f = g[s][v] + heuristic(v, target, cols); if (chosen < 0 || f < best_f || (f == best_f && order[s][v] < order[s][(usz)chosen])) { chosen = (long)v; best_f = f; } }
   if (chosen < 0) continue; usz u = (usz)chosen; opened[s][u] = false; closed[s][u] = true;
   if (g[1 - s][u] < INF_COST && g[s][u] + g[1 - s][u] < best) { best = g[s][u] + g[1 - s][u]; meet = chosen; }
   long y = (long)(u / cols), x = (long)(u % cols);
   for (usz d = 0; d < 4; d++) { long ny = y + dr[d], nx = x + dc[d]; if (ny < 0 || (usz)ny >= rows || nx < 0 || (usz)nx >= cols) continue; usz v = (usz)ny * cols + (usz)nx; if (blocked[v] || closed[s][v]) continue; long ng = g[s][u] + 1; if (ng < g[s][v]) { g[s][v] = ng; parent[s][v] = chosen; opened[s][v] = true; order[s][v] = seq[s]++; if (g[1 - s][v] < INF_COST && ng + g[1 - s][v] < best) { best = ng + g[1 - s][v]; meet = (long)v; } } }
  }
  bool any = false; for (usz s = 0; s < 2; s++) for (usz v = 0; v < cells; v++) any = any || opened[s][v]; if (!any) break;
 }
 usz[MAX_CELLS] path, rev; usz count = 0; if (meet < 0) { path[count++] = start; } else { usz n = 0; long v = meet; while (v >= 0) { rev[n++] = (usz)v; v = parent[0][(usz)v]; } while (n > 0) path[count++] = rev[--n]; v = parent[1][(usz)meet]; while (v >= 0) { path[count++] = (usz)v; v = parent[1][(usz)v]; } }
 usz bytes = (1 + 2 * count) * 8; if (output == null || capacity < bytes) return -2; put_i64(output, 0, (long)count); for (usz i = 0; i < count; i++) { put_i64(output, 1 + 2 * i, (long)(path[i] / cols)); put_i64(output, 2 + 2 * i, (long)(path[i] % cols)); } return (long)bytes;
}
