# Minimum-area enclosing rectangle

This draft computes the exact minimum area of a rectangle enclosing a strictly
convex counterclockwise polygon. For each polygon edge, the algorithm tracks
the extreme supporting vertices in the edge and perpendicular directions.
The edge-alignment theorem makes these orientations sufficient; rotating the
supports around the polygon is linear after initialization. This differs from
[`rotating_calipers`](../rotating_calipers/README.md), which sweeps antipodal
pairs to compute diameter rather than four rectangle supports.

Input is `[N,x0,y0,...]`, with `3<=N<=16`, integer coordinates in `[-100,100]`,
and vertices in strictly convex counterclockwise cyclic order. Every other
vertex must lie strictly to the left of each directed polygon edge. Exact
valid/parseable input lengths are at most 33/34 i64 words. Output is a reduced
nonnegative area fraction `[numerator,denominator]` as two little-endian i64
words; success returns 16. Invalid or null input returns `-1`; valid input with
null output or fewer than 16 bytes returns `-2`; errors write nothing.

The calipers kernel uses `O(N)` time and space for the supplied polygon;
explicit contract validation adds `O(N²)` time. The independent reference
scans every vertex for every edge in `O(N²)`. Bounds keep all projection and
fraction cross-products within signed 64-bit range. [Toussaint's paper](https://ptacts.uspto.gov/ptacts/public-informations/petitions/1536341/download-documents?artifactId=a4dYnzeXTQb2XDkU2Gq_sp88LLBLXNLPEaKi_yIOyyJP7zr_lAjz3iU)
is used for mathematical ideas only; no source code, prose, or examples were
copied. The contract, two reference drafts, ten language drafts, workload,
rights note, package checker, and byte-output suite wiring are independently
authored. The verifier source specifies rotated convex chains, maximum frames,
and output and input error probes. The workload includes a polygon whose
minimum area is the nonintegral fraction `64/5`. Nothing has been compiled or
run.
