# Package inventory

`sierpinski_curve_trace` implements one closed, four-state recursive curve.
The title audit pins score 28 of the RosettaCodeData popular-title index at
commit `1d475861d7141ef2fafff293d9339f56e4b0f5db`; Wirth §3.3 supplies the
specific recursion.

- ABI: `i64_array_bytes_output`; exact input `[order]`, 0 through 2.
- Output: raw direction/length bytes, 4 through 64 bytes.
- Workspace: 256 bytes; 64 fixed two-byte expansion frames plus scalar state.
- Primary reference: recursive A/B/C/D move emission.
- Independent reference: level-tagged grammar rewriting.
- Workload: 11 pinned fixtures, including order-zero base, max order/output,
  capacity, malformed frame, null input/output, and validation precedence.
- Rights and title-band dispositions: `RIGHTS.md`, `TITLE_AUDIT.md`.
- Static metadata: `INVENTORY.json`; static-only helpers are
  `check_inventory.py` and `verify_workload.py`.
- Native source paths: all ten are listed in `INVENTORY.json`.
- Shared runner, catalog, and coverage integration: pending root ownership.

No native code or project helper was executed during package construction.
