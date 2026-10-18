# RSA factor recovery from explicit bases

This benchmark follows the pinned Python `rsafactor(d, e, n)` routine with a supplied sequence of its random base choices. It recovers a proper factor from the public and private exponents; it does not perform trial division or generate RSA keys.

## Contract

Input is a signed 64-bit integer array:

`[d,e,n,attempt_count,base_0,...,base_(attempt_count-1)]`

`d` and `e` are in `[1,1,000,000]`; `n` is an odd integer in `[3,65,535]`; and `k = d*e - 1` must be positive and even. There are 1 through 16 attempts. Each supplied base must be in the same inclusive range as Python's `random.randint(2, n-1)`, namely `[2,n-1]`. The exact length is `4 + attempt_count`; maximum valid length is 20 and maximum parseable length is 21.

For each base, start with `t=k`. While `t` is even, first set `t=t//2`, then calculate `x = base^t mod n`, and then `y = gcd(x-1,n)`. Return as soon as `x>1` and `y>1`, with factors sorted as `[y,n//y]`. If `t` is odd, abandon that base and consume the next one. Exhausting the supplied bases without finding a factor returns `-1`; the source's unbounded random retry loop is thereby bounded by `attempt_count`.

The modular exponentiation computes the same exact residue as Python's arbitrary-precision `base**t % n`, without constructing the full power. Input bounds keep every modular product and `d*e-1` inside signed 64-bit range. A factor pair is packed into one scalar as `p*65,536 + q`, where `p<=q`; decode with `p=result/65,536` and `q=result%65,536`. Since `n<=65,535`, each factor fits in 16 bits. Valid outputs range from 0 through 4,294,967,295. Malformed input, an invalid base, a nonpositive or odd `k`, a null pointer, or exhausted attempts returns `-1`.

The oracle is [`../../rsa_factorization_oracle.py`](../../rsa_factorization_oracle.py), and [`workload.json`](workload.json) lists successful, retrying, and malformed streams.

## Implementations

| Language | Path |
| --- | --- |
| C | [`c/r/rsa_factorization.c`](../../../c/r/rsa_factorization.c) |
| C3 | [`c3/r/rsa_factorization.c3`](../../../c3/r/rsa_factorization.c3) |
| C++ | [`cpp/r/rsa_factorization.cpp`](../../../cpp/r/rsa_factorization.cpp) |
| Elisa | [`elisa/r/rsa_factorization.elisa`](../../../elisa/r/rsa_factorization.elisa) |
| Nim | [`nim/r/rsa_factorization.nim`](../../../nim/r/rsa_factorization.nim) |
| Odin | [`odin/r/rsa_factorization.odin`](../../../odin/r/rsa_factorization.odin) |
| Rust | [`rust/r/rsa_factorization.rs`](../../../rust/r/rsa_factorization.rs) |
| V | [`v/r/rsa_factorization.v`](../../../v/r/rsa_factorization.v) |
| Zig | [`zig/r/rsa_factorization.zig`](../../../zig/r/rsa_factorization.zig) |

## Pinned source

- Python [`rsa_factorization.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/rsa_factorization.py), function `rsafactor`.
