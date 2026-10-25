/*
 * Anagram program by Raymond Chen,
 * inspired by a similar program by Brian Scearce
 *
 * This program is Copyright 1991 by Raymond Chen.
 *             (rjc@math.princeton.edu)
 *
 * This program may be freely distributed provided all alterations
 * to the original are clearly indicated as such.
 * Alterations: bounded packed-array input, portable 64-bit packed counts,
 * and a scalar decomposition count instead of periodic printing.
 */

const max_phrase: usize = 16;
const max_words: usize = 12;
const max_word_length: usize = 16;
const alphabet: usize = 26;

const Candidate = struct { mask: u64, length: usize };
const Search = struct {
    candidates: [max_words]Candidate,
    candidate_count: usize,
    order: [alphabet]usize,
    letter_mask: [alphabet]u64,
    sign_mask: u64,
};

fn letterIndex(value: i64) ?usize {
    if (value >= 97 and value <= 122) return @intCast(value - 97);
    if (value >= 65 and value <= 90) return @intCast(value - 65);
    return null;
}

fn findAnagrams(search: *Search, remaining_mask: u64, remaining_length: usize,
                start_value: usize, first_letter: usize) i64 {
    if (remaining_length == 0) return 1;
    var pivot_position = first_letter;
    while (pivot_position < alphabet) : (pivot_position += 1) {
        const letter = search.order[pivot_position];
        if ((remaining_mask & search.letter_mask[letter]) != 0) break;
    }
    if (pivot_position == alphabet) return 0;
    const pivot = search.order[pivot_position];
    var start = start_value;
    var ending = search.candidate_count;
    var solutions: i64 = 0;
    while (start < ending) {
        const candidate = search.candidates[start];
        const after = remaining_mask -% candidate.mask;
        if ((after & search.sign_mask) != 0) { start += 1; continue; }
        if ((candidate.mask & search.letter_mask[pivot]) == 0) {
            search.candidates[start] = search.candidates[ending - 1];
            search.candidates[ending - 1] = candidate;
            ending -= 1;
            continue;
        }
        const next_length = remaining_length - candidate.length;
        if (next_length == 0) solutions += 1
        else solutions += findAnagrams(search, after, next_length, start, pivot_position);
        start += 1;
    }
    return solutions;
}

export fn ptrdist_anagram(input: ?[*]const i64, length: usize) i64 {
    const values_ptr = input orelse return -1;
    if (length < 3 or length > 222) return -1;
    const values = values_ptr[0..length];
    if (values[0] < 1 or values[0] > @as(i64, @intCast(max_phrase))) return -1;
    const phrase_length: usize = @intCast(values[0]);
    const count_offset = phrase_length + 1;
    if (count_offset >= length or values[count_offset] < 0 or values[count_offset] > @as(i64, @intCast(max_words))) return -1;
    var phrase_counts: [alphabet]u8 = @splat(0);
    for (0..phrase_length) |i| {
        const letter = letterIndex(values[i + 1]) orelse return -1;
        phrase_counts[letter] += 1;
    }

    const word_count: usize = @intCast(values[count_offset]);
    var offset = count_offset + 1;
    var phrase_mask: u64 = 0;
    var sign_mask: u64 = 0;
    var letter_mask: [alphabet]u64 = @splat(0);
    var letter_shift: [alphabet]u6 = @splat(0);
    var global_frequency: [alphabet]u32 = @splat(0);
    var shift: u32 = 0;
    for (0..alphabet) |letter| {
        const frequency: u32 = phrase_counts[letter];
        if (frequency == 0) continue;
        var count_bits: u32 = 1;
        while ((@as(u32, 1) << @as(u5, @intCast(count_bits))) <= frequency) : (count_bits += 1) {}
        if (shift + count_bits + 1 > 64) return -1;
        const lane_shift: u6 = @intCast(shift);
        const bits: u6 = @intCast(count_bits);
        letter_mask[letter] = ((@as(u64, 1) << bits) - 1) << lane_shift;
        phrase_mask |= @as(u64, frequency) << lane_shift;
        sign_mask |= @as(u64, 1) << @as(u6, @intCast(shift + count_bits));
        letter_shift[letter] = lane_shift;
        shift += count_bits + 1;
    }

    var search: Search = undefined;
    search.candidates = undefined;
    search.candidate_count = 0;
    search.letter_mask = letter_mask;
    search.sign_mask = sign_mask;
    for (0..word_count) |_| {
        if (offset >= length or values[offset] < 1 or values[offset] > @as(i64, @intCast(max_word_length))) return -1;
        const word_length: usize = @intCast(values[offset]);
        offset += 1;
        if (word_length > length - offset) return -1;
        var counts: [alphabet]u8 = @splat(0);
        for (0..word_length) |i| {
            const letter = letterIndex(values[offset + i]) orelse return -1;
            counts[letter] += 1;
        }
        var fits = true;
        for (0..alphabet) |letter| {
            if (counts[letter] > phrase_counts[letter]) fits = false;
        }
        if (fits and ((word_length >= 2 and word_length + 2 <= phrase_length) or word_length == phrase_length)) {
            var mask: u64 = 0;
            for (0..alphabet) |letter| {
                mask |= @as(u64, counts[letter]) << letter_shift[letter];
                global_frequency[letter] += counts[letter];
            }
            search.candidates[search.candidate_count] = .{ .mask = mask, .length = word_length };
            search.candidate_count += 1;
        }
        offset += word_length;
    }
    if (offset != length) return -1;

    for (0..alphabet) |letter| search.order[letter] = letter;
    for (1..alphabet) |i| {
        const key = search.order[i];
        var j = i;
        while (j > 0) {
            const previous = search.order[j - 1];
            const previous_frequency = if (global_frequency[previous] == 0) 0xffffffff else global_frequency[previous];
            const key_frequency = if (global_frequency[key] == 0) 0xffffffff else global_frequency[key];
            if (previous_frequency < key_frequency or (previous_frequency == key_frequency and previous < key)) break;
            search.order[j] = search.order[j - 1];
            j -= 1;
        }
        search.order[j] = key;
    }
    return findAnagrams(&search, phrase_mask, phrase_length, 0, 0);
}
