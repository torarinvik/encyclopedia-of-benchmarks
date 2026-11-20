# Source crosswalk

| Source | Role in this package |
|---|---|
| Aho et al. (1981), DOI [10.1137/0210030](https://doi.org/10.1137/0210030) | Operational rooted-tree consistency method: construct the Aho graph, reject a connected graph on a non-singleton leaf set, recurse over connected components, and join their trees below a root. |
| Jansson and Sung, *Encyclopedia of Algorithms*, Chapter 92, DOI [10.1007/978-1-4939-2864-4_92](https://doi.org/10.1007/978-1-4939-2864-4_92) | Book context on combining rooted triplets into galled networks; this benchmark does not implement the chapter's network algorithms. |

The package emits the specific tree returned by the BUILD/Aho recurrence when
the input is compatible. “Least-resolved” is not used as a global optimality
claim. Sorting child components by minimum taxon ID only fixes a stable byte
serialization for the unordered tree.
