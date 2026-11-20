# Static inventory

The package-local `verify_workload.py` checks workload structure, both
reference results, required cases, and all ten exported source paths. It does
not compile or execute the language ports.

The primary uses completion-count DP for rank and unrank. The independent
reference scans the fixed-cardinality opening-position combinations in
lexicographic order. Source paths are linked in [README.md](README.md).
