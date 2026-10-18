# Memoized function calls

This benchmark exercises the pinned JavaScript `memoize` wrapper around one deterministic callback. Each adapter invocation creates a fresh wrapper with its default `Map` cache. The benchmark supplies bounded positional integer arguments, so JSON serialization produces an unambiguous array key; nested objects, `Set`, `Map`, `undefined`, cyclic values, and caller-provided cache implementations are outside this contract.

## Contract

Input is `[arity, call_count, arguments...]`. Arity is 0 through 4, call count is 0 through 64, and the remaining signed-i64 words are exactly `arity * call_count` integer arguments in `[-100,100]`, grouped into fixed-arity calls. The maximum valid input contains 258 words; the maximum parseable input is 259 words, for an extra-word framing probe.

For each call, the callback encodes its argument tuple in base 201: starting from zero, for each argument `a` in positional order set `result = result * 201 + (a + 100)`. This is injective for a fixed arity in the declared argument domain. The memoized wrapper keys each call by the JSON serialization of its argument array, returns a cached result on a hit, and evaluates the callback only on a miss. A fresh cache is used for each adapter invocation.

Output is a little-endian signed-i64 word sequence containing one callback result for each input call, followed by the number of callback evaluations (cache misses). The output is at least one word even for zero calls, and its byte length is `8 * (call_count + 1)`, at most 520 bytes. A valid call returns that byte length.

Malformed framing, out-of-domain values, or a null input returns `-1`. A null output pointer or capacity below the required byte length returns `-2` after input validation. Error returns write no output bytes.

The independent oracle is [`../memoize_oracle.py`](../memoize_oracle.py). The workload includes repeated keys, order-swapped tuples, zero-arity calls, argument bounds, maximum call count, malformed framing, and output-capacity edges.

## Pinned source

- JavaScript [`Memoize.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Cache/Memoize.js) keys the spread argument array with `JSON.stringify(args, jsonReplacer)`, checks `cache.has`, returns `cache.get` on a hit, and calls and stores the result on a miss. The source replacer also converts `Set` and `Map` values; those input types are excluded here.

## Language ports

| Language | Port |
|---|---|
| C | [`c/memoize.c`](../../c/memoize.c) |
| C3 | [`c3/memoize.c3`](../../c3/memoize.c3) |
| C++ | [`cpp/memoize.cpp`](../../cpp/memoize.cpp) |
| Elisa | [`elisa/memoize.elisa`](../../elisa/memoize.elisa) |
| Nim | [`nim/memoize.nim`](../../nim/memoize.nim) |
| Odin | [`odin/memoize.odin`](../../odin/memoize.odin) |
| Rust | [`rust/memoize.rs`](../../rust/memoize.rs) |
| V | [`v/memoize.v`](../../v/memoize.v) |
| Zig | [`zig/memoize.zig`](../../zig/memoize.zig) |
