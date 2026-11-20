const KHP_N: usize = 24
const KHP_K: usize = 3
const KHP_INPUT: usize = 27
const KHP_CONTEXT: usize = 48
const KHP_FACTORS: usize = 25
const KHP_PERIODS: usize = 13
const KHP_BITS: usize = 117
const KHP_OUTPUT: usize = 39112

def khp_right(w: view[i32], size: usize, center: usize, period: usize, allowed: usize) -> usize:
    left: usize = center - period
    limit: usize = if size - left < size - center then size - left else size - center
    var errors: mutable usize = 0
    var d: mutable usize = 0
    while d < limit:
        if w[left + d] != w[center + d]:
            errors <- errors + 1
            if errors > allowed: return d
        d <- d + 1
    return limit

def khp_left(w: view[i32], center: usize, period: usize, allowed: usize) -> usize:
    limit: usize = center - period
    var errors: mutable usize = 0
    var d: mutable usize = 0
    while d < limit:
        if w[center - period - 1 - d] != w[center - 1 - d]:
            errors <- errors + 1
            if errors > allowed: return d
        d <- d + 1
    return limit

def khp_mark(seen: mutable view[u64], n: usize, base: usize, size: usize,
             center: usize, next: usize, lo: usize, hi: usize, period: usize):
    if hi >= size or hi - lo + 1 < period * 2: return
    if lo > center + 1 or hi + 1 < center: return
    if lo <= next + 1 and hi + 1 >= next: return
    start: usize = base + lo
    finish: usize = base + hi
    if finish >= n: return
    index: usize = (start * KHP_N + finish) * KHP_PERIODS + period
    seen[index // 64] <- seen[index // 64] | (1 << (index % 64))

def khp_at_head(seen: mutable view[u64], text: view[i32], budget: usize,
                base: usize, center: usize, next: usize):
    size: usize = text.length
    if center == 0 or center + 1 >= size: return
    var period: mutable usize = 1
    while period <= center:
        var split: mutable usize = 0
        while split <= budget:
            f: usize = khp_right(text, size, center, period, split)
            b: usize = khp_left(text, center, period, budget - split)
            if f <= period and f + b >= period:
                khp_mark(seen, KHP_N, base, size, center, next,
                         center - period - b, center + f - 1, period)
            split <- split + 1
        period <- period + 1
    var reversed = InlineArray[i32, KHP_CONTEXT](fill=0)
    var reverse_view: mutable view[i32] = reversed[0:KHP_CONTEXT]
    var i: mutable usize = 0
    while i < size:
        reverse_view[i] <- text[size - 1 - i]
        i <- i + 1
    reverse_center: usize = size - 1 - center
    period <- 1
    while period <= reverse_center:
        var split: mutable usize = 0
        while split <= budget:
            f: usize = khp_right(reverse_view, size, reverse_center, period, split)
            b: usize = khp_left(reverse_view, reverse_center, period, budget - split)
            if f <= period and f + b >= period:
                reverse_start: usize = reverse_center - period - b
                reverse_end: usize = reverse_center + f - 1
                khp_mark(seen, KHP_N, base, size, center, next,
                         size - 1 - reverse_end, size - 1 - reverse_start, period)
            split <- split + 1
        period <- period + 1

def khp_factorize(text: view[i32], n: usize, starts: mutable view[usize],
                  ends: mutable view[usize], factor_count: mutable usize&):
    var pos: mutable usize = 0
    while pos < n:
        var best: mutable usize = 0
        var earlier: mutable usize = 0
        while earlier < pos:
            var matched: mutable usize = 0
            while pos + matched < n and earlier + matched < n and text[earlier + matched] == text[pos + matched]:
                matched <- matched + 1
            if matched > best: best <- matched
            earlier <- earlier + 1
        finish: usize = pos + best + 1
        if finish > n: finish <- n
        starts[factor_count] <- pos
        ends[factor_count] <- finish
        factor_count <- factor_count + 1
        pos <- finish

def khp_run_heads(text: view[i32], n: usize, budget: usize,
                  starts: view[usize], ends: view[usize], factor_count: usize,
                  seen: mutable view[u64]):
    block: usize = budget + 2
    blocks: usize = (factor_count + block - 1) // block
    var bi: mutable usize = 0
    while bi + 1 < blocks:
        first: usize = bi * block
        first_end: usize = first + block
        if first_end > factor_count: first_end <- factor_count
        second_end: usize = first_end + block
        if second_end > factor_count: second_end <- factor_count
        head: usize = ends[first_end - 1] - 1
        next_head: usize = ends[second_end - 1] - 1
        pair_start: usize = starts[first]
        pair_end: usize = ends[second_end - 1]
        span: usize = pair_end - pair_start
        base: usize = if pair_start > span then pair_start - span else 0
        khp_at_head(seen, text[base:pair_end], budget, base,
                    head - base, next_head - base)
        bi <- bi + 1

def khp_marked(seen: view[u64], start: usize, finish: usize, period: usize) -> bool:
    index: usize = (start * KHP_N + finish) * KHP_PERIODS + period
    (seen[index // 64] & (1 << (index % 64))) != 0

def khp_put(output: mutable view[u8], offset: usize, value: i64):
    var bits: mutable u64 = value.u64()
    var b: mutable usize = 0
    while b < 8:
        output[offset + b] <- (bits & 255).u8()
        bits <- bits >> 8
        b <- b + 1

def khp_impl(input: view[i64], length: usize, output: mutable view[u8],
             capacity: usize, output_is_null: bool) -> i64:
    if length < 3 or length > KHP_INPUT: return -1
    n_value: i64 = input[0]
    budget_value: i64 = input[1]
    if n_value < 1 or n_value > KHP_N.i64() or budget_value < 0 or budget_value > KHP_K.i64(): return -1
    n: usize = n_value.usize()
    budget: usize = budget_value.usize()
    if length != n + 2: return -1
    var text = InlineArray[i32, KHP_N](fill=0)
    var starts = InlineArray[usize, KHP_FACTORS](fill=0)
    var ends = InlineArray[usize, KHP_FACTORS](fill=0)
    var seen = InlineArray[u64, KHP_BITS](fill=0)
    var text_view: mutable view[i32] = text[0:KHP_N]
    var starts_view: mutable view[usize] = starts[0:KHP_FACTORS]
    var ends_view: mutable view[usize] = ends[0:KHP_FACTORS]
    var seen_view: mutable view[u64] = seen[0:KHP_BITS]
    var i: mutable usize = 0
    while i < n:
        symbol: i64 = input[i + 2]
        if symbol < 0 or symbol > 4: return -1
        text_view[i] <- symbol.i32()
        i <- i + 1
    i <- 0
    while i + 1 < n:
        if text_view[i] == text_view[n - 1]: return -1
        i <- i + 1
    var factor_count: mutable usize = 0
    khp_factorize(text_view, n, starts_view, ends_view, factor_count)
    khp_run_heads(text_view, n, budget, starts_view, ends_view, factor_count, seen_view)
    var records: mutable usize = 0
    var start: mutable usize = 0
    while start < n:
        var len: mutable usize = 2
        while len <= n - start:
            finish: usize = start + len - 1
            var period: mutable usize = 1
            while period <= len // 2:
                if khp_marked(seen_view, start, finish, period): records <- records + 1
                period <- period + 1
            len <- len + 1
        start <- start + 1
    written: usize = 8 + records * 32
    if written > KHP_OUTPUT: return -1
    if output_is_null or capacity < written: return -2
    khp_put(output, 0, records.i64())
    var offset: mutable usize = 8
    start <- 0
    while start < n:
        var len: mutable usize = 2
        while len <= n - start:
            finish <- start + len - 1
            var period: mutable usize = 1
            while period <= len // 2:
                if khp_marked(seen_view, start, finish, period):
                    var errors: mutable usize = 0
                    var j: mutable usize = start
                    while j + period <= finish:
                        if text_view[j] != text_view[j + period]: errors <- errors + 1
                        j <- j + 1
                    khp_put(output, offset, start.i64()); offset <- offset + 8
                    khp_put(output, offset, len.i64()); offset <- offset + 8
                    khp_put(output, offset, period.i64()); offset <- offset + 8
                    khp_put(output, offset, errors.i64()); offset <- offset + 8
                period <- period + 1
            len <- len + 1
        start <- start + 1
    written.i64()

export fn k_repetition_block_head_pair_pass(input: i64&, length: usize,
    output: mutable u8&, capacity: usize) -> i64:
    if input.is_null() or length < 3 or length > KHP_INPUT: return -1
    if output.is_null():
        var scratch = InlineArray[u8, 1](fill=0)
        return khp_impl(input[0:length], length, scratch[0:0], capacity, true)
    safe_capacity: mutable usize = capacity
    if safe_capacity > KHP_OUTPUT: safe_capacity <- KHP_OUTPUT
    khp_impl(input[0:length], length, output[0:safe_capacity], capacity, false)
