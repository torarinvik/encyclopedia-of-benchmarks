# K-th distinct substring by suffix automaton

Select the one-based k-th distinct nonempty substring of a byte sequence in
lexicographic order. The input frame is `[n, k, byte_0, ..., byte_(n-1)]`:
`1 <= n <= 256`, every byte is in `0..255`, and the frame has exactly `n+2`
words. At most 259 words are parseable. A null or invalid input, a nonpositive
k, or k greater than the number of distinct substrings returns `-1`. A null
or insufficient output buffer returns `-2` after input and rank validation.
Errors leave the output untouched. Success writes the selected substring as
raw bytes and returns its length. Byte zero is an ordinary symbol.

Build a suffix automaton over the input. Process states in decreasing maximum
length and count nonempty paths from each state: every outgoing edge contributes
one for its label plus the paths from its destination. Starting at the root,
visit outgoing labels in byte order, subtracting whole path counts until the
group containing k is found. The edge label itself precedes all its longer
extensions. Counts fit in signed 64-bit integers because there are at most
`n*(n+1)/2 = 32896` distinct substrings. Length counting sort supplies the
reverse topological order; a transition always increases maximum length.

With a dense alphabet of size A=256, construction, path counting, and
selection take O(A*n) time and O(A*n) space. This selects a substring, unlike
the existing suffix-automaton membership/count and minimum-rotation profiles.
The fixed-capacity drafts initialize 512 state slots on every call, even for
short inputs, and their dense transition arrays consume at least 512 KiB of
per-call storage (more where entries are wider than 32 bits).
The [CP-Algorithms suffix automaton article](https://cp-algorithms.com/string/suffix-automaton.html#lexicographically-k-th-substring)
describes the mathematical reduction; the contract, reference, and any ports
are independently authored.

Status: contract, direct enumeration oracle, all ten language ports, workload,
package checker, and byte-output suite wiring are drafted. The verifier source
includes exhaustive small binary inputs and full-size rank boundaries. Nothing
has been compiled or run; the drafts remain unverified.
