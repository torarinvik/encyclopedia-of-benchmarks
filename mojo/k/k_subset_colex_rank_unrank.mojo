from std.collections import InlineArray

const MAX_N: usize = 16
const MAX_K: usize = 16
const MAX_INPUT: usize = 20
const MAX_OUTPUT: usize = 136

def choose_small(n: usize, k_value: usize) -> i64:
    if k_value > n: return 0
    k: mutable usize = k_value
    if k > n - k: k <- n - k
    result: mutable i64 = 1
    i: mutable usize = 1
    while i <= k:
        result <- result * (n - k + i).i64() / i.i64()
        i <- i + 1
    result

def store_i64_le(output: mutable view[u8], offset: usize, value: i64):
    bits: mutable u64 = value.u64()
    byte: mutable usize = 0
    while byte < 8:
        output[offset + byte] <- (bits & 255).u8()
        bits <- bits >> 8
        byte <- byte + 1

def colex_impl(input: view[i64], length: usize, output: mutable view[u8],
               capacity: usize, output_is_null: bool) -> i64:
    if length < 3 or length > MAX_INPUT: return -1
    mode: i64 = input[0]
    if mode != 0 and mode != 1: return -1
    raw_n: i64 = input[1]
    raw_k: i64 = input[2]
    if raw_n < 0 or raw_n > MAX_N.i64() or raw_k < 0 or raw_k > raw_n: return -1
    n: usize = raw_n.usize()
    k: usize = raw_k.usize()
    indices: mutable InlineArray[Int, MAX_K] = InlineArray[Int, MAX_K](fill=0)
    rank: mutable i64 = 0

    if mode == 0:
        if length != 3 + k: return -1
        i: mutable usize = 0
        while i < k:
            index: i64 = input[3 + i]
            if index < 0 or index >= raw_n: return -1
            if i > 0 and indices[i - 1] >= index: return -1
            indices[i] <- index.Int()
            rank <- rank + choose_small(index.usize(), i + 1)
            i <- i + 1
    else:
        if length != 4: return -1
        rank <- input[3]
        if rank < 0 or rank >= choose_small(n, k): return -1
        upper: mutable Int = n.Int() - 1
        remaining: mutable i64 = rank
        order: mutable usize = k
        while order > 0:
            candidate: mutable Int = upper
            while candidate >= 0 and choose_small(candidate.usize(), order) > remaining:
                candidate <- candidate - 1
            if candidate < 0: return -1
            indices[order - 1] <- candidate
            remaining <- remaining - choose_small(candidate.usize(), order)
            upper <- candidate - 1
            order <- order - 1

    needed: usize = (k + 1) * 8
    if output_is_null or capacity < needed: return -2
    store_i64_le(output, 0, rank)
    i: mutable usize = 0
    while i < k:
        store_i64_le(output, (i + 1) * 8, indices[i].i64())
        i <- i + 1
    needed.i64()

export fn k_subset_colex_rank_unrank(input: i64&, length: usize,
        output: mutable u8&, capacity: usize) -> i64:
    if input.is_null() or length < 1 or length > MAX_INPUT: return -1
    if length < 3: return -1
    if output.is_null():
        var scratch = InlineArray[u8, 1](fill=0)
        return colex_impl(input[0:length], length, scratch[0:0], capacity, true)
    safe_capacity: mutable usize = capacity
    if safe_capacity > MAX_OUTPUT: safe_capacity <- MAX_OUTPUT
    colex_impl(input[0:length], length, output[0:safe_capacity], capacity, false)
