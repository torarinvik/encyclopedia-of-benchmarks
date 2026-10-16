# Elisa stage1 direct-export probe

This fixture checks whether the configured Elisa stage1 compiler emits a direct exported function with the scalar-array ABI used by the benchmark harness. The body validates a pointer and sums the input; it has no helper calls or external dependencies.

Run from the repository root:

```sh
/Users/torarinvikbjarko/zzwork/zzrepo/bin/elisac-stage1 -O3 -emit obj -o /tmp/elisa-direct-export.o benchmarks/elisa_stage1_export_probe/direct_export.elisa
nm -a /tmp/elisa-direct-export.o
cc benchmarks/elisa_stage1_export_probe/main.c /tmp/elisa-direct-export.o -o /tmp/elisa-direct-export
```

Observed on the configured stage1 compiler: compilation exits successfully and produces a 336-byte Mach-O object, but `nm -a` lists only local `ltmp0`; linking fails with undefined `_dsa_verify`. The same missing-export behavior occurs for a constant-return body and a direct loop body. This isolates the current blocker to stage1 export/code generation rather than DSA helper calls or DSA logic. Do not count this Elisa port as verified unless a later compiler build emits the exported symbol and passes runtime verification.
