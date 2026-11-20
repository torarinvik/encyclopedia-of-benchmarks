# Perfect totient number

## Contract

The exported `perfect_totient_number` scalar function accepts one signed
64-bit integer `n` in the conventional perfect-totient domain `3..65535`.
It returns `1` when

`phi(n) + phi(phi(n)) + ... + 1 = n`,

and `0` otherwise. Each term in the strictly decreasing totient chain is
included through its terminal value `1` exactly once. Values below 3 or above
65535 return `-1`. Thus 1 and 2 are outside this package's domain, not
non-members under an extended definition. ABI: `scalar_call`, symbol
`perfect_totient_number(i64) -> i64`.

## Algorithm and local overlap review

The primary ports repeatedly compute Euler's totient by factorizing the
current chain value and applying `phi(m) = m * product(1 - 1/p)` over its
distinct prime factors. They accumulate each new value until the chain reaches
1, then compare the sum with the original input.

The local `euler_totient` computes only one `phi(n)`; `euler_totient_sequence`
and `totients_linear_sieve` enumerate a range/table of individual totients.
`sum_of_totient_function` sums `phi(k)` over consecutive inputs. None decides
whether the iterated totient chain of one integer sums to that integer, so this
is a distinct scalar predicate. The ordinary `perfect_number` predicate sums
proper divisors and uses a different mathematical definition.

The independent oracle uses the definition `phi(m) = count(1 <= k <= m,
gcd(k,m)=1)` at each chain step. It has a different totient computation from
the factorization-based primary oracle and ports.

## Sources and workload

The mathematical definition follows Douglas E. Iannucci, Deng Moujie, and
Graeme L. Cohen, [“On Perfect Totient Numbers”](https://cs.uwaterloo.ca/journals/JIS/VOL6/Cohen2/cohen50.pdf),
*Journal of Integer Sequences* 6 (2003), article 03.4.5. [OEIS
A082897](https://oeis.org/A082897) is an independent sequence cross-reference.
The [RosettaGit task-title index](https://rosettagit.org/tasks/) identified the
candidate; it was used for discovery only. No task content or submission was
consulted.

[`workload.json`](workload.json) includes small and larger perfect/non-perfect
values, the terminal-one chain behavior, both excluded lower values, the
maximum supported input, and signed invalid boundaries. `primary_oracle.py`
and `independent_oracle.py` define separate reference methods; the static
fixture comparator is in `verify_workload.py`.

## Language ports

| Language | Source |
|---|---|
| C | `c/p/perfect_totient_number.c` |
| C3 | `c3/p/perfect_totient_number.c3` |
| C++ | `cpp/p/perfect_totient_number.cpp` |
| Elisa | `elisa/p/perfect_totient_number.elisa` |
| Mojo | `mojo/p/perfect_totient_number.mojo` |
| Nim | `nim/p/perfect_totient_number.nim` |
| Odin | `odin/p/perfect_totient_number.odin` |
| Rust | `rust/p/perfect_totient_number.rs` |
| V | `v/p/perfect_totient_number.v` |
| Zig | `zig/p/perfect_totient_number.zig` |
