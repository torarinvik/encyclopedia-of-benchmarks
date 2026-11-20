# Static inventory

`verify_workload.py` reads package metadata, both reference modules, fixtures,
and all ten language source files. It checks required case IDs, reference
agreement, the declared bounds, and exported symbol presence. It does not
compile or execute any source.
