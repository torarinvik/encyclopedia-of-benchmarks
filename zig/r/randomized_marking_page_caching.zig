const MAX_REQUESTS: usize = 32;
const MAX_PAGES: usize = 16;
const MAX_INPUT: usize = 67;
const MAX_OUTPUT_BYTES: usize = 536;

fn store_i64_le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn randomized_marking_page_caching(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const cache_raw = input[0];
    const requests_raw = input[1];
    if (cache_raw < 1 or cache_raw > 8 or requests_raw < 0 or requests_raw > @as(i64, MAX_REQUESTS)) return -1;
    const cache_size: usize = @intCast(cache_raw);
    const requests: usize = @intCast(requests_raw);
    if (length < 3 + requests) return -1;
    const choices_raw = input[2 + requests];
    if (choices_raw < 0 or choices_raw > requests_raw or length != 3 + requests + @as(usize, @intCast(choices_raw))) return -1;
    const choice_count: usize = @intCast(choices_raw);
    var pages: [MAX_REQUESTS]usize = @splat(0);
    var choices: [MAX_REQUESTS]usize = @splat(0);
    for (0..requests) |i| {
        const page = input[2 + i];
        if (page < 0 or page >= MAX_PAGES) return -1;
        pages[i] = @intCast(page);
    }
    for (0..choice_count) |i| {
        const choice = input[3 + requests + i];
        if (choice < 0 or choice > MAX_PAGES) return -1;
        choices[i] = @intCast(choice);
    }
    var resident: [MAX_PAGES]bool = @splat(false);
    var marked: [MAX_PAGES]bool = @splat(false);
    var hits: [MAX_REQUESTS]i64 = @splat(0);
    var victims: [MAX_REQUESTS]i64 = @splat(-1);
    var resident_count: usize = 0;
    var choice_at: usize = 0;
    var misses: i64 = 0;
    for (0..requests) |request| {
        const page = pages[request];
        if (resident[page]) { hits[request] = 1; marked[page] = true; continue; }
        misses += 1;
        if (resident_count == cache_size) {
            var eligible: [MAX_PAGES]usize = @splat(0);
            var eligible_count: usize = 0;
            for (0..MAX_PAGES) |candidate| {
                if (resident[candidate] and !marked[candidate]) { eligible[eligible_count] = candidate; eligible_count += 1; }
            }
            if (eligible_count == 0) {
                for (0..MAX_PAGES) |candidate| {
                    if (resident[candidate]) { marked[candidate] = false; eligible[eligible_count] = candidate; eligible_count += 1; }
                }
            }
            if (choice_at >= choice_count or choices[choice_at] >= eligible_count) return -1;
            const victim = eligible[choices[choice_at]];
            choice_at += 1;
            resident[victim] = false; marked[victim] = false; resident_count -= 1;
            victims[request] = @intCast(victim);
        }
        resident[page] = true; marked[page] = true; resident_count += 1;
    }
    if (choice_at != choice_count) return -1;
    var resident_mask: i64 = 0;
    var marked_mask: i64 = 0;
    for (0..MAX_PAGES) |page| {
        if (resident[page]) resident_mask |= @as(i64, 1) << @intCast(page);
        if (resident[page] and marked[page]) marked_mask |= @as(i64, 1) << @intCast(page);
    }
    var words: [3 + 2 * MAX_REQUESTS]i64 = @splat(0);
    words[0] = misses; words[1] = resident_mask; words[2] = marked_mask;
    for (0..requests) |i| { words[3 + i] = hits[i]; words[3 + requests + i] = victims[i]; }
    const output_bytes = 8 * (3 + 2 * requests);
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    var staged: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    for (0..3 + 2 * requests) |word| store_i64_le(&staged, 8 * word, words[word]);
    for (0..output_bytes) |byte| output[byte] = staged[byte];
    return @intCast(output_bytes);
}
