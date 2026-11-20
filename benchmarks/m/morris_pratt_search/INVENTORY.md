# Static inventory

`verify_workload.py` checks package metadata, all ten exported source symbols,
the bounded alphabet and length contract, the provenance URL, required fixture
coverage, and agreement of the workload's expected scalar with both references.
This inventory is intended for static preflight by the suite runner/verifier;
it does not compile or execute a language port.
