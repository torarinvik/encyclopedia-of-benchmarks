# Best time to buy and sell stock

Given one price per day, compute the greatest profit from one purchase followed by one sale on a later day. Return zero when every possible transaction loses or breaks even.

## Contract

- Input is a signed 64-bit array of zero through 4,096 prices.
- Prices must be from 0 through 1,000,000,000.
- Return the maximum `price_sell - price_buy` for indices with `buy < sell`, or zero when no positive profit exists.
- Empty input returns zero. Oversized arrays and out-of-range prices return `-1`.
- The portable implementations track the lowest price seen and the best gain. The C LeetCode source uses Kadane's recurrence on adjacent price differences, which computes the same contract.

## Workload and verification

[`workload.json`](workload.json) covers rising and falling prices, repeated minima, zero and boundary prices, invalid entries, and empty input. [`verify_best_time_to_buy_and_sell_stock.py`](../../verify_best_time_to_buy_and_sell_stock.py) checks against a direct minimum-price oracle, exhausts short arrays, and adds deterministic random and maximum-length inputs across all nine languages.

```sh
python3 benchmarks/verify_best_time_to_buy_and_sell_stock.py --elisa-compiler /absolute/path/to/elisac
```

Build and record with the `i64_array_scalar` ABI family. Sources are under `b/` in `c/`, `c3/`, `cpp/`, `elisa/`, `nim/`, `odin/`, `rust/`, `v/`, and `zig/`.

## Reviewed TheAlgorithms sources

- [C LeetCode `121.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/121.c) uses Kadane's algorithm on daily price differences.
- [Python `best_time_to_buy_and_sell_stock.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/greedy_methods/best_time_to_buy_and_sell_stock.py) tracks the minimum price and best later sale.
- [Java `StockProfitCalculator.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/greedyalgorithms/StockProfitCalculator.java) implements the same single-transaction running-minimum method.
