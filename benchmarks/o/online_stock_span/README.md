# Online Stock Span

For each day in a price stream, return the number of consecutive days ending today whose prices were no greater than today's price. The scan keeps a monotone stack of prior day indexes and removes every price less than or equal to the current price.

## Contract

- Input is `[count, price0, ..., price(count-1)]`.
- `count` is in `1..4095`; each price is in `1..100000`. The upstream problem permits up to 10,000 calls; this packed benchmark caps the stream at 4,095 prices so the count header and values fit the shared runner's 4,096-value input limit.
- Return `count` spans as little-endian signed 64-bit values and return the element count. Invalid packed inputs return `-1`; insufficient output capacity returns `-2`. Input is read only.
- Equal prices are popped from the monotone stack (`previous_price <= current_price`), so their spans combine. Time is O(n) amortized; auxiliary space is O(n).

## Workload

[`workload.json`](workload.json) covers the published stream, increasing and decreasing prices, equal-price ties, multi-pop behavior, price bounds, invalid input, and a maximum-length stream.

## Upstream source

- [TheAlgorithms/C LeetCode 901 at the pinned revision](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/901.c)
- [LeetCode 901 statement and constraints](https://leetcode.com/problems/online-stock-span/description/)
