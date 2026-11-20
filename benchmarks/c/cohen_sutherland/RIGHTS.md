# Rights and provenance

The clipping method is a published computer-graphics algorithm. The algorithm
description was reviewed in McGill University's
[clipping lecture notes](https://cim.mcgill.ca/~langer/557/6-slides-9pp.pdf)
and the University of Helsinki's
[overview](https://www.cs.helsinki.fi/group/goa/viewing/leikkaus/uuu). The
candidate implementation was located in TheAlgorithms/Java at commit
[`e43ec3897e48f23843972d02cd05a5bb1b6864a2`](https://github.com/TheAlgorithms/Java/tree/e43ec3897e48f23843972d02cd05a5bb1b6864a2).
The pinned [`CohenSutherland.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/lineclipping/CohenSutherland.java)
was consulted only to confirm the implementation's selected boundary order.
Its MIT license is reproduced below because the pinned implementation is
recorded as provenance. The ports, references, workload, and documentation in
this package were independently authored; no implementation code, tests,
examples, or task wording were copied.

The package's independent reference uses the separately described
Liang–Barsky interval method. The local
[`liang_barsky`](../../l/liang_barsky/README.md) package was consulted only to
confirm that this is a distinct clipping method; the Cohen–Sutherland primary
continues to use outcodes and iterative endpoint updates.

## Upstream MIT license

```text
MIT License

Copyright (c) 2021 The Algorithms

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
