# Halley root-finding package inventory

The `float64_pair` package contains ten native language ports, a binary64
primary reference, a high-precision Decimal independent reference, and a
bounded workload. NIST DLMF §3.8(v), Eq. 3.8.12 is the algorithm description
source. Static paths and the package identifier are recorded in
[`INVENTORY.json`](INVENTORY.json); `check_inventory.py` exposes a static
inventory check, and `verify_workload.py` checks fixture/reference agreement.
No programs or tests were run while authoring the package.
