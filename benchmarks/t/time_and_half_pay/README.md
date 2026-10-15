# Time and a half pay

## Contract

Compute regular pay plus the overtime premium. The three binary64 inputs are
`[hours_worked, pay_rate, threshold_hours]`; each must be finite and in
`[0, 1,000]`. The result is binary64. Inputs outside this benchmark domain map
to `-1e300`.

Ports preserve the pinned Python operation order:

```text
normal_pay = hours_worked * pay_rate
over_time = max(0, hours_worked - threshold_hours)
over_time_pay = over_time * pay_rate / 2
return normal_pay + over_time_pay
```

The threshold is passed explicitly to preserve the source's optional `hours`
parameter; the source default is 40 hours. Values at or below the threshold
receive regular pay only. This function adds a half-rate premium for hours over
the threshold, rather than replacing the overtime rate with 1.5 times pay.

## Source and workload

The contract follows TheAlgorithms Python
[`time_and_half_pay.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/financial/time_and_half_pay.py)
at commit `e1a2a8b016001309a73d5fec4818c35cca139795`. The workload includes
below-threshold, exactly-at-threshold, overtime, zero, fractional, and domain
edge cases. Results use absolute and relative tolerance `1e-12`.

The nine ports use the shared `float64_triple` ABI with parameters
`(hours_worked, pay_rate, threshold_hours)`.
