# Package inventory

The package provides a clean-room decimal-prefix successor algorithm, two
independently structured references, bounded scalar workload, rights and
provenance notes, and ten language source ports. `check_inventory.py` reviews
the package artifact list and all ten expected source paths without building
or executing them.

The input is one signed-i64 value. The valid bound is
`0 <= n <= 9,999,999,999,999,999`; the largest result is
`10,000,000,000,000,001`. The scalar ABI returns `-1` for malformed frames or
values outside the bound.

Duplicate review: [`palindrome_number`](../p/palindrome_number/README.md) and
[`valid_palindrome`](../v/valid_palindrome/README.md) recognize palindromes but
do not find a numeric successor. [`shortest_palindrome`](../s/shortest_palindrome/README.md)
and [`palindrome_partitioning`](../p/palindrome_partitioning/README.md)
transform strings, so their contracts are distinct.
