# Rights and provenance

- Algorithm reference: Kiana Hajebi, Yasin Abbasi-Yadkori, Hossein Shahbazi,
  and Hong Zhang, “Fast Approximate Nearest-Neighbor Search with k-Nearest
  Neighbor Graph,” IJCAI 2011, pp. 1312–1316,
  [official proceedings page](https://ijcai.org/proceedings/2011/222), DOI
  [10.5591/978-1-57735-516-8/IJCAI11-222](https://doi.org/10.5591/978-1-57735-516-8/IJCAI11-222).
- GraphAIBench source audit: [pinned commit
  `17834cb29b7c542481c2e3740dc9664841b72f59`](https://github.com/chenxuhao/GraphAIBench/tree/17834cb29b7c542481c2e3740dc9664841b72f59).
  Its nearest-neighbor OpenMP source is an empty stub; no GraphAIBench code is
  copied into this package.
- The paper is cited for the GNNS idea only. The bounded input/output
  contract, deterministic choices, fixtures, oracles, and ten ports are
  clean-room work. No upstream source code or prose is reused.
