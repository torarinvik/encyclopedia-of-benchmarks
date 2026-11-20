# Rights and provenance

The [Codewars public title/tag index](https://www.codewars.com/kata?tags=Algorithms%2CCryptography)
was used only to discover the ECDSA signature-verification algorithm family.
No kata page, problem text, examples, tests, solutions, or code were consulted
or reused.

The ECDSA procedure is specified by [NIST FIPS 186-5](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.186-5.pdf);
elliptic-curve domain validation context is described in [NIST SP 800-186](https://csrc.nist.gov/pubs/sp/800/186/final).
The package uses the mathematical algorithm only and independently authors
the toy-domain contract, point arithmetic, references, fixtures, documentation,
and ports. The toy parameters `(p,a,b,G,n)=(17,2,2,(5,1),19)` are not a
recommended cryptographic domain. This is an algorithm benchmark, not a
security implementation.

All native implementations and fixtures are original clean-room work. No
standard test vectors, upstream code, prose, figures, or tables are copied.
