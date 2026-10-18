# Traveling salesman brute force

This benchmark maps to the pinned Java `TravelingSalesman.bruteForce` method. It enumerates every ordering of cities `1..n-1`, fixes city 0 as the first stop, adds the return edge to city 0, and returns the least tour cost. This is a separate algorithm from the Held–Karp `traveling_salesman_bitmask` benchmark.

## Contract

Input is `[n, d00, d01, ..., d(n-1)(n-1)]`, with the directed matrix flattened in row-major order. The bounded domain accepts 0–8 cities and requires exactly `1 + n*n` signed 64-bit integers. Matrix entries must fit a Java signed 32-bit integer. For `n = 0` or `n = 1`, the result is `0`, matching the source's early return before it inspects the matrix. For `n >= 2`, each off-diagonal cost is either an integer in `[0, 1000]` or `2147483647` (`Integer.MAX_VALUE`), which marks a missing edge. Diagonal entries are accepted as any signed 32-bit integer because the source's route calculation never reads them.

The method checks each permutation in the order produced by the source's recursive swap routine. A route that contains a missing edge is treated as invalid. The result is the minimum cost among valid closed tours; if every route has a missing edge, the source returns `2147483647`. The input bounds keep all finite tour costs at most 8,000, avoiding Java `int` overflow while retaining the source's sentinel behavior. The 8-city limit bounds brute-force work to at most 7! = 5,040 tours.

Input framing and matrix values outside this contract return `-1`. Maximum valid input length is 65 and the parser accepts up to 66 elements so it can reject a trailing value after a maximum-size matrix. The scalar result is a signed 64-bit integer.

Pinned source: [Java `TravelingSalesman.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/graph/TravelingSalesman.java), method `bruteForce`.

See [workload](workload.json) and [oracle](../../traveling_salesman_oracle.py).
