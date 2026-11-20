# Cupif–Giannini perfect-tree traversal

This benchmark follows the count-XOR-key traversal described by the [NIST
Dictionary of Algorithms and Data Structures
entry](https://xlinux.nist.gov/dads/HTML/CupifGianniniTreeTraversal.html).
For a perfect binary tree of height `h`, it visits one root-to-leaf path for
each count in ascending order. The low-order bit of `count XOR key` selects
the root branch, the next bit selects the next branch, and so on. Zero selects
left and one selects right. The key is an input so every workload call is
deterministic.

## Bounded ABI

Use `i64_array_bytes_output`, symbol `cupif_giannini_tree_traversal`, with the
two-word input `[height,key]`. Heights range from 0 through 6. The key must be
in `[0,2^height)`, which means height zero accepts key zero only. The exact
valid frame is two signed 64-bit words; malformed frames return `-1`.

For each count `0..2^height-1`, the implementation follows the selected path
and emits its root-to-leaf branch code as one byte. Branches are packed with
the root decision in bit 0, so the emitted byte is `count XOR key`. The result
is exactly `2^height` bytes, at most 64. A null output pointer or insufficient
capacity returns `-2` without writing. Input validation precedes output
pointer/capacity validation. The language ports use constant local state; the
caller-owned output buffer is not part of the 128-byte workspace allowance.

The traversal takes `O(height * 2^height)` time and `O(1)` auxiliary space.
The profile pins the count-XOR pseudocode and its bit order. NIST describes
the method's intended dispersion, but this package does not assert or measure
an optimal-dispersion bound.

This operation differs from the local
[`xor_leaf_tree_traversal`](../../x/xor_leaf_tree_traversal/README.md): that
benchmark peels leaves from an input tree and reports parent edges plus a
removal order, while this one visits every path of an implicit perfect tree
in a key-shifted counter order.

## References and rights

NIST DADS attributes the traversal to François, Lahmadi, Giannini, Cupif, Beck,
and Wallrich, “Optimizing Internet Scanning for Assessing Industrial Systems
Exposure,” IWCMC 2016, pp. 516–522,
[DOI 10.1109/IWCMC.2016.7577111](https://doi.org/10.1109/IWCMC.2016.7577111).
The DADS entry supplies the count-XOR pseudocode and tree-path bit order. The
ports and references use a newly written bounded contract and do not copy
published code, pseudocode, fixtures, comments, or prose. See
[`RIGHTS.md`](RIGHTS.md) for the reuse boundary.

## Package artifacts

- [`workload.json`](workload.json) records the bounded frames, result bytes,
  maximum-height fixture, error behavior, and measurement settings.
- [`primary_oracle.py`](primary_oracle.py) simulates each count's path directly.
- [`independent_oracle.py`](independent_oracle.py) scans path codes and
  scatters them into visit-rank order; it does not call the primary reference.
- [`INVENTORY.md`](INVENTORY.md) lists all ten source drafts.

The ten source drafts are registered with the `i64_array_bytes_output`
runner and verifier, and the package appears in the repository catalog. No
program, test, build, or checker has been run for this package.
