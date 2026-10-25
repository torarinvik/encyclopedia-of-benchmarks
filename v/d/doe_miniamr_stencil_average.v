// ************************************************************************
//
// miniAMR: stencil computations with boundary exchange and AMR.
//
// Copyright (2014) Sandia Corporation. Under the terms of Contract
// DE-AC04-94AL85000 with Sandia Corporation. The U.S. Government
// retains certain rights in this software.
//
// This library is free software; you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as
// published by the Free Software Foundation; either version 2.1 of the
// License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA
// Questions? Contact Courtenay T. Vaughan (ctvaugh@sandia.gov)
//                    Richard F. Barrett (rfbarre@sandia.gov)
//
// ************************************************************************
@[export: 'doe_miniamr_stencil_average']
pub fn doe_miniamr_stencil_average(values &i64, length usize) f64 {
	if length < 68 || length > 220 { return -1.0e300 }
	unsafe {
		stencil := values[0]
		nx_raw, ny_raw, nz_raw := values[1], values[2], values[3]
		if (stencil != 7 && stencil != 27) ||
			nx_raw < 2 || nx_raw > 4 || nx_raw % 2 != 0 ||
			ny_raw < 2 || ny_raw > 4 || ny_raw % 2 != 0 ||
			nz_raw < 2 || nz_raw > 4 || nz_raw % 2 != 0 { return -1.0e300 }

		nx, ny, nz := int(nx_raw), int(ny_raw), int(nz_raw)
		grid_cells := (nx + 2) * (ny + 2) * (nz + 2)
		if length != usize(4 + grid_cells) { return -1.0e300 }
		for q in 0 .. grid_cells {
			if values[4 + q] < -1000 || values[4 + q] > 1000 { return -1.0e300 }
		}

		stride_i, stride_j := (ny + 2) * (nz + 2), nz + 2
		mut work := [64]f64{}
		mut count := 0
		for i in 1 .. nx + 1 {
			for j in 1 .. ny + 1 {
				for k in 1 .. nz + 1 {
					base := 4 + i * stride_i + j * stride_j + k
					if stencil == 7 {
						sum := f64(values[base-stride_i]) + f64(values[base-stride_j]) + f64(values[base-1]) +
							f64(values[base]) + f64(values[base+1]) + f64(values[base+stride_j]) + f64(values[base+stride_i])
						work[count] = sum / 7.0
					} else {
						sb := f64(values[base-stride_i-stride_j-1]) + f64(values[base-stride_i-stride_j]) + f64(values[base-stride_i-stride_j+1]) +
							f64(values[base-stride_i-1]) + f64(values[base-stride_i]) + f64(values[base-stride_i+1]) +
							f64(values[base-stride_i+stride_j-1]) + f64(values[base-stride_i+stride_j]) + f64(values[base-stride_i+stride_j+1])
						sm := f64(values[base-stride_j-1]) + f64(values[base-stride_j]) + f64(values[base-stride_j+1]) +
							f64(values[base-1]) + f64(values[base]) + f64(values[base+1]) +
							f64(values[base+stride_j-1]) + f64(values[base+stride_j]) + f64(values[base+stride_j+1])
						sf := f64(values[base+stride_i-stride_j-1]) + f64(values[base+stride_i-stride_j]) + f64(values[base+stride_i-stride_j+1]) +
							f64(values[base+stride_i-1]) + f64(values[base+stride_i]) + f64(values[base+stride_i+1]) +
							f64(values[base+stride_i+stride_j-1]) + f64(values[base+stride_i+stride_j]) + f64(values[base+stride_i+stride_j+1])
						work[count] = (sb + sm + sf) / 27.0
					}
					count++
				}
			}
		}

		mut checksum := f64(0)
		for q in 0 .. count {
			value := work[q]
			checksum += f64(q + 1) * value * value
		}
		return checksum
	}
}
