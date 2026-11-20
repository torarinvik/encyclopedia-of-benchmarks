module weisfeiler_lehman_color_refinement;

const usz MAX_VERTICES = 8;
const usz MAX_INPUT_LENGTH = 9;
const long INVALID_RESULT = -1;
const long DEGREE_COLOR_PLACE = 43046721;

fn usz bit_count(long value) {
    usz count = 0;
    while (value != 0) {
        count += (usz)(value & 1);
        value >>= 1;
    }
    return count;
}

fn long weisfeiler_lehman_color_refinement(long* input, usz length)
        @export("weisfeiler_lehman_color_refinement") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH + 1) return INVALID_RESULT;
    if (input[0] < 0 || input[0] > (long)MAX_VERTICES) return INVALID_RESULT;
    usz n = (usz)input[0];
    if (length != 1 + n) return INVALID_RESULT;

    long[MAX_VERTICES] adjacency = {};
    long[MAX_VERTICES] colors = {};
    long[MAX_VERTICES] next_colors = {};
    long allowed = (1L << n) - 1L;
    usz class_count = 0;
    for (usz vertex = 0; vertex < n; ++vertex) {
        long mask = input[1 + vertex];
        if (mask < 0 || (mask & ~allowed) != 0 || (mask & (1L << vertex)) != 0)
            return INVALID_RESULT;
        adjacency[vertex] = mask;
        colors[vertex] = (long)bit_count(mask);
        bool first_degree = true;
        for (usz prior = 0; prior < vertex; ++prior) {
            if (colors[prior] == colors[vertex]) first_degree = false;
            if (((adjacency[vertex] >> prior) & 1L) != ((adjacency[prior] >> vertex) & 1L))
                return INVALID_RESULT;
        }
        if (first_degree) ++class_count;
    }
    if (n == 0) return 0;

    for (;;) {
        long[MAX_VERTICES] keys = {};
        long[MAX_VERTICES] unique_keys = {};
        usz unique_count = 0;
        for (usz vertex = 0; vertex < n; ++vertex) {
            long[MAX_VERTICES] neighbor_colors = {};
            usz neighbor_count = 0;
            for (usz neighbor = 0; neighbor < n; ++neighbor) {
                if ((adjacency[vertex] & (1L << neighbor)) == 0) continue;
                long value = colors[neighbor];
                usz position = neighbor_count;
                while (position > 0 && neighbor_colors[position - 1] > value) {
                    neighbor_colors[position] = neighbor_colors[position - 1];
                    --position;
                }
                neighbor_colors[position] = value;
                ++neighbor_count;
            }

            long suffix = 0;
            for (usz slot = 0; slot < MAX_VERTICES; ++slot) {
                suffix *= 9;
                if (slot < neighbor_count) suffix += neighbor_colors[slot] + 1;
            }
            keys[vertex] = colors[vertex] * DEGREE_COLOR_PLACE + suffix;

            bool seen = false;
            for (usz prior = 0; prior < vertex; ++prior)
                if (keys[prior] == keys[vertex]) seen = true;
            if (!seen) unique_keys[unique_count++] = keys[vertex];
        }

        for (usz index = 1; index < unique_count; ++index) {
            long value = unique_keys[index];
            usz position = index;
            while (position > 0 && unique_keys[position - 1] > value) {
                unique_keys[position] = unique_keys[position - 1];
                --position;
            }
            unique_keys[position] = value;
        }
        for (usz vertex = 0; vertex < n; ++vertex) {
            usz rank = 0;
            while (unique_keys[rank] != keys[vertex]) ++rank;
            next_colors[vertex] = (long)rank;
        }
        if (unique_count == class_count) {
            for (usz vertex = 0; vertex < n; ++vertex) colors[vertex] = next_colors[vertex];
            break;
        }
        for (usz vertex = 0; vertex < n; ++vertex) colors[vertex] = next_colors[vertex];
        class_count = unique_count;
    }

    long packed = 0;
    long place = 1;
    for (usz vertex = 0; vertex < n; ++vertex) {
        packed += colors[vertex] * place;
        place *= 9;
    }
    return packed;
}
