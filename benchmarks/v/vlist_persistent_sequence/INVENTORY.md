# Package inventory

This package contains a bounded geometric-block VList profile, a block/offset
primary oracle, a tuple-version independent oracle, 13 workload fixtures,
provenance/rights notes, and ten native source ports. The static inventory and
workload APIs are described in `check_inventory.py` and `verify_workload.py`;
neither is run as part of source drafting.

The profile is limited to 32 prepends in one linear build chain followed by
persistent tail/index/length operations. It retains up to 49 roots, six blocks,
and 63 data slots. Input, output, and workspace bounds are respectively 145
valid words, 384 output bytes, and 4,096 bytes. Branch-prepend behavior is
explicitly outside the contract.
