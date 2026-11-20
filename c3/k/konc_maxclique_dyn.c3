module konc_maxclique_dyn;

const usz MAX_VERTICES = 24;
const usz MAX_PARSEABLE_INPUT = 26;

struct Candidate { int vertex; int bound; }
struct Search {
    ulong adjacency[MAX_VERTICES];
    int chosen[MAX_VERTICES];
    int chosen_count;
    int best;
    int steps[MAX_VERTICES + 2];
    int prior_child_steps[MAX_VERTICES + 2];
    int total_color_calls;
}

fn void degree_order(Search* search, int* vertices, int count, Candidate* ordered) {
    int ids[MAX_VERTICES] = {};
    int degrees[MAX_VERTICES] = {};
    int maximum_degree = 0;
    for (int i = 0; i < count; i += 1) {
        ids[i] = vertices[i];
        for (int j = 0; j < count; j += 1)
            if ((search.adjacency[ids[i]] & (1ul << vertices[j])) != 0) degrees[i] += 1;
        if (degrees[i] > maximum_degree) maximum_degree = degrees[i];
    }
    for (int i = 1; i < count; i += 1) {
        int id = ids[i];
        int degree = degrees[i];
        int j = i;
        while (j > 0 && (degrees[j - 1] < degree
                || (degrees[j - 1] == degree && ids[j - 1] > id))) {
            ids[j] = ids[j - 1];
            degrees[j] = degrees[j - 1];
            j -= 1;
        }
        ids[j] = id;
        degrees[j] = degree;
    }
    for (int i = 0; i < count; i += 1) {
        ordered[i].vertex = ids[i];
        ordered[i].bound = (i < maximum_degree ? i : maximum_degree) + 1;
    }
}

fn void expand(Search* search, Candidate* candidates, int count, int level) {
    search.steps[level] += search.steps[level - 1] - search.prior_child_steps[level];
    search.prior_child_steps[level] = search.steps[level - 1];
    while (count > 0) {
        if (search.chosen_count + candidates[count - 1].bound <= search.best) return;
        int vertex = candidates[count - 1].vertex;
        search.chosen[search.chosen_count] = vertex;
        search.chosen_count += 1;
        int neighbors[MAX_VERTICES] = {};
        int neighbor_count = 0;
        for (int i = 0; i + 1 < count; i += 1) {
            int other = candidates[i].vertex;
            if ((search.adjacency[vertex] & (1ul << other)) != 0) {
                neighbors[neighbor_count] = other;
                neighbor_count += 1;
            }
        }
        if (neighbor_count > 0) {
            int prior_steps = search.steps[level];
            search.steps[level] += 1;
            search.total_color_calls += 1;
            if ((long)prior_steps * 1000 < (long)search.total_color_calls * 25) {
                Candidate reordered[MAX_VERTICES] = {};
                degree_order(search, &neighbors[0], neighbor_count, &reordered[0]);
                for (int i = 0; i < neighbor_count; i += 1) neighbors[i] = reordered[i].vertex;
            }
            ulong class_masks[MAX_VERTICES] = {};
            int colors[MAX_VERTICES] = {};
            int class_count = 0;
            for (int i = 0; i < neighbor_count; i += 1) {
                int color = 0;
                while (color < class_count
                        && (class_masks[color] & search.adjacency[neighbors[i]]) != 0)
                    color += 1;
                if (color == class_count) class_count += 1;
                colors[i] = color + 1;
                class_masks[color] |= 1ul << neighbors[i];
            }
            int minimum_color = search.best - search.chosen_count + 1;
            if (minimum_color < 1) minimum_color = 1;
            Candidate child[MAX_VERTICES] = {};
            int child_count = 0;
            for (int color = minimum_color; color <= class_count; color += 1) {
                for (int i = 0; i < neighbor_count; i += 1) {
                    if (colors[i] == color) {
                        child[child_count].vertex = neighbors[i];
                        child[child_count].bound = color;
                        child_count += 1;
                    }
                }
            }
            expand(search, &child[0], child_count, level + 1);
        } else if (search.chosen_count > search.best) {
            search.best = search.chosen_count;
        }
        search.chosen_count -= 1;
        count -= 1;
    }
}

fn long konc_maxclique_dyn(long* input, usz length) @export("konc_maxclique_dyn") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_INPUT) return -1;
    long n_value = input[0];
    if (n_value < 0 || n_value > (long)MAX_VERTICES || length != 1 + (usz)n_value) return -1;
    int n = (int)n_value;
    ulong domain = (1ul << n) - 1ul;
    Search search = {};
    for (int vertex = 0; vertex < n; vertex += 1) {
        long row = input[1 + (usz)vertex];
        if (row < 0 || ((ulong)row & ~domain) != 0) return -1;
        search.adjacency[vertex] = (ulong)row;
        if ((search.adjacency[vertex] & (1ul << vertex)) != 0) return -1;
    }
    for (int left = 0; left < n; left += 1) {
        for (int right = left + 1; right < n; right += 1) {
            bool forward = (search.adjacency[left] & (1ul << right)) != 0;
            bool reverse = (search.adjacency[right] & (1ul << left)) != 0;
            if (forward != reverse) return -1;
        }
    }
    if (n == 0) return 0;
    int vertices[MAX_VERTICES] = {};
    Candidate roots[MAX_VERTICES] = {};
    for (int i = 0; i < n; i += 1) vertices[i] = i;
    degree_order(&search, &vertices[0], n, &roots[0]);
    expand(&search, &roots[0], n, 1);
    return search.best;
}
