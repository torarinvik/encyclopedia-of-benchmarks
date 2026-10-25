# ************************************************************************
#
# miniAMR: stencil computations with boundary exchange and AMR.
#
# Copyright (2014) Sandia Corporation. Under the terms of Contract
# DE-AC04-94AL85000 with Sandia Corporation. The U.S. Government
# retains certain rights in this software.
#
# This library is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 2.1 of the
# License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA
# Questions? Contact Courtenay T. Vaughan (ctvaugh@sandia.gov)
#                    Richard F. Barrett (rfbarre@sandia.gov)
#
# ************************************************************************
proc doe_miniamr_stencil_average*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "doe_miniamr_stencil_average".} =
  if values == nil or length < 68 or length > 220: return -1.0e300
  let stencil = values[0]
  let nxRaw = values[1]
  let nyRaw = values[2]
  let nzRaw = values[3]
  if (stencil != 7 and stencil != 27) or
     nxRaw < 2 or nxRaw > 4 or nxRaw mod 2 != 0 or
     nyRaw < 2 or nyRaw > 4 or nyRaw mod 2 != 0 or
     nzRaw < 2 or nzRaw > 4 or nzRaw mod 2 != 0: return -1.0e300

  let nx = int(nxRaw)
  let ny = int(nyRaw)
  let nz = int(nzRaw)
  let gridCells = (nx + 2) * (ny + 2) * (nz + 2)
  if length != csize_t(4 + gridCells): return -1.0e300
  for q in 0 ..< gridCells:
    if values[4 + q] < -1000 or values[4 + q] > 1000: return -1.0e300

  let strideI = (ny + 2) * (nz + 2)
  let strideJ = nz + 2
  var work: array[64, float64]
  var count = 0
  for i in 1 .. nx:
    for j in 1 .. ny:
      for k in 1 .. nz:
        let base = 4 + i * strideI + j * strideJ + k
        if stencil == 7:
          let sum = float64(values[base - strideI]) +
            float64(values[base - strideJ]) + float64(values[base - 1]) +
            float64(values[base]) + float64(values[base + 1]) +
            float64(values[base + strideJ]) + float64(values[base + strideI])
          work[count] = sum / 7.0
        else:
          let sb = float64(values[base - strideI - strideJ - 1]) +
            float64(values[base - strideI - strideJ]) + float64(values[base - strideI - strideJ + 1]) +
            float64(values[base - strideI - 1]) + float64(values[base - strideI]) + float64(values[base - strideI + 1]) +
            float64(values[base - strideI + strideJ - 1]) + float64(values[base - strideI + strideJ]) + float64(values[base - strideI + strideJ + 1])
          let sm = float64(values[base - strideJ - 1]) + float64(values[base - strideJ]) + float64(values[base - strideJ + 1]) +
            float64(values[base - 1]) + float64(values[base]) + float64(values[base + 1]) +
            float64(values[base + strideJ - 1]) + float64(values[base + strideJ]) + float64(values[base + strideJ + 1])
          let sf = float64(values[base + strideI - strideJ - 1]) + float64(values[base + strideI - strideJ]) + float64(values[base + strideI - strideJ + 1]) +
            float64(values[base + strideI - 1]) + float64(values[base + strideI]) + float64(values[base + strideI + 1]) +
            float64(values[base + strideI + strideJ - 1]) + float64(values[base + strideI + strideJ]) + float64(values[base + strideI + strideJ + 1])
          work[count] = (sb + sm + sf) / 27.0
        inc count

  var checksum = 0.0
  for q in 0 ..< count:
    let value = work[q]
    checksum += float64(q + 1) * value * value
  checksum
