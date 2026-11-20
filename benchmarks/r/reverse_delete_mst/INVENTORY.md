# Package inventory

`reverse_delete_mst` contains a bounded connected-graph profile, direct
reverse-delete primary reference, exhaustive spanning-tree independent
reference, 17 workload fixtures, provenance/rights notes, and ten language
ports. The static APIs in `check_inventory.py` and `verify_workload.py` are
package artifacts and have not been run.

The maximum frame is 62 valid or 63 parseable signed-i64 words. Output is a
fixed 16-byte payload containing the retained input-edge mask and total tree
weight. Native workspace is capped at 2,048 bytes. Inputs are limited to eight
vertices and twenty edges; the independent reference enumerates subsets of
exactly `n-1` edges.
