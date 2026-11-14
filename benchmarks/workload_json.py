"""Load benchmark workloads without silently overwriting duplicate JSON keys."""

import json


def _unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate workload JSON key: {key!r}")
        result[key] = value
    return result


def load_workload(path):
    try:
        return json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=_unique_object)
    except ValueError as error:
        raise ValueError(f"invalid workload {path}: {error}") from error
