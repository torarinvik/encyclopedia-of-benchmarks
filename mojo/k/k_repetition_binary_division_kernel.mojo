from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime KBR_N = 32
comptime KBR_K = 3
comptime KBR_INPUT = 35
comptime KBR_PERIODS = 17
comptime KBR_BITS = 272
comptime KBR_FACTORS = 33
comptime KBR_OUTPUT = 91400

fn kbr_lp(mut text: InlineArray[Int, KBR_N], lo: Int, hi: Int, center: Int,
          period: Int, allowed: Int) -> Int:
    let left = center - period
    let limit = min(hi - left, hi - center)
    var errors = 0
    for j in range(limit):
        if text[left + j] != text[center + j]:
            errors += 1
            if errors > allowed: return j
    limit

fn kbr_ls(mut text: InlineArray[Int, KBR_N], lo: Int, center: Int,
          period: Int, allowed: Int) -> Int:
    let limit = min(center - period - lo, center - lo)
    var errors = 0
    for j in range(limit):
        if text[center - period - 1 - j] != text[center - 1 - j]:
            errors += 1
            if errors > allowed: return j
    limit

fn kbr_mark(mut seen: InlineArray[Int, KBR_BITS], n: Int, lo: Int,
            last_head: Int, local_start: Int, local_end: Int, period: Int):
    let start = lo + local_start
    let end = lo + local_end
    if start <= lo or end >= n or end - start + 1 < 2 * period: return
    if start <= last_head + 1 and end + 1 >= last_head: return
    let index = (start * KBR_N + end) * KBR_PERIODS + period
    seen[index // 64] = seen[index // 64] | (1 << (index % 64))

fn kbr_at_center(mut text: InlineArray[Int, KBR_N], size: Int, budget: Int,
                 center: Int, lo: Int, last_head: Int,
                 mut seen: InlineArray[Int, KBR_BITS]):
    let hi = lo + size
    if center <= lo or center + 1 >= hi: return
    for period in range(1, center - lo + 1):
        for k in range(budget + 1):
            let forward = kbr_lp(mut text, lo, hi, center, period, k)
            let backward = kbr_ls(mut text, lo, center, period, budget - k)
            if forward <= period and forward + backward >= period:
                kbr_mark(mut seen, KBR_N, lo, last_head,
                         center - period - backward - lo,
                         center + forward - 1 - lo, period)

    var reversed = InlineArray[Int, KBR_N](fill=0)
    for i in range(size): reversed[i] = text[hi - 1 - i]
    let rc = size - 1 - (center - lo)
    for period in range(1, rc + 1):
        for k in range(budget + 1):
            let forward = kbr_lp(mut reversed, 0, size, rc, period, k)
            let backward = kbr_ls(mut reversed, 0, rc, period, budget - k)
            if forward <= period and forward + backward >= period:
                let reverse_start = rc - period - backward
                let reverse_end = rc + forward - 1
                kbr_mark(mut seen, KBR_N, lo, last_head,
                         size - 1 - reverse_end, size - 1 - reverse_start, period)

fn kbr_divide(mut text: InlineArray[Int, KBR_N], mut starts: InlineArray[Int, KBR_FACTORS],
              mut ends: InlineArray[Int, KBR_FACTORS], budget: Int,
              mut seen: InlineArray[Int, KBR_BITS], first: Int, last: Int):
    if first >= last: return
    let middle = first + (last - first) // 2
    let lo = starts[first]
    let hi = ends[last]
    let center = ends[middle] - 1
    let last_head = ends[last] - 1
    kbr_at_center(mut text, hi - lo, budget, center, lo, last_head, mut seen)
    kbr_divide(mut text, mut starts, mut ends, budget, mut seen, first, middle)
    kbr_divide(mut text, mut starts, mut ends, budget, mut seen, middle + 1, last)

@export("k_repetition_binary_division_kernel")
fn k_repetition_binary_division_kernel(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > KBR_INPUT: return -1
    let nv = input[0]
    let kv = input[1]
    if nv < 1 or nv > KBR_N or kv < 0 or kv > KBR_K: return -1
    let n = Int(nv)
    let budget = Int(kv)
    if length != c_size_t(n + 2): return -1
    var text = InlineArray[Int, KBR_N](fill=0)
    var starts = InlineArray[Int, KBR_FACTORS](fill=0)
    var ends = InlineArray[Int, KBR_FACTORS](fill=0)
    var seen = InlineArray[Int, KBR_BITS](fill=0)
    for i in range(n):
        if input[i + 2] < 0 or input[i + 2] > 4: return -1
        text[i] = Int(input[i + 2])
    for i in range(n - 1):
        if text[i] == text[n - 1]: return -1

    var factor_count = 0
    var pos = 0
    while pos < n:
        var best = 0
        for earlier in range(pos):
            var matched = 0
            while pos + matched < n and earlier + matched < n and text[earlier + matched] == text[pos + matched]:
                matched += 1
            best = max(best, matched)
        let end = min(n, pos + best + 1)
        starts[factor_count] = pos
        ends[factor_count] = end
        factor_count += 1
        pos = end
    let block = budget + 2
    var first = 0
    while first < factor_count:
        kbr_divide(mut text, mut starts, mut ends, budget, mut seen,
                   first, min(factor_count, first + block) - 1)
        first += block

    var records = 0
    for start in range(n):
        for len in range(2, n - start + 1):
            let end = start + len - 1
            for period in range(1, len // 2 + 1):
                let index = (start * KBR_N + end) * KBR_PERIODS + period
                if (seen[index // 64] & (1 << (index % 64))) != 0: records += 1
    let written = 8 + records * 32
    if written > KBR_OUTPUT: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(written): return -2

    var offset = 0
    for byte in range(8): output[offset + byte] = UInt8((records >> (byte * 8)) & 255)
    offset += 8
    for start in range(n):
        for len in range(2, n - start + 1):
            let end = start + len - 1
            for period in range(1, len // 2 + 1):
                let index = (start * KBR_N + end) * KBR_PERIODS + period
                if (seen[index // 64] & (1 << (index % 64))) == 0: continue
                var mismatches = 0
                for i in range(start, end - period + 1):
                    if text[i] != text[i + period]: mismatches += 1
                for value in [start, len, period, mismatches]:
                    for byte in range(8): output[offset + byte] = UInt8((value >> (byte * 8)) & 255)
                    offset += 8
    written
