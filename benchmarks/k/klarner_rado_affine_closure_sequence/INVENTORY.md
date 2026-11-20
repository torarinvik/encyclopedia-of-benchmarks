# Package inventory

| Artifact | Role |
|---|---|
| `primary_oracle.py` | Three-stream merge reference. |
| `independent_oracle.py` | Min-heap closure reference. |
| `verify_workload.py` | Metadata and two-reference agreement review. |
| `check_inventory.py` | Static required-file and ten-port inventory. |
| `workload.json` | Bounded valid, boundary, and malformed scalar fixtures. |
| `README.md` / `RIGHTS.md` | Contract, provenance, and rights notes. |
| `INVENTORY.json` | Machine-readable source, artifact, and bound inventory. |

All ten language paths implement `klarner_rado_affine_closure_sequence` in
the `k/` source folder for that language. Each native port stores at most 64
signed 64-bit terms; the 1,024-byte workspace ceiling also allows for scalar
state and alignment. The maximum generated term is 120; the largest candidate
transform needed to reach it is 699.
