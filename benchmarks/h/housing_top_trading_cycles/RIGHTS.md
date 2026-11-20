# Rights and provenance

This benchmark independently implements the Top Trading Cycles (TTC) rule for
the strict-preference Shapley–Scarf housing exchange. The algorithm is
attributed to David Gale and described in Shapley and Scarf's [On Cores and
Indivisibility](https://doi.org/10.1016/0304-4068(74)90033-0). The 2016
Encyclopedia of Algorithms chapter on the stable partition problem mentions
TTC for strict B-preferences but does not provide its complete pointer and
cycle-removal procedure; this package uses the standard housing-market
variant specified in the cited source.

Only mathematical algorithm descriptions were consulted. No source code,
examples, fixtures, problem statements, or prose were copied. The bounded
contract, workload, references, and language ports are independently authored.
