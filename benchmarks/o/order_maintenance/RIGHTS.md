# Rights and provenance

The clean-room profile is based on the order-maintenance algorithmic ideas in
Dietz and Sleator's 1987 paper and the pinned
[Spaghetti Source implementation](https://github.com/spaghetti-source/algorithm/blob/4fdac8202e26def25c1baf9127aaaed6a2c9f7c7/data_structure/order_maintenance.cc).
The pinned repository [README](https://github.com/spaghetti-source/algorithm/blob/4fdac8202e26def25c1baf9127aaaed6a2c9f7c7/README.md)
states that its code is public domain and may be used for any purpose without
warranty. This package does not copy its code, prose, or fixtures. The
benchmark ports, references, workload cases, and documentation are original.

The source's deletion method is excluded from the profile because static
inspection shows its two link assignments leave the neighbors unchanged.
