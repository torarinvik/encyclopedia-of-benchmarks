module stern_brocot_tree;

const usz MAX_QUERIES = 128;
const usz MAX_RUNS = 64;
const usz MAX_INPUT_LENGTH = 16384;
const usz MAX_OUTPUT_WORDS = 32768;
const long MAX_COMPONENT = 1000000000;

struct Run { long direction; long count; }
struct Decoded { long numerator; long denominator; long lower_num; long lower_den; long upper_num; long upper_den; }

fn long sbt_gcd(long a, long b) {
    while (b != 0) { long remainder = a % b; a = b; b = remainder; }
    return a;
}

fn bool sbt_valid_fraction(long numerator, long denominator) {
    return numerator >= 1 && numerator <= MAX_COMPONENT && denominator >= 1 &&
        denominator <= MAX_COMPONENT && sbt_gcd(numerator, denominator) == 1;
}

fn bool sbt_encode(long numerator, long denominator, Run* runs, usz* run_count) {
    *run_count = 0;
    while (numerator != denominator) {
        if (*run_count >= MAX_RUNS) return false;
        if (numerator < denominator) {
            long count = (denominator - 1) / numerator;
            runs[*run_count] = {0, count};
            denominator -= count * numerator;
        } else {
            long count = (numerator - 1) / denominator;
            runs[*run_count] = {1, count};
            numerator -= count * denominator;
        }
        *run_count += 1;
    }
    return true;
}

fn bool sbt_decode(Run* runs, usz run_count, Decoded* result) {
    long ln = 0, ld = 1, un = 1, ud = 0, previous = -1;
    for (usz i = 0; i < run_count; i++) {
        long direction = runs[i].direction, count = runs[i].count;
        if ((direction != 0 && direction != 1) || count < 1 || count > MAX_COMPONENT || direction == previous) return false;
        if (direction == 0) {
            un += count * ln; ud += count * ld;
            if (un > MAX_COMPONENT || ud > MAX_COMPONENT) return false;
        } else {
            ln += count * un; ld += count * ud;
            if (ln > MAX_COMPONENT || ld > MAX_COMPONENT) return false;
        }
        previous = direction;
    }
    long numerator = ln + un, denominator = ld + ud;
    if (!sbt_valid_fraction(numerator, denominator)) return false;
    result.numerator = numerator; result.denominator = denominator;
    result.lower_num = ln; result.lower_den = ld;
    result.upper_num = un; result.upper_den = ud;
    return true;
}

fn usz sbt_common_prefix(Run* left, usz left_count, Run* right, usz right_count, Run* prefix) {
    usz i = 0, j = 0, count = 0;
    long left_used = 0, right_used = 0;
    while (i < left_count && j < right_count && left[i].direction == right[j].direction) {
        long left_remaining = left[i].count - left_used;
        long right_remaining = right[j].count - right_used;
        long shared = left_remaining < right_remaining ? left_remaining : right_remaining;
        prefix[count] = {left[i].direction, shared}; count += 1;
        left_used += shared; right_used += shared;
        if (left_used == left[i].count) { i += 1; left_used = 0; }
        if (right_used == right[j].count) { j += 1; right_used = 0; }
    }
    return count;
}

fn bool sbt_append(long* words, usz* word_count, long value) {
    if (*word_count >= MAX_OUTPUT_WORDS) return false;
    words[*word_count] = value; *word_count += 1;
    return true;
}

