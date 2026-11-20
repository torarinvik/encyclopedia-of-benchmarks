# Zobrist position hash trace

This benchmark measures the incremental XOR update used by Zobrist position
hashing. A fixed 4×4 position has sixteen slots and three nonempty feature
kinds per slot. The caller supplies a 63-bit key for every `(slot, feature)`;
the benchmark does not generate random keys or claim a collision rate.

## Call contract

- ABI: `i64_array_bytes_output`; exported function symbol:
  `zobrist_position_hash_trace(input, length, output, capacity)`.
- Input frame: `[operation_count, keys[48], initial_slots[16], (slot,new_feature)*]`.
- `operation_count` is 0 through 64. Keys are signed-i64 words in
  `0..=2^63-1` and are used as 63-bit XOR values; duplicate keys are allowed.
  Each initial slot and `new_feature` is 0 through 3, with 0 meaning empty.
  Each operation slot is 0 through 15.
- The exact valid input length is `65 + 2*operation_count` words. At most 193
  words are valid; 194 is the largest parseable frame and permits rejecting a
  one-word overlong call without reading beyond it.
- Validation order: reject null input; reject lengths outside 65..194; validate
  the operation count and exact frame length; validate key signs, initial
  features, then each operation; finally check the output pointer and capacity.
  Invalid input returns `-1`; a null output or insufficient capacity returns
  `-2`. No output bytes are written on either error.
- The initial hash is the XOR of the keys for occupied slots. Emit it first as
  eight little-endian bytes. For each edit, XOR out the old feature key if
  occupied, XOR in the new feature key if occupied, update the slot, and emit
  the resulting hash as eight little-endian bytes. Success returns the number
  of bytes written, `8*(operation_count+1)`.
- The output maximum is 520 bytes. The bounded workspace is 128 bytes: sixteen
  one-byte slot states, the current hash, and scalar loop/index temporaries.
  The caller's key table and output buffer are excluded from workspace.

## References and workload

[`primary_oracle.py`](primary_oracle.py) models the reversible incremental
updates. [`independent_oracle.py`](independent_oracle.py) changes the board
then recomputes each full-position XOR from all sixteen slots, so it does not
reuse the incremental hash transition. [`workload.json`](workload.json) pins
the bounded frame, feature table, expected bytes, malformed-input behavior,
and a one-byte-short output-capacity case.

The feature keys in the workload are powers of two, `key(slot,feature) =
2^(3*slot+feature-1)`. This is a convenient deterministic fixture table; the
algorithm contract accepts any nonnegative signed-i64 keys.

## Provenance and duplicate rationale

The method follows Albert L. Zobrist, “A New Hashing Method with Application
for Game Playing,” University of Wisconsin Computer Sciences Department
Technical Report #88 (April 1970), [report PDF](https://research.cs.wisc.edu/techreports/1970/TR88.pdf).
The [NIST DADS tabulation-hashing entry](https://xlinux.nist.gov/dads/HTML/tabulationHashing.html)
defines feature-table values combined with XOR and cross-references Zobrist.
The local [`pearson_hash`](../../p/pearson_hash/README.md) instead feeds each
byte through `T[h XOR byte]`; CRC and polynomial rolling hashes also use
different recurrences. Hash-map benchmarks measure table storage and
collision resolution rather than a position-hash update. This package pins
the incremental position profile and does not add a second generic tabulation
hash package.

No external code, task text, examples, or fixtures are reused. See
[`RIGHTS.md`](RIGHTS.md) for provenance and reuse boundaries and
[`INVENTORY.md`](INVENTORY.md) for the ten source ports. The package is
registered with the `i64_array_bytes_output` runner and verifier. No
executable checks have been run.
