# Package inventory

`inventory.json` lists the ten native ports and package-local reference and
workload files. `check_inventory.py` checks that those declared text files are
present and that each source includes the exported symbol. `verify_workload.py`
contains source-only validation logic for fixture framing and agreement between
the recursive primary reference and the independent stack reference.

Static status: ten ports are present and listed in the inventory manifest.
The package is registered with the `i64_array_bytes_output` runner, verifier,
catalog, and root README. Source review was static; no program, checker, test,
build, compiler, or benchmark was run.
