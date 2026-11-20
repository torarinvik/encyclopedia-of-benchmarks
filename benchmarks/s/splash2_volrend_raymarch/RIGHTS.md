# Rights and provenance

This package is a clean-room, bounded algorithmic profile inspired by the
high-level volume ray-casting workload in SPLASH-2 Volrend. It contains no
copied or adapted SPLASH-2 source code, datasets, or prose. The input schema,
fixed-point arithmetic, test fixtures, opacity-support pyramid, oracles, and
ten language ports were specified independently for this benchmark suite.

Algorithm provenance:

- Jason Nieh and Marc Levoy, “Volume Rendering on Scalable Shared-Memory MIMD
  Architectures,” Proc. 1992 Workshop on Volume Visualization,
  [author paper page](https://graphics.stanford.edu/papers/vv92/).
- Steven Cameron Woo et al., “The SPLASH-2 Programs: Characterization and
  Methodological Considerations,” ISCA 1995,
  [paper](https://pages.cs.wisc.edu/~markhill/restricted/isca95_splash2.pdf).
- The pinned SPLASH-2 source mirror is cited only to clarify algorithm
  provenance: [opacity pyramid](https://raw.githubusercontent.com/staceyson/splash2/be64f8e4840fc29ff4c076c3f747e27fdb55ac68/codes/apps/volrend/octree.C),
  [ray traversal and compositing](https://raw.githubusercontent.com/staceyson/splash2/be64f8e4840fc29ff4c076c3f747e27fdb55ac68/codes/apps/volrend/raytrace.C),
  and [render pipeline](https://raw.githubusercontent.com/staceyson/splash2/be64f8e4840fc29ff4c076c3f747e27fdb55ac68/codes/apps/volrend/main.C).

The referenced Stanford source headers state a 1994 Stanford University
copyright, permit use/copy/modification only for non-commercial purposes with
the notice retained, and forbid redistribution without prior written
permission. No source code from that distribution is included here. This
package's own files are original benchmark materials and remain governed by the
repository's license; the cited algorithms are not claimed as original.
