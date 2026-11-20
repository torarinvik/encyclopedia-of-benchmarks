# Rights and provenance

The algorithm idea is based on the exact-edge shortest-path problem for a
Monge graph, described in Bein, Larmore, and Park's
[Sandia extended abstract](https://www.osti.gov/servlets/purl/10146169), and
the monotone-minima implementation idea documented in Nyaan's
[Monge d-edge path page](https://nyaannyaan.github.io/library/dp/monge-d-edge-shortest-path-enumerate.hpp.html).
The local profile fixes a small explicit upper triangle, validates the local
Monge promise, and computes exactly one requested edge-count layer.

All code, fixtures, oracle logic, contract prose, and documentation here are
clean-room authored. No upstream code, tests, samples, or prose are copied.
