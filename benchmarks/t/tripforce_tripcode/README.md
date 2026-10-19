# tripforce tripcode kernel

This benchmark computes one bounded Futaba-style tripcode for an explicitly supplied eight-byte candidate. It preserves tripforce's fixed candidate alphabet, salt derivation and normalization, traditional DES key treatment, and the 10-byte extraction from `DES_fcrypt`.

The upstream source is [nfinit/ansibench at `ef90abd09d7b7bb1f2809f896d6f67fb9724bebe`](https://github.com/nfinit/ansibench/tree/ef90abd09d7b7bb1f2809f896d6f67fb9724bebe/tripforce), especially `tripforce/src/tripforce.c` and `tripforce/LICENSE`. The original program and this benchmark package are attributed to microsounds and licensed under GPL-3.0; see [LICENSE](LICENSE). The ports are independently written and do not copy tripforce or OpenSSL source. This is a fixed-candidate kernel, not a password search or tripforce throughput result.

## ABI

`tripforce_tripcode(const int64_t *values, size_t length, uint8_t *output, size_t output_capacity)` takes exactly eight integer values, each an ASCII byte from tripforce's 92-character candidate alphabet. It returns ten raw ASCII bytes on success. It returns `-1` for null input, wrong length, or an out-of-alphabet byte; it returns `-2` for null output or capacity below ten. Errors leave output untouched.

The salt starts as `[password[1], password[2], 'H', '.']`. Each byte below `'.'` or above `'z'` becomes `'.'`; bytes in `':'..'@'` and `'['..'\x60'` are then increased by six. DES uses the first two normalized salt bytes. The eight password bytes are shifted left once to form the DES key bytes, DES parity bits are ignored by PC-1, and the all-zero block is encrypted 25 times with the salt-selected expansion swaps. The tripcode is `DES_fcrypt` output bytes 3 through 12 (zero-based), excluding its two-character salt prefix and first encoded character.

## Sources and license

The algorithm attribution and GPL-3.0 terms come from the pinned tripforce source. The standard DES permutation and S-box constants are standard DES parameters. No upstream source files are included.
