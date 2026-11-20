# Pearson byte-string hash

This package measures Peter K. Pearson's table-based 8-bit hash for variable-
length byte strings. The function receives a permutation table as part of each
bounded call frame, so the benchmark does not copy the table printed in the
article or include table construction in the hash operation.

## Contract

- ABI: `i64_array_scalar`; frame `[n, T[256], text[n]]`.
- `n` is in `0..=64`. The exact valid frame length is `257+n`, with a maximum
  of 321 i64 words. The parser accepts at most 322 words so an extra-word frame
  can be rejected safely.
- The declared workspace is at most 1,024 bytes, including the 256-byte table,
  256 one-byte permutation markers, and scalar temporaries.
- Every table entry is a byte, and the 256 entries must be a permutation of
  `0..=255`. Every text element is a byte in `0..=255`.
- Validation order is: pointer and total frame bound; declared text length;
  exact frame length; table byte range and permutation; text byte range. Any
  invalid frame returns `-1`.
- For a valid frame, initialize `h=0`, then for each text byte `c` set
  `h = T[h XOR c]`. Return the final byte as an integer. Empty text returns 0.
- The workload uses the explicitly defined permutation
  `T[x] = ((x & 15) << 4) | (x >> 4)`, which swaps the two nibbles of each
  byte. This is a test permutation, not part of the algorithm's general
  contract. Workload cases store text and deliberate frame mutations compactly;
  the scalar suite adapter materializes the stated ABI frame.

## Provenance

The algorithm is attributed to Peter K. Pearson, “Fast Hashing of Variable-
Length Text Strings,” *Communications of the ACM* 33(6), 677–680 (June 1990),
[DOI 10.1145/78973.78978](https://doi.org/10.1145/78973.78978). The [NIST DADS
entry](https://xlinux.nist.gov/dads/HTML/pearsonshash.html) supplies the title
lead and links the original article. Its short definition says the algorithm
uses no XOR, which conflicts with the primary paper's explicit XOR lookup
recurrence. This profile follows Pearson's original paper. The ports and
references are clean-room descriptions of that update rule; no sample table,
code, or article prose is reused.

This update rule is distinct from local XOR/sum, DJB2, SDBM, ELF, CRC, and
rolling hashes. It is also distinct from the repository's hash-table
benchmarks, which measure storage and collision-resolution behavior.

## Package files

- [`workload.json`](workload.json) defines the bounded frames and fixtures.
- [`primary_oracle.py`](primary_oracle.py) applies the state recurrence.
- [`independent_oracle.py`](independent_oracle.py) composes all 256 possible
  state transitions for each byte and returns the composed map's image at 0.
- [`verify_workload.py`](verify_workload.py) is the package-local fixture
  materializer and oracle comparison entry point; it has not been run.
- [`RIGHTS.md`](RIGHTS.md) records provenance and reuse boundaries.
- [`INVENTORY.md`](INVENTORY.md) lists the ten source ports.

The ten language ports are intended for the `i64_array_scalar` suite. Shared
catalog and runner integration is coordinated separately.
