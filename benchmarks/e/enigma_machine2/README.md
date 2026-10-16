# Enigma machine (fixed rotor core)

This benchmark covers the portable deterministic rotor core of the pinned Python `ciphers/enigma_machine2.py`. It fixes the source's default rotor selection (`EGZWVONAHDCLFQMSIPJBYUKXTR`, `FOBHMDKEXQNRAULPGSJVTYICZW`, `ZJXESIUQLHAVRMDOYGTNFWPBKC`), the source's reciprocal A↔N through M↔Z reflector, and an empty plugboard. Initial rotor positions use the source's 1-based range 1–26. Only uppercase A–Z messages are in contract, with at most 12 letters.

Input is `[text_length, rotor1_position, rotor2_position, rotor3_position, letter_values...]`, where A=0 through Z=25. After each letter, rotor 1 advances; when it wraps, rotor 2 advances; when rotor 2 wraps, rotor 3 advances. The source has no notch turnover. Output is the ciphertext encoded as a base-26 integer, preserving leading A letters through the input length. Invalid inputs return -1. The same operation decrypts its output when called again with the same initial positions because the reflector and rotor paths are reciprocal.

`enigma_machine.py` is not an alias: it uses a 94-character printable ASCII alphabet and shared module-global mutable rotor/code state. Repeated calls inherit rotor positions and append to prior output, so it is excluded as state-leaking. This benchmark uses the separate uppercase machine2 source.

## Pinned source

The pinned source is [TheAlgorithms/Python `enigma_machine2.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/enigma_machine2.py) at commit `e1a2a8b016001309a73d5fec4818c35cca139795`.
