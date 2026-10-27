module randomized_marking_page_caching;

const usz MAX_REQUESTS = 32;
const usz MAX_PAGES = 16;
const usz MAX_INPUT = 67;
const usz MAX_OUTPUT_BYTES = 536;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

long randomized_marking_page_caching(long* input, usz length, char* output, usz capacity)
        @export("randomized_marking_page_caching") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long cache_raw = input[0], requests_raw = input[1];
    if (cache_raw < 1 || cache_raw > 8 || requests_raw < 0 || requests_raw > MAX_REQUESTS.long()) return -1;
    usz cache_size = cache_raw.usz(), requests = requests_raw.usz();
    if (length < 3 + requests) return -1;
    long choices_raw = input[2 + requests];
    if (choices_raw < 0 || choices_raw > requests_raw || length != 3 + requests + choices_raw.usz()) return -1;
    usz choice_count = choices_raw.usz();
    int[MAX_REQUESTS] pages = zeroed, choices = zeroed;
    for (usz i = 0; i < requests; i += 1) {
        long page = input[2 + i];
        if (page < 0 || page >= MAX_PAGES.long()) return -1;
        pages[i] = page.int();
    }
    for (usz i = 0; i < choice_count; i += 1) {
        long choice = input[3 + requests + i];
        if (choice < 0 || choice > MAX_PAGES.long()) return -1;
        choices[i] = choice.int();
    }
    bool[MAX_PAGES] resident = zeroed, marked = zeroed;
    long[MAX_REQUESTS] hits = zeroed, victims = zeroed;
    for (usz i = 0; i < MAX_REQUESTS; i += 1) victims[i] = -1;
    usz resident_count = 0, choice_at = 0;
    long misses = 0;
    for (usz request = 0; request < requests; request += 1) {
        int page = pages[request];
        if (resident[page.usz()]) { hits[request] = 1; marked[page.usz()] = true; continue; }
        misses += 1;
        if (resident_count == cache_size) {
            int[MAX_PAGES] eligible = zeroed;
            usz eligible_count = 0;
            for (usz candidate = 0; candidate < MAX_PAGES; candidate += 1)
                if (resident[candidate] && !marked[candidate]) { eligible[eligible_count] = candidate.int(); eligible_count += 1; }
            if (eligible_count == 0) {
                for (usz candidate = 0; candidate < MAX_PAGES; candidate += 1) {
                    if (resident[candidate]) { marked[candidate] = false; eligible[eligible_count] = candidate.int(); eligible_count += 1; }
                }
            }
            if (choice_at >= choice_count || choices[choice_at].usz() >= eligible_count) return -1;
            usz victim = eligible[choices[choice_at].usz()].usz();
            choice_at += 1;
            resident[victim] = false; marked[victim] = false; resident_count -= 1; victims[request] = victim.long();
        }
        resident[page.usz()] = true; marked[page.usz()] = true; resident_count += 1;
    }
    if (choice_at != choice_count) return -1;
    ulong resident_mask = 0, marked_mask = 0;
    for (usz page = 0; page < MAX_PAGES; page += 1) {
        if (resident[page]) resident_mask |= 1UL << page;
        if (resident[page] && marked[page]) marked_mask |= 1UL << page;
    }
    long[3 + 2 * MAX_REQUESTS] words = zeroed;
    words[0] = misses; words[1] = resident_mask.long(); words[2] = marked_mask.long();
    for (usz i = 0; i < requests; i += 1) { words[3 + i] = hits[i]; words[3 + requests + i] = victims[i]; }
    usz output_bytes = 8 * (3 + 2 * requests);
    if (output == null || capacity < output_bytes) return -2;
    char[MAX_OUTPUT_BYTES] staged = zeroed;
    for (usz word = 0; word < 3 + 2 * requests; word += 1) store_i64_le(&staged[0], 8 * word, words[word]);
    for (usz byte = 0; byte < output_bytes; byte += 1) output[byte] = staged[byte];
    return output_bytes.long();
}
