module aho_build_rooted_triplet_tree;

const usz MAX_TAXA = 7;
const usz MAX_TRIPLETS = 105;
const usz MAX_NODES = 13;

fn void write_word(char* output, usz offset, long value) {
    ulong bits = value.ulong();
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long aho_build_rooted_triplet_tree(long* input, usz length, char* output, usz capacity) @export("aho_build_rooted_triplet_tree") {
    if (input == null || length < 2 || length > 318) return -1;
    if (input[0] < 1 || input[0] > 7 || input[1] < 0) return -1;
    int n = input[0].int();
    usz q_limit = (usz)(n * (n - 1) * (n - 2) / 2);
    if (input[1].ulong() > q_limit) return -1;
    usz q = input[1].usz();
    if (length != 2 + 3 * q) return -1;

    int[MAX_TRIPLETS * 3] triples;
    for (usz i = 0; i < q; i++) {
        long aa = input[2 + 3 * i], bb = input[3 + 3 * i], cc = input[4 + 3 * i];
        if (aa < 0 || aa >= n || bb < 0 || bb >= n || cc < 0 || cc >= n || aa == bb || aa == cc || bb == cc) return -1;
        int a = aa.int(), b = bb.int(), c = cc.int();
        if (a > b) { int t = a; a = b; b = t; }
        for (usz j = 0; j < i; j++) if (triples[3 * j] == a && triples[3 * j + 1] == b && triples[3 * j + 2] == c) return -1;
        triples[3 * i] = a; triples[3 * i + 1] = b; triples[3 * i + 2] = c;
    }

    int[MAX_NODES] kind, value;
    int[MAX_NODES] tasks;
    usz node_count = 0, top = 1;
    tasks[0] = (1 << n) - 1;
    bool compatible = true;
    while (top > 0) {
        top--;
        int mask = tasks[top];
        if ((mask & (mask - 1)) == 0) {
            int label = 0;
            while ((mask & (1 << label)) == 0) label++;
            kind[node_count] = 1; value[node_count] = label; node_count++;
            continue;
        }
        bool[MAX_TAXA * MAX_TAXA] edge;
        for (usz i = 0; i < MAX_TAXA * MAX_TAXA; i++) edge[i] = false;
        for (usz i = 0; i < q; i++) {
            int a = triples[3 * i], b = triples[3 * i + 1], c = triples[3 * i + 2];
            int needed = (1 << a) | (1 << b) | (1 << c);
            if ((mask & needed) == needed) { edge[a * 7 + b] = true; edge[b * 7 + a] = true; }
        }
        bool[MAX_TAXA] seen;
        for (int i = 0; i < 7; i++) seen[i] = false;
        int[MAX_TAXA] components;
        usz component_count = 0;
        for (int start = 0; start < n; start++) {
            if ((mask & (1 << start)) == 0 || seen[start]) continue;
            int[MAX_TAXA] queue;
            usz head = 0, tail = 1;
            int component = 0;
            queue[0] = start; seen[start] = true;
            while (head < tail) {
                int current = queue[head]; head++;
                component |= 1 << current;
                for (int other = 0; other < n; other++) if (edge[current * 7 + other] && !seen[other]) {
                    seen[other] = true; queue[tail] = other; tail++;
                }
            }
            components[component_count] = component; component_count++;
        }
        if (component_count == 1) { compatible = false; break; }
        kind[node_count] = 0; value[node_count] = component_count.int(); node_count++;
        usz k = component_count;
        while (k > 0) { k--; tasks[top] = components[k]; top++; }
    }

    long[MAX_NODES + 1] words;
    usz word_count = 1;
    if (compatible) {
        words[0] = node_count.long();
        for (usz i = 0; i < node_count; i++) {
            if (kind[i] == 1) words[i + 1] = -(value[i] + 1).long();
            else words[i + 1] = value[i].long();
        }
        word_count += node_count;
    } else { words[0] = 0; }
    usz output_size = word_count * 8;
    if (output == null || capacity < output_size) return -2;
    for (usz i = 0; i < word_count; i++) write_word(output, i * 8, words[i]);
    output_size.long()
}
