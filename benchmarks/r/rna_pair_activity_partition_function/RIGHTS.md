# Rights and provenance

The algorithm idea is based on the sum-product RNA secondary-structure
partition-function dynamic program described by McCaskill and by Lyngsø's
*Encyclopedia of Algorithms* chapter on the RNA secondary-structure Boltzmann
distribution. This benchmark uses a bounded integer specialization: caller
supplied pair activities replace Boltzmann factors, and all noncrossing
partial matchings are counted with the product of their selected activities.

Only algorithm descriptions and bibliographic metadata were consulted. No
source code, prose, problem statements, test cases, or example data were
copied. Workload cases are original bounded values derived from the stated
recurrence. The references in this package are newly written implementations
of the contract, with different interval decompositions.
