module oi_wiki_maximum_clique_branch_bound;

const usz MAX_VERTICES = 24;
const usz MAX_PARSEABLE_INPUT = 26;

struct Clique_Search {
    ulong adjacency[MAX_VERTICES];
    long suffix_best[MAX_VERTICES];
    long best;
}

fn long bit_count(ulong bits) {
    long count = 0;
    while (bits != 0) { bits &= bits - 1ul; count += 1; }
    return count;
}

fn bool search_clique(Clique_Search* search, ulong candidates, long chosen) {
    if (candidates == 0) {
        if (chosen > search.best) { search.best = chosen; return true; }
        return false;
    }
    ulong remaining = candidates;
    while (remaining != 0) {
        if (chosen + bit_count(remaining) <= search.best) return false;
        ulong bit = remaining & (~remaining + 1ul);
        usz vertex = 0;
        ulong scan = bit;
        while ((scan & 1ul) == 0) { scan >>= 1; vertex += 1; }
        remaining &= ~bit;
        if (chosen + search.suffix_best[vertex] <= search.best) return false;
        if (search_clique(search, remaining & search.adjacency[vertex], chosen + 1)) return true;
    }
    return false;
}

fn long oi_wiki_maximum_clique_branch_bound(long* input, usz length)
    @export("oi_wiki_maximum_clique_branch_bound") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_INPUT) return -1;
    long n_value = input[0];
    if (n_value < 0 || n_value > (long)MAX_VERTICES || length != 1 + (usz)n_value) return -1;
    usz n = (usz)n_value;
    ulong domain = (1ul << n) - 1ul;
    Clique_Search search = {};
    for (usz vertex = 0; vertex < n; vertex += 1) {
        long row = input[1 + vertex];
        if (row < 0 || ((ulong)row & ~domain) != 0) return -1;
        search.adjacency[vertex] = (ulong)row;
        if ((search.adjacency[vertex] & (1ul << vertex)) != 0) return -1;
    }
    for (usz left = 0; left < n; left += 1) {
        for (usz right = left + 1; right < n; right += 1) {
            bool forward = (search.adjacency[left] & (1ul << right)) != 0;
            bool reverse = (search.adjacency[right] & (1ul << left)) != 0;
            if (forward != reverse) return -1;
        }
    }
    long root = (long)n - 1;
    while (root >= 0) {
        ulong greater = domain & ~((1ul << (usz)(root + 1)) - 1ul);
        search_clique(&search, search.adjacency[(usz)root] & greater, 1);
        search.suffix_best[(usz)root] = search.best;
        root -= 1;
    }
    return search.best;
}
