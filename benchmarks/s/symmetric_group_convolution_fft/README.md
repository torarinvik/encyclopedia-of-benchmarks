# Fourier convolution on a symmetric group — draft

This reserved profile computes convolution of two functions on the permutation
group `S_n` over the field of 998244353 elements. The intended kernel uses a
subgroup-chain Fourier transform and inverse transform with matrix products in
irreducible representation blocks. The group is generally noncommutative, so
block multiplication order and the chosen permutation convention matter.
This differs from the repository's cyclic, XOR, subset, and multiplicative
group convolutions.

The intended input is `[n, a_0, ..., a_(n!-1), b_0, ..., b_(n!-1)]`, where
`1 <= n <= 9` and both arrays use lexicographic order on zero-based permutation
images. Every coefficient is in `0..998244353-1`. Composition means
`(q ∘ r)[i] = q[r[i]]`; output position `p` is the sum of `a[q]*b[r]` over
compositions `q ∘ r = p`, reduced modulo the field prime. The desired output
is all `n!` coefficients as little-endian unsigned 32-bit words. The proposed
`i64_array_bytes_output` ABI returns the output byte count on success, `-1` for
null or malformed input, `-2` for null or insufficient output, `-3` for
allocation failure, and `-4` for an internal representation-plan invariant
failure. Input validation precedes output validation, which precedes
allocation; every error leaves output untouched. Exact framing is required.
At `n=9` the frame has 725761 signed words and the output has 1451520 bytes;
725762 words is the largest parseable malformed frame for an extra-word probe.

The byte-output runner and checker C harnesses default to 100002 input words
and 400004 output bytes. Their bounds are now overridable at compile time, and
the build script supplies the degree-nine bounds for this reserved algorithm;
those changes are uncompiled. The Python runner's input and output size checks
now admit the same bounds for this symbol. An unexecuted small workload and
oracle dispatch are drafted. The unexecuted [verifier draft](../../verify_symmetric_group_convolution_fft.py)
uses an existing build and checker, checks fixture and structured-case results,
and compares recorder provenance; it performs no builds. Full-range structured
checking is opt-in. The separate
paired-comparison harness has an uncompiled `--stdin` path for full-size frames.
Its stream contains `length expected-count expected-byte-length`, followed by
the signed input words and a contiguous expected-output hex string (or `-` for
empty output), separated by whitespace. Its output capacity equals the expected
byte length; it does not exercise null or short-output cases.
The paired harness checks each call's returned count during warmup and timed
batches; this adds a small amount of harness work to the measured interval.
The unexecuted [structured pair driver](run_structured_pair.py) serializes
explicitly selected closed-form cases to this stream, checks the harness exit
status and timing rows, and reports the case name alongside each row. It takes
already-built harness and library paths and performs no builds. The paired
driver skips unrequested degrees before constructing their cases; this matters
for the factorially sized inputs. Paired timings do not replace the byte
runner's ABI error probes.

The prime exceeds `n`, so it does not divide `n!`; modular inverses of the
nonzero integers through nine exist. A seminormal basis is a promising way to
avoid importing complex orthogonal formulas that require square roots. The
generator convention and inverse transform recurrence are drafted but
unverified. Full complexity and workspace bounds still require derivation
before any scalable implementation is claimed. [Transform notes](TRANSFORM_NOTES.md)
record the proposed composition and subgroup-factorization invariants.

