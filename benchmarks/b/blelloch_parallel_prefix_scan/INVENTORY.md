# Static package inventory

The `blelloch_parallel_prefix_scan` package exposes the `i64_array_bytes_output`
ABI through ten language source paths pinned in `INVENTORY.json`. It computes
exclusive prefixes with a padded power-of-two tree and complete upsweep and
downsweep levels. The bounded input has at most 64 elements, the largest tree
payload is 512 bytes, and output is at most 512 bytes.

The package includes the CMU primary-source citation, rights note, 12 pinned
fixtures, a tree-stage primary reference, a direct running-sum reference, and
package-local workload/inventory checkers. They have not been run; no source
was compiled or executed.
