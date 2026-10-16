# Optimal job scheduling

This package implements the pinned Java dynamic program for a precedence chain of processes assigned to machines with pair-dependent transfer delays. For process `i` and machine `j`, its cumulative cost is the minimum over previous machine `k` of `cost[i-1][k] + transfer[k][j] + run[i][j]`; the first process costs only its run time. The output contains the full cumulative cost matrix.

The `i64_array_bytes_output` input layout is `[process_count, machine_count, row-major run_costs, row-major transfer_costs]`. It supports 1–16 processes, 1–8 machines, and nonnegative costs through 1,000. Output is decimal ASCII, with comma-separated costs per row and newline-separated rows. These bounds keep every cumulative value within the source's 32-bit integer arithmetic.

This is the precedence-constrained, machine-transfer-cost problem; it is distinct from weighted interval scheduling. Invalid input returns `-1`; insufficient output capacity returns `-2`. `optimal_job_scheduling_oracle.py` is the runtime expected-output oracle.
