module depth_first_search_iterative;
const int MAX_VERTICES = 64;
const int MAX_EDGES = 256;
fn long depth_first_search_iterative(long* input, usz length) @export("depth_first_search_iterative") {
    if (input == null || length < 4 || length > 518) return -1;
    long nv = input[0], mv = input[1], source = input[2], target = input[3];
    if (nv < 1 || nv > MAX_VERTICES || mv < 0 || mv > MAX_EDGES || source < 0 || source >= nv
           ) return -1;
    int m = (int)mv;
    if (length != 4 + 2 * (usz)m) return -1;
    for (int edge = 0; edge < m; edge++) {
        long left = input[4 + 2 * edge], right = input[5 + 2 * edge];
        if (left < 0 || left >= nv || right < 0 || right >= nv) return -1;
    }
    bool[MAX_VERTICES] visited = zeroed;
    int[MAX_VERTICES] pending;
    int top = 1;
    pending[0] = (int)source;
    visited[(int)source] = true;
    while (top > 0) {
        top--;
        int current = pending[top];
        if ((long)current == target) return 1;
        for (int edge = 0; edge < m; edge++) {
            long left = input[4 + 2 * edge], right = input[5 + 2 * edge];
            long neighbor = left == current ? right : right == current ? left : -1;
            if (neighbor >= 0 && !visited[(int)neighbor]) {
                visited[(int)neighbor] = true;
                pending[top] = (int)neighbor;
                top++;
            }
        }
    }
    return 0;
}
