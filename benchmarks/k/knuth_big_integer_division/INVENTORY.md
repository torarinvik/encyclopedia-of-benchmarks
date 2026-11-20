# Static inventory

Package: `knuth_big_integer_division`  
ABI: `i64_array_bytes_output`  
Exported symbol: `knuth_big_integer_division`  
Input limit: 130 signed 64-bit words  
Output limit: 129 bytes  
Workspace model: four eight-limb base-1,000,000,000 arrays, a nine-limb
normalized dividend, an eight-limb normalized divisor, and a 129-byte staging
buffer (521 bytes in the C layout).

Ports present as source files: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V,
and Zig. References: Algorithm D primary and built-in-integer `divmod`
independent oracle. Fixtures in `workload.json` include quotient-estimate
correction and subtraction add-back cases. The package-local verifier checks
fixture agreement and static source inventory. Shared runner/verifier
registration is present.

This is a static file inventory. `verify_workload.py` is available for later
fixture and source review but has not been run; no port has been compiled or
executed.
