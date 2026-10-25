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
export fn doe_miniamr_stencil_average(values_opt: ?[*]const i64, length: usize) f64 {
    if (values_opt == null or length < 68 or length > 220) return -1.0e300;
    const values = values_opt.?;
    const stencil = values[0];
    const nx_raw = values[1];
    const ny_raw = values[2];
    const nz_raw = values[3];
    if ((stencil != 7 and stencil != 27) or
        nx_raw < 2 or nx_raw > 4 or @mod(nx_raw, 2) != 0 or
        ny_raw < 2 or ny_raw > 4 or @mod(ny_raw, 2) != 0 or
        nz_raw < 2 or nz_raw > 4 or @mod(nz_raw, 2) != 0) return -1.0e300;

    const nx: usize = @intCast(nx_raw);
    const ny: usize = @intCast(ny_raw);
    const nz: usize = @intCast(nz_raw);
    const grid_cells = (nx + 2) * (ny + 2) * (nz + 2);
    if (length != 4 + grid_cells) return -1.0e300;
    for (0..grid_cells) |q| {
        if (values[4 + q] < -1000 or values[4 + q] > 1000) return -1.0e300;
    }

    const stride_i = (ny + 2) * (nz + 2);
    const stride_j = nz + 2;
    var work: [64]f64 = @splat(0.0);
    var count: usize = 0;
    for (1..nx + 1) |i| {
        for (1..ny + 1) |j| {
            for (1..nz + 1) |k| {
                const base = 4 + i * stride_i + j * stride_j + k;
                if (stencil == 7) {
                    const sum = @as(f64, @floatFromInt(values[base - stride_i])) +
                        @as(f64, @floatFromInt(values[base - stride_j])) + @as(f64, @floatFromInt(values[base - 1])) +
                        @as(f64, @floatFromInt(values[base])) + @as(f64, @floatFromInt(values[base + 1])) +
                        @as(f64, @floatFromInt(values[base + stride_j])) + @as(f64, @floatFromInt(values[base + stride_i]));
                    work[count] = sum / 7.0;
                } else {
                    const sb = @as(f64, @floatFromInt(values[base - stride_i - stride_j - 1])) +
                        @as(f64, @floatFromInt(values[base - stride_i - stride_j])) + @as(f64, @floatFromInt(values[base - stride_i - stride_j + 1])) +
                        @as(f64, @floatFromInt(values[base - stride_i - 1])) + @as(f64, @floatFromInt(values[base - stride_i])) + @as(f64, @floatFromInt(values[base - stride_i + 1])) +
                        @as(f64, @floatFromInt(values[base - stride_i + stride_j - 1])) + @as(f64, @floatFromInt(values[base - stride_i + stride_j])) + @as(f64, @floatFromInt(values[base - stride_i + stride_j + 1]));
                    const sm = @as(f64, @floatFromInt(values[base - stride_j - 1])) + @as(f64, @floatFromInt(values[base - stride_j])) + @as(f64, @floatFromInt(values[base - stride_j + 1])) +
                        @as(f64, @floatFromInt(values[base - 1])) + @as(f64, @floatFromInt(values[base])) + @as(f64, @floatFromInt(values[base + 1])) +
                        @as(f64, @floatFromInt(values[base + stride_j - 1])) + @as(f64, @floatFromInt(values[base + stride_j])) + @as(f64, @floatFromInt(values[base + stride_j + 1]));
                    const sf = @as(f64, @floatFromInt(values[base + stride_i - stride_j - 1])) + @as(f64, @floatFromInt(values[base + stride_i - stride_j])) + @as(f64, @floatFromInt(values[base + stride_i - stride_j + 1])) +
                        @as(f64, @floatFromInt(values[base + stride_i - 1])) + @as(f64, @floatFromInt(values[base + stride_i])) + @as(f64, @floatFromInt(values[base + stride_i + 1])) +
                        @as(f64, @floatFromInt(values[base + stride_i + stride_j - 1])) + @as(f64, @floatFromInt(values[base + stride_i + stride_j])) + @as(f64, @floatFromInt(values[base + stride_i + stride_j + 1]));
                    work[count] = (sb + sm + sf) / 27.0;
                }
                count += 1;
            }
        }
    }

    var checksum: f64 = 0.0;
    for (0..count) |q| {
        const value = work[q];
        checksum += @as(f64, @floatFromInt(q + 1)) * value * value;
    }
    return checksum;
}
