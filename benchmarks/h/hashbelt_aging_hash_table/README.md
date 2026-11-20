# Hashbelt aging hash table

This benchmark replays bounded updates, lookups, and generation-aging steps
over a hashbelt: a short rotating array of hash tables. An aging step creates
a new empty newest generation and drops the oldest generation with all its
entries. Lookups search newest to oldest. The profile also pins the hashbelt
LRU use described by NIST DADS: a hit in an older table is moved into the
newest table and removed from its older table. Each key therefore has at most
one live entry across the belt.

## Contract

The signed-i64 input is `[operation_count,(opcode,key,argument)*]`, with at
most 64 operations. The structure has four generations, each with eight
separate-chaining buckets and room for 32 distinct keys. Keys are `0..31`;
values are `-1000..1000`. The deterministic bucket function is `key mod 8`.

- Opcode `0` puts `(key,argument)` into the newest generation. It updates a
  matching entry already there or adds a new one. If the key exists only in
  an older generation, the put removes that entry and inserts the new value
  into the newest generation. The operation emits `1` if the key was absent
  from all generations before the put, otherwise `0`.
- Opcode `1` looks up `key`; `argument` must be zero. The first match from
  newest to oldest supplies the returned value. A match in an older table is
  moved to the newest table by removing its old chain
  entry and inserting the same value at the head. A miss emits
  `-2147483648`, which is outside the allowed value range.
- Opcode `2` advances the belt; both `key` and `argument` must be zero. The
  oldest table is cleared and becomes the new newest table. The operation
  emits the number of live entries dropped from that table.

Every operation emits one signed-i64 value in little-endian order. The result
is the output byte count, up to 512 bytes. The maximum valid input length is
193 words; a 194-word parse bound permits rejecting a one-word trailing frame.
Malformed input returns `-1`. After validating the complete frame, a null or
short output buffer returns `-2` without writes. A valid empty trace returns
zero bytes. The fixed workspace bound is 4,096 bytes.

## References

NIST DADS defines hashbelt aging as rotating a short list or array of hash
tables, dropping the oldest table and searching the tables for lookup. Its
note describes moving a used item to the newest table for an LRU cache.
William Grosso's “The Hashbelt Data Structure” (O'Reilly ONJava, January 2002)
is the cited design article. The bounded deterministic behavior above makes
the generation count, chaining function, key/value domain, operation framing,
and status output explicit. Promotion removes the old entry before adding it
to the newest table, so an accessed key cannot reappear after its promoted
copy later expires.

The [primary reference](primary_oracle.py) uses fixed bucket-chain arrays and
a circular generation index. The [independent reference](independent_oracle.py)
stores four ordinary key/value maps in newest-first order and uses a direct
generation scan. The references share framing rules but use separate state
representations and lookup/update paths.

## Package files

- Workload: [`workload.json`](workload.json)
- Primary oracle: [`primary_oracle.py`](primary_oracle.py)
- Independent oracle: [`independent_oracle.py`](independent_oracle.py)
- Workload/reference verifier: [`verify_workload.py`](verify_workload.py)
- Static inventory checker: [`check_inventory.py`](check_inventory.py)
- Rights and provenance: [`RIGHTS.md`](RIGHTS.md)

## Language ports

| Language | Source |
|---|---|
| C | [`c/h/hashbelt_aging_hash_table.c`](../../../c/h/hashbelt_aging_hash_table.c) |
| C3 | [`c3/h/hashbelt_aging_hash_table.c3`](../../../c3/h/hashbelt_aging_hash_table.c3) |
| C++ | [`cpp/h/hashbelt_aging_hash_table.cpp`](../../../cpp/h/hashbelt_aging_hash_table.cpp) |
| Elisa | [`elisa/h/hashbelt_aging_hash_table.elisa`](../../../elisa/h/hashbelt_aging_hash_table.elisa) |
| Mojo | [`mojo/h/hashbelt_aging_hash_table.mojo`](../../../mojo/h/hashbelt_aging_hash_table.mojo) |
| Nim | [`nim/h/hashbelt_aging_hash_table.nim`](../../../nim/h/hashbelt_aging_hash_table.nim) |
| Odin | [`odin/h/hashbelt_aging_hash_table.odin`](../../../odin/h/hashbelt_aging_hash_table.odin) |
| Rust | [`rust/h/hashbelt_aging_hash_table.rs`](../../../rust/h/hashbelt_aging_hash_table.rs) |
| V | [`v/h/hashbelt_aging_hash_table.v`](../../../v/h/hashbelt_aging_hash_table.v) |
| Zig | [`zig/h/hashbelt_aging_hash_table.zig`](../../../zig/h/hashbelt_aging_hash_table.zig) |

The package is registered in the `i64_array_bytes_output` suite and catalog.
No code, protected task text, or fixtures are reused. No
programs, tests, scripts, checkers, builds, compilers, profilers, or benchmarks
were run.
