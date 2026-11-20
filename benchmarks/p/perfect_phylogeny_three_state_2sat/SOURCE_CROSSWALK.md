# Source crosswalk

## Encyclopedia entry

Jesper Jansson, “Perfect Phylogeny (Bounded Number of States),”
*Encyclopedia of Algorithms*, Chapter 288,
[DOI 10.1007/978-1-4939-2864-4_288](https://doi.org/10.1007/978-1-4939-2864-4_288).
This entry supplies the book-level problem context: decide perfect-phylogeny
feasibility when the number of states per character is bounded. This package
specializes the input domain to exactly three possible state labels.

## Operational method

Dan Gusfield and Yufeng Wu, “The Three-state Perfect Phylogeny Problem Reduces
to 2-SAT,” *Communications in Information and Systems* 9(4), 295–302 (2009),
§2, Theorem 2.1, pp. 297–298, and Theorem 2.2,
[DOI 10.4310/CIS.2009.v9.n4.a1](https://doi.org/10.4310/CIS.2009.v9.n4.a1).
For characters with all three states observed, the implementation follows
the paper's operational reduction: expand each character into its three
state-membership columns; require at least two columns for every original
character; and forbid simultaneously selecting two columns from different
characters when they exhibit all four binary taxon patterns. These clauses
form a 2-CNF formula, decided by implication-graph SCCs.

The benchmark also accepts characters with fewer than three observed states.
This is an explicit package extension: a two-state character forces its
absent column false, so both observed columns must be selected; a constant
character imposes no compatibility condition. This preprocessing preserves
the observed binary split and is not attributed to Gusfield and Wu's printed
3-state reduction.

The independent reference uses the equivalent exact-two-columns formulation
from Theorem 2.2 for three-state characters. It enumerates which one
state-column is omitted for each character and checks compatibility directly.
For two-state characters only the absent column may be omitted; constants are
ignored. Any compatible selection with at least two columns per character can
be reduced to exactly two per character by deleting extra columns; deletion
preserves compatibility.

## Local duplicate decision

The repository's `directed_perfect_phylogeny` profile accepts binary
characters and checks their pairwise directed-cluster compatibility. It does
not accept three-state characters or measure the expansion-to-2-SAT method.
This package is therefore a distinct bounded-state profile in the same
problem family, rather than a second implementation of the binary contract.

The sources provide mathematical algorithm descriptions only. The benchmark
ports, references, fixtures, and explanatory text are independently authored;
no source code or source examples are reproduced.
