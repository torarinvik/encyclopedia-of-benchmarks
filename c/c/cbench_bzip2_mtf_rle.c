/* Altered, bounded clean-room port of a bzip2/libbzip2 1.0.4 coding stage. */
/*
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
*/
#include <stddef.h>
#include <stdint.h>

enum { MAX_BLOCK = 32, MAX_TOKENS = 33, MAX_INPUT = 68 };

static size_t emit_zero_run(uint8_t *tokens, size_t used, size_t count)
{
    if (count == 0) return used;
    size_t value = count - 1;
    for (;;) {
        tokens[used++] = (uint8_t)((value & 1U) ? 1 : 0);
        if (value < 2) break;
        value = (value - 2) / 2;
    }
    return used;
}

int64_t cbench_bzip2_mtf_rle(const int64_t *input, size_t length,
                              uint8_t *output, size_t capacity)
{
    uint8_t staged[MAX_TOKENS];
    size_t staged_count = 0;
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;

    if (input[0] == 0) {
        if (input[1] != 0 || input[2] < 1 || input[2] > MAX_BLOCK ||
            length != 3 + (size_t)input[2]) return -1;
        const size_t block_length = (size_t)input[2];
        uint8_t alphabet[MAX_BLOCK], order[MAX_BLOCK];
        size_t alphabet_length = 0;
        for (size_t i = 0; i < block_length; ++i) {
            if (input[3 + i] < 0 || input[3 + i] > 255) return -1;
            const uint8_t value = (uint8_t)input[3 + i];
            size_t at = 0;
            while (at < alphabet_length && alphabet[at] < value) ++at;
            if (at < alphabet_length && alphabet[at] == value) continue;
            for (size_t j = alphabet_length; j > at; --j) alphabet[j] = alphabet[j - 1];
            alphabet[at] = value;
            ++alphabet_length;
        }
        for (size_t i = 0; i < alphabet_length; ++i) order[i] = (uint8_t)i;
        size_t pending_zeros = 0;
        for (size_t i = 0; i < block_length; ++i) {
            const uint8_t value = (uint8_t)input[3 + i];
            size_t symbol = 0;
            while (alphabet[symbol] != value) ++symbol;
            size_t rank = 0;
            while (order[rank] != symbol) ++rank;
            if (rank == 0) {
                ++pending_zeros;
                continue;
            }
            staged_count = emit_zero_run(staged, staged_count, pending_zeros);
            pending_zeros = 0;
            staged[staged_count++] = (uint8_t)(rank + 1);
            const uint8_t moved = order[rank];
            for (size_t j = rank; j > 0; --j) order[j] = order[j - 1];
            order[0] = moved;
        }
        staged_count = emit_zero_run(staged, staged_count, pending_zeros);
        staged[staged_count++] = (uint8_t)(alphabet_length + 1);
    } else if (input[0] == 1) {
        if (input[1] < 1 || input[1] > MAX_BLOCK || input[2] < 2 || input[2] > MAX_TOKENS)
            return -1;
        const size_t alphabet_length = (size_t)input[1];
        const size_t token_count = (size_t)input[2];
        if (length != 3 + alphabet_length + token_count) return -1;
        uint8_t order[MAX_BLOCK];
        for (size_t i = 0; i < alphabet_length; ++i) {
            const int64_t symbol = input[3 + i];
            if (symbol < 0 || symbol > 255 || (i > 0 && input[2 + i] >= symbol)) return -1;
            order[i] = (uint8_t)symbol;
        }
        const size_t token_start = 3 + alphabet_length;
        const int64_t eob = (int64_t)alphabet_length + 1;
        for (size_t i = 0; i < token_count; ++i) {
            const int64_t token = input[token_start + i];
            if (token < 0 || token > eob || (i + 1 < token_count && token == eob)) return -1;
        }
        if (input[token_start + token_count - 1] != eob) return -1;

        size_t index = 0;
        while (index + 1 < token_count) {
            int64_t token = input[token_start + index];
            if (token == 0 || token == 1) {
                size_t run_count = 0, weight = 1;
                while (index + 1 < token_count) {
                    token = input[token_start + index];
                    if (token != 0 && token != 1) break;
                    if (weight > MAX_BLOCK) return -1;
                    const size_t add = (size_t)(token + 1) * weight;
                    if (run_count + add > MAX_BLOCK) return -1;
                    run_count += add;
                    weight *= 2;
                    ++index;
                }
                if (staged_count + run_count > MAX_BLOCK) return -1;
                for (size_t j = 0; j < run_count; ++j) staged[staged_count++] = order[0];
                continue;
            }
            if (token < 2 || token >= eob) return -1;
            const size_t rank = (size_t)(token - 1);
            if (rank >= alphabet_length || staged_count >= MAX_BLOCK) return -1;
            const uint8_t moved = order[rank];
            staged[staged_count++] = moved;
            for (size_t j = rank; j > 0; --j) order[j] = order[j - 1];
            order[0] = moved;
            ++index;
        }
        if (staged_count == 0) return -1;
    } else {
        return -1;
    }

    if (output == NULL || capacity < staged_count) return -2;
    for (size_t i = 0; i < staged_count; ++i) output[i] = staged[i];
    return (int64_t)staged_count;
}
