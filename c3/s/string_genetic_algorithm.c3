module string_genetic_algorithm;

const long POPULATION_SIZE = 200;
const long SELECTED_SIZE = 50;
const long ELITE_SIZE = 66;
const ulong RNG_MODULUS = 2147483647ul;

fn ulong next_random(ulong* state) {
    state[0] = (state[0] * 48271ul) % RNG_MODULUS;
    return state[0];
}

fn void write_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long string_genetic_algorithm(long* values, usz length, char* output,
                                 usz output_capacity) @export("string_genetic_algorithm") {
    if (values == null || length < 6 || length > 44) return -2;
    long target_length_value = values[0];
    long gene_count_value = values[1];
    long seed_value = values[2];
    long max_generations_value = values[3];
    if (target_length_value < 1 || target_length_value > 8 || gene_count_value < 1 || gene_count_value > 32 ||
        seed_value < 1 || seed_value >= (long)RNG_MODULUS || max_generations_value < 1 || max_generations_value > 1000) return -2;
    usz target_length = (usz)target_length_value;
    usz gene_count = (usz)gene_count_value;
    usz max_generations = (usz)max_generations_value;
    if (length != 4 + target_length + gene_count) return -2;
    char[8] target;
    char[32] genes;
    for (usz i = 0; i < target_length; i++) {
        long value = values[4 + i];
        if (value < 32 || value > 126) return -2;
        target[i] = (char)value;
    }
    for (usz i = 0; i < gene_count; i++) {
        long value = values[4 + target_length + i];
        if (value < 32 || value > 126) return -2;
        genes[i] = (char)value;
    }
    for (usz position = 0; position < target_length; position++) {
        bool found = false;
        for (usz gene = 0; gene < gene_count; gene++) if (genes[gene] == target[position]) found = true;
        if (!found) return -2;
    }
    if (output == null) return -2;

    ulong state = (ulong)seed_value;
    ulong[200] population;
    ulong[200] next_population;
    char[200] scores;
    usz[200] order;
    for (usz individual = 0; individual < 200; individual++) {
        ulong word = 0;
        for (usz position = 0; position < target_length; position++) {
            word |= (ulong)genes[(usz)(next_random(&state) % (ulong)gene_count)] << (8 * position);
        }
        population[individual] = word;
    }

    long total_population = 0;
    for (usz generation = 1; generation <= max_generations; generation++) {
        total_population += POPULATION_SIZE;
        for (usz individual = 0; individual < 200; individual++) {
            char score = 0;
            for (usz position = 0; position < target_length; position++) {
                if (((population[individual] >> (8 * position)) & 0xfful) == (ulong)target[position]) score++;
            }
            scores[individual] = score;
            order[individual] = individual;
            if ((usz)score == target_length) {
                if (output_capacity < 16) return -2;
                write_i64_le(output, 0, (long)generation);
                write_i64_le(output, 8, total_population);
                return 16;
            }
        }
        for (usz index = 1; index < 200; index++) {
            usz selected = order[index];
            usz insertion = index;
            while (insertion > 0 && scores[order[insertion - 1]] < scores[selected]) {
                order[insertion] = order[insertion - 1];
                insertion--;
            }
            order[insertion] = selected;
        }
        usz next_count = 0;
        for (; next_count < 66; next_count++) { next_population[next_count] = population[order[next_count]]; }
        for (usz parent_rank = 0; parent_rank < 50 && next_count < 200; parent_rank++) {
            ulong first = population[order[parent_rank]];
            usz child_count = (usz)scores[order[parent_rank]] * 100 / target_length + 1;
            if (child_count > 10) child_count = 10;
            for (usz round = 0; round < child_count && next_count < 200; round++) {
                ulong second = population[order[(usz)(next_random(&state) % 51ul)]];
                usz cut = (usz)(next_random(&state) % (ulong)target_length);
                ulong[2] children = {0, 0};
                for (usz position = 0; position < target_length; position++) {
                    ulong a = (first >> (8 * position)) & 0xfful;
                    ulong b = (second >> (8 * position)) & 0xfful;
                    children[0] |= (position < cut ? a : b) << (8 * position);
                    children[1] |= (position < cut ? b : a) << (8 * position);
                }
                for (usz child = 0; child < 2; child++) {
                    if (next_random(&state) % 5ul < 2ul) {
                        usz position = (usz)(next_random(&state) % (ulong)target_length);
                        ulong replacement = (ulong)genes[(usz)(next_random(&state) % (ulong)gene_count)];
                        ulong mask = 0xfful << (8 * position);
                        children[child] = (children[child] & ~mask) | (replacement << (8 * position));
                    }
                    if (next_count < 200) next_population[next_count++] = children[child];
                }
            }
        }
        for (usz index = 0; index < 200; index++) { population[index] = next_population[index]; }
    }
    return -1;
}
