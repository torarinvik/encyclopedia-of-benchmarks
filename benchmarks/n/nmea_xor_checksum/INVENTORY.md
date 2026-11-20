# Package inventory

- Ten native language ports are present under c/, c3/, cpp/, elisa/, mojo/,
  nim/, odin/, rust/, v/, and zig/.
- primary_oracle.py uses a bytewise XOR fold; independent_oracle.py
  reconstructs the result from per-bit parity counts.
- workload.json pins valid, malformed, null, and maximum-length fixtures.
- verify_workload.py checks the fixture contract and compares both references.
- check_inventory.py checks source/artifact presence and confirms the Elisa
  port uses a borrowed reference rather than a raw pointer.
- The method is derived from the NMEA protocol description at
  https://gpsd.gitlab.io/gpsd/NMEA.html; no source implementation is reused.

No language source has been compiled or executed.
