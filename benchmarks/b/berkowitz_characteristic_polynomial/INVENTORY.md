# Static package inventory

`INVENTORY.json` pins ten clean-room language ports of
`berkowitz_characteristic_polynomial` under the `i64_array_bytes_output` ABI.
The bounded input has at most 51 signed 64-bit words, dimensions at most 7,
modulus at most 1,000,000,000, output at most 64 bytes, and a 4,096-byte
workspace cap.

The package includes 14 pinned fixtures, a division-free Toeplitz-recursion
reference, an independent permutation-expansion reference, source provenance
and rights notes, a workload verifier, and a static inventory checker. These
validation artifacts have not been run.