The [Library Checker proposal](https://github.com/yosupo06/library-checker-problems/issues/1432)
identifies the operation and a factorial-times-polynomial target, with tentative
size bounds. [Maslen and Rockmore's overview](https://library2.msri.org/books/Book46/files/11maslen.pdf)
describes subgroup-chain transforms; [Rockmore's inversion paper](https://math.utoledo.edu/~dgajews/p31-rockmore.pdf)
discusses seminormal representations. These sources provide ideas only; no
code, statements, or examples are copied. The repository of the proposal is
Apache-2.0, while other references are not licensed for code reuse here.

The small [direct reference](independent_oracle.py) enumerates permutation
pairs and supports `n <= 5`; it is only an oracle, not the intended benchmark.
It raises an exception for larger inputs rather than claiming those inputs are
outside the production contract. A second [target-oriented reference](target_oracle.py)
enumerates the left operand for each output and derives the right operand by
inversion. The [ABI reference](abi_reference.py) specifies error precedence and
serialization, with full-range direct formulas when either operand is constant,
has at most one nonzero coefficient, or is exactly the sign character or even
subgroup indicator. It also recognizes pairs whose values are one plus the
image of position zero or one. It raises `NotImplementedError` for other valid
inputs above degree five; those inputs remain in scope. [Reference
cases](reference_cases.py) include opposite orders of
two noncommuting transpositions and degree-four identity and constant inputs.
The small workload exercises dense degree-two products, modular cancellation,
a field-boundary singleton product, degree-three identity and noncommuting
products, null pointers and invalid-input precedence. It does not cover
performance at larger degrees. All drafts are unexecuted.

The [reference-check draft](reference_checks.py) specifies ABI boundaries, generator
involutions, braid and commutation relations, and restriction-block checks
through degree five. An unexecuted [forward transform draft](forward_reference.py)
recurses over subgroup cosets and sparse generator actions; its checks include
the convolution theorem on the small reference cases. It is a research
implementation, not a production port, and has not been run.
The [inverse draft](inverse_reference.py) transposes that recurrence using a
diagonal invariant form; the reference checks specify small round trips.
[A research convolution composition](convolution_reference.py) connects the
two transforms with ordered block products. Its input validation, results,
performance, and workspace remain unverified; it is not a production port.
A [C++ plan scaffold](../../../cpp/s/symmetric_group_convolution_fft_plan.hpp)
drafts tableau enumeration and sparse seminormal generators through degree
nine, with subgroup restriction embeddings. Separate [C++ forward](../../../cpp/s/symmetric_group_convolution_fft_forward.hpp)
and [inverse](../../../cpp/s/symmetric_group_convolution_fft_inverse.hpp)
drafts use those embeddings and coset actions. A [C++ entry point](../../../cpp/s/symmetric_group_convolution_fft.cpp)
drafts ordered block multiplication and the ABI. The builder records the three
header hashes; the runner now checks those hashes and preserves them in records,
and the verifier source compares them. Other language ports and complete suite
integration remain outstanding. The C++ entry point and provenance changes
remain uncompiled and unexecuted.
A [Rust plan scaffold](../../../rust/s/symmetric_group_convolution_fft_plan.rs)
now drafts the same degree-nine tableau, generator, and restriction structures.
The [Rust forward draft](../../../rust/s/symmetric_group_convolution_fft_forward.rs)
uses that plan for subgroup transforms, and the [Rust inverse draft](../../../rust/s/symmetric_group_convolution_fft_inverse.rs)
uses the transposed recurrence. A [Rust entry-point draft](../../../rust/s/symmetric_group_convolution_fft.rs)
connects both transforms and ordered block products. The builder and runner
now record and check its three module hashes. The plan, forward transform,
block products and inverse use fallible vector reservation in the source draft.
Allocation-failure handling, compiler panic behavior and internal bounds still
need verification. None has been compiled or run.

An independent [C plan draft](../../../c/s/symmetric_group_convolution_fft_plan.h)
enumerates and orders tableau bases, constructs sparse generators, and records
restriction blocks with allocation and invariant errors. The separate [C forward
draft](../../../c/s/symmetric_group_convolution_fft_forward.h) adds the subgroup
recurrence and sparse generator operations. An [inverse draft](../../../c/s/symmetric_group_convolution_fft_inverse.h)
adds the invariant diagonal and transposed recurrence. The [C ABI entry-point
draft](../../../c/s/symmetric_group_convolution_fft.c) connects the transforms
and block products. The build, runner, and verifier sources now record or check
all three C header hashes. The port and provenance changes have not been
compiled or run.

The [Nim plan draft](../../../nim/s/symmetric_group_convolution_fft_plan.nim)
enumerates tableau bases and constructs generators and restrictions. A separate
[forward-transform draft](../../../nim/s/symmetric_group_convolution_fft_forward.nim)
adds subgroup restriction and sparse generator actions. An [inverse draft](../../../nim/s/symmetric_group_convolution_fft_inverse.nim)
adds the invariant diagonal and transposed recurrence. Nim's allocation-failure
behavior has not been reconciled with the proposed `-3` result. An [ABI entry
draft](../../../nim/s/symmetric_group_convolution_fft.nim) connects the transforms
and block products, and the builder, runner, and verifier sources record or check
the three Nim module hashes. The build draft selects Nim ARC for this port to
release temporary sequences between calls; static-library initialization and
memory behavior still require verification. The drafts have not been compiled
or run.

The [Zig representation-plan draft](../../../zig/s/symmetric_group_convolution_fft_plan.zig)
enumerates tableau bases and constructs sparse generators and restriction
embeddings using caller-owned allocation. A [forward-transform draft](../../../zig/s/symmetric_group_convolution_fft_forward.zig)
adds subgroup recursion and scoped scratch arenas. An [inverse draft](../../../zig/s/symmetric_group_convolution_fft_inverse.zig)
adds the invariant diagonal and transposed recurrence. An [ABI entry draft](../../../zig/s/symmetric_group_convolution_fft.zig)
connects the transforms and maps allocation and invariant errors. The builder,
runner, and verifier sources record or check the three Zig module hashes. These
drafts and their scratch-memory behavior have not been compiled or run.

The [Odin draft](../../../odin/s/symmetric_group_convolution_fft.odin)
enumerates tableau bases, constructs generators and restriction embeddings,
and drafts forward and inverse subgroup transforms with explicit temporary
cleanup and an ABI entry point that initializes an Odin context before allocating.
Allocation-failure handling has not been mapped to the proposed `-3` result;
context initialization and the draft remain uncompiled and unverified.

The [V draft](../../../v/s/symmetric_group_convolution_fft.v) enumerates
tableaux, constructs generators and restriction embeddings, and drafts forward
and inverse transforms and an ABI entry point. Generator actions reuse a pair
of scratch blocks instead of allocating a new block for every action; loop-local
scratch, restrictions, child blocks, inverse weights, and ABI buffers have
drafted scoped cleanup, including transform error paths. Plan and partially
built plan cleanup is also drafted for the repository's `-gc none` build.
Array ownership and cleanup require compilation and runtime verification;
recoverable allocation-failure handling remains unresolved. The draft is
uncompiled and unexecuted.

The [C3 draft](../../../c3/s/symmetric_group_convolution_fft.c3) enumerates
tableaux, constructs generators and restriction embeddings, and drafts forward
and inverse transforms with an ABI entry point and separate allocation and
invariant error statuses. The draft has not been compiled or run.

The [Elisa tableau-plan draft](../../../elisa/s/symmetric_group_convolution_fft_plan.elisa)
uses caller-owned views to enumerate and order tableau bases, restriction blocks,
and sparse generators. A separate [forward draft](../../../elisa/s/symmetric_group_convolution_fft_forward.elisa)
adds permutation indexing, sparse generator actions, and subgroup recursion over
caller-owned workspace. The [inverse draft](../../../elisa/s/symmetric_group_convolution_fft_inverse.elisa)
includes invariant diagonal construction, block weights, and transpose recursion.
The [kernel draft](../../../elisa/s/symmetric_group_convolution_fft_kernel.elisa)
connects them with ordered block products using caller-owned workspace. An
[ABI draft](../../../elisa/s/symmetric_group_convolution_fft.elisa) owns one
temporary allocation and confines raw references to the ABI and allocator
boundaries. The build source composes the four helper files with the entry point;
the builder, runner, and verifier record or check their hashes. Compilation,
workspace bounds, allocation behavior, and correctness remain unverified.

The [Mojo tableau-plan draft](../../../mojo/s/symmetric_group_convolution_fft.mojo)
uses caller-owned lists for tableau enumeration, restriction embeddings, sparse
generators, the forward subgroup recurrence, inverse diagonal/weighting,
transpose recursion, and an ABI entry point. Recoverable allocation failure is
not yet mapped to `-3`; the draft has not been compiled or run.

The [structured-case draft](structured_cases.py) specifies identity,
constant-function, sign-character, and even-subgroup outputs through degree
nine, plus a maximum extra-word rejection. Sign-character cases use two dense,
nonconstant operands; coordinate cases use two dense functions whose reversed
orders distinguish noncommuting products. It also includes the two orders of
noncommuting adjacent swaps, and weighted two-support translations against a
dense function, through degree nine. The ABI reference separately accumulates
products for operands with at most three nonzero coefficients; three-support
cases through degree five exercise that limit against both direct oracles. These exact
outputs do not depend on the transform, but the cases have not been generated
or run. The verifier is drafted to compare each generated case against the ABI
reference before invoking the checker. Through degree five it also compares
the output against an independently organized target-oriented direct convolution
and checks the coordinate, parity, and bounded-sparse shortcuts themselves against that direct
result. These comparisons remain unexecuted; above degree five they do not
provide an independent general-purpose oracle for arbitrary dense inputs.
