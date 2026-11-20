# Rights and provenance

The algorithmic idea is based on the “Search for a subarray with a
maximum/minimum average” section of the CP-Algorithms article
[`Maximum average segment`](https://cp-algorithms.com/others/maximum_average_segment.html).
The article is published under CC BY-SA 4.0; no article text or implementation
code is copied here. This package is a clean-room bounded adaptation: it
searches integer thresholds at scale 1,000 and uses transformed-prefix
feasibility for subarrays whose length is at least the supplied minimum.

Fixtures and all language implementations were authored independently for
this repository. The independent reference enumerates intervals and compares
exact rational averages by cross multiplication.
