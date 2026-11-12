# Rights and provenance

The bounded benchmark's algorithm discovery source is [OI Wiki, Minimum Cost
Flow](https://en.oi-wiki.org/graph/flow/min-cost/), specifically its
shortest-distance followed by tight-edge blocking-flow method. The article
states CC BY-SA 4.0 and SATA terms.

All benchmark ports and oracles were written clean-room from the high-level
algorithm description. No source implementation, problem statement, tests, or
article prose was copied. The workload uses locally defined bounded inputs and
fixtures. The existing AtCoder-based `min_cost_max_flow` package is referenced
only to share its public workload bounds and byte-output contract; its source
code and attribution are not part of this package.
