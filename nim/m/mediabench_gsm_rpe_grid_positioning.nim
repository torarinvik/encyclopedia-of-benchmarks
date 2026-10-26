#[
  Independent bounded port of GSM RPE grid positioning.
  Copyright 1992, 1993, 1994 by Jutta Degener and Carsten Bormann,
  Technische Universitaet Berlin

  Any use of this software is permitted provided that this notice is not
  removed and that neither the authors nor the Technische Universitaet Berlin
  are deemed to have made any representations as to the suitability of this
  software for any purpose nor are held responsible for any defects of this
  software. THERE IS ABSOLUTELY NO WARRANTY FOR THIS SOFTWARE.
  As a matter of courtesy, the authors request to be informed about uses
  this software has found, about bugs in this software, and about any
  improvements that may be of general interest.

  Berlin, 28.11.1994
  Jutta Degener
  Carsten Bormann
]#
const InputCount = 14
const MaxInputLength = 15
const OutputCount = 40
const OutputBytes = 80

proc storeI16Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = uint16(value and 65535'i64)
  output[offset] = uint8(bits and 255'u16)
  output[offset + 1] = uint8(bits shr 8)

proc mediabench_gsm_rpe_grid_positioning*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "mediabench_gsm_rpe_grid_positioning".} =
  if input == nil or inputLength < 1 or inputLength > MaxInputLength.csize_t: return -1
  if inputLength != InputCount.csize_t or input[0] < 0 or input[0] > 3: return -1
  for index in 1 ..< InputCount:
    if input[index] < -32768 or input[index] > 32767: return -1

  var staged: array[OutputCount, int64]
  let grid = int(input[0])
  for index in 0 ..< 13: staged[grid + 3 * index] = input[index + 1]
  if output == nil or outputCapacity < OutputBytes.csize_t: return -2
  for index in 0 ..< OutputCount: storeI16Le(output, 2 * index, staged[index])
  OutputBytes.int64
