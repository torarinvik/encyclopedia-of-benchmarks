# Rights and provenance

The RosettaCodeData popular-title index supplied a candidate title only. Its task text, source implementations, examples, and tests are not included in this package.

Algorithm behavior was specified from the [Bitcoin Wiki Base58Check revision 68948](https://en.bitcoin.it/wiki/Base58Check?oldid=68948) and checked against Bitcoin Core v28.0 [`src/base58.cpp`](https://github.com/bitcoin/bitcoin/blob/110183746150428e6385880c79f8c5733b1361ba/src/base58.cpp). No code or prose has been copied from either reference. All native ports, oracles, fixture frames, and benchmark metadata were written specifically for this repository.

Success fixtures use standard interoperability known-answer outputs for an empty payload, a zero-version twenty-zero payload that exercises preserved leading zeroes, and a 32-byte uncompressed private-key payload whose encoding reaches the 51-byte bound. The bounded input frames and all invalid/capacity cases are authored for this package. The known answers are used only as conformance anchors for the stated algorithm contract.
