# Rights and provenance

This benchmark is a clean-room implementation of a bounded algorithm profile. It does not copy source code, prose, examples, figures, or test data from the cited works.

- Glencora Borradaile and Philip N. Klein, “An O(n log n) Algorithm for Maximum st-Flow in a Directed Planar Graph,” *Journal of the ACM* 56(2), Article 9 (2009), DOI: <https://doi.org/10.1145/1502793.1502798>. Section 3 supplies the dual-potential preprocessing, capacity transformation, and leftmost-path augmentation method.
- Heike Ripphausen-Lipa, Dorothea Wagner, and Karsten Weihe, “The Vertex-Disjoint Menger Problem in Planar Graphs,” *SIAM Journal on Computing* 26(2) (1997), DOI: <https://doi.org/10.1137/S0097539793253565>. Section 1 defines the counterclockwise-next right-first DFS incidence convention used here.
- Glencora Borradaile, “Planar Maximum s-t Flow,” *Encyclopedia of Algorithms*, Chapter 626, DOI: <https://doi.org/10.1007/978-1-4939-2864-4_626>. This is the local book crosswalk entry.

The bounded contract and fixtures are original. The implementation uses direct bounded shortest-path and search procedures instead of the source's asymptotically faster data structures; it makes no claim to the paper's time bound. No external license for copied code is required because none is included.
