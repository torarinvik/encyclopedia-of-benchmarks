# Rights and provenance

The algorithm is Bentley's 1977 plane sweep for Klee's measure problem on
rectangles. Bentley's *Solutions to Klee's Rectangle Problems* is cited as
unpublished notes from Carnegie Mellon University. Jan van Leeuwen and Derick
Wood's [1979 author technical report](https://ics-archive.science.uu.nl/research/techreps/repo/CS-1979/1979-06.pdf)
describes the x-sweep, the covered y-measure between consecutive event
coordinates, and Bentley's segment tree for maintaining that measure. The
method is also described in their 1981 *Journal of Algorithms* article,
[*The Measure Problem for Rectangular Ranges in d-Space*](https://doi.org/10.1016/0196-6774(81)90027-4),
2(3), 282–300.

The ports use the algorithm description only. No implementation code, source
prose, or Codewars solution was copied. Codewars was used only to discover the
general problem title; it is not the algorithm source.
