# Rights and provenance

The algorithm contract follows the public IETF descriptions in RFC 6238 and
RFC 4226, including HOTP's minimum 128-bit shared-key requirement. This
package contains newly written bounded ports, Python references,
documentation, and workload framing. The one known-answer-derived workload
fixture is attributed to RFC 6238 Appendix B. No source code, reference
implementation, Rosetta Code wording, or Rosetta task fixture was copied.

The pinned RosettaCodeData score-tier index and Rosetta Code task page are
discovery citations only.
The standalone repository SHA-1 benchmark is not imported or linked; each
TOTP port contains its own SHA-1/HMAC helper as part of the measured operation.
