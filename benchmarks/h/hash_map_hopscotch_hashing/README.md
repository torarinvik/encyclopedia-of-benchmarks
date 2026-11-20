# Hopscotch hashing

This benchmark measures the neighborhood-bitmap and hole-relocation method from Herlihy, Shavit, and Tzafrir's 2008 Hopscotch Hashing paper. Each key has a caller-supplied home slot. Its home bitmap identifies the next H-1 slots that contain its residents, so lookup examines only that bounded neighborhood. Insertion first probes clockwise for an empty slot, then moves the hole backward by relocating residents whose new positions remain inside their own home neighborhoods.

## Bounded profile

The table has 16 circular slots and neighborhood size H=4. Each call contains [operation_count, (opcode, key, home_slot)...], with at most 32 operations, keys in 0..63, and home slots in 0..15. Opcode 1 inserts; opcode 2 looks up. Every occurrence of the same key must supply the same home. Hash computation, resizing, deletion, and concurrency are outside this profile.

The insertion policy makes the paper's otherwise unconstrained choice of a movable resident deterministic. Starting at the hole, candidate homes are inspected from hole-(H-1) through hole-1 in clockwise order. For each candidate home, residents are considered by increasing offset. A resident can move only if the hole is inside its neighborhood and the move strictly reduces the pending key's distance to the hole. This matches the free-slot movement described in §2 and Figure 1 while pinning ties for reproducibility.

If no free slot exists, or no eligible resident can move the hole close enough, insertion emits status 0; the new key is absent. Relocations already completed remain in place, and every existing key remains within its home neighborhood. This fixed-capacity result stands in for the paper's resize-and-rehash path. A duplicate insertion emits 2 without changing the table; successful insertion emits 1. Lookup emits 1 for a hit and 0 for a miss.

Output bytes are the operation statuses, followed by 16 slot codes and 16 hop bitmaps. Empty slots encode as zero; key k encodes as k+1. Bitmap bit d records a key stored d clockwise slots from that home. A valid call writes operation_count + 32 bytes, up to 64. Malformed input returns -1; a null or undersized output buffer returns -2. The full frame is validated before output-buffer checks. Workspace is bounded to 1,024 bytes.

The [primary reference](primary_oracle.py) stores and updates the hop bitmaps during each relocation. The [independent reference](independent_oracle.py) stores resident (key, home) pairs and reconstructs eligible residents by scanning the table; it does not use the primary bitmap update path.

| Language | Port |
|---|---|
| C | [c/h/hash_map_hopscotch_hashing.c](../../../c/h/hash_map_hopscotch_hashing.c) |
| C3 | [c3/h/hash_map_hopscotch_hashing.c3](../../../c3/h/hash_map_hopscotch_hashing.c3) |
| C++ | [cpp/h/hash_map_hopscotch_hashing.cpp](../../../cpp/h/hash_map_hopscotch_hashing.cpp) |
| Elisa | [elisa/h/hash_map_hopscotch_hashing.elisa](../../../elisa/h/hash_map_hopscotch_hashing.elisa) |
| Mojo | [mojo/h/hash_map_hopscotch_hashing.mojo](../../../mojo/h/hash_map_hopscotch_hashing.mojo) |
| Nim | [nim/h/hash_map_hopscotch_hashing.nim](../../../nim/h/hash_map_hopscotch_hashing.nim) |
| Odin | [odin/h/hash_map_hopscotch_hashing.odin](../../../odin/h/hash_map_hopscotch_hashing.odin) |
| Rust | [rust/h/hash_map_hopscotch_hashing.rs](../../../rust/h/hash_map_hopscotch_hashing.rs) |
| V | [v/h/hash_map_hopscotch_hashing.v](../../../v/h/hash_map_hopscotch_hashing.v) |
| Zig | [zig/h/hash_map_hopscotch_hashing.zig](../../../zig/h/hash_map_hopscotch_hashing.zig) |

Primary algorithm source: Herlihy, Maurice, Nir Shavit, and Moran Tzafrir, “Hopscotch Hashing,” Distributed Computing (DISC 2008), §2 and Figure 1, [DOI 10.1007/978-3-540-87779-0_24](https://doi.org/10.1007/978-3-540-87779-0_24), [author-hosted PDF](https://people.csail.mit.edu/shanir/publications/disc2008_submission_98.pdf). NIST DADS's hashing entries were used for discovery; DADS is not the detailed specification for the relocation rule.

The workload includes direct lookup, duplicate insertion, successful relocation, circular wraparound, an unmovable neighborhood, full-table failure, malformed frames, null/capacity behavior, and maximum-size output. The maximum output is 64 bytes; the declared fixed workspace is 1,024 bytes. This package has not been executed or compiled.
