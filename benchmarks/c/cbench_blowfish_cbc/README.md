# cBench Blowfish CBC stage

This package exposes Eric Young's Blowfish CBC routine, `BF_cbc_encrypt`, as a
bounded multi-block operation. It implements the CBC chaining around the
source-compatible Blowfish key schedule and block rounds. The fixed key
selectors use the two test keys published in the same pinned LAC-DCC
repository's MiBench `bftest.c`.

## Contract

The ABI is `i64_array_bytes_output`, symbol `cbench_blowfish_cbc`. Input is
`[direction,key_selector,block_count,iv[8],blocks[8*block_count]]`. Direction
is `0` for encryption or `1` for decryption; key selector is `0` or `1`; the
key selectors choose `abcdefghijklmnopqrstuvwxyz` and `Who is John Galt?`.
Block count is 1 through 4. IV, input blocks, and output blocks are byte values
in `0..255`, represented in big-endian Blowfish block order. The exact input
length is `11 + 8*block_count`, at most 43 values. Output contains exactly
`8*block_count` raw bytes, at most 32. Invalid input returns `-1` before
output checks. Null output or insufficient capacity returns `-2` without
writes.

Encryption XORs each plaintext block with the previous ciphertext (or IV)
before the Blowfish encryption. Decryption applies the inverse block transform
and XORs the previous ciphertext (or IV). This is the CBC helper from the
cBench source set; the neighboring ECB, CFB64, and OFB64 routines and the
launcher build/runtime wrapper are outside this package profile.

## Pinned source and rights

The pinned launcher is
[`cBench/security_blowfish_d/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/security_blowfish_d/src/info.sh)
at commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. It selects the `.c`
files in that directory. The CBC operation is in
[`bf_cbc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/security_blowfish_d/src/bf_cbc.c);
the block primitive, key schedule, and initial P/S words are in `bf_enc.c`,
`bf_skey.c`, `bf_pi.h`, and `blowfish.h`. The two fixed test keys are from
[`MiBench/security-blowfish/bftest.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/security-blowfish/bftest.c)
at the same commit.

These ports are modified derivatives of Eric Young's source and retain its
terms. The complete notice is reproduced in each source file and bundled in
[`LICENSE.txt`](LICENSE.txt). The required advertising acknowledgment is:
“This product includes cryptographic software written by Eric Young
(eay@mincom.oz.au)”. The notice also forbids changing the license and
distribution terms for public versions and derivatives.

```text
/* crypto/bf/bf_enc.c */
/* Copyright (C) 1995-1997 Eric Young (eay@mincom.oz.au)
 * All rights reserved.
 *
 * This package is an SSL implementation written
 * by Eric Young (eay@mincom.oz.au).
 * The implementation was written so as to conform with Netscapes SSL.
 * 
 * This library is free for commercial and non-commercial use as long as
 * the following conditions are aheared to.  The following conditions
 * apply to all code found in this distribution, be it the RC4, RSA,
 * lhash, DES, etc., code; not just the SSL code.  The SSL documentation
 * included with this distribution is covered by the same copyright terms
 * except that the holder is Tim Hudson (tjh@mincom.oz.au).
 * 
 * Copyright remains Eric Young's, and as such any Copyright notices in
 * the code are not to be removed.
 * If this package is used in a product, Eric Young should be given attribution
 * as the author of the parts of the library used.
 * This can be in the form of a textual message at program startup or
 * in documentation (online or textual) provided with the package.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *    "This product includes cryptographic software written by
 *     Eric Young (eay@mincom.oz.au)"
 *    The word 'cryptographic' can be left out if the rouines from the library
 *    being used are not cryptographic related :-).
 * 4. If you include any Windows specific code (or a derivative thereof) from 
 *    the apps directory (application code) you must include an acknowledgement:
 *    "This product includes software written by Tim Hudson (tjh@mincom.oz.au)"
 * 
 * THIS SOFTWARE IS PROVIDED BY ERIC YOUNG ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 * 
 * The licence and distribution terms for any publically available version or
 * derivative of this code cannot be changed.  i.e. this code cannot simply be
 * copied and put under another distribution licence
 * [including the GNU Public Licence.]
 */
```

The independent byte-level model is
[`cbench_blowfish_cbc_oracle.py`](../../cbench_blowfish_cbc_oracle.py), and
[`workload.json`](workload.json) contains the bounded fixtures.

## Ports

| Language | Port |
|---|---|
| C | [`c/c/cbench_blowfish_cbc.c`](../../../c/c/cbench_blowfish_cbc.c) |
| C3 | [`c3/c/cbench_blowfish_cbc.c3`](../../../c3/c/cbench_blowfish_cbc.c3) |
| C++ | [`cpp/c/cbench_blowfish_cbc.cpp`](../../../cpp/c/cbench_blowfish_cbc.cpp) |
| Elisa | [`elisa/c/cbench_blowfish_cbc.elisa`](../../../elisa/c/cbench_blowfish_cbc.elisa) |
| Nim | [`nim/c/cbench_blowfish_cbc.nim`](../../../nim/c/cbench_blowfish_cbc.nim) |
| Odin | [`odin/c/cbench_blowfish_cbc.odin`](../../../odin/c/cbench_blowfish_cbc.odin) |
| Rust | [`rust/c/cbench_blowfish_cbc.rs`](../../../rust/c/cbench_blowfish_cbc.rs) |
| V | [`v/c/cbench_blowfish_cbc.v`](../../../v/c/cbench_blowfish_cbc.v) |
| Zig | [`zig/c/cbench_blowfish_cbc.zig`](../../../zig/c/cbench_blowfish_cbc.zig) |