fn long stern_brocot_tree(long* input, usz length, char* output, usz output_capacity)
    @export("stern_brocot_tree") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long query_count = input[0];
    if (query_count < 1 || query_count > (long)MAX_QUERIES) return -1;
    long[MAX_OUTPUT_WORDS] words;
    usz word_count = 0, position = 1;
    for (long query = 0; query < query_count; query++) {
        if (position >= length) return -1;
        long operation = input[position]; position += 1;
        if (operation == 0) {
            if (position + 2 > length) return -1;
            long numerator = input[position], denominator = input[position + 1]; position += 2;
            if (!sbt_valid_fraction(numerator, denominator)) return -1;
            Run[MAX_RUNS] runs; usz run_count;
            if (!sbt_encode(numerator, denominator, &runs[0], &run_count) ||
                !sbt_append(&words[0], &word_count, operation) ||
                !sbt_append(&words[0], &word_count, (long)run_count)) return -1;
            for (usz i = 0; i < run_count; i++)
                if (!sbt_append(&words[0], &word_count, runs[i].direction) ||
                    !sbt_append(&words[0], &word_count, runs[i].count)) return -1;
        } else if (operation == 1) {
            if (position >= length) return -1;
            long raw_count = input[position]; position += 1;
            if (raw_count < 0 || raw_count > (long)MAX_RUNS || position + (usz)raw_count * 2 > length) return -1;
            usz run_count = (usz)raw_count; Run[MAX_RUNS] runs;
            for (usz i = 0; i < run_count; i++) { runs[i] = {input[position], input[position + 1]}; position += 2; }
            Decoded decoded;
            if (!sbt_decode(&runs[0], run_count, &decoded) ||
                !sbt_append(&words[0], &word_count, operation) ||
                !sbt_append(&words[0], &word_count, decoded.numerator) ||
                !sbt_append(&words[0], &word_count, decoded.denominator)) return -1;
        } else if (operation == 2) {
            if (position + 4 > length) return -1;
            long a = input[position], b = input[position + 1], c = input[position + 2], d = input[position + 3]; position += 4;
            if (!sbt_valid_fraction(a, b) || !sbt_valid_fraction(c, d)) return -1;
            Run[MAX_RUNS] left, right, prefix; usz left_count, right_count;
            if (!sbt_encode(a, b, &left[0], &left_count) || !sbt_encode(c, d, &right[0], &right_count)) return -1;
            usz prefix_count = sbt_common_prefix(&left[0], left_count, &right[0], right_count, &prefix[0]);
            Decoded decoded;
            if (!sbt_decode(&prefix[0], prefix_count, &decoded) ||
                !sbt_append(&words[0], &word_count, operation) ||
                !sbt_append(&words[0], &word_count, decoded.numerator) ||
                !sbt_append(&words[0], &word_count, decoded.denominator)) return -1;
        } else if (operation == 3) {
            if (position + 3 > length) return -1;
            long depth = input[position], numerator = input[position + 1], denominator = input[position + 2]; position += 3;
            if (depth < 1 || depth > MAX_COMPONENT || !sbt_valid_fraction(numerator, denominator)) return -1;
            Run[MAX_RUNS] path, prefix; usz path_count;
            if (!sbt_encode(numerator, denominator, &path[0], &path_count) || !sbt_append(&words[0], &word_count, operation)) return -1;
            long total_depth = 0;
            for (usz i = 0; i < path_count; i++) total_depth += path[i].count;
            if (depth > total_depth) {
                if (!sbt_append(&words[0], &word_count, -1)) return -1;
            } else {
                long remaining = depth; usz prefix_count = 0;
                for (usz i = 0; i < path_count && remaining > 0; i++) {
                    long take = remaining < path[i].count ? remaining : path[i].count;
                    prefix[prefix_count] = {path[i].direction, take}; prefix_count += 1; remaining -= take;
                }
                Decoded decoded;
                if (!sbt_decode(&prefix[0], prefix_count, &decoded) ||
                    !sbt_append(&words[0], &word_count, decoded.numerator) ||
                    !sbt_append(&words[0], &word_count, decoded.denominator)) return -1;
            }
        } else if (operation == 4) {
            if (position + 2 > length) return -1;
            long numerator = input[position], denominator = input[position + 1]; position += 2;
            if (!sbt_valid_fraction(numerator, denominator)) return -1;
            Run[MAX_RUNS] path; usz path_count;
            if (!sbt_encode(numerator, denominator, &path[0], &path_count)) return -1;
            Decoded decoded;
            if (!sbt_decode(&path[0], path_count, &decoded) ||
                !sbt_append(&words[0], &word_count, operation) ||
                !sbt_append(&words[0], &word_count, decoded.lower_num) ||
                !sbt_append(&words[0], &word_count, decoded.lower_den) ||
                !sbt_append(&words[0], &word_count, decoded.upper_num) ||
                !sbt_append(&words[0], &word_count, decoded.upper_den)) return -1;
        } else return -1;
    }
    if (position != length) return -1;
    usz byte_count = word_count * 8;
    if (output_capacity < byte_count || output == null) return -2;
    for (usz i = 0; i < word_count; i++) {
        ulong bits = (ulong)words[i];
        for (usz byte = 0; byte < 8; byte++) output[i * 8 + byte] = (char)((bits >> (byte * 8)) & 255);
    }
    return query_count;
}
