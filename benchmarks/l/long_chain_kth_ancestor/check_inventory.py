"""Static inventory entry point; does not build or execute language ports."""

try:
    from .verify_workload import verify_workload
except ImportError:  # Direct invocation from the package directory.
    from verify_workload import verify_workload  # type: ignore[no-redef]


def inventory_errors() -> list[str]:
    return verify_workload()
