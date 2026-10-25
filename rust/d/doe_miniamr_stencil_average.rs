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
#[no_mangle]
pub unsafe extern "C" fn doe_miniamr_stencil_average(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length < 68 || length > 220 { return -1.0e300; }
    let values = std::slice::from_raw_parts(values, length);
    let stencil = values[0];
    let (nx_raw, ny_raw, nz_raw) = (values[1], values[2], values[3]);
    if (stencil != 7 && stencil != 27) ||
       !(2..=4).contains(&nx_raw) || nx_raw % 2 != 0 ||
       !(2..=4).contains(&ny_raw) || ny_raw % 2 != 0 ||
       !(2..=4).contains(&nz_raw) || nz_raw % 2 != 0 { return -1.0e300; }

    let (nx, ny, nz) = (nx_raw as usize, ny_raw as usize, nz_raw as usize);
    let grid_cells = (nx + 2) * (ny + 2) * (nz + 2);
    if length != 4 + grid_cells || values[4..].iter().any(|&v| !(-1000..=1000).contains(&v)) {
        return -1.0e300;
    }

    let stride_i = (ny + 2) * (nz + 2);
    let stride_j = nz + 2;
    let mut work = [0.0f64; 64];
    let mut count = 0usize;
    for i in 1..=nx {
        for j in 1..=ny {
            for k in 1..=nz {
                let base = 4 + i * stride_i + j * stride_j + k;
                if stencil == 7 {
                    let sum = values[base - stride_i] as f64 + values[base - stride_j] as f64 + values[base - 1] as f64 +
                        values[base] as f64 + values[base + 1] as f64 + values[base + stride_j] as f64 + values[base + stride_i] as f64;
                    work[count] = sum / 7.0;
                } else {
                    let sb = values[base - stride_i - stride_j - 1] as f64 + values[base - stride_i - stride_j] as f64 + values[base - stride_i - stride_j + 1] as f64 +
                        values[base - stride_i - 1] as f64 + values[base - stride_i] as f64 + values[base - stride_i + 1] as f64 +
                        values[base - stride_i + stride_j - 1] as f64 + values[base - stride_i + stride_j] as f64 + values[base - stride_i + stride_j + 1] as f64;
                    let sm = values[base - stride_j - 1] as f64 + values[base - stride_j] as f64 + values[base - stride_j + 1] as f64 +
                        values[base - 1] as f64 + values[base] as f64 + values[base + 1] as f64 +
                        values[base + stride_j - 1] as f64 + values[base + stride_j] as f64 + values[base + stride_j + 1] as f64;
                    let sf = values[base + stride_i - stride_j - 1] as f64 + values[base + stride_i - stride_j] as f64 + values[base + stride_i - stride_j + 1] as f64 +
                        values[base + stride_i - 1] as f64 + values[base + stride_i] as f64 + values[base + stride_i + 1] as f64 +
                        values[base + stride_i + stride_j - 1] as f64 + values[base + stride_i + stride_j] as f64 + values[base + stride_i + stride_j + 1] as f64;
                    work[count] = (sb + sm + sf) / 27.0;
                }
                count += 1;
            }
        }
    }

    let mut checksum = 0.0;
    for q in 0..count {
        let value = work[q];
        checksum += (q + 1) as f64 * value * value;
    }
    checksum
}
