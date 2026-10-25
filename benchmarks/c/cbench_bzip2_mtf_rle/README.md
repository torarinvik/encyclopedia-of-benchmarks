# cBench bzip2 MTF zero-run coding

This package isolates the byte-symbol transform between bzip2's block sort and
Huffman coding. Mode 0 ports the `generateMTFValues` stage; mode 1 ports its
matching RUNA/RUNB expansion and inverse-MTF step from the decoder. It does
not implement a second full BWT/Huffman codec: the input to mode 0 is an
already sorted BWT last column, and mode 1 returns that last column for the
existing inverse-BWT stage.

## Contract

The `i64_array_bytes_output` ABI uses one mode-tagged signed-i64 array:

- Mode 0: `[0, 0, length, last_column_bytes...]`. The alphabet is derived in
  ascending byte order. Each byte is mapped to its move-to-front rank; runs of
  rank zero become bzip2 RUNA/RUNB tokens, followed by the bzip2 EOB token.
- Mode 1: `[1, alphabet_length, token_count, alphabet_bytes..., tokens...]`.
  The alphabet must be strictly ascending. RUNA/RUNB expand repetitions of
  the current front symbol; other nonzero ranks perform inverse move-to-front.
  The final token must be EOB.

Block length and alphabet size are bounded at 32 bytes. The token alphabet is
`RUNA=0`, `RUNB=1`, nonzero MTF rank `j` encoded as `j+1`, and `EOB=alphabet
length+1`. Output is one byte per token in mode 0 or the decoded BWT last
column in mode 1. Invalid input returns `-1`; a null output pointer or
insufficient capacity returns `-2` without writing. The success value is the
number of bytes written.

This differs from the local generic `move_to_front` transform, which emits
every index directly and has no RUNA/RUNB zero-run code, and from
[`pcompress2`](../../p/pcompress2/README.md), whose BWT pipeline uses its own
RLE packets and adaptive arithmetic coding. This profile includes the
bzip2-specific MTF zero-run stage but excludes BWT sorting, outer RLE, Huffman
tables, and bitstream serialization.

## Provenance and rights

The encoder is from pinned
[`cBench/bzip2e/src/compress.c::generateMTFValues`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/bzip2e/src/compress.c)
and its RUNA/RUNB constants are in `bzlib_private.h`. The decoder stage is
from pinned
[`cBench/bzip2d/src/decompress.c::BZ2_decompress`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/bzip2d/src/decompress.c).
Both cBench launchers use all `*.c` files, add `-lm`, and specify no run
options. The source is bzip2/libbzip2 1.0.4 (20 December 2006), copyright
Julian R Seward. These are altered, bounded ports of one codec stage, not the
original bzip2 software; each port and this README retain the complete
upstream notice below.

## Workload

[`workload.json`](workload.json) covers single-symbol and longer zero runs,
nonzero MTF ranks, inverse runs, malformed alphabet/token streams, null
pointers, and output-capacity errors. The independent oracle is
[`cbench_bzip2_mtf_rle_oracle.py`](../../cbench_bzip2_mtf_rle_oracle.py).

## Upstream license notice

```text
--------------------------------------------------------------------------

This program, "bzip2", the associated library "libbzip2", and all
documentation, are copyright (C) 1996-2006 Julian R Seward.  All
rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. The origin of this software must not be misrepresented; you must
   not claim that you wrote the original software.  If you use this
   software in a product, an acknowledgment in the product
   documentation would be appreciated but is not required.

3. Altered source versions must be plainly marked as such, and must
   not be misrepresented as being the original software.
4. The name of the author may not be used to endorse or promote
   products derived from this software without specific prior written
   permission.
THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS
OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
Julian Seward, Cambridge, UK.
jseward@bzip.org
bzip2/libbzip2 version 1.0.4 of 20 December 2006

--------------------------------------------------------------------------
```

| Language | Port |
| --- | --- |
| C | [`c/cbench_bzip2_mtf_rle.c`](../../../c/c/cbench_bzip2_mtf_rle.c) |
| C3 | [`c3/cbench_bzip2_mtf_rle.c3`](../../../c3/c/cbench_bzip2_mtf_rle.c3) |
| C++ | [`cpp/cbench_bzip2_mtf_rle.cpp`](../../../cpp/c/cbench_bzip2_mtf_rle.cpp) |
| Elisa | [`elisa/cbench_bzip2_mtf_rle.elisa`](../../../elisa/c/cbench_bzip2_mtf_rle.elisa) |
| Nim | [`nim/cbench_bzip2_mtf_rle.nim`](../../../nim/c/cbench_bzip2_mtf_rle.nim) |
| Odin | [`odin/cbench_bzip2_mtf_rle.odin`](../../../odin/c/cbench_bzip2_mtf_rle.odin) |
| Rust | [`rust/cbench_bzip2_mtf_rle.rs`](../../../rust/c/cbench_bzip2_mtf_rle.rs) |
| V | [`v/cbench_bzip2_mtf_rle.v`](../../../v/c/cbench_bzip2_mtf_rle.v) |
| Zig | [`zig/cbench_bzip2_mtf_rle.zig`](../../../zig/c/cbench_bzip2_mtf_rle.zig) |
