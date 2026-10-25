// ************************************************************************
//
// miniAMR: stencil computations with boundary exchange and AMR.
//
// Copyright (2014) Sandia Corporation. Under the terms of Contract
// DE-AC04-94AL85000 with Sandia Corporation, the U.S. Government
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
#include <cstddef>
#include <cstdint>

extern "C" double doe_miniamr_stencil_average(const std::int64_t *values,
                                                std::size_t length) noexcept {
    if (values == nullptr || length < 68 || length > 220) return -1.0e300;
    const auto stencil = values[0];
    const auto nx_raw = values[1], ny_raw = values[2], nz_raw = values[3];
    if ((stencil != 7 && stencil != 27) ||
        nx_raw < 2 || nx_raw > 4 || nx_raw % 2 != 0 ||
        ny_raw < 2 || ny_raw > 4 || ny_raw % 2 != 0 ||
        nz_raw < 2 || nz_raw > 4 || nz_raw % 2 != 0) return -1.0e300;

    const auto nx = static_cast<std::size_t>(nx_raw);
    const auto ny = static_cast<std::size_t>(ny_raw);
    const auto nz = static_cast<std::size_t>(nz_raw);
    const auto grid_cells = (nx + 2) * (ny + 2) * (nz + 2);
    if (length != 4 + grid_cells) return -1.0e300;
    for (std::size_t q = 0; q < grid_cells; ++q)
        if (values[4 + q] < -1000 || values[4 + q] > 1000) return -1.0e300;

    const auto stride_i = (ny + 2) * (nz + 2);
    const auto stride_j = nz + 2;
    double work[64];
    std::size_t count = 0;
    for (std::size_t i = 1; i <= nx; ++i) {
        for (std::size_t j = 1; j <= ny; ++j) {
            for (std::size_t k = 1; k <= nz; ++k) {
                const auto base = 4 + i * stride_i + j * stride_j + k;
                if (stencil == 7) {
                    const double sum = static_cast<double>(values[base - stride_i]) +
                        static_cast<double>(values[base - stride_j]) + static_cast<double>(values[base - 1]) +
                        static_cast<double>(values[base]) + static_cast<double>(values[base + 1]) +
                        static_cast<double>(values[base + stride_j]) + static_cast<double>(values[base + stride_i]);
                    work[count++] = sum / 7.0;
                } else {
                    const double sb = static_cast<double>(values[base - stride_i - stride_j - 1]) +
                        static_cast<double>(values[base - stride_i - stride_j]) + static_cast<double>(values[base - stride_i - stride_j + 1]) +
                        static_cast<double>(values[base - stride_i - 1]) + static_cast<double>(values[base - stride_i]) + static_cast<double>(values[base - stride_i + 1]) +
                        static_cast<double>(values[base - stride_i + stride_j - 1]) + static_cast<double>(values[base - stride_i + stride_j]) + static_cast<double>(values[base - stride_i + stride_j + 1]);
                    const double sm = static_cast<double>(values[base - stride_j - 1]) + static_cast<double>(values[base - stride_j]) + static_cast<double>(values[base - stride_j + 1]) +
                        static_cast<double>(values[base - 1]) + static_cast<double>(values[base]) + static_cast<double>(values[base + 1]) +
                        static_cast<double>(values[base + stride_j - 1]) + static_cast<double>(values[base + stride_j]) + static_cast<double>(values[base + stride_j + 1]);
                    const double sf = static_cast<double>(values[base + stride_i - stride_j - 1]) + static_cast<double>(values[base + stride_i - stride_j]) + static_cast<double>(values[base + stride_i - stride_j + 1]) +
                        static_cast<double>(values[base + stride_i - 1]) + static_cast<double>(values[base + stride_i]) + static_cast<double>(values[base + stride_i + 1]) +
                        static_cast<double>(values[base + stride_i + stride_j - 1]) + static_cast<double>(values[base + stride_i + stride_j]) + static_cast<double>(values[base + stride_i + stride_j + 1]);
                    work[count++] = (sb + sm + sf) / 27.0;
                }
            }
        }
    }

    double checksum = 0.0;
    for (std::size_t q = 0; q < count; ++q) {
        const double value = work[q];
        checksum += static_cast<double>(q + 1) * value * value;
    }
    return checksum;
}
