# Cactus stack branch trace

This package benchmarks the branch/notch behavior of a cactus stack, also
called a saguaro stack. It is a small operation trace over eight stack handles.
Ordinary stack packages in the repository cover push, pop, top, and empty
checks; the persistent VList package covers a block sequence. Neither models a
branch attached at a stack top, the branch-head pop restriction, or automatic
branch detachment when the branch empties.

## Contract

The ABI is `i64_array_bytes_output` with symbol
`cactus_stack_branch_trace`. Input is `[Q,(opcode,a,b)*Q]`, exactly framed,
where `0<=Q<=48`. All eight handles start as empty stacks. Values are in
`[-1000,1000]`; the fixed output record for each operation is two
little-endian signed-i64 words `[status,value]`.

| Opcode | Operands | Behavior and output record |
| --- | --- | --- |
| 0 | `a=handle, b=value` | Push value; emit `[1,0]`. |
| 1 | `a=handle, b=0` | Pop and emit `[1,popped]`; empty or branch-head pop emits `[0,0]` without mutation. |
| 2 | `a=handle, b=0` | Top emits `[1,value]`; empty emits `[0,0]`. |
| 3 | `a=handle, b=0` | Notch query emits `[1,1]` exactly when the current head is a live branch marker, otherwise `[1,0]`. |
| 4 | `a=owner, b=branch handle` | Attach the branch stack at the owner's top; emit `[1,1]`. An empty branch is immediately detached and emits `[1,0]`. |

The bounded profile permits one active branch per owner and no nested
branches. A branch attaches only when owner and branch handles differ, the
owner is nonempty and is not itself attached, the owner has no active branch,
and the branch handle is not attached and has no active branch. A violation
invalidates the full trace with result `-1` and no output. These restrictions
bound the profile; they do not change the source operation's branch/notch
semantics.

Branch attachment replaces the owner's current stack handle with
`branch(S,T)`, where `S` is its previous stack and `T` is separately
addressable only through its original handle. The branch marker is a notch:
`top(branch(S,T))=top(S)`, and popping at that marker is rejected until T
empties. A push over the marker creates an ordinary top node, so a pop removes
that pushed value and reveals the notch again. When T becomes empty, its
attachment is removed automatically; the owner then behaves as S. A rejected
pop is a normal nonmutating trace result, not a malformed request.

Malformed framing, unknown operations, invalid handle/value ranges, or an
invalid branch attachment returns `-1`. A valid trace requires exactly
`1+3Q` words; maximum valid and parseable lengths are 145 and 146 words.
Validation and semantic errors take precedence over output checks. Null output
or capacity below `16Q` returns `-2` without writing. Maximum output is 768
bytes. Caller input/output buffers are excluded from the 4,096-byte workspace
cap; fixed node records, handle/branch metadata, and staged output records fit
within that bound.

The node-table primary performs `O(Q)` time and uses `O(Q+H)` words, with
`H=8`; the independent vector model also performs `O(Q)` amortized work and
uses `O(Q+H)` words. The workload includes empty and max-sized frames,
branch-head rejection, push-over-notch restoration, automatic detachment,
malformed branch requests, null framing/output, and one-byte-short capacity.

## Sources and scope

NIST DADS defines the cactus-stack branch operation, branch removal when the
branch empties, the pop restriction, and the notch/top axioms in its
[cactus stack entry](https://xlinux.nist.gov/dads/HTML/cactusstack.html).
Hauck and Dent's original [Burroughs B6500/B7500 stack-mechanism paper,
AFIPS 1968](https://people.eecs.berkeley.edu/~kubitron/cs252/handouts/papers/burroughs.pdf)
describes the tree-structured stack and budding of independent jobs sharing
prior stack history. The package uses these descriptions only; it does not
simulate the Burroughs instruction set, scheduler, or hardware stack registers.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/c/cactus_stack_branch_trace.c](../../../c/c/cactus_stack_branch_trace.c) |
| C3 | [c3/c/cactus_stack_branch_trace.c3](../../../c3/c/cactus_stack_branch_trace.c3) |
| C++ | [cpp/c/cactus_stack_branch_trace.cpp](../../../cpp/c/cactus_stack_branch_trace.cpp) |
| Elisa | [elisa/c/cactus_stack_branch_trace.elisa](../../../elisa/c/cactus_stack_branch_trace.elisa) |
| Mojo | [mojo/c/cactus_stack_branch_trace.mojo](../../../mojo/c/cactus_stack_branch_trace.mojo) |
| Nim | [nim/c/cactus_stack_branch_trace.nim](../../../nim/c/cactus_stack_branch_trace.nim) |
| Odin | [odin/c/cactus_stack_branch_trace.odin](../../../odin/c/cactus_stack_branch_trace.odin) |
| Rust | [rust/c/cactus_stack_branch_trace.rs](../../../rust/c/cactus_stack_branch_trace.rs) |
| V | [v/c/cactus_stack_branch_trace.v](../../../v/c/cactus_stack_branch_trace.v) |
| Zig | [zig/c/cactus_stack_branch_trace.zig](../../../zig/c/cactus_stack_branch_trace.zig) |

The primary reference uses fixed node records and transparent dead-notch
normalization. The independent reference copies each handle into an ordinary
value vector and tracks the active branch depth separately; neither reference
is derived from published code.
