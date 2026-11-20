"""Static source inventory entry point; intentionally performs no builds."""

try:
    from .verify_workload import verify_workload
except ImportError:  # Direct invocation from the package directory.
    from verify_workload import verify_workload  # type: ignore[no-redef]


def inventory_errors() -> list[str]:
    return verify_workload()
