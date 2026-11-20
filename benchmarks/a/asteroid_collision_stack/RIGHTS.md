# Rights and provenance

The public LeetCode title **Asteroid Collision** is used only as an idea-discovery
reference: <https://leetcode.com/problems/asteroid-collision/>. No task wording,
examples, tests, submissions, or source code from that page are included here.

The ten ports and two references are independently written from the bounded
contract in this package. They implement the standard one-dimensional
equal-magnitude pair-collision model. The primary uses a one-pass survivor
stack; the independent reference repeatedly rewrites the leftmost colliding
adjacent pair. The profile, ABI framing, signed-byte limits, and workload are
original benchmark choices. Repository code is covered by the repository's
license; this file makes no claim over the discovery source.
