# Functional graph cycle parameters by Brent's method

This in-progress benchmark computes the tail length `mu` and eventual cycle
length `lambda` of a supplied successor map. Brent's method advances one moving
node, resetting a checkpoint after blocks of doubling length. After finding
`lambda`, two nodes separated by that many steps advance together to find `mu`.
This differs from the two-speed Floyd traversal in
[`functional_graph_cycle_parameters`](../functional_graph_cycle_parameters/README.md).

The scalar input is `[N,start,next[0],...,next[N-1]]`, where `1 <= N <= 64`
and all node IDs are in `0..N-1`. Its exact length is `N+2` words; 67 is the
maximum parseable length for malformed-frame checks. Return `65*mu+lambda`;
null or invalid input returns `-1`. The bound `mu+lambda <= N` makes this
encoding unambiguous. The search takes O(N) successor evaluations and O(1)
additional space.

The method is described in the [formal cycle-finding study](https://ticamore.logic.at/publications/ITP_2018_paper_16.pdf)
and in [CP-Algorithms' factorization discussion](https://cp-algorithms.com/algebra/factorization.html).
Only algorithmic ideas are used; implementation and eventual fixtures are
independently authored. CP-Algorithms text is CC BY-SA 4.0 and is not copied.
Drafts in all ten languages, two independently organized references, a workload,
and scalar runner and verifier registration are present. The verifier source
includes every successor map through four nodes and every possible tail/cycle
length pair up to 64 nodes. Small maps also compare with the existing Floyd
reference and exercise a bijective vertex relabeling. Static review remains
outstanding; nothing has been executed.

The workload also includes a nonzero start with a nonempty tail and an invalid
successor in a component unreachable from the start. The latter checks the
contract's requirement to validate the entire supplied map. These fixtures have
not been executed.
