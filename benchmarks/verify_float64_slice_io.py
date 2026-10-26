#!/usr/bin/env python3
"""Check float64 slice-to-slice ports against their independent oracles."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import json
import math
from pathlib import Path
import random
import struct
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from graphai_gcn_aggregation_verifier_oracle import (
    N_LIMIT as GRAPHAI_GCN_N_LIMIT,
    M_LIMIT as GRAPHAI_GCN_M_LIMIT,
    D_LIMIT as GRAPHAI_GCN_D_LIMIT,
    INPUT_LIMIT as GRAPHAI_GCN_INPUT_LIMIT,
    OUTPUT_LIMIT as GRAPHAI_GCN_OUTPUT_LIMIT,
    expected_output as graphai_gcn_verifier_oracle,
)
from graphai_sage_aggregation_verifier_oracle import (
    expected_output as graphai_sage_verifier_oracle,
)
from graphai_gat_aggregation_verifier_oracle import (
    expected_output as graphai_gat_verifier_oracle,
)
from graphai_frontier_sampler_verifier_oracle import (
    expected_output as graphai_frontier_sampler_verifier_oracle,
)
from graphai_cf_sgd_sweep_verifier_oracle import (
    expected_output as graphai_cf_sgd_sweep_verifier_oracle,
)
from gardenia_symgs_verifier_oracle import (
    expected_output as gardenia_symgs_verifier_oracle,
)
from gardenia_sgd_verifier_oracle import (
    expected_output as gardenia_sgd_verifier_oracle,
)
from jacobi_1d_oracle import MAX_N as JACOBI_1D_MAX_N, MAX_TSTEPS as JACOBI_1D_MAX_TSTEPS
from jacobi_2d_oracle import MAX_N as JACOBI_2D_MAX_N, MAX_TSTEPS as JACOBI_2D_MAX_TSTEPS
from syr2k_oracle import MAX_M as SYR2K_MAX_M, MAX_N as SYR2K_MAX_N
from syr2k_oracle import MAX_OUTPUT_ELEMENTS as SYR2K_MAX_OUTPUT_ELEMENTS
from fdtd_2d_oracle import (
    MAX_INPUT_LENGTH as FDTD_2D_MAX_INPUT_LENGTH,
    MAX_NX as FDTD_2D_MAX_NX,
    MAX_NY as FDTD_2D_MAX_NY,
    MAX_OUTPUT_ELEMENTS as FDTD_2D_MAX_OUTPUT_ELEMENTS,
    MAX_TMAX as FDTD_2D_MAX_TMAX,
)
from heat_3d_oracle import (
    INVALID_RESULT as HEAT_3D_INVALID_RESULT,
    MAX_INPUT_LENGTH as HEAT_3D_MAX_INPUT_LENGTH,
    MAX_N as HEAT_3D_MAX_N,
    MAX_OUTPUT_ELEMENTS as HEAT_3D_MAX_OUTPUT_ELEMENTS,
    MAX_TSTEPS as HEAT_3D_MAX_TSTEPS,
    OUTPUT_ERROR as HEAT_3D_OUTPUT_ERROR,
)
from asci_purple_smg2000_residual_oracle import (
    MAX_INPUT_LENGTH as ASCI_PURPLE_SMG2000_MAX_INPUT_LENGTH,
    MAX_CELLS as ASCI_PURPLE_SMG2000_MAX_CELLS,
    MAX_ABS_FIELD as ASCI_PURPLE_SMG2000_MAX_ABS_FIELD,
)
from himenobmtxpa_oracle import (
    INPUT_LENGTH as HIMENO_INPUT_LENGTH,
    INVALID_RESULT as HIMENO_INVALID_RESULT,
    MAX_ITERATIONS as HIMENO_MAX_ITERATIONS,
    MAX_OUTPUT_ELEMENTS as HIMENO_MAX_OUTPUT_ELEMENTS,
    MAX_PARSEABLE_INPUT_LENGTH as HIMENO_MAX_PARSEABLE_INPUT_LENGTH,
    MAX_SIDE as HIMENO_MAX_SIDE,
    MIN_ITERATIONS as HIMENO_MIN_ITERATIONS,
    MIN_SIDE as HIMENO_MIN_SIDE,
    OUTPUT_ERROR as HIMENO_OUTPUT_ERROR,
)
from trmm_oracle import (
    INVALID_RESULT as TRMM_INVALID_RESULT,
    MAX_DIM as TRMM_MAX_DIM,
    MAX_INPUT_LENGTH as TRMM_MAX_INPUT_LENGTH,
    MAX_OUTPUT_ELEMENTS as TRMM_MAX_OUTPUT_ELEMENTS,
    OUTPUT_ERROR as TRMM_OUTPUT_ERROR,
)
from misc_dt_oracle import expected_output as misc_dt_verifier_expected_output
from olden_bh_oracle import MAX_BODIES as OLDEN_BH_MAX_BODIES
from olden_bh_oracle import expected_output as olden_bh_verifier_expected_output
from olden_em3d_oracle import MAX_DEGREE as OLDEN_EM3D_MAX_DEGREE
from olden_em3d_oracle import MAX_NODES as OLDEN_EM3D_MAX_NODES
from olden_em3d_oracle import expected_output as olden_em3d_verifier_expected_output
from cbench_rsynth_impulsive_glottal_oracle import (
    MIN_OPEN as CBENCH_RSYNTH_IMPULSIVE_MIN_OPEN,
    MAX_OPEN as CBENCH_RSYNTH_IMPULSIVE_MAX_OPEN,
    MAX_SAMPLE_INDEX as CBENCH_RSYNTH_IMPULSIVE_MAX_SAMPLE_INDEX,
    MAX_INPUT_LENGTH as CBENCH_RSYNTH_IMPULSIVE_MAX_INPUT_LENGTH,
    MAX_PARSEABLE_INPUT_LENGTH as CBENCH_RSYNTH_IMPULSIVE_MAX_PARSEABLE_INPUT_LENGTH,
    MAX_OUTPUT_ELEMENTS as CBENCH_RSYNTH_IMPULSIVE_MAX_OUTPUT_ELEMENTS,
    SAMPLE_RATE as CBENCH_RSYNTH_IMPULSIVE_SAMPLE_RATE,
)
from run_float64_slice_io import (
    _decode_linear_discriminant_analysis_abi_values,
    validate_linear_discriminant_analysis_workload,
    validate_kalman_filter_workload,
    validate_kalman_filter_r_two_state_simulation_workload,
    validate_muon_optimizer_workload,
    validate_pseudo_inverse_workload,
    validate_tdigest_workload,
    TDIGEST_WORKSPACE_ELEMENTS,
    validate_risk_metrics_workload,
    validate_pca_workload,
    validate_principal_component_analysis_workload,
    validate_principle_component_analysis_workload,
    validate_ramer_douglas_peucker_workload,
    validate_sir_workload,
    validate_syrk_workload,
    validate_matmul_f64_4x4_workload,
    validate_misc_fp_convert_workload,
    validate_misc_dt_workload,
    validate_olden_bh_workload,
    validate_olden_em3d_workload,
    validate_trisolv_workload,
    validate_polybench_jacobi_workload,
    validate_syr2k_workload,
    validate_trmm_workload,
    validate_fdtd_2d_workload,
    validate_heat_3d_workload,
    validate_parboil_stencil_laplacian_workload,
                                  validate_graphai_gcn_aggregation_workload,
                                  validate_graphai_sage_aggregation_workload,
                                  validate_graphai_gat_aggregation_workload,
                                  validate_graphai_frontier_sampler_workload,
                                  validate_graphai_cf_sgd_sweep_workload,
                                  validate_gardenia_workload,
                                  validate_asci_purple_smg2000_residual_workload,
    validate_mafft_falign_fft_lag_correlation_workload,
    validate_himenobmtxpa_workload,
    validate_polybench_gramschmidt_workload,
    validate_polybench_lu_workload,
    validate_polybench_correlation_workload,
    validate_polybench_seidel_2d_workload,
    validate_mibench_automotive_basicmath_cubic_workload,
    validate_mibench_lame_mdct_long_workload,
    validate_cbench_consumer_mad_imdct36_workload,
    validate_cbench_consumer_lame_mdct_short_workload,
    validate_cbench_lame_mid_side_workload,
    validate_cbench_rsynth_natural_glottal_workload,
    validate_cbench_rsynth_impulsive_glottal_workload,
)
from pca_oracle import (
    MAX_OUTPUT_ELEMENTS as PCA_MAX_OUTPUT_ELEMENTS,
    MAX_SAMPLES as PCA_MAX_SAMPLES,
    MIN_SAMPLES as PCA_MIN_SAMPLES,
    expected_result as pca_verifier_oracle,
)
from principal_component_analysis_oracle import (
    INVALID_RESULT as PRINCIPAL_COMPONENT_ANALYSIS_INVALID_RESULT,
    MAX_ABS_VALUE as PRINCIPAL_COMPONENT_ANALYSIS_MAX_ABS_VALUE,
    MAX_FEATURES as PRINCIPAL_COMPONENT_ANALYSIS_MAX_FEATURES,
    MAX_INPUT_LENGTH as PRINCIPAL_COMPONENT_ANALYSIS_MAX_INPUT_LENGTH,
    MAX_ITERATIONS as PRINCIPAL_COMPONENT_ANALYSIS_MAX_ITERATIONS,
    MAX_OUTPUT_LENGTH as PRINCIPAL_COMPONENT_ANALYSIS_MAX_OUTPUT_LENGTH,
    MAX_SAMPLES as PRINCIPAL_COMPONENT_ANALYSIS_MAX_SAMPLES,
    MIN_FEATURES as PRINCIPAL_COMPONENT_ANALYSIS_MIN_FEATURES,
    MIN_NORM as PRINCIPAL_COMPONENT_ANALYSIS_MIN_NORM,
    MIN_SAMPLES as PRINCIPAL_COMPONENT_ANALYSIS_MIN_SAMPLES,
    TOLERANCE as PRINCIPAL_COMPONENT_ANALYSIS_TOLERANCE,
    expected_result as principal_component_analysis_verifier_oracle,
)
from principle_component_analysis_oracle import (
    MAX_OUTPUT_LENGTH as PRINCIPLE_COMPONENT_ANALYSIS_MAX_OUTPUT_LENGTH,
    expected_output as principle_component_analysis_abi_verifier_oracle,
    expected_result as principle_component_analysis_verifier_oracle,
)
from ramer_douglas_peucker_oracle import (
    INVALID_RESULT as RAMER_DOUGLAS_PEUCKER_INVALID_RESULT,
    MAX_ABS_COORDINATE as RAMER_DOUGLAS_PEUCKER_MAX_ABS_COORDINATE,
    MAX_EPSILON as RAMER_DOUGLAS_PEUCKER_MAX_EPSILON,
    MAX_INPUT_LENGTH as RAMER_DOUGLAS_PEUCKER_MAX_INPUT_LENGTH,
    MAX_OUTPUT_LENGTH as RAMER_DOUGLAS_PEUCKER_MAX_OUTPUT_LENGTH,
    MAX_POINTS as RAMER_DOUGLAS_PEUCKER_MAX_POINTS,
    expected_result as ramer_douglas_peucker_verifier_oracle,
)
from kalman_filter_oracle import (
    MAX_OUTPUT_ELEMENTS as KALMAN_FILTER_MAX_OUTPUT_ELEMENTS,
    MAX_PARSEABLE_INPUT_LENGTH as KALMAN_FILTER_MAX_PARSEABLE_INPUT_LENGTH,
    MAX_STEPS as KALMAN_FILTER_MAX_STEPS,
    MAX_STATE_MICRO as KALMAN_FILTER_MAX_STATE_MICRO,
    MAX_VARIANCE_MICRO as KALMAN_FILTER_MAX_VARIANCE_MICRO,
    MIN_MEASUREMENT_NOISE_MICRO as KALMAN_FILTER_MIN_MEASUREMENT_NOISE_MICRO,
    MIN_STATE_MICRO as KALMAN_FILTER_MIN_STATE_MICRO,
    MIN_VARIANCE_MICRO as KALMAN_FILTER_MIN_VARIANCE_MICRO,
    expected_output as kalman_filter_abi_verifier_oracle,
    expected_result as kalman_filter_verifier_oracle,
)
from kalman_filter_r_two_state_simulation_oracle import (
    INVALID_OUTPUT_RESULT as KALMAN_FILTER_R_INVALID_OUTPUT_RESULT,
    INVALID_RESULT as KALMAN_FILTER_R_INVALID_RESULT,
    MAX_OBSERVATIONS as KALMAN_FILTER_R_MAX_OBSERVATIONS,
    MAX_OUTPUT_ELEMENTS as KALMAN_FILTER_R_MAX_OUTPUT_ELEMENTS,
    MAX_PARSEABLE_INPUT_LENGTH as KALMAN_FILTER_R_MAX_PARSEABLE_INPUT_LENGTH,
    MAX_OBSERVATION as KALMAN_FILTER_R_MAX_OBSERVATION,
    MIN_OBSERVATIONS as KALMAN_FILTER_R_MIN_OBSERVATIONS,
    MIN_OBSERVATION as KALMAN_FILTER_R_MIN_OBSERVATION,
    expected_output as kalman_filter_r_abi_verifier_oracle,
)
from risk_metrics_oracle import (
    ALGORITHM_NAMES as RISK_METRICS_ALGORITHM_NAMES,
    INVALID_RESULT as RISK_METRICS_INVALID_RESULT,
    MAX_CONFIDENCE as RISK_METRICS_MAX_CONFIDENCE,
    MAX_PORTFOLIO_VALUE as RISK_METRICS_MAX_PORTFOLIO_VALUE,
    MAX_RETURN as RISK_METRICS_MAX_RETURN,
    MAX_RETURN_COUNT as RISK_METRICS_MAX_RETURN_COUNT,
    MAX_SIMULATION_COUNT as RISK_METRICS_MAX_SIMULATION_COUNT,
    MAX_STANDARD_NORMAL as RISK_METRICS_MAX_STANDARD_NORMAL,
    MAX_TIME_HORIZON as RISK_METRICS_MAX_TIME_HORIZON,
    MAX_UPDATE_RETURN_COUNT as RISK_METRICS_MAX_UPDATE_RETURN_COUNT,
    MIN_CONFIDENCE as RISK_METRICS_MIN_CONFIDENCE,
    MIN_PORTFOLIO_VALUE as RISK_METRICS_MIN_PORTFOLIO_VALUE,
    MIN_RETURN as RISK_METRICS_MIN_RETURN,
    MIN_RETURN_COUNT as RISK_METRICS_MIN_RETURN_COUNT,
    MIN_SIMULATION_COUNT as RISK_METRICS_MIN_SIMULATION_COUNT,
    MIN_STANDARD_NORMAL as RISK_METRICS_MIN_STANDARD_NORMAL,
    MIN_TIME_HORIZON as RISK_METRICS_MIN_TIME_HORIZON,
    OUTPUT_ERROR as RISK_METRICS_OUTPUT_ERROR,
    expected_output as risk_metrics_abi_verifier_oracle,
    expected_result as risk_metrics_verifier_oracle,
)
from muon_optimizer_oracle import (
    INVALID_RESULT as MUON_OPTIMIZER_INVALID_RESULT,
    MAX_INPUT_LENGTH as MUON_OPTIMIZER_MAX_PARSEABLE_INPUT_LENGTH,
    MAX_OUTPUT_ELEMENTS as MUON_OPTIMIZER_MAX_OUTPUT_ELEMENTS,
    OUTPUT_ERROR as MUON_OPTIMIZER_OUTPUT_ERROR,
    expected_output as muon_optimizer_abi_verifier_oracle,
)
from pseudo_inverse_oracle import (
    INVALID_RESULT as PSEUDO_INVERSE_INVALID_RESULT,
    MAX_OUTPUT_LENGTH as PSEUDO_INVERSE_MAX_OUTPUT_LENGTH,
    MAX_PARSEABLE_INPUT_LENGTH as PSEUDO_INVERSE_MAX_PARSEABLE_INPUT_LENGTH,
    OUTPUT_ERROR as PSEUDO_INVERSE_OUTPUT_ERROR,
    expected_output as pseudo_inverse_abi_verifier_oracle,
)
from tdigest_oracle import (
    INVALID_RESULT as TDIGEST_INVALID_RESULT,
    MAX_INPUT_LENGTH as TDIGEST_MAX_INPUT_LENGTH,
    MAX_OUTPUT_LENGTH as TDIGEST_MAX_OUTPUT_LENGTH,
    MAX_PARSEABLE_INPUT_LENGTH as TDIGEST_MAX_PARSEABLE_INPUT_LENGTH,
    MAX_QUERIES as TDIGEST_MAX_QUERIES,
    MAX_SAMPLES as TDIGEST_MAX_SAMPLES,
    MAX_COMPRESSION as TDIGEST_MAX_COMPRESSION,
    MIN_COMPRESSION as TDIGEST_MIN_COMPRESSION,
    OUTPUT_ERROR as TDIGEST_OUTPUT_ERROR,
    expected_output as tdigest_abi_verifier_oracle,
)
from sir_oracle import (
    INPUT_LENGTH as SIR_INPUT_LENGTH,
    INVALID_RESULT as SIR_INVALID_RESULT,
    MAX_BETA as SIR_MAX_BETA,
    MAX_K as SIR_MAX_K,
    MAX_OUTPUT_ELEMENTS as SIR_MAX_OUTPUT_ELEMENTS,
    MAX_PARSEABLE_INPUT_LENGTH as SIR_MAX_PARSEABLE_INPUT_LENGTH,
    MAX_POPULATION as SIR_MAX_POPULATION,
    MAX_TIME as SIR_MAX_TIME,
    OUTPUT_ERROR as SIR_OUTPUT_ERROR,
    expected_output as sir_abi_oracle,
)
from linear_discriminant_analysis_oracle import (
    INVALID_RESULT as LINEAR_DISCRIMINANT_ANALYSIS_INVALID_RESULT,
    MAX_CLASSES as LINEAR_DISCRIMINANT_ANALYSIS_MAX_CLASSES,
    MAX_OUTPUT_ELEMENTS as LINEAR_DISCRIMINANT_ANALYSIS_MAX_OUTPUT_ELEMENTS,
    MAX_PARSEABLE_INPUT_LENGTH as LINEAR_DISCRIMINANT_ANALYSIS_MAX_PARSEABLE_INPUT_LENGTH,
    MAX_TOTAL_SAMPLES as LINEAR_DISCRIMINANT_ANALYSIS_MAX_TOTAL_SAMPLES,
    MAX_VALID_INPUT_LENGTH as LINEAR_DISCRIMINANT_ANALYSIS_MAX_VALID_INPUT_LENGTH,
    OUTPUT_ERROR as LINEAR_DISCRIMINANT_ANALYSIS_OUTPUT_ERROR,
    expected_output as linear_discriminant_analysis_abi_oracle,
)
from run_float64_slice_io import (MAX_RAYLEIGH_QUOTIENT_INPUT_LENGTH, ORACLES,
                                  _format_output, _output_token, encode_case, tolerances,
                                  validate_tsvc_s111_odd_index_neighbor_update_workload,
                                  validate_tsvc_vtvtv_triple_product_map_workload,
                                  validate_tsvc_s451_sincos_vector_map_workload,
                                  validate_tsvc_s221_partial_recursive_fused_update_workload,
                                  validate_tsvc_s222_interleaved_square_recurrence_workload,
                                  validate_tsvc_s2251_carried_scalar_expansion_workload,
                                  validate_tsvc_s1251_per_element_dual_update_workload,
                                  validate_tsvc_s3251_forward_shifted_array_expansion_workload,
                                  validate_tsvc_s2712_comparison_gated_axpy_workload,
                                  validate_tsvc_s2710_nested_scalar_vector_branch_update_workload,
                                  validate_tsvc_s1279_nested_conditional_accumulation_workload,
                                  validate_tsvc_s2275_matrix_vector_axpy_interleave_workload,
                                  validate_tsvc_s482_break_after_update_workload,
                                  validate_tsvc_s441_s443_d_sign_branch_updates_workload,
                                  validate_tsvc_s242_fused_prefix_update_workload,
                                  validate_tsvc_s351_direct_unrolled_saxpy_workload,
                                  validate_tsvc_s275_column_conditional_axpy_recurrence_workload,
                                  validate_tsvc_s313_dot_product_reduction_workload,
                                  validate_versabench_beamformer_workload,
                                  validate_rader_fft_workload,
                                  validate_smallest_enclosing_ball_3d_workload,
                                  validate_euclidean_t_spanner_workload,
                                  validate_joint_probability_distribution_workload,
                                  validate_pid_workload,
                                  validate_shreedharacharya_workload,
                                  validate_rotation_matrix_workload,
                                  validate_simple_pendulum_rk4_workload,
                                  validate_piecewise_without_inbuilt_workload,
                                  validate_koch_snowflake_workload,
                                  validate_k_d_tree_workload,
                                  validate_linear_regression_vectorized_workload,
                                  validate_perlin_noise_workload,
                                  validate_single_point_crossover_workload,
                                  validate_quaternions_workload,
                                  validate_rhumb_distance_workload,
                                  validate_rhumb_bearing_workload,
                                  validate_rhumb_destination_workload,
                                  validate_median_of_running_array_double_workload,
                                  validate_median_of_running_array_float_workload,
                                  validate_mean_shift_workload,
                                  validate_local_weighted_learning_workload,
                                  validate_k_means_clust_workload,
                                  validate_lu_decompose_workload,
                                  validate_lu_elimination_workload,
                                  validate_lu_pivot_decomposition_workload,
                                  validate_kohonen_som_trace_workload,
                                  validate_kohonen_som_topology_workload,
                                  validate_qr_decompose_workload,
                                  validate_qr_decomposition_workload,
                                  validate_qr_eigen_values_workload,
                                  validate_shuffle_workload,
                                  validate_spirograph_workload,
                                  validate_polynomial_regression_workload,
                                  validate_pi_monte_carlo_estimation_workload,
                                  validate_montecarlopi_workload,
                                  validate_monte_carlo_simulation_workload,
                                  validate_mini_batch_gradient_descent_workload,
                                  validate_momentum_sgd_workload,
                                  validate_soboleva_modified_hyperbolic_tangent_workload,
                                  validate_rmsprop_workload,
                                  validate_sherman_morrison_workload,
                                  validate_linearregressionrawr_workload,
                                  validate_q_learning_workload,
                                  validate_single_indeterminate_operations_workload,
                                  validate_decision_tree_python_regression_workload,
                                  validate_perceptron_workload,
                                  TRAVELLING_SALESMAN_PYTHON_ALGORITHMS,
                                  TSP_BRUTEFORCE_COORDINATE_BOUND,
                                  TSP_BRUTEFORCE_MAX_CITIES,
                                  TSP_BRUTEFORCE_MAX_OUTPUT_ELEMENTS,
                                  TSP_HELD_KARP_COORDINATE_BOUND,
                                  TSP_HELD_KARP_MAX_CITIES,
                                  TSP_HELD_KARP_MAX_OUTPUT_ELEMENTS,
                                  validate_travelling_salesman_python_workload,
                                  MONTECARLOPI_MAX_OUTPUT_ELEMENTS,
                                  MONTECARLOPI_MAX_PARSEABLE_INPUT_LENGTH,
                                  MONTECARLOPI_MAX_VALID_INPUT_LENGTH,
                                  MONTECARLOPI_MAX_RANDOM_POINTS,
                                  MONTECARLOPI_MIN_RANDOM_POINTS,
                                  MONTECARLOPI_SAMPLE_COORDINATE_LEVELS,
                                  montecarlopi_abi_oracle,
                                  MONTE_CARLO_SIMULATION_MAX_OUTPUT_ELEMENTS,
                                  MONTE_CARLO_SIMULATION_MAX_PARSEABLE_INPUT_LENGTH,
                                  MONTE_CARLO_SIMULATION_MAX_VALID_INPUT_LENGTH,
                                  MONTE_CARLO_SIMULATION_MAX_SIMULATIONS,
                                  MONTE_CARLO_SIMULATION_MATURITIES,
                                  MONTE_CARLO_SIMULATION_STEP_COUNTS,
                                  MONTE_CARLO_SIMULATION_ABSOLUTE_TOLERANCE,
                                  monte_carlo_simulation_abi_oracle,
                                  MINI_BATCH_GRADIENT_DESCENT_MAX_EPOCHS,
                                  MINI_BATCH_GRADIENT_DESCENT_MAX_FEATURES,
                                  MINI_BATCH_GRADIENT_DESCENT_MAX_INPUT_LENGTH,
                                  MINI_BATCH_GRADIENT_DESCENT_MAX_OUTPUT_LENGTH,
                                  MINI_BATCH_GRADIENT_DESCENT_MAX_SAMPLES,
                                  MINI_BATCH_GRADIENT_DESCENT_MIN_EPOCHS,
                                  MINI_BATCH_GRADIENT_DESCENT_MIN_FEATURES,
                                  MINI_BATCH_GRADIENT_DESCENT_MIN_SAMPLES,
                                  mini_batch_gradient_descent_oracle,
                                  LINEARREGRESSIONRAWR_MAX_OUTPUT_ELEMENTS,
                                  LINEARREGRESSIONRAWR_MAX_PARSEABLE_INPUT_LENGTH,
                                  LINEARREGRESSIONRAWR_MAX_PREDICTOR,
                                  LINEARREGRESSIONRAWR_MAX_RESPONSE,
                                  LINEARREGRESSIONRAWR_MAX_SAMPLE_COUNT,
                                  LINEARREGRESSIONRAWR_MIN_PREDICTOR,
                                  LINEARREGRESSIONRAWR_MIN_RESPONSE,
                                  LINEARREGRESSIONRAWR_MIN_SAMPLE_COUNT,
                                  SHERMAN_MORRISON_MAX_DIMENSION,
                                  SHERMAN_MORRISON_MAX_ENTRY,
                                  SHERMAN_MORRISON_MAX_OUTPUT_ELEMENTS,
                                  SHERMAN_MORRISON_MAX_PARSEABLE_INPUT_LENGTH,
                                  SHERMAN_MORRISON_MIN_DIMENSION,
                                  SHERMAN_MORRISON_MIN_ENTRY,
                                  _sherman_morrison_finite_number,
                                  rmsprop_abi_oracle,
                                  RMSPROP_MAX_EPSILON, RMSPROP_MAX_GRADIENT,
                                  RMSPROP_MAX_LEARNING_RATE, RMSPROP_MAX_MOVING_AVERAGE,
                                  RMSPROP_MAX_PARAMETER, RMSPROP_MAX_RHO,
                                  RMSPROP_MAX_VECTOR_LENGTH, RMSPROP_MIN_EPSILON,
                                  RMSPROP_MIN_GRADIENT, RMSPROP_MIN_LEARNING_RATE,
                                  RMSPROP_MIN_MOVING_AVERAGE, RMSPROP_MIN_PARAMETER,
                                  RMSPROP_MIN_RHO, RMSPROP_MIN_VECTOR_LENGTH,
                                  _same_float64_sequence,
                                  _decode_k_d_tree_abi_values,
                                  _decode_single_point_crossover_abi_values)
from q_learning_oracle import (
    MAX_NEXT_ACTIONS as Q_LEARNING_MAX_NEXT_ACTIONS,
    MAX_OUTPUT_ELEMENTS as Q_LEARNING_MAX_OUTPUT_ELEMENTS,
    MAX_PARSEABLE_INPUT_LENGTH as Q_LEARNING_MAX_PARSEABLE_INPUT_LENGTH,
    MAX_RATE as Q_LEARNING_MAX_RATE,
    MAX_SCALAR as Q_LEARNING_MAX_SCALAR,
    MIN_NEXT_ACTIONS as Q_LEARNING_MIN_NEXT_ACTIONS,
    MIN_RATE as Q_LEARNING_MIN_RATE,
    MIN_SCALAR as Q_LEARNING_MIN_SCALAR,
    expected_output as q_learning_abi_oracle,
)
from single_indeterminate_operations_oracle import (
    MAX_COEFFICIENT as SINGLE_INDETERMINATE_OPERATIONS_MAX_COEFFICIENT,
    MAX_DEGREE as SINGLE_INDETERMINATE_OPERATIONS_MAX_DEGREE,
    MAX_EVALUATION_POINT as SINGLE_INDETERMINATE_OPERATIONS_MAX_EVALUATION_POINT,
    MAX_INTEGRAL_CONSTANT as SINGLE_INDETERMINATE_OPERATIONS_MAX_INTEGRAL_CONSTANT,
    MAX_OUTPUT_ELEMENTS as SINGLE_INDETERMINATE_OPERATIONS_MAX_OUTPUT_ELEMENTS,
    MAX_PARSEABLE_INPUT_LENGTH as SINGLE_INDETERMINATE_OPERATIONS_MAX_PARSEABLE_INPUT_LENGTH,
    MIN_COEFFICIENT as SINGLE_INDETERMINATE_OPERATIONS_MIN_COEFFICIENT,
    MIN_DEGREE as SINGLE_INDETERMINATE_OPERATIONS_MIN_DEGREE,
    MIN_EVALUATION_POINT as SINGLE_INDETERMINATE_OPERATIONS_MIN_EVALUATION_POINT,
    MIN_INTEGRAL_CONSTANT as SINGLE_INDETERMINATE_OPERATIONS_MIN_INTEGRAL_CONSTANT,
    OP_ADD as SINGLE_INDETERMINATE_OPERATIONS_OP_ADD,
    OP_DERIVATIVE as SINGLE_INDETERMINATE_OPERATIONS_OP_DERIVATIVE,
    OP_EVALUATE as SINGLE_INDETERMINATE_OPERATIONS_OP_EVALUATE,
    OP_INTEGRAL as SINGLE_INDETERMINATE_OPERATIONS_OP_INTEGRAL,
    OP_MULTIPLY as SINGLE_INDETERMINATE_OPERATIONS_OP_MULTIPLY,
    OP_SUBTRACT as SINGLE_INDETERMINATE_OPERATIONS_OP_SUBTRACT,
    expected_output as single_indeterminate_operations_abi_oracle,
)
from shreedharacharya_oracle import MAX_COEFFICIENT as SHREEDHARACHARYA_MAX_COEFFICIENT
from shreedharacharya_oracle import MIN_ABS_LEADING_COEFFICIENT as SHREEDHARACHARYA_MIN_ABS_A
from linear_regression_vectorized_oracle import MAX_ALPHA as LINEAR_REGRESSION_MAX_ALPHA
from linear_regression_vectorized_oracle import MAX_FEATURE_COUNT as LINEAR_REGRESSION_MAX_FEATURE_COUNT
from linear_regression_vectorized_oracle import MAX_FEATURE_OR_LABEL as LINEAR_REGRESSION_MAX_FEATURE_OR_LABEL
from linear_regression_vectorized_oracle import MAX_ITERATIONS as LINEAR_REGRESSION_MAX_ITERATIONS
from linear_regression_vectorized_oracle import MAX_SAMPLE_COUNT as LINEAR_REGRESSION_MAX_SAMPLE_COUNT
from linear_regression_vectorized_oracle import MIN_ALPHA as LINEAR_REGRESSION_MIN_ALPHA
from linear_regression_vectorized_oracle import MIN_FEATURE_COUNT as LINEAR_REGRESSION_MIN_FEATURE_COUNT
from linear_regression_vectorized_oracle import MIN_FEATURE_OR_LABEL as LINEAR_REGRESSION_MIN_FEATURE_OR_LABEL
from linear_regression_vectorized_oracle import MIN_ITERATIONS as LINEAR_REGRESSION_MIN_ITERATIONS
from linear_regression_vectorized_oracle import MIN_SAMPLE_COUNT as LINEAR_REGRESSION_MIN_SAMPLE_COUNT
from perlin_noise_oracle import INVALID_RESULT as PERLIN_NOISE_INVALID_RESULT
from perlin_noise_oracle import MAX_DIMENSION as PERLIN_NOISE_MAX_DIMENSION
from perlin_noise_oracle import MAX_OCTAVES as PERLIN_NOISE_MAX_OCTAVES
from perlin_noise_oracle import MAX_OUTPUT_ELEMENTS as PERLIN_NOISE_MAX_OUTPUT_ELEMENTS
from perlin_noise_oracle import MAX_SEED as PERLIN_NOISE_MAX_SEED
from perlin_noise_oracle import MIN_DIMENSION as PERLIN_NOISE_MIN_DIMENSION
from perlin_noise_oracle import MIN_OCTAVES as PERLIN_NOISE_MIN_OCTAVES
from perlin_noise_oracle import MIN_SEED as PERLIN_NOISE_MIN_SEED
from perlin_noise_oracle import OUTPUT_ERROR as PERLIN_NOISE_OUTPUT_ERROR
from perlin_noise_oracle import PERSISTENCE_VALUES as PERLIN_NOISE_PERSISTENCE_VALUES
from perlin_noise_oracle import expected_result as perlin_noise_oracle
from single_point_crossover_oracle import expected_abi_result as single_point_crossover_expected_abi_result
from quaternions_oracle import expected_abi_result as quaternions_expected_abi_result
from median_of_running_array_float_oracle import _as_float32 as median_float32
from mean_shift_oracle import (
    MAX_PARSEABLE_INPUT_LENGTH as MEAN_SHIFT_MAX_PARSEABLE_INPUT_LENGTH,
    WORKSPACE_ELEMENTS as MEAN_SHIFT_WORKSPACE_ELEMENTS,
    expected_output as mean_shift_oracle,
)
from local_weighted_learning_oracle import (
    ABSOLUTE_TOLERANCE as LOCAL_WEIGHTED_LEARNING_ABSOLUTE_TOLERANCE,
    INVALID_RESULT as LOCAL_WEIGHTED_LEARNING_INVALID_RESULT,
    MAX_D as LOCAL_WEIGHTED_LEARNING_MAX_D,
    MAX_N as LOCAL_WEIGHTED_LEARNING_MAX_N,
    MAX_OUTPUT_ELEMENTS as LOCAL_WEIGHTED_LEARNING_MAX_OUTPUT_ELEMENTS,
    MAX_PARSEABLE_INPUT_LENGTH as LOCAL_WEIGHTED_LEARNING_MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH as LOCAL_WEIGHTED_LEARNING_MAX_VALID_INPUT_LENGTH,
    OUTPUT_ERROR as LOCAL_WEIGHTED_LEARNING_OUTPUT_ERROR,
    RELATIVE_TOLERANCE as LOCAL_WEIGHTED_LEARNING_RELATIVE_TOLERANCE,
    expected_output as local_weighted_learning_abi_oracle,
)
from k_means_clust_oracle import (
    MAX_CLUSTER_COUNT as K_MEANS_CLUST_MAX_CLUSTER_COUNT,
    MAX_DIMENSION as K_MEANS_CLUST_MAX_DIMENSION,
    MAX_OUTPUT_ELEMENTS as K_MEANS_CLUST_MAX_OUTPUT_ELEMENTS,
    MAX_PARSEABLE_INPUT_LENGTH as K_MEANS_CLUST_MAX_PARSEABLE_INPUT_LENGTH,
    MAX_POINT_COUNT as K_MEANS_CLUST_MAX_POINT_COUNT,
    MAX_VALID_INPUT_LENGTH as K_MEANS_CLUST_MAX_VALID_INPUT_LENGTH,
    expected_output as k_means_clust_abi_oracle,
)
from lu_decompose_oracle import (
    MAX_DIMENSION as LU_DECOMPOSE_MAX_DIMENSION,
    MAX_OUTPUT_ELEMENTS as LU_DECOMPOSE_MAX_OUTPUT_ELEMENTS,
    MAX_PARSEABLE_INPUT_LENGTH as LU_DECOMPOSE_MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH as LU_DECOMPOSE_MAX_VALID_INPUT_LENGTH,
    expected_output as lu_decompose_abi_oracle,
)
from lu_elimination_oracle import (
    MAX_DIMENSION as LU_ELIMINATION_MAX_DIMENSION,
    MAX_OUTPUT_ELEMENTS as LU_ELIMINATION_MAX_OUTPUT_ELEMENTS,
    MAX_PARSEABLE_INPUT_LENGTH as LU_ELIMINATION_MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH as LU_ELIMINATION_MAX_VALID_INPUT_LENGTH,
    expected_output as lu_elimination_abi_oracle,
)
from lu_pivot_decomposition_oracle import (
    MAX_DIMENSION as LU_PIVOT_DECOMPOSITION_MAX_DIMENSION,
    MAX_OUTPUT_ELEMENTS as LU_PIVOT_DECOMPOSITION_MAX_OUTPUT_ELEMENTS,
    MAX_PARSEABLE_INPUT_LENGTH as LU_PIVOT_DECOMPOSITION_MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH as LU_PIVOT_DECOMPOSITION_MAX_VALID_INPUT_LENGTH,
    expected_output as lu_pivot_decomposition_abi_oracle,
)
from kohonen_som_trace_oracle import (
    MAX_FEATURES as KOHONEN_SOM_TRACE_MAX_FEATURES,
    MAX_NODES as KOHONEN_SOM_TRACE_MAX_NODES,
    MAX_OUTPUT_ELEMENTS as KOHONEN_SOM_TRACE_MAX_OUTPUT_ELEMENTS,
    MAX_PARSEABLE_INPUT_LENGTH as KOHONEN_SOM_TRACE_MAX_PARSEABLE_INPUT_LENGTH,
    MAX_RADIUS as KOHONEN_SOM_TRACE_MAX_RADIUS,
    MAX_VALID_INPUT_LENGTH as KOHONEN_SOM_TRACE_MAX_VALID_INPUT_LENGTH,
    expected_output as kohonen_som_trace_abi_oracle,
)
from kohonen_som_topology_oracle import (
    MAX_FEATURES as KOHONEN_SOM_TOPOLOGY_MAX_FEATURES,
    MAX_MAP_SIZE as KOHONEN_SOM_TOPOLOGY_MAX_MAP_SIZE,
    MAX_OUTPUT_ELEMENTS as KOHONEN_SOM_TOPOLOGY_MAX_OUTPUT_ELEMENTS,
    MAX_PARSEABLE_INPUT_LENGTH as KOHONEN_SOM_TOPOLOGY_MAX_PARSEABLE_INPUT_LENGTH,
    MAX_RADIUS as KOHONEN_SOM_TOPOLOGY_MAX_RADIUS,
    MAX_VALID_INPUT_LENGTH as KOHONEN_SOM_TOPOLOGY_MAX_VALID_INPUT_LENGTH,
    expected_output as kohonen_som_topology_abi_oracle,
)
from qr_decompose_oracle import (
    MAX_DIMENSION as QR_DECOMPOSE_MAX_DIMENSION,
    MAX_OUTPUT_ELEMENTS as QR_DECOMPOSE_MAX_OUTPUT_ELEMENTS,
    MAX_PARSEABLE_INPUT_LENGTH as QR_DECOMPOSE_MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH as QR_DECOMPOSE_MAX_VALID_INPUT_LENGTH,
    MAX_MATRIX_VALUE as QR_DECOMPOSE_MAX_MATRIX_VALUE,
    MIN_MATRIX_VALUE as QR_DECOMPOSE_MIN_MATRIX_VALUE,
    MIN_DIMENSION as QR_DECOMPOSE_MIN_DIMENSION,
    expected_output as qr_decompose_abi_oracle,
)
from qr_eigen_values_oracle import expected_output as qr_eigen_values_abi_verifier_oracle
from qr_decomposition_oracle import (
    MAX_DIMENSION as QR_DECOMPOSITION_MAX_DIMENSION,
    MAX_OUTPUT_ELEMENTS as QR_DECOMPOSITION_MAX_OUTPUT_ELEMENTS,
    MAX_PARSEABLE_INPUT_LENGTH as QR_DECOMPOSITION_MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH as QR_DECOMPOSITION_MAX_VALID_INPUT_LENGTH,
    MAX_MATRIX_VALUE as QR_DECOMPOSITION_MAX_MATRIX_VALUE,
    MIN_MATRIX_VALUE as QR_DECOMPOSITION_MIN_MATRIX_VALUE,
    MIN_DIMENSION as QR_DECOMPOSITION_MIN_DIMENSION,
    expected_output as qr_decomposition_abi_oracle,
)
from shuffle_oracle import (
    MAX_LENGTH as SHUFFLE_MAX_LENGTH,
    MAX_OUTPUT_ELEMENTS as SHUFFLE_MAX_OUTPUT_ELEMENTS,
    MAX_PARSEABLE_INPUT_LENGTH as SHUFFLE_MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH as SHUFFLE_MAX_VALID_INPUT_LENGTH,
    MAX_VALUE as SHUFFLE_MAX_VALUE,
    MIN_LENGTH as SHUFFLE_MIN_LENGTH,
    MIN_VALUE as SHUFFLE_MIN_VALUE,
    expected_output as shuffle_abi_oracle,
)
from spirograph_oracle import (
    ABSOLUTE_TOLERANCE as SPIROGRAPH_ABSOLUTE_TOLERANCE,
    INVALID_RESULT as SPIROGRAPH_INVALID_RESULT,
    MAX_INNER_RATIO as SPIROGRAPH_MAX_INNER_RATIO,
    MAX_MARKER_RATIO as SPIROGRAPH_MAX_MARKER_RATIO,
    MAX_OUTPUT_ELEMENTS as SPIROGRAPH_MAX_OUTPUT_ELEMENTS,
    MAX_PARSEABLE_INPUT_LENGTH as SPIROGRAPH_MAX_PARSEABLE_INPUT_LENGTH,
    MAX_POINTS as SPIROGRAPH_MAX_POINTS,
    MAX_ROTATIONS as SPIROGRAPH_MAX_ROTATIONS,
    MAX_VALID_INPUT_LENGTH as SPIROGRAPH_MAX_VALID_INPUT_LENGTH,
    MIN_INNER_RATIO as SPIROGRAPH_MIN_INNER_RATIO,
    MIN_MARKER_RATIO as SPIROGRAPH_MIN_MARKER_RATIO,
    MIN_POINTS as SPIROGRAPH_MIN_POINTS,
    MIN_ROTATIONS as SPIROGRAPH_MIN_ROTATIONS,
    OUTPUT_ERROR as SPIROGRAPH_OUTPUT_ERROR,
    RELATIVE_TOLERANCE as SPIROGRAPH_RELATIVE_TOLERANCE,
    expected_output as spirograph_abi_oracle,
)
from polynomial_regression_oracle import (
    MAX_ABSCISSA as POLYNOMIAL_REGRESSION_MAX_ABSCISSA,
    MAX_DEGREE as POLYNOMIAL_REGRESSION_MAX_DEGREE,
    MAX_PARSEABLE_INPUT_LENGTH as POLYNOMIAL_REGRESSION_MAX_PARSEABLE_INPUT_LENGTH,
    MAX_QUERY_COUNT as POLYNOMIAL_REGRESSION_MAX_QUERY_COUNT,
    MAX_RESPONSE as POLYNOMIAL_REGRESSION_MAX_RESPONSE,
    MAX_TRAINING_COUNT as POLYNOMIAL_REGRESSION_MAX_TRAINING_COUNT,
    MAX_VALID_INPUT_LENGTH as POLYNOMIAL_REGRESSION_MAX_VALID_INPUT_LENGTH,
    MIN_ABSCISSA as POLYNOMIAL_REGRESSION_MIN_ABSCISSA,
    MIN_DEGREE as POLYNOMIAL_REGRESSION_MIN_DEGREE,
    MIN_QUERY_COUNT as POLYNOMIAL_REGRESSION_MIN_QUERY_COUNT,
    MIN_RESPONSE as POLYNOMIAL_REGRESSION_MIN_RESPONSE,
    expected_output as polynomial_regression_abi_oracle,
)
from soboleva_modified_hyperbolic_tangent_oracle import expected_output as soboleva_modified_hyperbolic_tangent_abi_oracle
from soboleva_modified_hyperbolic_tangent_oracle import INVALID_RESULT as SOBOLEVA_MODIFIED_HYPERBOLIC_TANGENT_INVALID_RESULT
from momentum_sgd_oracle import (
    MAX_CALL_COUNT as MOMENTUM_SGD_MAX_CALL_COUNT,
    MAX_GROUP_COUNT as MOMENTUM_SGD_MAX_GROUP_COUNT,
    MAX_GROUP_VECTOR_ELEMENTS as MOMENTUM_SGD_MAX_GROUP_VECTOR_ELEMENTS,
    MAX_GRADIENT as MOMENTUM_SGD_MAX_GRADIENT,
    MAX_LEARNING_RATE as MOMENTUM_SGD_MAX_LEARNING_RATE,
    MAX_MOMENTUM as MOMENTUM_SGD_MAX_MOMENTUM,
    MAX_OUTPUT_ELEMENTS as MOMENTUM_SGD_MAX_OUTPUT_ELEMENTS,
    MAX_PARAMETER as MOMENTUM_SGD_MAX_PARAMETER,
    MAX_VECTOR_LENGTH as MOMENTUM_SGD_MAX_VECTOR_LENGTH,
    MIN_CALL_COUNT as MOMENTUM_SGD_MIN_CALL_COUNT,
    MIN_GROUP_COUNT as MOMENTUM_SGD_MIN_GROUP_COUNT,
    MIN_GRADIENT as MOMENTUM_SGD_MIN_GRADIENT,
    MIN_LEARNING_RATE as MOMENTUM_SGD_MIN_LEARNING_RATE,
    MIN_MOMENTUM as MOMENTUM_SGD_MIN_MOMENTUM,
    MIN_PARAMETER as MOMENTUM_SGD_MIN_PARAMETER,
    MIN_VECTOR_LENGTH as MOMENTUM_SGD_MIN_VECTOR_LENGTH,
    expected_output as momentum_sgd_abi_oracle,
)
from sherman_morrison_oracle import expected_output as sherman_morrison_abi_oracle
from linearregressionrawr_oracle import expected_output as linearregressionrawr_abi_oracle
from decision_tree_python_regression_oracle import (
    INVALID_RESULT as DECISION_TREE_INVALID_RESULT,
    MAX_DEPTH as DECISION_TREE_MAX_DEPTH,
    MAX_INPUT_LENGTH as DECISION_TREE_MAX_INPUT_LENGTH,
    MAX_LEAF_SIZE as DECISION_TREE_MAX_LEAF_SIZE,
    MAX_OUTPUT_LENGTH as DECISION_TREE_MAX_OUTPUT_LENGTH,
    MAX_PARSEABLE_INPUT_LENGTH as DECISION_TREE_MAX_PARSEABLE_INPUT_LENGTH,
    MAX_QUERY_COUNT as DECISION_TREE_MAX_QUERY_COUNT,
    MAX_SAMPLE_COUNT as DECISION_TREE_MAX_SAMPLE_COUNT,
    MAX_VALUE as DECISION_TREE_MAX_VALUE,
    MIN_DEPTH as DECISION_TREE_MIN_DEPTH,
    MIN_LEAF_SIZE as DECISION_TREE_MIN_LEAF_SIZE,
    MIN_QUERY_COUNT as DECISION_TREE_MIN_QUERY_COUNT,
    MIN_SAMPLE_COUNT as DECISION_TREE_MIN_SAMPLE_COUNT,
    MIN_VALUE as DECISION_TREE_MIN_VALUE,
    OUTPUT_ERROR as DECISION_TREE_OUTPUT_ERROR,
    expected_output as decision_tree_python_regression_abi_verifier_oracle,
)
from perceptron_java_oracle import (
    INVALID_RESULT as PERCEPTRON_JAVA_INVALID_RESULT,
    MAX_FEATURES as PERCEPTRON_JAVA_MAX_FEATURES,
    MAX_INPUT_LENGTH as PERCEPTRON_JAVA_MAX_INPUT_LENGTH,
    MAX_OUTPUT_LENGTH as PERCEPTRON_JAVA_MAX_OUTPUT_LENGTH,
    MAX_PARSEABLE_INPUT_LENGTH as PERCEPTRON_JAVA_MAX_PARSEABLE_INPUT_LENGTH,
    MAX_QUERIES as PERCEPTRON_JAVA_MAX_QUERIES,
    MAX_SAMPLES as PERCEPTRON_JAVA_MAX_SAMPLES,
    OUTPUT_ERROR as PERCEPTRON_JAVA_OUTPUT_ERROR,
    expected_output as perceptron_java_abi_verifier_oracle,
)
from perceptron_python_oracle import (
    INVALID_RESULT as PERCEPTRON_PYTHON_INVALID_RESULT,
    MAX_FEATURES as PERCEPTRON_PYTHON_MAX_FEATURES,
    MAX_INPUT_LENGTH as PERCEPTRON_PYTHON_MAX_INPUT_LENGTH,
    MAX_OUTPUT_LENGTH as PERCEPTRON_PYTHON_MAX_OUTPUT_LENGTH,
    MAX_PARSEABLE_INPUT_LENGTH as PERCEPTRON_PYTHON_MAX_PARSEABLE_INPUT_LENGTH,
    MAX_QUERIES as PERCEPTRON_PYTHON_MAX_QUERIES,
    MAX_SAMPLES as PERCEPTRON_PYTHON_MAX_SAMPLES,
    OUTPUT_ERROR as PERCEPTRON_PYTHON_OUTPUT_ERROR,
    expected_output as perceptron_python_abi_verifier_oracle,
)
from perceptron_r_oracle import (
    INVALID_RESULT as PERCEPTRON_R_INVALID_RESULT,
    MAX_FEATURES as PERCEPTRON_R_MAX_FEATURES,
    MAX_INPUT_LENGTH as PERCEPTRON_R_MAX_INPUT_LENGTH,
    MAX_OUTPUT_LENGTH as PERCEPTRON_R_MAX_OUTPUT_LENGTH,
    MAX_PARSEABLE_INPUT_LENGTH as PERCEPTRON_R_MAX_PARSEABLE_INPUT_LENGTH,
    MAX_QUERIES as PERCEPTRON_R_MAX_QUERIES,
    MAX_SAMPLES as PERCEPTRON_R_MAX_SAMPLES,
    OUTPUT_ERROR as PERCEPTRON_R_OUTPUT_ERROR,
    expected_output as perceptron_r_abi_verifier_oracle,
)
from perceptron_rust_oracle import (
    INVALID_RESULT as PERCEPTRON_RUST_INVALID_RESULT,
    MAX_FEATURES as PERCEPTRON_RUST_MAX_FEATURES,
    MAX_INPUT_LENGTH as PERCEPTRON_RUST_MAX_INPUT_LENGTH,
    MAX_OUTPUT_LENGTH as PERCEPTRON_RUST_MAX_OUTPUT_LENGTH,
    MAX_PARSEABLE_INPUT_LENGTH as PERCEPTRON_RUST_MAX_PARSEABLE_INPUT_LENGTH,
    MAX_QUERIES as PERCEPTRON_RUST_MAX_QUERIES,
    MAX_SAMPLES as PERCEPTRON_RUST_MAX_SAMPLES,
    OUTPUT_ERROR as PERCEPTRON_RUST_OUTPUT_ERROR,
    expected_output as perceptron_rust_abi_verifier_oracle,
)

ALGORITHMS = tuple(ORACLES)


def tsvc_s313_verifier_oracle(values, capacity=1, output_is_null=False,
                              input_is_null=False, input_length=None):
    """Independent direct dot-product reference for the bounded TSVC s313 profile."""
    if (input_is_null or not isinstance(values, (list, tuple))
            or input_length is not None and input_length != len(values)
            or len(values) < 3 or len(values) > 129):
        return -1, []
    n_value = values[0]
    if (type(n_value) not in (int, float) or not math.isfinite(float(n_value))
            or float(n_value).is_integer() is False or not 1 <= n_value <= 64):
        return -1, []
    n = int(n_value)
    if len(values) != 1 + 2 * n:
        return -1, []
    if any(type(value) not in (int, float) or not math.isfinite(float(value))
           or not float(value).is_integer() or abs(float(value)) > 1000
           for value in values[1:]):
        return -1, []
    if type(capacity) is not int or capacity < 0:
        return -1, []
    if output_is_null or capacity < 1:
        return -2, []
    first = values[1:1 + n]
    second = values[1 + n:]
    result = 0.0
    for left, right in zip(first, second):
        result = result + float(left) * float(right)
    return 1, [result]


def tsvc_s275_verifier_oracle(values, capacity=64, output_is_null=False,
                              input_is_null=False, input_length=None):
    """Independent bounded model of s275's guarded column-wise recurrence."""
    if (input_is_null or not isinstance(values, (tuple, list))
            or input_length is not None and input_length != len(values)
            or len(values) < 2 or len(values) > 193):
        return -1, []
    n_value = values[0]
    if (type(n_value) not in (int, float) or not math.isfinite(float(n_value))
            or not float(n_value).is_integer() or not 1 <= n_value <= 8):
        return -1, []
    n = int(n_value)
    cell_count = n * n
    if len(values) != 1 + 3 * cell_count:
        return -1, []
    operands = values[1:]
    if any(type(value) not in (int, float) or not math.isfinite(float(value))
           or not float(value).is_integer() or abs(float(value)) > 16 for value in operands):
        return -1, []
    if type(capacity) is not int or capacity < 0:
        return -1, []
    if output_is_null or capacity < cell_count:
        return -2, []
    a = [float(value) for value in operands[:cell_count]]
    b = operands[cell_count:2 * cell_count]
    c = operands[2 * cell_count:]
    # Build each column's row recurrence explicitly from the prior row value.
    for column in range(n):
        guard = a[column]
        if guard <= 0:
            continue
        previous = guard
        for row in range(1, n):
            index = row * n + column
            current = previous + float(b[index]) * float(c[index])
            a[index] = current
            previous = current
    return cell_count, a


def tsvc_s111_verifier_oracle(values, capacity=64, output_is_null=False,
                              input_is_null=False, input_length=None):
    """Independent direct model of s111's odd-position writes."""
    if (input_is_null or not isinstance(values, (tuple, list))
            or input_length is not None and input_length != len(values)
            or len(values) < 3 or len(values) > 129):
        return -1, []
    n_value = values[0]
    if (type(n_value) not in (int, float) or not math.isfinite(float(n_value))
            or not float(n_value).is_integer() or not 1 <= n_value <= 64):
        return -1, []
    n = int(n_value)
    if len(values) != 1 + 2 * n:
        return -1, []
    data = values[1:]
    if any(type(value) not in (int, float) or not math.isfinite(float(value))
           or not float(value).is_integer() or abs(float(value)) > 1000 for value in data):
        return -1, []
    if type(capacity) is not int or capacity < 0:
        return -1, []
    if output_is_null or capacity < n:
        return -2, []
    result = [float(value) for value in data[:n]]
    b = data[n:]
    for destination in range(1, n, 2):
        result[destination] = float(data[destination - 1]) + float(b[destination])
    return n, result


def tsvc_s2251_verifier_oracle(values, capacity=128, output_is_null=False,
                               input_is_null=False, input_length=None):
    """Independent recurrence model of TSVC s2251's carried scalar."""
    if (input_is_null or not isinstance(values, (tuple, list))
            or input_length is not None and input_length != len(values)
            or len(values) < 6 or len(values) > 321):
        return -1, []
    raw_n = values[0]
    if (type(raw_n) not in (int, float) or not math.isfinite(float(raw_n))
            or not float(raw_n).is_integer() or not 1 <= raw_n <= 64):
        return -1, []
    n = int(raw_n)
    if len(values) != 1 + 5*n:
        return -1, []
    data = values[1:]
    if any(type(v) not in (int, float) or not math.isfinite(float(v))
           or not float(v).is_integer() or abs(float(v)) > 1 for v in data):
        return -1, []
    if type(capacity) is not int or capacity < 0:
        return -1, []
    if output_is_null or capacity < 2*n:
        return -2, []
    _, old_b, c_values, d_values, e_values = (data[i*n:(i+1)*n] for i in range(5))
    final_a = []
    final_b = []
    scalar = 0.0
    for i in range(n):
        current_a = scalar * float(e_values[i])
        scalar = float(old_b[i]) + float(c_values[i])
        current_b = current_a + float(d_values[i])
        final_a.append(current_a)
        final_b.append(current_b)
        old_b[i] = current_b
    return 2*n, final_a + final_b


def tsvc_s1251_verifier_oracle(values, capacity=128, output_is_null=False,
                               input_is_null=False, input_length=None):
    """Independent per-position model of s1251's saved sum and dual update."""
    if (input_is_null or not isinstance(values, (tuple, list))
            or input_length is not None and input_length != len(values)
            or len(values) < 6 or len(values) > 321):
        return -1, []
    raw_n = values[0]
    if (type(raw_n) not in (int, float) or not math.isfinite(float(raw_n))
            or not float(raw_n).is_integer() or not 1 <= raw_n <= 64):
        return -1, []
    n = int(raw_n)
    if len(values) != 1 + 5*n:
        return -1, []
    data = values[1:]
    if any(type(v) not in (int, float) or not math.isfinite(float(v))
           or not float(v).is_integer() or abs(float(v)) > 1 for v in data):
        return -1, []
    if type(capacity) is not int or capacity < 0:
        return -1, []
    if output_is_null or capacity < 2*n:
        return -2, []
    a, b, c_values, d_values, e_values = ([float(v) for v in data[i*n:(i+1)*n]
                                           ] for i in range(5))
    for i in range(n):
        old_sum = b[i] + c_values[i]
        replacement_b = a[i] + d_values[i]
        replacement_a = old_sum * e_values[i]
        b[i] = replacement_b
        a[i] = replacement_a
    return 2*n, a + b


def tsvc_s3251_verifier_oracle(values, capacity=192, output_is_null=False,
                               input_is_null=False, input_length=None):
    """Independent forward-dependency model of Expansion s3251."""
    if (input_is_null or not isinstance(values, (tuple, list))
            or input_length is not None and input_length != len(values)
            or len(values) < 6 or len(values) > 321):
        return -1, []
    raw_n = values[0]
    if (type(raw_n) not in (int, float) or not math.isfinite(float(raw_n))
            or not float(raw_n).is_integer() or not 1 <= raw_n <= 64):
        return -1, []
    n = int(raw_n)
    if len(values) != 1 + 5*n:
        return -1, []
    data = values[1:]
    if any(type(v) not in (int, float) or not math.isfinite(float(v))
           or not float(v).is_integer() or abs(float(v)) > 1 for v in data):
        return -1, []
    if type(capacity) is not int or capacity < 0:
        return -1, []
    if output_is_null or capacity < 3*n:
        return -2, []
    block = [[float(v) for v in data[j*n:(j+1)*n]] for j in range(5)]
    aa, bb, cc, dd, ee = block
    for index in range(n-1):
        next_a = bb[index] + cc[index]
        aa[index+1] = next_a
        bb[index] = cc[index] * ee[index]
        dd[index] = aa[index] * ee[index]
    return 3*n, aa + bb + dd


def tsvc_s2712_verifier_oracle(values, capacity=64, output_is_null=False,
                               input_is_null=False, input_length=None):
    """Independent repeated thresholded update model of TSVC s2712."""
    if (input_is_null or not isinstance(values, (tuple, list))
            or input_length is not None and input_length != len(values)
            or len(values) < 5 or len(values) > 194):
        return -1, []
    n_raw, pass_raw = values[0], values[1]
    if (type(n_raw) not in (int, float) or not math.isfinite(float(n_raw))
            or not float(n_raw).is_integer() or not 1 <= n_raw <= 64
            or type(pass_raw) not in (int, float) or not math.isfinite(float(pass_raw))
            or not float(pass_raw).is_integer() or not 1 <= pass_raw <= 8):
        return -1, []
    n, passes = int(n_raw), int(pass_raw)
    if len(values) != 2 + 3*n:
        return -1, []
    data = values[2:]
    if any(type(v) not in (int, float) or not math.isfinite(float(v))
           or not float(v).is_integer() or abs(float(v)) > 2 for v in data):
        return -1, []
    if type(capacity) is not int or capacity < 0:
        return -1, []
    if output_is_null or capacity < n:
        return -2, []
    a = [float(v) for v in data[:n]]
    b = [float(v) for v in data[n:2*n]]
    c = [float(v) for v in data[2*n:]]
    for _ in range(passes):
        for i in range(n):
            if a[i] > b[i]:
                a[i] = a[i] + b[i]*c[i]
    return n, a


def tsvc_s2710_verifier_oracle(values, capacity=192, output_is_null=False,
                               input_is_null=False, input_length=None):
    """Independent model of s2710's vector comparison and scalar C branch."""
    if (input_is_null or not isinstance(values, (tuple, list))
            or input_length is not None and input_length != len(values)
            or len(values) < 58 or len(values) > 323):
        return -1, []
    raw_n, raw_passes, raw_scalar = values[:3]
    if (type(raw_n) not in (int, float) or not math.isfinite(float(raw_n))
            or not float(raw_n).is_integer() or not 11 <= raw_n <= 64
            or type(raw_passes) not in (int, float) or not math.isfinite(float(raw_passes))
            or not float(raw_passes).is_integer() or not 1 <= raw_passes <= 8
            or type(raw_scalar) not in (int, float) or not math.isfinite(float(raw_scalar))
            or not float(raw_scalar).is_integer() or abs(float(raw_scalar)) > 1):
        return -1, []
    n, passes, scalar = int(raw_n), int(raw_passes), float(raw_scalar)
    if len(values) != 3 + 5*n:
        return -1, []
    body = values[3:]
    if any(type(v) not in (int, float) or not math.isfinite(float(v))
           or not float(v).is_integer() or abs(float(v)) > 1 for v in body):
        return -1, []
    if type(capacity) is not int or capacity < 0:
        return -1, []
    if output_is_null or capacity < 3*n:
        return -2, []
    arrays = [[float(v) for v in body[j*n:(j+1)*n]] for j in range(5)]
    a, b, c, d, e = arrays
    for _ in range(passes):
        for index in range(n):
            if a[index] > b[index]:
                a[index] = a[index] + b[index]*d[index]
                c[index] = c[index] + d[index]*d[index]
            else:
                b[index] = a[index] + e[index]*e[index]
                if scalar > 0:
                    c[index] = a[index] + d[index]*d[index]
                else:
                    c[index] = c[index] + e[index]*e[index]
    return 3*n, a + b + c


def tsvc_s1279_verifier_oracle(values, capacity=64, output_is_null=False,
                               input_is_null=False, input_length=None):
    """Independent s1279 model, retaining both strict nested predicates."""
    if (input_is_null or not isinstance(values, (tuple, list))
            or input_length is not None and input_length != len(values)
            or len(values) < 7 or len(values) > 322):
        return -1, []
    raw_n, raw_passes = values[:2]
    if (type(raw_n) not in (int, float) or not math.isfinite(float(raw_n))
            or not float(raw_n).is_integer() or not 1 <= raw_n <= 64
            or type(raw_passes) not in (int, float) or not math.isfinite(float(raw_passes))
            or not float(raw_passes).is_integer() or not 1 <= raw_passes <= 8):
        return -1, []
    n, passes = int(raw_n), int(raw_passes)
    if len(values) != 2 + 5*n:
        return -1, []
    payload = values[2:]
    if any(type(v) not in (int, float) or not math.isfinite(float(v))
           or not float(v).is_integer() or abs(float(v)) > 1 for v in payload):
        return -1, []
    if type(capacity) is not int or capacity < 0:
        return -1, []
    if output_is_null or capacity < n:
        return -2, []
    a = [float(v) for v in payload[:n]]
    b = [float(v) for v in payload[n:2*n]]
    c = [float(v) for v in payload[2*n:3*n]]
    d = [float(v) for v in payload[3*n:4*n]]
    e = [float(v) for v in payload[4*n:5*n]]
    for _ in range(passes):
        for i in range(n):
            if a[i] < 0:
                if b[i] > a[i]:
                    c[i] += d[i] * e[i]
    return n, c


def tsvc_s2275_verifier_oracle(values, capacity=72, output_is_null=False,
                               input_is_null=False, input_length=None):
    """Independent model of s2275's matrix column sweep and vector overwrite."""
    if (input_is_null or not isinstance(values, (tuple, list))
            or input_length is not None and input_length != len(values)
            or len(values) < 9 or len(values) > 226):
        return -1, []
    raw_n, raw_passes = values[:2]
    if (type(raw_n) not in (int, float) or not math.isfinite(float(raw_n))
            or not float(raw_n).is_integer() or not 1 <= raw_n <= 8
            or type(raw_passes) not in (int, float) or not math.isfinite(float(raw_passes))
            or not float(raw_passes).is_integer() or not 1 <= raw_passes <= 8):
        return -1, []
    n, passes = int(raw_n), int(raw_passes)
    if len(values) != 2 + 3*n*n + 4*n:
        return -1, []
    payload = values[2:]
    if any(type(v) not in (int, float) or not math.isfinite(float(v))
           or not float(v).is_integer() or abs(float(v)) > 1 for v in payload):
        return -1, []
    out_count = n*n+n
    if type(capacity) is not int or capacity < 0:
        return -1, []
    if output_is_null or capacity < out_count:
        return -2, []
    mat = n*n
    aa = [float(v) for v in payload[:mat]]
    bb = [float(v) for v in payload[mat:2*mat]]
    cc = [float(v) for v in payload[2*mat:3*mat]]
    pos = 3*mat
    a = [float(v) for v in payload[pos:pos+n]]
    b = [float(v) for v in payload[pos+n:pos+2*n]]
    c = [float(v) for v in payload[pos+2*n:pos+3*n]]
    d = [float(v) for v in payload[pos+3*n:pos+4*n]]
    for _ in range(passes):
        for col in range(n):
            for row in range(n):
                cell = row*n+col
                aa[cell] = aa[cell] + bb[cell]*cc[cell]
            a[col] = b[col] + c[col]*d[col]
    return out_count, aa+a


def tsvc_s482_verifier_oracle(values, capacity=64, output_is_null=False,
                              input_is_null=False, input_length=None):
    """Independent model of s482's update-before-strict-break control flow."""
    if (input_is_null or not isinstance(values, (tuple, list))
            or input_length is not None and input_length != len(values)
            or len(values) < 5 or len(values) > 194):
        return -1, []
    raw_n, raw_passes = values[:2]
    if (type(raw_n) not in (int, float) or not math.isfinite(float(raw_n))
            or not float(raw_n).is_integer() or not 1 <= raw_n <= 64
            or type(raw_passes) not in (int, float) or not math.isfinite(float(raw_passes))
            or not float(raw_passes).is_integer() or not 1 <= raw_passes <= 8):
        return -1, []
    n, passes = int(raw_n), int(raw_passes)
    if len(values) != 2 + 3*n:
        return -1, []
    payload = values[2:]
    if any(type(v) not in (int, float) or not math.isfinite(float(v))
           or not float(v).is_integer() or abs(float(v)) > 1 for v in payload):
        return -1, []
    if type(capacity) is not int or capacity < 0:
        return -1, []
    if output_is_null or capacity < n:
        return -2, []
    a = [float(v) for v in payload[:n]]
    b = [float(v) for v in payload[n:2*n]]
    c = [float(v) for v in payload[2*n:3*n]]
    for _ in range(passes):
        for index in range(n):
            a[index] = a[index] + b[index]*c[index]
            if c[index] > b[index]:
                break
    return n, a


def tsvc_s441_s443_verifier_oracle(values, capacity=64, output_is_null=False,
                                   input_is_null=False, input_length=None):
    """Independent mode model for the D-sign branch formulas in s441/s443."""
    if (input_is_null or not isinstance(values, (tuple, list))
            or input_length is not None and input_length != len(values)
            or len(values) < 7 or len(values) > 259):
        return -1, []
    raw_mode, raw_n, raw_passes = values[:3]
    if (type(raw_mode) not in (int, float) or not math.isfinite(float(raw_mode))
            or not float(raw_mode).is_integer() or raw_mode not in (0, 1)
            or type(raw_n) not in (int, float) or not math.isfinite(float(raw_n))
            or not float(raw_n).is_integer() or not 1 <= raw_n <= 64
            or type(raw_passes) not in (int, float) or not math.isfinite(float(raw_passes))
            or not float(raw_passes).is_integer() or not 1 <= raw_passes <= 8):
        return -1, []
    mode, n, passes = int(raw_mode), int(raw_n), int(raw_passes)
    if len(values) != 3 + 4*n:
        return -1, []
    data = values[3:]
    if any(type(v) not in (int, float) or not math.isfinite(float(v))
           or not float(v).is_integer() or abs(float(v)) > 1 for v in data):
        return -1, []
    if type(capacity) is not int or capacity < 0:
        return -1, []
    if output_is_null or capacity < n:
        return -2, []
    a = [float(v) for v in data[:n]]
    b = [float(v) for v in data[n:2*n]]
    c = [float(v) for v in data[2*n:3*n]]
    d = [float(v) for v in data[3*n:4*n]]
    for _ in range(passes):
        for i in range(n):
            if mode == 0:
                if d[i] < 0.0:
                    a[i] = a[i] + b[i]*c[i]
                elif d[i] == 0.0:
                    a[i] = a[i] + b[i]*b[i]
                else:
                    a[i] = a[i] + c[i]*c[i]
            else:
                if d[i] <= 0.0:
                    a[i] = a[i] + b[i]*c[i]
                else:
                    a[i] = a[i] + b[i]*b[i]
    return n, a


def tsvc_s242_verifier_oracle(values, capacity=64, output_is_null=False,
                              input_is_null=False, input_length=None):
    """Independent left-to-right model of s242's fused prefix recurrence."""
    if (input_is_null or not isinstance(values, (tuple, list))
            or input_length is not None and input_length != len(values)
            or len(values) < 7 or len(values) > 259):
        return -1, []
    raw_n = values[0]
    if (type(raw_n) not in (int, float) or not math.isfinite(float(raw_n))
            or not float(raw_n).is_integer() or not 1 <= raw_n <= 64):
        return -1, []
    n = int(raw_n)
    if len(values) != 3 + 4*n:
        return -1, []
    if any(type(v) not in (int, float) or not math.isfinite(float(v))
           or not float(v).is_integer() or abs(float(v)) > 1 for v in values[1:]):
        return -1, []
    if type(capacity) is not int or capacity < 0:
        return -1, []
    if output_is_null or capacity < n:
        return -2, []
    s1, s2 = float(values[1]), float(values[2])
    a = [float(v) for v in values[3:3+n]]
    b = values[3+n:3+2*n]
    c = values[3+2*n:3+3*n]
    d = values[3+3*n:3+4*n]
    for i in range(1, n):
        accumulated = a[i-1] + s1
        accumulated += s2
        accumulated += float(b[i])
        accumulated += float(c[i])
        accumulated += float(d[i])
        a[i] = accumulated
    return n, a


def tsvc_s351_verifier_oracle(values, capacity=40, output_is_null=False,
                              input_is_null=False, input_length=None):
    """Independent model of the five-lane direct SAXPY update order."""
    if (input_is_null or not isinstance(values, (tuple, list))
            or input_length is not None and input_length != len(values)
            or len(values) < 12 or len(values) > 82):
        return -1, []
    raw_n = values[0]
    if (type(raw_n) not in (int, float) or not math.isfinite(float(raw_n))
            or not float(raw_n).is_integer() or not 5 <= raw_n <= 40):
        return -1, []
    n = int(raw_n)
    if n % 5 or len(values) != 2 + 2*n:
        return -1, []
    if any(type(v) not in (int, float) or not math.isfinite(float(v))
           or not float(v).is_integer() or abs(float(v)) > 1 for v in values[1:]):
        return -1, []
    if type(capacity) is not int or capacity < 0:
        return -1, []
    if output_is_null or capacity < n:
        return -2, []
    alpha = float(values[1])
    a = [float(v) for v in values[2:2+n]]
    b = values[2+n:]
    for start in range(0, n, 5):
        lanes = range(start, start + 5)
        for i in lanes:
            contribution = alpha * float(b[i])
            a[i] += contribution
    return n, a


def tsvc_vtvtv_verifier_oracle(values, capacity=64, output_is_null=False,
                               input_is_null=False, input_length=None):
    """Independent bounded model of the left-associative TSVC vtvtv map."""
    if (input_is_null or not isinstance(values, (tuple, list))
            or input_length is not None and input_length != len(values)
            or len(values) < 4 or len(values) > 193):
        return -1, []
    raw_n = values[0]
    if (type(raw_n) not in (int, float) or not math.isfinite(float(raw_n))
            or not float(raw_n).is_integer() or not 1 <= raw_n <= 64):
        return -1, []
    n = int(raw_n)
    if len(values) != 1 + 3*n:
        return -1, []
    data = values[1:]
    if any(type(v) not in (int, float) or not math.isfinite(float(v))
           or not float(v).is_integer() or abs(float(v)) > 2 for v in data):
        return -1, []
    if type(capacity) is not int or capacity < 0:
        return -1, []
    if output_is_null or capacity < n:
        return -2, []
    a, b, c = data[:n], data[n:2*n], data[2*n:]
    result = []
    for i in range(n):
        first_product = float(a[i]) * float(b[i])
        result.append(first_product * float(c[i]))
    return n, result


def tsvc_s451_verifier_oracle(values, capacity=64, output_is_null=False,
                              input_is_null=False, input_length=None):
    """Independent binary64 model of s451's pointwise sin-plus-cos operation."""
    if (input_is_null or not isinstance(values, (tuple, list))
            or input_length is not None and input_length != len(values)
            or len(values) < 3 or len(values) > 129):
        return -1, []
    raw_n = values[0]
    if (type(raw_n) not in (int, float) or not math.isfinite(float(raw_n))
            or not float(raw_n).is_integer() or not 1 <= raw_n <= 64):
        return -1, []
    n = int(raw_n)
    if len(values) != 1 + 2*n:
        return -1, []
    operands = values[1:]
    if any(type(v) not in (int, float) or not math.isfinite(float(v))
           or abs(float(v)) > 10 for v in operands):
        return -1, []
    if type(capacity) is not int or capacity < 0:
        return -1, []
    if output_is_null or capacity < n:
        return -2, []
    b, c = operands[:n], operands[n:]
    result = []
    for i in range(n):
        sine_value = math.sin(float(b[i]))
        cosine_value = math.cos(float(c[i]))
        result.append(sine_value + cosine_value)
    return n, result


def tsvc_s221_verifier_oracle(values, capacity=128, output_is_null=False,
                              input_is_null=False, input_length=None):
    """Independent source-order model of s221's A update and B recurrence."""
    if (input_is_null or not isinstance(values, (list, tuple))
            or input_length is not None and input_length != len(values)
            or len(values) < 5 or len(values) > 257):
        return -1, []
    raw_n = values[0]
    if (type(raw_n) not in (int, float) or not math.isfinite(float(raw_n))
            or not float(raw_n).is_integer() or not 1 <= raw_n <= 64):
        return -1, []
    n = int(raw_n)
    if len(values) != 1 + 4*n:
        return -1, []
    operands = values[1:]
    if any(type(v) not in (int, float) or not math.isfinite(float(v))
           or not float(v).is_integer() or abs(float(v)) > 2 for v in operands):
        return -1, []
    if type(capacity) is not int or capacity < 0:
        return -1, []
    required = 2*n
    if output_is_null or capacity < required:
        return -2, []
    a = [float(v) for v in operands[:n]]
    b = [float(v) for v in operands[n:2*n]]
    c = operands[2*n:3*n]
    d = operands[3*n:]
    for i in range(1, n):
        updated_a = a[i] + float(c[i]) * float(d[i])
        a[i] = updated_a
        updated_b = b[i-1] + updated_a
        b[i] = updated_b + float(d[i])
    return required, a + b


def tsvc_s222_verifier_oracle(values, capacity=128, output_is_null=False,
                              input_is_null=False, input_length=None):
    """Independently evaluate the s222 interleaved statements and E recurrence."""
    if (input_is_null or not isinstance(values, (list, tuple))
            or input_length is not None and input_length != len(values)
            or len(values) < 5 or len(values) > 257):
        return -1, []
    raw_n=values[0]
    if (type(raw_n) not in (int, float) or not math.isfinite(float(raw_n))
            or not float(raw_n).is_integer() or not 1 <= raw_n <= 64):
        return -1, []
    n=int(raw_n)
    if len(values) != 1+4*n:
        return -1, []
    a=[float(x) for x in values[1:1+n]]
    b=[float(x) for x in values[1+n:1+2*n]]
    c=[float(x) for x in values[1+2*n:1+3*n]]
    e=[float(x) for x in values[1+3*n:]]
    if (any(not math.isfinite(x) or not x.is_integer() or abs(x)>2 for x in a+b+c)
            or any(not math.isfinite(x) or x not in {-1.0,-0.5,0.0,0.5,1.0} for x in e)):
        return -1, []
    if type(capacity) is not int or capacity < 0:
        return -1, []
    required=2*n
    if output_is_null or capacity<required:
        return -2, []
    for i in range(1,n):
        t=b[i]*c[i]
        a[i]=a[i]+t
        e[i]=e[i-1]*e[i-1]
        a[i]=a[i]-t
    return required,a+e


def trmm_verifier_oracle(values, capacity=None, output_is_null=False,
                         input_is_null=False, input_length=None):
    """Independent source-order reference for bounded PolyBench TRMM."""
    if (not isinstance(values, (list, tuple))
            or len(values) > TRMM_MAX_INPUT_LENGTH
            or any(type(value) not in (int, float) or not math.isfinite(float(value))
                   for value in values)
            or type(output_is_null) is not bool or type(input_is_null) is not bool
            or (input_is_null and (values or input_length not in (None, 0)))
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return TRMM_INVALID_RESULT, []
    if len(values) != TRMM_MAX_INPUT_LENGTH:
        return TRMM_INVALID_RESULT, []
    dimensions = []
    for value in values:
        numeric = float(value)
        if numeric != math.trunc(numeric) or not 1 <= numeric <= TRMM_MAX_DIM:
            return TRMM_INVALID_RESULT, []
        dimensions.append(int(numeric))
    m, n = dimensions
    required = m * n
    if output_is_null or (capacity is not None and capacity < required):
        return TRMM_OUTPUT_ERROR, []

    alpha = 1.5
    a = [[0.0] * m for _ in range(m)]
    b = [[0.0] * n for _ in range(m)]
    for i in range(m):
        for j in range(i):
            a[i][j] = float((i + j) % m) / float(m)
        a[i][i] = 1.0
        for j in range(n):
            b[i][j] = float((n + i - j) % n) / float(n)
    for i in range(m):
        for j in range(n):
            for k in range(i + 1, m):
                b[i][j] += a[k][i] * b[k][j]
            b[i][j] = alpha * b[i][j]
    output = [b[i][j] for i in range(m) for j in range(n)]
    return len(output), output


def fdtd_2d_verifier_oracle(values, capacity=None, output_is_null=False,
                            input_is_null=False, input_length=None):
    """Independent source-order reference for bounded PolyBench FDTD 2D."""
    if (not isinstance(values, (list, tuple))
            or len(values) > FDTD_2D_MAX_INPUT_LENGTH
            or any(type(value) not in (int, float) or not math.isfinite(float(value))
                   for value in values)
            or type(output_is_null) is not bool or type(input_is_null) is not bool
            or (input_is_null and values)
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return -1, []
    if input_is_null or len(values) != FDTD_2D_MAX_INPUT_LENGTH:
        return -1, []
    dimensions = []
    for value in values:
        numeric = float(value)
        if numeric != math.trunc(numeric):
            return -1, []
        dimensions.append(int(numeric))
    tmax, nx, ny = dimensions
    if not (0 <= tmax <= FDTD_2D_MAX_TMAX
            and 1 <= nx <= FDTD_2D_MAX_NX
            and 1 <= ny <= FDTD_2D_MAX_NY):
        return -1, []
    required = 3 * nx * ny
    if output_is_null or (capacity is not None and capacity < required):
        return -2, []

    fict = [float(t) for t in range(tmax)]
    ex = [[float(i * (j + 1)) / float(nx) for j in range(ny)] for i in range(nx)]
    ey = [[float(i * (j + 2)) / float(ny) for j in range(ny)] for i in range(nx)]
    hz = [[float(i * (j + 3)) / float(nx) for j in range(ny)] for i in range(nx)]
    for t in range(tmax):
        for j in range(ny):
            ey[0][j] = fict[t]
        for i in range(1, nx):
            for j in range(ny):
                ey[i][j] = ey[i][j] - 0.5 * (hz[i][j] - hz[i - 1][j])
        for i in range(nx):
            for j in range(1, ny):
                ex[i][j] = ex[i][j] - 0.5 * (hz[i][j] - hz[i][j - 1])
        for i in range(nx - 1):
            for j in range(ny - 1):
                delta = (ex[i][j + 1] - ex[i][j]) + (ey[i + 1][j] - ey[i][j])
                hz[i][j] = hz[i][j] - 0.7 * delta
    output = [value for matrix in (ex, ey, hz) for row in matrix for value in row]
    return len(output), output


def heat_3d_verifier_oracle(values, capacity=None, output_is_null=False,
                            input_is_null=False, input_length=None):
    """Independent source-order reference for bounded PolyBench heat-3d."""
    if (not isinstance(values, (list, tuple))
            or len(values) > HEAT_3D_MAX_INPUT_LENGTH
            or any(type(value) not in (int, float) or not math.isfinite(float(value))
                   for value in values)
            or type(output_is_null) is not bool or type(input_is_null) is not bool
            or (input_is_null and values)
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return HEAT_3D_INVALID_RESULT, []
    if input_is_null or len(values) != HEAT_3D_MAX_INPUT_LENGTH:
        return HEAT_3D_INVALID_RESULT, []
    dimensions = []
    for value in values:
        numeric = float(value)
        if numeric != math.trunc(numeric):
            return HEAT_3D_INVALID_RESULT, []
        dimensions.append(int(numeric))
    n, steps = dimensions
    if not (1 <= n <= HEAT_3D_MAX_N and 0 <= steps <= HEAT_3D_MAX_TSTEPS):
        return HEAT_3D_INVALID_RESULT, []
    required = n * n * n
    if output_is_null or (capacity is not None and capacity < required):
        return HEAT_3D_OUTPUT_ERROR, []

    a = [[[((i + j + n - k) * 10.0) / float(n) for k in range(n)]
          for j in range(n)] for i in range(n)]
    b = [[row[:] for row in plane] for plane in a]
    for _ in range(steps):
        for i in range(1, n - 1):
            for j in range(1, n - 1):
                for k in range(1, n - 1):
                    center = a[i][j][k]
                    dx = 0.125 * (a[i + 1][j][k] - 2.0 * center + a[i - 1][j][k])
                    dy = 0.125 * (a[i][j + 1][k] - 2.0 * center + a[i][j - 1][k])
                    dz = 0.125 * (a[i][j][k + 1] - 2.0 * center + a[i][j][k - 1])
                    b[i][j][k] = ((dx + dy) + dz) + center
        for i in range(1, n - 1):
            for j in range(1, n - 1):
                for k in range(1, n - 1):
                    center = b[i][j][k]
                    dx = 0.125 * (b[i + 1][j][k] - 2.0 * center + b[i - 1][j][k])
                    dy = 0.125 * (b[i][j + 1][k] - 2.0 * center + b[i][j - 1][k])
                    dz = 0.125 * (b[i][j][k + 1] - 2.0 * center + b[i][j][k - 1])
                    a[i][j][k] = ((dx + dy) + dz) + center
    output = [a[i][j][k] for i in range(n) for j in range(n) for k in range(n)]
    return len(output), output


def _parboil_stencil_f32(value):
    return struct.unpack("<f", struct.pack("<f", float(value)))[0]


def parboil_stencil_laplacian_verifier_oracle(
        values, capacity=None, output_is_null=False,
        input_is_null=False, input_length=None):
    """Independent source-order binary32 reference for Parboil's 7-point stencil."""
    max_input = 129
    if (not isinstance(values, (list, tuple)) or len(values) > max_input
            or any(type(value) not in (int, float) or not math.isfinite(float(value))
                   for value in values)
            or type(output_is_null) is not bool or type(input_is_null) is not bool
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return -1, []
    if input_is_null or len(values) < 4:
        return -1, []
    header = values[:4]
    if any(float(value) != math.trunc(float(value)) for value in header):
        return -1, []
    nx, ny, nz, steps = (int(value) for value in header)
    if not (3 <= nx <= 5 and 3 <= ny <= 5 and 3 <= nz <= 5 and 1 <= steps <= 4):
        return -1, []
    cell_count = nx * ny * nz
    if len(values) != 4 + cell_count:
        return -1, []
    initial = []
    for value in values[4:]:
        number = float(value)
        if not -8.0 <= number <= 8.0:
            return -1, []
        initial.append(_parboil_stencil_f32(number))
    if output_is_null or capacity is not None and capacity < cell_count:
        return -2, []

    def index(x, y, z):
        return x + nx * (y + ny * z)

    current = initial[:]
    next_grid = initial[:]
    c0 = _parboil_stencil_f32(_parboil_stencil_f32(1.0) / _parboil_stencil_f32(6.0))
    c1 = _parboil_stencil_f32(
        _parboil_stencil_f32(_parboil_stencil_f32(1.0) / _parboil_stencil_f32(6.0))
        / _parboil_stencil_f32(6.0))
    for _ in range(steps):
        for x in range(1, nx - 1):
            for y in range(1, ny - 1):
                for z in range(1, nz - 1):
                    q = index(x, y, z)
                    total = _parboil_stencil_f32(
                        current[index(x, y, z + 1)] + current[index(x, y, z - 1)])
                    total = _parboil_stencil_f32(total + current[index(x, y + 1, z)])
                    total = _parboil_stencil_f32(total + current[index(x, y - 1, z)])
                    total = _parboil_stencil_f32(total + current[index(x + 1, y, z)])
                    total = _parboil_stencil_f32(total + current[index(x - 1, y, z)])
                    neighbor_term = _parboil_stencil_f32(total * c1)
                    center_term = _parboil_stencil_f32(current[q] * c0)
                    next_grid[q] = _parboil_stencil_f32(neighbor_term - center_term)
        current, next_grid = next_grid, current
    return cell_count, [float(value) for value in current]


def asci_purple_smg2000_residual_verifier_oracle(
        values, capacity=None, output_is_null=False,
        input_is_null=False, input_length=None):
    """Independently evaluate the launcher-profiled anisotropic residual."""
    if (not isinstance(values, (list, tuple))
            or len(values) > ASCI_PURPLE_SMG2000_MAX_INPUT_LENGTH
            or any(type(value) not in (int, float) or not math.isfinite(float(value))
                   or float(value) != math.trunc(float(value)) for value in values)
            or type(output_is_null) is not bool or type(input_is_null) is not bool
            or input_is_null
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))
            or capacity is not None and (type(capacity) is not int or capacity < 0)):
        return -1, []
    if len(values) < 3:
        return -1, []
    nx, ny, nz = (int(value) for value in values[:3])
    if any(side < 2 or side > 5 for side in (nx, ny, nz)):
        return -1, []
    cells = nx * ny * nz
    if len(values) != 3 + 2 * cells:
        return -1, []
    fields = [int(value) for value in values[3:]]
    if any(abs(field) > ASCI_PURPLE_SMG2000_MAX_ABS_FIELD for field in fields):
        return -1, []
    solution, rhs = fields[:cells], fields[cells:]
    output = []
    for i in range(nx):
        for j in range(ny):
            for k in range(nz):
                index = i * ny * nz + j * nz + k
                scaled_operator = 222 * solution[index]
                if i > 0:
                    scaled_operator -= solution[index - ny * nz]
                if i + 1 < nx:
                    scaled_operator -= solution[index + ny * nz]
                if j > 0:
                    scaled_operator -= 10 * solution[index - nz]
                if j + 1 < ny:
                    scaled_operator -= 10 * solution[index + nz]
                if k > 0:
                    scaled_operator -= 100 * solution[index - 1]
                if k + 1 < nz:
                    scaled_operator -= 100 * solution[index + 1]
                output.append((10 * rhs[index] - scaled_operator) / 10.0)
    if output_is_null or capacity is not None and capacity < cells:
        return -2, []
    return cells, output


_MAFFT_V_ALPHABET = "ARNDCQEGHILKMFPSTWYV"
_MAFFT_V_POLARITY = (8.1, 10.5, 11.6, 13.0, 5.5, 10.5, 12.3, 9.0, 10.4, 5.2,
                    4.9, 11.3, 5.7, 5.2, 8.0, 9.2, 8.6, 5.4, 6.2, 5.9)
_MAFFT_V_VOLUME = (31.0, 124.0, 56.0, 54.0, 55.0, 85.0, 83.0, 3.0, 96.0, 111.0,
                   111.0, 119.0, 105.0, 132.0, 32.5, 32.0, 61.0, 170.0, 136.0, 84.0)
_MAFFT_V_CODE_TO_INDEX = {ord(letter): index for index, letter in enumerate(_MAFFT_V_ALPHABET)}


def mafft_falign_fft_lag_correlation_verifier_oracle(
        values, capacity=None, output_is_null=False,
        input_is_null=False, input_length=None):
    """Compute the launcher-default complex feature profile with direct sums."""
    if (not isinstance(values, (list, tuple))
            or len(values) > 66
            or any(type(value) not in (int, float) or not math.isfinite(float(value))
                   or float(value) != math.trunc(float(value)) for value in values)
            or type(output_is_null) is not bool or type(input_is_null) is not bool
            or input_is_null
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))
            or capacity is not None and (type(capacity) is not int or capacity < 0)):
        return -1, []
    if len(values) < 4:
        return -1, []
    first_length, second_length = int(values[0]), int(values[1])
    if (not 1 <= first_length <= 32 or not 1 <= second_length <= 32
            or len(values) != 2 + first_length + second_length):
        return -1, []
    codes = [int(value) for value in values[2:]]
    if any(code not in _MAFFT_V_CODE_TO_INDEX for code in codes):
        return -1, []
    n = 2
    while n <= max(first_length, second_length):
        n *= 2
    if output_is_null or capacity is not None and capacity < n:
        return -2, []

    polarity_center = sum(_MAFFT_V_POLARITY) / len(_MAFFT_V_POLARITY)
    volume_center = sum(_MAFFT_V_VOLUME) / len(_MAFFT_V_VOLUME)
    polarity_scale = math.sqrt(sum((item - polarity_center) ** 2
                                   for item in _MAFFT_V_POLARITY)
                               / len(_MAFFT_V_POLARITY))
    volume_scale = math.sqrt(sum((item - volume_center) ** 2
                                 for item in _MAFFT_V_VOLUME)
                             / len(_MAFFT_V_VOLUME))
    feature_vectors = [
        ((polarity - polarity_center) / polarity_scale,
         (volume - volume_center) / volume_scale)
        for polarity, volume in zip(_MAFFT_V_POLARITY, _MAFFT_V_VOLUME)
    ]
    first = [feature_vectors[_MAFFT_V_CODE_TO_INDEX[code]]
             for code in codes[:first_length]]
    second = [feature_vectors[_MAFFT_V_CODE_TO_INDEX[code]]
              for code in codes[first_length:]]
    profile = []
    for output_index in range(n):
        lag = output_index - n // 2
        accumulator = 0.0
        for first_index in range(first_length):
            second_index = (first_index + lag) % n
            if second_index < second_length:
                real_a, imaginary_a = first[first_index]
                real_b, imaginary_b = second[second_index]
                accumulator += real_a * real_b + imaginary_a * imaginary_b
        profile.append(accumulator / n)
    return n, profile


def himenobmtxpa_verifier_oracle(values, capacity=None, output_is_null=False,
                                input_is_null=False, input_length=None):
    """Independent binary32 model of the bounded 3D Poisson relaxation."""
    if (not isinstance(values, (list, tuple))
            or len(values) > HIMENO_MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) not in (int, float) or not math.isfinite(float(value))
                   for value in values)
            or type(output_is_null) is not bool or type(input_is_null) is not bool
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return HIMENO_INVALID_RESULT, []
    if input_is_null or len(values) != HIMENO_INPUT_LENGTH:
        return HIMENO_INVALID_RESULT, []
    dims = []
    for value in values:
        numeric = float(value)
        if numeric != math.trunc(numeric):
            return HIMENO_INVALID_RESULT, []
        dims.append(int(numeric))
    nx, ny, nz, iterations = dims
    if (not HIMENO_MIN_SIDE <= nx <= HIMENO_MAX_SIDE
            or not HIMENO_MIN_SIDE <= ny <= HIMENO_MAX_SIDE
            or not HIMENO_MIN_SIDE <= nz <= HIMENO_MAX_SIDE
            or not HIMENO_MIN_ITERATIONS <= iterations <= HIMENO_MAX_ITERATIONS):
        return HIMENO_INVALID_RESULT, []
    if output_is_null or (capacity is not None and capacity < HIMENO_MAX_OUTPUT_ELEMENTS):
        return HIMENO_OUTPUT_ERROR, []

    def binary32(value: float) -> float:
        return struct.unpack("<f", struct.pack("<f", value))[0]

    pressure = [0.0] * (nx * ny * nz)
    staged = [0.0] * len(pressure)
    denominator = binary32(float((nx - 1) * (nx - 1)))
    for i in range(nx):
        for j in range(ny):
            for k in range(nz):
                index = i * ny * nz + j * nz + k
                pressure[index] = binary32(binary32(float(i * i)) / denominator)
    inverse_six = binary32(1.0 / 6.0)
    relaxation = binary32(0.8)
    residual_sum = binary32(0.0)
    for _iteration in range(iterations):
        residual_sum = binary32(0.0)
        for i in range(1, nx - 1):
            for j in range(1, ny - 1):
                for k in range(1, nz - 1):
                    index = i * ny * nz + j * nz + k
                    neighbor_sum = binary32(pressure[index + ny * nz] + pressure[index + nz])
                    neighbor_sum = binary32(neighbor_sum + pressure[index + 1])
                    neighbor_sum = binary32(neighbor_sum + pressure[index - ny * nz])
                    neighbor_sum = binary32(neighbor_sum + pressure[index - nz])
                    neighbor_sum = binary32(neighbor_sum + pressure[index - 1])
                    correction = binary32(binary32(neighbor_sum * inverse_six) - pressure[index])
                    residual_sum = binary32(
                        residual_sum + binary32(correction * correction))
                    staged[index] = binary32(
                        pressure[index] + binary32(relaxation * correction))
        for i in range(1, nx - 1):
            for j in range(1, ny - 1):
                for k in range(1, nz - 1):
                    index = i * ny * nz + j * nz + k
                    pressure[index] = staged[index]
    return HIMENO_MAX_OUTPUT_ELEMENTS, [float(residual_sum)]


def polybench_lu_verifier_oracle(values, capacity=None, output_is_null=False,
                                 input_is_null=False, input_length=None):
    """Independent source-order reference for bounded PolyBench LU."""
    maximum_n = 6
    if (not isinstance(values, (list, tuple))
            or len(values) > 1
            or any(type(value) not in (int, float) or not math.isfinite(float(value))
                   for value in values)
            or type(output_is_null) is not bool or type(input_is_null) is not bool
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return -1, []
    if input_is_null or len(values) != 1:
        return -1, []
    numeric_n = float(values[0])
    if numeric_n != math.trunc(numeric_n) or not 1 <= numeric_n <= maximum_n:
        return -1, []
    n = int(numeric_n)
    base = [[0.0 for _ in range(n)] for _ in range(n)]
    for i in range(n):
        for j in range(i + 1):
            base[i][j] = 1.0 - float(j) / float(n)
        base[i][i] = 1.0

    factor = [[0.0 for _ in range(n)] for _ in range(n)]
    for t in range(n):
        for r in range(n):
            for s in range(n):
                factor[r][s] = factor[r][s] + base[r][t] * base[s][t]
    for i in range(n):
        for j in range(i):
            for k in range(j):
                factor[i][j] = factor[i][j] - factor[i][k] * factor[k][j]
            factor[i][j] = factor[i][j] / factor[j][j]
        for j in range(i, n):
            for k in range(i):
                factor[i][j] = factor[i][j] - factor[i][k] * factor[k][j]

    output = [factor[i][j] for i in range(n) for j in range(n)]
    if output_is_null or (capacity is not None and capacity < len(output)):
        return -2, []
    return len(output), output


def polybench_gramschmidt_verifier_oracle(values, capacity=None, output_is_null=False,
                                          input_is_null=False, input_length=None):
    """Independent verifier for the bounded modified Gram-Schmidt QR source."""
    if (not isinstance(values, (list, tuple)) or len(values) > 2
            or any(type(value) not in (int, float) or not math.isfinite(float(value))
                   for value in values)
            or type(output_is_null) is not bool or type(input_is_null) is not bool
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return -1, []
    if input_is_null or len(values) != 2:
        return -1, []
    m_value, n_value = (float(value) for value in values)
    if (m_value != math.trunc(m_value) or n_value != math.trunc(n_value)
            or not 1 <= n_value <= m_value <= 6):
        return -1, []
    m, n = int(m_value), int(n_value)
    matrix = [[(((row * column) % m) / float(m) * 100.0) + 10.0
               for column in range(n)] for row in range(m)]
    q_matrix = [[0.0 for _column in range(n)] for _row in range(m)]
    r_matrix = [[0.0 for _column in range(n)] for _row in range(n)]
    for column in range(n):
        squared_length = sum(matrix[row][column] * matrix[row][column]
                             for row in range(m))
        r_matrix[column][column] = math.sqrt(squared_length)
        if r_matrix[column][column] == 0.0 or not math.isfinite(r_matrix[column][column]):
            return -1, []
        for row in range(m):
            q_matrix[row][column] = matrix[row][column] / r_matrix[column][column]
        for later_column in range(column + 1, n):
            projection = 0.0
            for row in range(m):
                projection += q_matrix[row][column] * matrix[row][later_column]
            r_matrix[column][later_column] = projection
            for row in range(m):
                matrix[row][later_column] -= q_matrix[row][column] * projection
    output = ([r_matrix[row][column] for row in range(n) for column in range(n)]
              + [q_matrix[row][column] for row in range(m) for column in range(n)])
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, []
    return len(output), output


def polybench_correlation_verifier_oracle(values, capacity=None, output_is_null=False,
                                          input_is_null=False, input_length=None):
    """Independent source-order model for bounded PolyBench correlation."""
    if (not isinstance(values, (list, tuple)) or len(values) > 2
            or any(type(value) not in (int, float) or not math.isfinite(float(value))
                   for value in values)
            or type(output_is_null) is not bool or type(input_is_null) is not bool
            or (input_is_null and values)
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return -1, []
    if input_is_null or len(values) != 2:
        return -1, []
    n_value, m_value = (float(value) for value in values)
    if (n_value != math.trunc(n_value) or m_value != math.trunc(m_value)
            or not 1 <= n_value <= 6 or not 1 <= m_value <= 6):
        return -1, []
    n, m = int(n_value), int(m_value)
    matrix = [[float(i * j) / float(m) + float(i) for j in range(m)] for i in range(n)]
    means = [0.0] * m
    deviations = [0.0] * m
    for column in range(m):
        for row in range(n):
            means[column] += matrix[row][column]
        means[column] /= float(n)
    for column in range(m):
        for row in range(n):
            difference = matrix[row][column] - means[column]
            deviations[column] += difference * difference
        deviations[column] /= float(n)
        deviations[column] = math.sqrt(deviations[column])
        if deviations[column] <= 0.1:
            deviations[column] = 1.0
    normalization = [math.sqrt(float(n)) * deviations[col] for col in range(m)]
    for row in range(n):
        for column in range(m):
            matrix[row][column] = (matrix[row][column] - means[column]) / normalization[column]
    result = [[0.0] * m for _ in range(m)]
    for left in range(m):
        result[left][left] = 1.0
        for right in range(left + 1, m):
            value = 0.0
            for row in range(n):
                value += matrix[row][left] * matrix[row][right]
            result[left][right] = value
            result[right][left] = value
    output = [result[row][column] for row in range(m) for column in range(m)]
    if output_is_null or (capacity is not None and capacity < len(output)):
        return -2, []
    return len(output), output


def polybench_seidel_2d_verifier_oracle(values, capacity=None, output_is_null=False,
                                        input_is_null=False, input_length=None):
    """Independent source-order model for bounded PolyBench Seidel 2D."""
    if (not isinstance(values, (list, tuple)) or len(values) > 2
            or any(type(value) not in (int, float) or not math.isfinite(float(value))
                   for value in values)
            or type(output_is_null) is not bool or type(input_is_null) is not bool
            or (input_is_null and values)
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return -1, []
    if input_is_null or len(values) != 2:
        return -1, []
    n_value, steps_value = (float(value) for value in values)
    if (n_value != math.trunc(n_value) or steps_value != math.trunc(steps_value)
            or not 1 <= n_value <= 6 or not 0 <= steps_value <= 4):
        return -1, []
    n, steps = int(n_value), int(steps_value)
    matrix = [[(float(i) * float(j + 2) + 2.0) / float(n)
               for j in range(n)] for i in range(n)]
    for _ in range(steps):
        for i in range(1, n - 1):
            for j in range(1, n - 1):
                total = 0.0
                for row in range(i - 1, i + 2):
                    for column in range(j - 1, j + 2):
                        total += matrix[row][column]
                matrix[i][j] = total / 9.0
    output = [matrix[i][j] for i in range(n) for j in range(n)]
    if output_is_null or (capacity is not None and capacity < len(output)):
        return -2, []
    return len(output), output


def mibench_lame_mdct_long_verifier_oracle(
        values, capacity=None, output_is_null=False,
        input_is_null=False, input_length=None):
    """Independent cosine-sum reference for LAME's 18-point long MDCT."""
    if (not isinstance(values, (list, tuple)) or len(values) > 19
            or any(type(value) not in (int, float) or not math.isfinite(float(value))
                   or not -16.0 <= float(value) <= 16.0 for value in values)
            or type(output_is_null) is not bool or type(input_is_null) is not bool
            or (input_is_null and (values or input_length not in (None, 0)))
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return -1, []
    if input_is_null or len(values) != 18:
        return -1, []
    if output_is_null or capacity is not None and capacity < 18:
        return -2, []
    output = []
    for m in range(18):
        total = math.fsum(
            float(values[k]) * math.cos(
                math.pi * (2 * m + 1) * (4 * k + (38 if k < 9 else 74)) / 144.0
            )
            for k in range(18)
        )
        output.append((4.0 / 36.0) * total)
    return 18, output


def cbench_consumer_mad_imdct36_verifier_oracle(
        values, capacity=None, output_is_null=False,
        input_is_null=False, input_length=None):
    """Independent high-accuracy cosine-sum reference for libmad IMDCT36."""
    if (not isinstance(values, (list, tuple)) or len(values) > 19
            or any(type(value) not in (int, float) or not math.isfinite(float(value))
                   or not -16.0 <= float(value) <= 16.0 for value in values)
            or type(output_is_null) is not bool or type(input_is_null) is not bool
            or (input_is_null and (values or input_length not in (None, 0)))
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return -1, []
    if input_is_null or len(values) != 18:
        return -1, []
    if output_is_null or capacity is not None and capacity < 36:
        return -2, []
    output = []
    for n in range(36):
        output.append(math.fsum(
            float(values[k]) * math.cos(
                math.pi * (2 * n + 19) * (2 * k + 1) / 72.0
            )
            for k in range(18)
        ))
    return 36, output


def cbench_consumer_lame_mdct_short_verifier_oracle(
        values, capacity=None, output_is_null=False,
        input_is_null=False, input_length=None):
    """Independent cosine-sum reference for LAME's three short MDCT windows."""
    if (not isinstance(values, (list, tuple)) or len(values) > 19
            or any(type(value) not in (int, float) or not math.isfinite(float(value))
                   or not -32768.0 <= float(value) <= 32768.0 for value in values)
            or type(output_is_null) is not bool or type(input_is_null) is not bool
            or (input_is_null and (values or input_length not in (None, 0)))
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return -1, []
    if input_is_null or len(values) != 18:
        return -1, []
    if output_is_null or capacity is not None and capacity < 18:
        return -2, []
    output = [0.0] * 18
    for window in range(3):
        base = 6 * window
        for m in range(6):
            products = []
            for coefficient in range(6):
                i = coefficient if coefficient < 3 else coefficient - 3
                window_scale = (math.cos(math.pi * (i + 0.5) / 12.0)
                                * 0.030526638 / 32768.0 * (4.0 / 12.0))
                angle = math.pi * (2 * m + 1) / 48.0
                offset = 14 if coefficient < 3 else 38
                transform_coefficient = window_scale * math.cos(angle * (4 * i + offset))
                products.append(float(values[base + coefficient]) * transform_coefficient)
            output[3 * m + window] = math.fsum(products)
    return 18, output


def cbench_lame_mid_side_verifier_oracle(
        values, capacity=None, output_is_null=False,
        input_is_null=False, input_length=None):
    """Independent source-order reference for LAME's stereo mid-side conversion."""
    if (not isinstance(values, (list, tuple)) or len(values) > 66
            or any(type(value) not in (int, float) or not math.isfinite(float(value))
                   for value in values)
            or type(output_is_null) is not bool or type(input_is_null) is not bool
            or (input_is_null and (values or input_length not in (None, 0)))
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return -1, []
    if input_is_null or not 3 <= len(values) <= 65:
        return -1, []
    count_value = float(values[0])
    if count_value != math.trunc(count_value) or not 1 <= count_value <= 32:
        return -1, []
    count = int(count_value)
    if len(values) != 1 + 2 * count:
        return -1, []
    samples = [float(value) for value in values[1:]]
    if any(value < -16.0 or value > 16.0 for value in samples):
        return -1, []
    required = 2 * count
    if output_is_null or capacity is not None and capacity < required:
        return -2, []
    scale = math.sqrt(2.0) * 0.5
    output = []
    for index in range(count):
        left = samples[index]
        right = samples[count + index]
        output.append((left + right) * scale)
        output.append((left - right) * scale)
    return required, output


def _cbench_rsynth_f32(value: float) -> float:
    return struct.unpack("<f", struct.pack("<f", value))[0]


def cbench_rsynth_natural_glottal_verifier_oracle(
        values, capacity=None, output_is_null=False,
        input_is_null=False, input_length=None):
    """Independent binary32 recurrence for one bounded RSynth glottal sample."""
    if (not isinstance(values, (list, tuple)) or len(values) > 3
            or any(type(value) not in (int, float) or not math.isfinite(float(value))
                   for value in values)
            or type(output_is_null) is not bool or type(input_is_null) is not bool
            or (input_is_null and (values or input_length not in (None, 0)))
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return -1, []
    if input_is_null or len(values) != 2:
        return -1, []
    open_value, sample_value = (float(value) for value in values)
    if (open_value != math.trunc(open_value) or sample_value != math.trunc(sample_value)
            or not 40 <= open_value <= 263 or not 0 <= sample_value <= 299):
        return -1, []
    nopen, sample_index = int(open_value), int(sample_value)
    result = 0.0
    if sample_index < nopen:
        # Integer truncation matches the pinned source table's bounded formula.
        natglot_b = _cbench_rsynth_f32(1_920_000 // (nopen * nopen))
        natglot_a = _cbench_rsynth_f32(
            _cbench_rsynth_f32(natglot_b * float(nopen)) * 0.333)
        vwave = _cbench_rsynth_f32(0.0)
        for _ in range(sample_index + 1):
            natglot_a = _cbench_rsynth_f32(natglot_a - natglot_b)
            vwave = _cbench_rsynth_f32(vwave + natglot_a)
        result = _cbench_rsynth_f32(vwave * 0.028)
    if output_is_null or capacity is not None and capacity < 1:
        return -2, []
    return 1, [result]


def cbench_rsynth_impulsive_glottal_verifier_oracle(
        values, capacity=None, output_is_null=False,
        input_is_null=False, input_length=None):
    """Replay the binary32 impulse and second-order resonator recurrence."""
    if (not isinstance(values, (list, tuple))
            or len(values) > CBENCH_RSYNTH_IMPULSIVE_MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) not in (int, float) or not math.isfinite(float(value))
                   for value in values)
            or type(output_is_null) is not bool or type(input_is_null) is not bool
            or (input_is_null and (values or input_length not in (None, 0)))
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return -1, []
    if input_is_null or len(values) != 2:
        return -1, []
    nopen_value, sample_value = (float(value) for value in values)
    if (nopen_value != math.trunc(nopen_value)
            or sample_value != math.trunc(sample_value)
            or not CBENCH_RSYNTH_IMPULSIVE_MIN_OPEN <= nopen_value <= CBENCH_RSYNTH_IMPULSIVE_MAX_OPEN
            or not 0 <= sample_value <= CBENCH_RSYNTH_IMPULSIVE_MAX_SAMPLE_INDEX):
        return -1, []
    if output_is_null or capacity is not None and capacity < CBENCH_RSYNTH_IMPULSIVE_MAX_OUTPUT_ELEMENTS:
        return -2, []

    nopen = int(nopen_value)
    sample_index = int(sample_value)
    bandwidth = CBENCH_RSYNTH_IMPULSIVE_SAMPLE_RATE // nopen
    minus_pi_t = _cbench_rsynth_f32(-math.pi / CBENCH_RSYNTH_IMPULSIVE_SAMPLE_RATE)
    two_pi_t = _cbench_rsynth_f32(-2.0 * minus_pi_t)
    radius = _cbench_rsynth_f32(math.exp(float(minus_pi_t) * bandwidth))
    coefficient_c = _cbench_rsynth_f32(-(radius * radius))
    coefficient_b = _cbench_rsynth_f32(
        float(radius) * math.cos(float(two_pi_t) * 0.0) * 2.0)
    coefficient_a = _cbench_rsynth_f32(
        1.0 - float(coefficient_b) - float(coefficient_c))
    gain = _cbench_rsynth_f32(float(nopen) * 0.00833)
    coefficient_a = _cbench_rsynth_f32(
        coefficient_a * _cbench_rsynth_f32(gain * gain))
    previous_1 = _cbench_rsynth_f32(0.0)
    previous_2 = _cbench_rsynth_f32(0.0)
    sample = _cbench_rsynth_f32(0.0)
    for index in range(sample_index + 1):
        if index == 1:
            impulse = _cbench_rsynth_f32(13_000_000.0)
        elif index == 2:
            impulse = _cbench_rsynth_f32(-13_000_000.0)
        else:
            impulse = _cbench_rsynth_f32(0.0)
        sample = _cbench_rsynth_f32(
            _cbench_rsynth_f32(_cbench_rsynth_f32(coefficient_a * impulse)
                               + _cbench_rsynth_f32(coefficient_b * previous_1))
            + _cbench_rsynth_f32(coefficient_c * previous_2))
        previous_2, previous_1 = previous_1, sample
    return 1, [sample]


def mibench_automotive_basicmath_cubic_verifier_oracle(
        values, capacity=None, output_is_null=False,
        input_is_null=False, input_length=None):
    """Independent Cardano reference for bounded MiBench cubic fixtures."""
    if (not isinstance(values, (list, tuple)) or len(values) > 4
            or any(type(value) not in (int, float) or not math.isfinite(float(value))
                   or abs(float(value)) > 100.0 for value in values)
            or type(output_is_null) is not bool or type(input_is_null) is not bool
            or (input_is_null and (values or input_length not in (None, 0)))
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return -1, []
    if input_is_null or len(values) != 4:
        return -1, []
    a, b, c, d = (float(value) for value in values)
    if abs(a) < 1.0:
        return -1, []
    shift = b / (3.0 * a)
    p = (3.0 * a * c - b * b) / (3.0 * a * a)
    q = (2.0 * b * b * b - 9.0 * a * b * c + 27.0 * a * a * d) / (27.0 * a * a * a)
    discriminant = (q / 2.0) ** 2 + (p / 3.0) ** 3
    if discriminant == 0.0:
        return -1, []
    if discriminant > 0.0:
        root = math.sqrt(discriminant)

        def cbrt(number):
            return math.copysign(abs(number) ** (1.0 / 3.0), number)

        roots = [cbrt(-q / 2.0 + root) + cbrt(-q / 2.0 - root) - shift]
    else:
        if p >= 0.0:
            return -1, []
        radius = 2.0 * math.sqrt(-p / 3.0)
        argument = -q / (2.0 * math.sqrt(-(p / 3.0) ** 3))
        argument = min(1.0, max(-1.0, argument))
        angle = math.acos(argument)
        roots = [radius * math.cos((angle + 2.0 * math.pi * index) / 3.0) - shift
                 for index in range(3)]
        roots.sort()
        roots = [roots[0], roots[2], roots[1]]
    if (len(roots) not in (1, 3)
            or any(not math.isfinite(value) for value in roots)):
        return -1, []
    if output_is_null or (capacity is not None and capacity < len(roots)):
        return -2, []
    return len(roots), roots


def checker_records(algorithm: str, workload: dict) -> tuple[str, int]:
    if algorithm == "tsvc_s111_odd_index_neighbor_update":
        validate_tsvc_s111_odd_index_neighbor_update_workload(workload)
    elif algorithm == "tsvc_vtvtv_triple_product_map":
        validate_tsvc_vtvtv_triple_product_map_workload(workload)
    elif algorithm == "tsvc_s451_sincos_vector_map":
        validate_tsvc_s451_sincos_vector_map_workload(workload)
    elif algorithm == "tsvc_s221_partial_recursive_fused_update":
        validate_tsvc_s221_partial_recursive_fused_update_workload(workload)
    elif algorithm == "tsvc_s222_interleaved_square_recurrence":
        validate_tsvc_s222_interleaved_square_recurrence_workload(workload)
    elif algorithm == "tsvc_s2251_carried_scalar_expansion":
        validate_tsvc_s2251_carried_scalar_expansion_workload(workload)
    elif algorithm == "tsvc_s1251_per_element_dual_update":
        validate_tsvc_s1251_per_element_dual_update_workload(workload)
    elif algorithm == "tsvc_s3251_forward_shifted_array_expansion":
        validate_tsvc_s3251_forward_shifted_array_expansion_workload(workload)
    elif algorithm == "tsvc_s2712_comparison_gated_axpy":
        validate_tsvc_s2712_comparison_gated_axpy_workload(workload)
    elif algorithm == "tsvc_s2710_nested_scalar_vector_branch_update":
        validate_tsvc_s2710_nested_scalar_vector_branch_update_workload(workload)
    elif algorithm == "tsvc_s1279_nested_conditional_accumulation":
        validate_tsvc_s1279_nested_conditional_accumulation_workload(workload)
    elif algorithm == "tsvc_s2275_matrix_vector_axpy_interleave":
        validate_tsvc_s2275_matrix_vector_axpy_interleave_workload(workload)
    elif algorithm == "tsvc_s482_break_after_update":
        validate_tsvc_s482_break_after_update_workload(workload)
    elif algorithm == "tsvc_s441_s443_d_sign_branch_updates":
        validate_tsvc_s441_s443_d_sign_branch_updates_workload(workload)
    elif algorithm == "tsvc_s242_fused_prefix_update":
        validate_tsvc_s242_fused_prefix_update_workload(workload)
    elif algorithm == "tsvc_s351_direct_unrolled_saxpy":
        validate_tsvc_s351_direct_unrolled_saxpy_workload(workload)
    elif algorithm == "tsvc_s275_column_conditional_axpy_recurrence":
        validate_tsvc_s275_column_conditional_axpy_recurrence_workload(workload)
    elif algorithm == "tsvc_s313_dot_product_reduction":
        validate_tsvc_s313_dot_product_reduction_workload(workload)
    elif algorithm == "versabench_beamformer":
        validate_versabench_beamformer_workload(workload)
    elif algorithm == "rader_fft":
        validate_rader_fft_workload(workload)
    elif algorithm == "smallest_enclosing_ball_3d":
        validate_smallest_enclosing_ball_3d_workload(workload)
    elif algorithm == "euclidean_t_spanner":
        validate_euclidean_t_spanner_workload(workload)
    elif algorithm == "matmul_f64_4x4":
        validate_matmul_f64_4x4_workload(workload)
    elif algorithm == "misc_fp_convert":
        validate_misc_fp_convert_workload(workload)
    elif algorithm == "misc_dt":
        validate_misc_dt_workload(workload)
    elif algorithm == "olden_bh":
        validate_olden_bh_workload(workload)
    elif algorithm == "olden_em3d":
        validate_olden_em3d_workload(workload)
    elif algorithm == "trisolv":
        validate_trisolv_workload(workload)
    elif algorithm in {"jacobi_1d", "jacobi_2d"}:
        validate_polybench_jacobi_workload(workload, algorithm)
    elif algorithm == "syr2k":
        validate_syr2k_workload(workload)
    elif algorithm == "syrk":
        validate_syrk_workload(workload)
    elif algorithm == "trmm":
        validate_trmm_workload(workload)
    elif algorithm == "fdtd_2d":
        validate_fdtd_2d_workload(workload)
    elif algorithm == "heat_3d":
        validate_heat_3d_workload(workload)
    elif algorithm == "parboil_stencil_laplacian":
        validate_parboil_stencil_laplacian_workload(workload)
    elif algorithm == "graphai_gcn_aggregation":
        validate_graphai_gcn_aggregation_workload(workload)
    elif algorithm == "graphai_sage_aggregation":
        validate_graphai_sage_aggregation_workload(workload)
    elif algorithm == "graphai_gat_aggregation":
        validate_graphai_gat_aggregation_workload(workload)
    elif algorithm == "graphai_frontier_sampler":
        validate_graphai_frontier_sampler_workload(workload)
    elif algorithm == "graphai_cf_sgd_sweep":
        validate_graphai_cf_sgd_sweep_workload(workload)
    elif algorithm in {"gardenia_symgs", "gardenia_sgd"}:
        validate_gardenia_workload(workload, algorithm)
    elif algorithm == "asci_purple_smg2000_residual":
        validate_asci_purple_smg2000_residual_workload(workload)
    elif algorithm == "mafft_falign_fft_lag_correlation":
        validate_mafft_falign_fft_lag_correlation_workload(workload)
    elif algorithm == "himenobmtxpa":
        validate_himenobmtxpa_workload(workload)
    elif algorithm == "polybench_gramschmidt":
        validate_polybench_gramschmidt_workload(workload)
    elif algorithm == "polybench_lu":
        validate_polybench_lu_workload(workload)
    elif algorithm == "polybench_correlation":
        validate_polybench_correlation_workload(workload)
    elif algorithm == "polybench_seidel_2d":
        validate_polybench_seidel_2d_workload(workload)
    elif algorithm == "mibench_automotive_basicmath_cubic":
        validate_mibench_automotive_basicmath_cubic_workload(workload)
    elif algorithm == "mibench_lame_mdct_long":
        validate_mibench_lame_mdct_long_workload(workload)
    elif algorithm == "cbench_consumer_mad_imdct36":
        validate_cbench_consumer_mad_imdct36_workload(workload)
    elif algorithm == "cbench_consumer_lame_mdct_short":
        validate_cbench_consumer_lame_mdct_short_workload(workload)
    elif algorithm == "cbench_lame_mid_side":
        validate_cbench_lame_mid_side_workload(workload)
    elif algorithm == "cbench_rsynth_natural_glottal_sample":
        validate_cbench_rsynth_natural_glottal_workload(workload)
    elif algorithm == "cbench_rsynth_impulsive_glottal_sample":
        validate_cbench_rsynth_impulsive_glottal_workload(workload)
    elif algorithm == "pca":
        validate_pca_workload(workload)
    elif algorithm == "principal_component_analysis":
        validate_principal_component_analysis_workload(workload)
    elif algorithm == "principle_component_analysis":
        validate_principle_component_analysis_workload(workload)
    elif algorithm == "ramer_douglas_peucker":
        validate_ramer_douglas_peucker_workload(workload)
    elif algorithm == "kalman_filter":
        validate_kalman_filter_workload(workload)
    elif algorithm == "kalman_filter_r_two_state_simulation":
        validate_kalman_filter_r_two_state_simulation_workload(workload)
    elif algorithm in RISK_METRICS_ALGORITHM_NAMES:
        validate_risk_metrics_workload(workload, algorithm)
    elif algorithm == "muon_optimizer":
        validate_muon_optimizer_workload(workload)
    elif algorithm == "pseudo_inverse":
        validate_pseudo_inverse_workload(workload)
    elif algorithm == "tdigest":
        validate_tdigest_workload(workload)
    elif algorithm == "rhumb_distance":
        validate_rhumb_distance_workload(workload)
    elif algorithm == "rhumb_bearing":
        validate_rhumb_bearing_workload(workload)
    elif algorithm == "rhumb_destination":
        validate_rhumb_destination_workload(workload)
    elif algorithm == "median_of_running_array_double":
        validate_median_of_running_array_double_workload(workload)
    elif algorithm == "median_of_running_array_float":
        validate_median_of_running_array_float_workload(workload)
    elif algorithm == "mean_shift":
        validate_mean_shift_workload(workload)
    elif algorithm == "local_weighted_learning":
        validate_local_weighted_learning_workload(workload)
    elif algorithm == "sir":
        validate_sir_workload(workload)
    elif algorithm == "linear_discriminant_analysis":
        validate_linear_discriminant_analysis_workload(workload)
    elif algorithm == "pi_monte_carlo_estimation":
        validate_pi_monte_carlo_estimation_workload(workload)
    elif algorithm == "montecarlopi":
        validate_montecarlopi_workload(workload)
    elif algorithm == "monte_carlo_simulation":
        validate_monte_carlo_simulation_workload(workload)
    elif algorithm == "mini_batch_gradient_descent":
        validate_mini_batch_gradient_descent_workload(workload)
    elif algorithm == "soboleva_modified_hyperbolic_tangent":
        validate_soboleva_modified_hyperbolic_tangent_workload(workload)
    elif algorithm == "rmsprop":
        validate_rmsprop_workload(workload)
    elif algorithm == "momentum_sgd":
        validate_momentum_sgd_workload(workload)
    elif algorithm == "k_means_clust":
        validate_k_means_clust_workload(workload)
    elif algorithm == "lu_decompose":
        validate_lu_decompose_workload(workload)
    elif algorithm == "lu_elimination":
        validate_lu_elimination_workload(workload)
    elif algorithm == "lu_pivot_decomposition":
        validate_lu_pivot_decomposition_workload(workload)
    elif algorithm == "kohonen_som_trace":
        validate_kohonen_som_trace_workload(workload)
    elif algorithm == "kohonen_som_topology":
        validate_kohonen_som_topology_workload(workload)
    elif algorithm == "qr_decompose":
        validate_qr_decompose_workload(workload)
    elif algorithm == "qr_decomposition":
        validate_qr_decomposition_workload(workload)
    elif algorithm == "qr_eigen_values":
        validate_qr_eigen_values_workload(workload)
    elif algorithm == "shuffle":
        validate_shuffle_workload(workload)
    elif algorithm == "spirograph":
        validate_spirograph_workload(workload)
    elif algorithm == "polynomial_regression":
        validate_polynomial_regression_workload(workload)
    elif algorithm == "sherman_morrison":
        validate_sherman_morrison_workload(workload)
    elif algorithm == "linearregressionrawr":
        validate_linearregressionrawr_workload(workload)
    elif algorithm == "q_learning":
        validate_q_learning_workload(workload)
    elif algorithm == "decision_tree_python_regression":
        validate_decision_tree_python_regression_workload(workload)
    elif algorithm in {"perceptron_java", "perceptron_python", "perceptron_r", "perceptron_rust"}:
        validate_perceptron_workload(workload, algorithm)
    elif algorithm in TRAVELLING_SALESMAN_PYTHON_ALGORITHMS:
        validate_travelling_salesman_python_workload(workload, algorithm)
    absolute_tolerance, relative_tolerance = tolerances(workload)
    workspace = workload.get("workspace", {}).get("elements")
    if algorithm in RISK_METRICS_ALGORITHM_NAMES or algorithm in TRAVELLING_SALESMAN_PYTHON_ALGORITHMS:
        workspace = workload.get("output", {}).get("maximum_elements")
    maximum_workspace = (SHUFFLE_MAX_OUTPUT_ELEMENTS if algorithm == "shuffle" else 1024)
    if (type(workspace) is not int or not 1 <= workspace <= maximum_workspace):
        raise ValueError(
            f"workspace.elements must be an integer from 1 through {maximum_workspace}")
    records: list[tuple[list[float], int, list[float | str], int, int, int]] = []
    valid_case: tuple[list[float], int, list[float | str]] | None = None
    for case in workload.get("cases", []):
        values, expected_result, expected_output = encode_case(
            case, algorithm, absolute_tolerance, relative_tolerance)
        if algorithm == "tsvc_s111_odd_index_neighbor_update":
            independent_result, independent_output = tsvc_s111_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"{case.get('id')}: TSVC s111 fixture differs from independent verifier oracle")
        elif algorithm == "tsvc_vtvtv_triple_product_map":
            independent_result, independent_output = tsvc_vtvtv_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"{case.get('id')}: TSVC vtvtv fixture differs from independent verifier oracle")
        elif algorithm == "tsvc_s451_sincos_vector_map":
            independent_result, independent_output = tsvc_s451_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"{case.get('id')}: TSVC s451 fixture differs from independent verifier oracle")
        elif algorithm == "tsvc_s221_partial_recursive_fused_update":
            independent_result, independent_output = tsvc_s221_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"{case.get('id')}: TSVC s221 fixture differs from independent verifier oracle")
        elif algorithm == "tsvc_s222_interleaved_square_recurrence":
            independent_result, independent_output = tsvc_s222_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"{case.get('id')}: TSVC s222 fixture differs from independent verifier oracle")
        elif algorithm == "tsvc_s2251_carried_scalar_expansion":
            independent_result, independent_output = tsvc_s2251_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"{case.get('id')}: TSVC s2251 fixture differs from independent verifier oracle")
        elif algorithm == "tsvc_s1251_per_element_dual_update":
            independent_result, independent_output = tsvc_s1251_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"{case.get('id')}: TSVC s1251 fixture differs from independent verifier oracle")
        elif algorithm == "tsvc_s3251_forward_shifted_array_expansion":
            independent_result, independent_output = tsvc_s3251_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"{case.get('id')}: TSVC s3251 fixture differs from independent verifier oracle")
        elif algorithm == "tsvc_s2712_comparison_gated_axpy":
            independent_result, independent_output = tsvc_s2712_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"{case.get('id')}: TSVC s2712 fixture differs from independent verifier oracle")
        elif algorithm == "tsvc_s2710_nested_scalar_vector_branch_update":
            independent_result, independent_output = tsvc_s2710_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"{case.get('id')}: TSVC s2710 fixture differs from independent verifier oracle")
        elif algorithm == "tsvc_s1279_nested_conditional_accumulation":
            independent_result, independent_output = tsvc_s1279_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"{case.get('id')}: TSVC s1279 fixture differs from independent verifier oracle")
        elif algorithm == "tsvc_s2275_matrix_vector_axpy_interleave":
            independent_result, independent_output = tsvc_s2275_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"{case.get('id')}: TSVC s2275 fixture differs from independent verifier oracle")
        elif algorithm == "tsvc_s482_break_after_update":
            independent_result, independent_output = tsvc_s482_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"{case.get('id')}: TSVC s482 fixture differs from independent verifier oracle")
        elif algorithm == "tsvc_s441_s443_d_sign_branch_updates":
            independent_result, independent_output = tsvc_s441_s443_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"{case.get('id')}: TSVC s441/s443 fixture differs from independent verifier oracle")
        elif algorithm == "tsvc_s242_fused_prefix_update":
            independent_result, independent_output = tsvc_s242_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"{case.get('id')}: TSVC s242 fixture differs from independent verifier oracle")
        elif algorithm == "tsvc_s351_direct_unrolled_saxpy":
            independent_result, independent_output = tsvc_s351_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"{case.get('id')}: TSVC s351 fixture differs from independent verifier oracle")
        elif algorithm == "tsvc_s275_column_conditional_axpy_recurrence":
            independent_result, independent_output = tsvc_s275_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"{case.get('id')}: TSVC s275 fixture differs from independent recurrence oracle")
        elif algorithm == "tsvc_s313_dot_product_reduction":
            independent_result, independent_output = tsvc_s313_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"{case.get('id')}: TSVC s313 fixture differs from independent dot-product oracle")
        elif algorithm == "trmm":
            independent_result, independent_output = trmm_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or len(independent_output) != len(expected_output)
                    or any(abs(actual - expected) > absolute_tolerance
                           + relative_tolerance * abs(expected)
                           for actual, expected in zip(independent_output, expected_output))):
                raise ValueError(f"{case.get('id')}: TRMM fixture differs from the independent verifier oracle")
        elif algorithm == "fdtd_2d":
            independent_result, independent_output = fdtd_2d_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or len(independent_output) != len(expected_output)
                    or any(abs(actual - expected) > absolute_tolerance
                           + relative_tolerance * abs(expected)
                           for actual, expected in zip(independent_output, expected_output))):
                raise ValueError(f"{case.get('id')}: FDTD 2D fixture differs from the independent verifier oracle")
        elif algorithm == "heat_3d":
            independent_result, independent_output = heat_3d_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or len(independent_output) != len(expected_output)
                    or any(abs(actual - expected) > absolute_tolerance
                           + relative_tolerance * abs(expected)
                           for actual, expected in zip(independent_output, expected_output))):
                raise ValueError(f"{case.get('id')}: heat_3d fixture differs from the independent verifier oracle")
        elif algorithm == "parboil_stencil_laplacian":
            independent_result, independent_output = parboil_stencil_laplacian_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(
                    f"{case.get('id')}: Parboil stencil fixture differs from the independent verifier oracle"
                )
        elif algorithm == "graphai_gcn_aggregation":
            independent_result, independent_output = graphai_gcn_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"{case.get('id')}: GraphAIBench GCN fixture differs from the independent oracle")
        elif algorithm == "graphai_sage_aggregation":
            independent_result, independent_output = graphai_sage_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"{case.get('id')}: GraphAIBench GraphSAGE fixture differs from the independent oracle")
        elif algorithm == "graphai_gat_aggregation":
            independent_result, independent_output = graphai_gat_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"{case.get('id')}: GraphAIBench GAT fixture differs from the independent oracle")
        elif algorithm == "graphai_frontier_sampler":
            independent_result, independent_output = graphai_frontier_sampler_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"{case.get('id')}: GraphAIBench sampler fixture differs from the independent oracle")
        elif algorithm == "graphai_cf_sgd_sweep":
            independent_result, independent_output = graphai_cf_sgd_sweep_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"{case.get('id')}: GraphAIBench CF fixture differs from the independent oracle")
        elif algorithm == "gardenia_symgs":
            independent_result, independent_output = gardenia_symgs_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"{case.get('id')}: GARDENIA SymGS fixture differs from the dense-row verifier")
        elif algorithm == "gardenia_sgd":
            independent_result, independent_output = gardenia_sgd_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"{case.get('id')}: GARDENIA SGD fixture differs from the matrix verifier")
        elif algorithm == "asci_purple_smg2000_residual":
            independent_result, independent_output = asci_purple_smg2000_residual_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"{case.get('id')}: ASCI-Purple residual differs from independent oracle")
        elif algorithm == "mafft_falign_fft_lag_correlation":
            independent_result, independent_output = mafft_falign_fft_lag_correlation_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"{case.get('id')}: MAFFT lag profile differs from the direct verifier oracle")
        elif algorithm == "himenobmtxpa":
            independent_result, independent_output = himenobmtxpa_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(
                    f"{case.get('id')}: Himeno fixture differs from the independent verifier oracle"
                )
        elif algorithm == "polybench_lu":
            independent_result, independent_output = polybench_lu_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or len(independent_output) != len(expected_output)
                    or any(abs(actual - expected) > absolute_tolerance
                           + relative_tolerance * abs(expected)
                           for actual, expected in zip(independent_output, expected_output))):
                raise ValueError(f"{case.get('id')}: polybench_lu fixture differs from the independent verifier oracle")
        elif algorithm == "polybench_gramschmidt":
            independent_result, independent_output = polybench_gramschmidt_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or len(independent_output) != len(expected_output)
                    or any(abs(actual - expected) > absolute_tolerance
                           + relative_tolerance * abs(expected)
                           for actual, expected in zip(independent_output, expected_output))):
                raise ValueError(f"{case.get('id')}: PolyBench QR differs from the independent verifier oracle")
        elif algorithm == "polybench_correlation":
            independent_result, independent_output = polybench_correlation_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or len(independent_output) != len(expected_output)
                    or any(abs(actual - expected) > absolute_tolerance
                           + relative_tolerance * abs(expected)
                           for actual, expected in zip(independent_output, expected_output))):
                raise ValueError(f"{case.get('id')}: correlation fixture differs from independent verifier oracle")
        elif algorithm == "polybench_seidel_2d":
            independent_result, independent_output = polybench_seidel_2d_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or len(independent_output) != len(expected_output)
                    or any(abs(actual - expected) > absolute_tolerance
                           + relative_tolerance * abs(expected)
                           for actual, expected in zip(independent_output, expected_output))):
                raise ValueError(f"{case.get('id')}: Seidel 2D fixture differs from independent verifier oracle")
        elif algorithm == "mibench_automotive_basicmath_cubic":
            independent_result, independent_output = mibench_automotive_basicmath_cubic_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or len(independent_output) != len(expected_output)
                    or any(abs(actual - expected) > absolute_tolerance
                           + relative_tolerance * abs(expected)
                           for actual, expected in zip(independent_output, expected_output))):
                raise ValueError(
                    f"{case.get('id')}: MiBench cubic fixture differs from the independent verifier oracle"
                )
        elif algorithm == "mibench_lame_mdct_long":
            independent_result, independent_output = mibench_lame_mdct_long_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(
                    f"{case.get('id')}: LAME MDCT fixture differs from the independent verifier oracle"
                )
        elif algorithm == "cbench_consumer_mad_imdct36":
            independent_result, independent_output = cbench_consumer_mad_imdct36_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(
                    f"{case.get('id')}: consumer_mad IMDCT36 fixture differs from the independent verifier oracle"
                )
        elif algorithm == "cbench_consumer_lame_mdct_short":
            independent_result, independent_output = cbench_consumer_lame_mdct_short_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(
                    f"{case.get('id')}: consumer_lame short MDCT fixture differs from the independent verifier oracle"
                )
        elif algorithm == "cbench_lame_mid_side":
            independent_result, independent_output = cbench_lame_mid_side_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(
                    f"{case.get('id')}: LAME mid-side fixture differs from the independent verifier oracle"
                )
        elif algorithm == "cbench_rsynth_natural_glottal_sample":
            independent_result, independent_output = cbench_rsynth_natural_glottal_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(
                    f"{case.get('id')}: RSynth natural-source fixture differs from the independent verifier oracle"
                )
        elif algorithm == "cbench_rsynth_impulsive_glottal_sample":
            independent_result, independent_output = cbench_rsynth_impulsive_glottal_verifier_oracle(
                values, case.get("output_capacity", workspace),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(
                    f"{case.get('id')}: RSynth impulsive-source fixture differs from the independent verifier oracle"
                )
        elif algorithm == "misc_dt":
            independent_result, independent_output = misc_dt_verifier_expected_output(values)
            if case.get("input_is_null", False) or case.get("input_length") != len(values):
                independent_result, independent_output = -1, []
            elif (independent_result >= 0
                    and (case.get("output_is_null", False)
                         or case.get("output_capacity", workspace) < independent_result)):
                independent_result, independent_output = -2, []
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"{case.get('id')}: dt fixture differs from the independent verifier oracle")
        elif algorithm in {"olden_bh", "olden_em3d"}:
            verifier_oracle = (olden_bh_verifier_expected_output if algorithm == "olden_bh"
                               else olden_em3d_verifier_expected_output)
            independent_result, independent_output = verifier_oracle(values)
            if case.get("input_is_null", False) or case.get("input_length") != len(values):
                independent_result, independent_output = -1, []
            elif (independent_result >= 0
                    and (case.get("output_is_null", False)
                         or case.get("output_capacity", workspace) < independent_result)):
                independent_result, independent_output = -2, []
            if (independent_result != expected_result
                    or not _matches_output(expected_output, independent_output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"{case.get('id')}: {algorithm} fixture differs from verifier oracle")
        if expected_result >= 0 and expected_result > workspace:
            raise ValueError(f"workspace is too small for {case.get('id')}")
        output_capacity = case.get("output_capacity", workspace)
        output_is_null = bool(case.get("output_is_null", False))
        records.append((values, expected_result, expected_output,
                        output_capacity, int(bool(case.get("input_is_null", False))),
                        int(output_is_null)))
        if expected_result > 0 and valid_case is None:
            valid_case = (values, expected_result, expected_output)

    if not records:
        raise ValueError("workload requires at least one case")
    if valid_case is None:
        raise ValueError("workload requires a successful output case for ABI boundary checks")
    values, result_count, _ = valid_case
    records.append((values, -2, [], result_count - 1, 0, 0))
    records.append((values, -2, [], workspace, 0, 1))
    if algorithm == "tsvc_s313_dot_product_reduction":
        maximum_input = [64.0, *([1000.0] * 64), *([1000.0] * 64)]
        result, output = ORACLES[algorithm](maximum_input)
        independent_result, independent_output = tsvc_s313_verifier_oracle(maximum_input)
        if result != 1 or output != (64_000_000.0,) or (result, list(output)) != (independent_result, independent_output):
            raise ValueError("TSVC s313 maximum-length workload disagrees with the independent oracle")
        records.append((maximum_input, result, [_output_token(value) for value in output],
                        workspace, 0, 0))
    elif algorithm == "tsvc_s242_fused_prefix_update":
        maximum_input = [64.0, 1.0, -1.0, *([1.0] * 64), *([1.0] * 64),
                         *([-1.0] * 64), *([1.0] * 64)]
        result, output = ORACLES[algorithm](maximum_input)
        independent_result, independent_output = tsvc_s242_verifier_oracle(maximum_input)
        if (result != 64 or len(output) != 64
                or (result, list(output)) != (independent_result, independent_output)):
            raise ValueError("TSVC s242 maximum profile differs from independent recurrence oracle")
        records.append((maximum_input, result, [_output_token(value) for value in output],
                        workspace, 0, 0))
    elif algorithm == "tsvc_s351_direct_unrolled_saxpy":
        n = 40
        maximum_input = [float(n), 1.0, *([-1.0] * n), *([1.0] * n)]
        result, output = ORACLES[algorithm](maximum_input)
        independent_result, independent_output = tsvc_s351_verifier_oracle(maximum_input)
        if (result != 40 or len(output) != 40
                or (result, list(output)) != (independent_result, independent_output)):
            raise ValueError("TSVC s351 maximum profile differs from independent SAXPY oracle")
        records.append((maximum_input, result, [_output_token(value) for value in output],
                        workspace, 0, 0))
    elif algorithm == "tsvc_s275_column_conditional_axpy_recurrence":
        n = 8
        matrix_a = [1.0] * (n * n)
        matrix_b = [1.0] * (n * n)
        matrix_c = [1.0] * (n * n)
        maximum_input = [float(n), *matrix_a, *matrix_b, *matrix_c]
        result, output = ORACLES[algorithm](maximum_input)
        independent_result, independent_output = tsvc_s275_verifier_oracle(maximum_input)
        if (result != n * n or len(output) != result
                or (result, list(output)) != (independent_result, independent_output)):
            raise ValueError("TSVC s275 maximum-size profile differs from independent recurrence oracle")
        records.append((maximum_input, result, [_output_token(value) for value in output],
                        workspace, 0, 0))
    elif algorithm == "tsvc_s111_odd_index_neighbor_update":
        maximum_input = [64.0, *([1000.0] * 64), *([1000.0] * 64)]
        result, output = ORACLES[algorithm](maximum_input)
        independent_result, independent_output = tsvc_s111_verifier_oracle(maximum_input)
        if (result != 64 or len(output) != 64
                or (result, list(output)) != (independent_result, independent_output)):
            raise ValueError("TSVC s111 maximum-length profile differs from independent oracle")
        records.append((maximum_input, result, [_output_token(value) for value in output],
                        workspace, 0, 0))
    elif algorithm == "tsvc_vtvtv_triple_product_map":
        maximum_input = [64.0, *([2.0] * 64), *([-2.0] * 64), *([1.0] * 64)]
        result, output = ORACLES[algorithm](maximum_input)
        independent_result, independent_output = tsvc_vtvtv_verifier_oracle(maximum_input)
        if (result != 64 or len(output) != 64
                or (result, list(output)) != (independent_result, independent_output)):
            raise ValueError("TSVC vtvtv maximum-size profile differs from independent oracle")
        records.append((maximum_input, result, [_output_token(value) for value in output],
                        workspace, 0, 0))
    elif algorithm == "tsvc_s451_sincos_vector_map":
        maximum_input = [64.0, *([0.0] * 64), *([0.0] * 64)]
        result, output = ORACLES[algorithm](maximum_input)
        independent_result, independent_output = tsvc_s451_verifier_oracle(maximum_input)
        if (result != 64 or len(output) != 64
                or (result, list(output)) != (independent_result, independent_output)):
            raise ValueError("TSVC s451 maximum-size profile differs from independent oracle")
        records.append((maximum_input, result, [_output_token(value) for value in output],
                        workspace, 0, 0))
    elif algorithm == "tsvc_s221_partial_recursive_fused_update":
        maximum_input = [64.0, *([2.0] * 64), *([2.0] * 64),
                         *([2.0] * 64), *([2.0] * 64)]
        result, output = ORACLES[algorithm](maximum_input)
        independent_result, independent_output = tsvc_s221_verifier_oracle(maximum_input)
        if (result != 128 or len(output) != 128
                or (result, list(output)) != (independent_result, independent_output)):
            raise ValueError("TSVC s221 maximum-size profile differs from independent oracle")
        records.append((maximum_input, result, [_output_token(value) for value in output],
                        workspace, 0, 0))
    elif algorithm == "tsvc_s222_interleaved_square_recurrence":
        maximum_input = [64.0, *([2.0] * 64), *([2.0] * 64),
                         *([2.0] * 64), *([0.5] * 64)]
        result, output = ORACLES[algorithm](maximum_input)
        independent_result, independent_output = tsvc_s222_verifier_oracle(maximum_input)
        if (result != 128 or len(output) != 128
                or (result, list(output)) != (independent_result, independent_output)):
            raise ValueError("TSVC s222 maximum-size profile differs from independent oracle")
        records.append((maximum_input, result, [_output_token(value) for value in output],
                        workspace, 0, 0))
    elif algorithm == "tsvc_s2251_carried_scalar_expansion":
        maximum_input = [64.0, *([1.0] * 64), *([1.0] * 64),
                         *([1.0] * 64), *([-1.0] * 64), *([1.0] * 64)]
        result, output = ORACLES[algorithm](maximum_input)
        independent_result, independent_output = tsvc_s2251_verifier_oracle(maximum_input)
        if (result != 128 or len(output) != 128
                or (result, list(output)) != (independent_result, independent_output)):
            raise ValueError("TSVC s2251 maximum profile differs from independent recurrence oracle")
        records.append((maximum_input, result, [_output_token(value) for value in output],
                        workspace, 0, 0))
    elif algorithm == "tsvc_s1251_per_element_dual_update":
        maximum_input = [64.0, *([1.0] * 64), *([-1.0] * 64),
                         *([1.0] * 64), *([-1.0] * 64), *([1.0] * 64)]
        result, output = ORACLES[algorithm](maximum_input)
        independent_result, independent_output = tsvc_s1251_verifier_oracle(maximum_input)
        if (result != 128 or len(output) != 128
                or (result, list(output)) != (independent_result, independent_output)):
            raise ValueError("TSVC s1251 maximum profile differs from independent recurrence oracle")
        records.append((maximum_input, result, [_output_token(value) for value in output],
                        workspace, 0, 0))
    elif algorithm == "tsvc_s3251_forward_shifted_array_expansion":
        maximum_input = [64.0, *([1.0] * 64), *([-1.0] * 64),
                         *([1.0] * 64), *([-1.0] * 64), *([1.0] * 64)]
        result, output = ORACLES[algorithm](maximum_input)
        independent_result, independent_output = tsvc_s3251_verifier_oracle(maximum_input)
        if (result != 192 or len(output) != 192
                or (result, list(output)) != (independent_result, independent_output)):
            raise ValueError("TSVC s3251 maximum profile differs from independent recurrence oracle")
        records.append((maximum_input, result, [_output_token(value) for value in output],
                        workspace, 0, 0))
    elif algorithm == "tsvc_s2712_comparison_gated_axpy":
        maximum_input = [64.0, 8.0, *([2.0] * 64), *([-2.0] * 64), *([-2.0] * 64)]
        result, output = ORACLES[algorithm](maximum_input)
        independent_result, independent_output = tsvc_s2712_verifier_oracle(maximum_input)
        if (result != 64 or len(output) != 64
                or (result, list(output)) != (independent_result, independent_output)):
            raise ValueError("TSVC s2712 maximum profile differs from independent recurrence oracle")
        records.append((maximum_input, result, [_output_token(value) for value in output],
                        workspace, 0, 0))
    elif algorithm == "tsvc_s2710_nested_scalar_vector_branch_update":
        maximum_input = [64.0, 8.0, 1.0, *([1.0] * 64), *([0.0] * 64),
                         *([0.0] * 64), *([1.0] * 64), *([0.0] * 64)]
        result, output = ORACLES[algorithm](maximum_input)
        independent_result, independent_output = tsvc_s2710_verifier_oracle(maximum_input)
        if (result != 192 or len(output) != 192
                or (result, list(output)) != (independent_result, independent_output)):
            raise ValueError("TSVC s2710 maximum profile differs from independent branch oracle")
        records.append((maximum_input, result, [_output_token(value) for value in output],
                        workspace, 0, 0))
    elif algorithm == "tsvc_s1279_nested_conditional_accumulation":
        maximum_input = [64.0, 8.0, *([-1.0] * 64), *([0.0] * 64),
                         *([0.0] * 64), *([1.0] * 64), *([1.0] * 64)]
        result, output = ORACLES[algorithm](maximum_input)
        independent_result, independent_output = tsvc_s1279_verifier_oracle(maximum_input)
        if (result != 64 or len(output) != 64
                or (result, list(output)) != (independent_result, independent_output)):
            raise ValueError("TSVC s1279 maximum profile differs from independent nested-predicate oracle")
        records.append((maximum_input, result, [_output_token(value) for value in output],
                        workspace, 0, 0))
    elif algorithm == "tsvc_s2275_matrix_vector_axpy_interleave":
        maximum_input = [8.0, 8.0, *([1.0] * 64), *([1.0] * 64),
                         *([1.0] * 64), *([1.0] * 8), *([1.0] * 8),
                         *([1.0] * 8), *([1.0] * 8)]
        result, output = ORACLES[algorithm](maximum_input)
        independent_result, independent_output = tsvc_s2275_verifier_oracle(maximum_input)
        if (result != 72 or len(output) != 72
                or (result, list(output)) != (independent_result, independent_output)):
            raise ValueError("TSVC s2275 maximum profile differs from independent matrix/vector oracle")
        records.append((maximum_input, result, [_output_token(value) for value in output],
                        workspace, 0, 0))
    elif algorithm == "tsvc_s482_break_after_update":
        maximum_input = [64.0, 8.0, *([1.0] * 64), *([0.0] * 64), *([0.0] * 64)]
        result, output = ORACLES[algorithm](maximum_input)
        independent_result, independent_output = tsvc_s482_verifier_oracle(maximum_input)
        if (result != 64 or len(output) != 64
                or (result, list(output)) != (independent_result, independent_output)):
            raise ValueError("TSVC s482 maximum profile differs from independent break-sweep oracle")
        records.append((maximum_input, result, [_output_token(value) for value in output],
                        workspace, 0, 0))
    elif algorithm == "tsvc_s441_s443_d_sign_branch_updates":
        for mode in (0.0, 1.0):
            maximum_input = [mode, 64.0, 8.0, *([1.0] * 64), *([1.0] * 64),
                             *([-1.0] * 64), *([0.0] * 64)]
            result, output = ORACLES[algorithm](maximum_input)
            independent_result, independent_output = tsvc_s441_s443_verifier_oracle(maximum_input)
            if (result != 64 or len(output) != 64
                    or (result, list(output)) != (independent_result, independent_output)):
                raise ValueError("TSVC s441/s443 maximum profile differs from independent D-sign oracle")
            records.append((maximum_input, result, [_output_token(value) for value in output],
                            workspace, 0, 0))
    for invalid_length in (4, 6):
        invalid_input = [0.0] * invalid_length
        oracle_result = ORACLES[algorithm](invalid_input)
        invalid = (oracle_result[0] < 0
                   if algorithm in {"versabench_beamformer", "olden_bh", "olden_em3d", "joint_probability_distribution", "shreedharacharya", "rotation_matrix", "tsvc_s313_dot_product_reduction", "tsvc_s275_column_conditional_axpy_recurrence", "tsvc_s111_odd_index_neighbor_update", "tsvc_vtvtv_triple_product_map", "tsvc_s451_sincos_vector_map", "tsvc_s221_partial_recursive_fused_update", "tsvc_s222_interleaved_square_recurrence", "tsvc_s2251_carried_scalar_expansion", "tsvc_s1251_per_element_dual_update", "tsvc_s3251_forward_shifted_array_expansion", "tsvc_s2712_comparison_gated_axpy", "tsvc_s2710_nested_scalar_vector_branch_update", "tsvc_s1279_nested_conditional_accumulation", "tsvc_s2275_matrix_vector_axpy_interleave", "tsvc_s482_break_after_update", "tsvc_s441_s443_d_sign_branch_updates", "tsvc_s242_fused_prefix_update", "tsvc_s351_direct_unrolled_saxpy",
                                    "trmm",
                                    "parboil_stencil_laplacian",
                                    "mafft_falign_fft_lag_correlation",
                                    "rhumb_distance", "rhumb_bearing", "rhumb_destination",
                                    "median_of_running_array_double", "median_of_running_array_float",
                                    "mean_shift", "k_means_clust", "lu_decompose",
                                    "lu_elimination",
                                    "lu_pivot_decomposition", "kohonen_som_trace",
                                    "kohonen_som_topology",
                                    "qr_decompose",
                                    "qr_decomposition",
                                    "shuffle",
                                    "spirograph",
                                    "polynomial_regression",
                                    "linearregressionrawr", "q_learning",
                                    "single_indeterminate_operations", "montecarlopi",
                                    "local_weighted_learning", "pseudo_inverse", "tdigest",
                                    "cbench_lame_mid_side", "cbench_rsynth_natural_glottal_sample",
                                    *TRAVELLING_SALESMAN_PYTHON_ALGORITHMS}
                   else oracle_result is None)
        if invalid:
            records.append((invalid_input, -1, [], workspace, 0, 0))
    if algorithm == "mafft_falign_fft_lag_correlation":
        sequence_a = [ord(letter) for letter in _MAFFT_V_ALPHABET + _MAFFT_V_ALPHABET[:12]]
        sequence_b = [ord(letter) for letter in (_MAFFT_V_ALPHABET[::-1] + _MAFFT_V_ALPHABET[:12])]
        maximum_input = [32.0, 32.0, *(float(code) for code in sequence_a),
                         *(float(code) for code in sequence_b)]
        result, output = ORACLES[algorithm](maximum_input)
        independent_result, independent_output = mafft_falign_fft_lag_correlation_verifier_oracle(
            maximum_input, workspace, False, False, len(maximum_input))
        if (result != 64 or len(output) != 64 or independent_result != result
                or not _matches_output(output, independent_output,
                                       absolute_tolerance, relative_tolerance)):
            raise ValueError("MAFFT maximum-length feature traces disagree with the direct oracle")
        records.append((maximum_input, result, [_output_token(value) for value in output],
                        workspace, 0, 0))
        records.append(([], -1, [], workspace, 1, 0))
    if algorithm == "misc_dt":
        for iterations, size in ((1, 1), (8, 2), (32, 16), (128, 64)):
            inputs = [float(iterations), float(size)]
            result, output = misc_dt_verifier_expected_output(inputs)
            if result != size or len(output) != size:
                raise ValueError("misc_dt independent oracle rejected a bounded vector profile")
            records.append((inputs, result, [_output_token(value) for value in output],
                            workspace, 0, 0))
    if algorithm == "olden_bh":
        rng = random.Random(0xB3)
        point_pool = [(x, y, z) for x in range(-16, 17)
                      for y in range(-16, 17) for z in range(-16, 17)]
        for case_index in range(15):
            body_count = 2 + case_index % (OLDEN_BH_MAX_BODIES - 1)
            points = rng.sample(point_pool, body_count)
            inputs = [float(body_count), rng.choice((0.0, 0.5, 1.0, 2.0)),
                      rng.choice((0.0, 0.25, 1.0)), 32.0, 0.0, 0.0]
            for x, y, z in points:
                inputs.extend((float(x), float(y), float(z), float(rng.randint(1, 16))))
            result, output = olden_bh_verifier_expected_output(inputs)
            if (result != 4 or len(output) != 4
                    or any(not math.isfinite(value) for value in output)):
                raise ValueError("Olden BH verifier oracle rejected a generated bounded tree")
            records.append((inputs, result, [_output_token(value) for value in output],
                            workspace, 0, 0))
    elif algorithm == "olden_em3d":
        rng = random.Random(0xE3D)
        for case_index in range(20):
            node_count = 1 + case_index % OLDEN_EM3D_MAX_NODES
            degree = rng.randint(1, min(OLDEN_EM3D_MAX_DEGREE, node_count))
            electric = [rng.random() for _ in range(node_count)]
            magnetic = [rng.random() for _ in range(node_count)]
            electric_neighbors = []
            magnetic_neighbors = []
            for _node in range(node_count):
                electric_neighbors.extend(rng.sample(range(node_count), degree))
                magnetic_neighbors.extend(rng.sample(range(node_count), degree))
            edge_count = node_count * degree
            inputs = ([float(node_count), float(degree)] + electric + magnetic
                      + [float(value) for value in electric_neighbors]
                      + [rng.random() for _ in range(edge_count)]
                      + [float(value) for value in magnetic_neighbors]
                      + [rng.random() for _ in range(edge_count)])
            result, output = olden_em3d_verifier_expected_output(inputs)
            if (result != 2 * node_count or len(output) != result
                    or any(not math.isfinite(value) for value in output)):
                raise ValueError("Olden EM3D verifier oracle rejected a generated bounded graph")
            records.append((inputs, result, [_output_token(value) for value in output],
                            workspace, 0, 0))
    if algorithm == "trisolv":
        maximum_input = [float(workload["input"]["n_range"][1])]
        maximum_output = ORACLES[algorithm](maximum_input)
        if (maximum_output is None or len(maximum_output) != workspace
                or any(not math.isfinite(value) for value in maximum_output)):
            raise ValueError("trisolv maximum-dimension oracle returned an invalid vector")
        records.append((maximum_input, len(maximum_output),
                        [_output_token(value) for value in maximum_output],
                        workspace, 0, 0))
    elif algorithm in {"jacobi_1d", "jacobi_2d"}:
        maximum_input = [float(JACOBI_1D_MAX_N if algorithm == "jacobi_1d" else JACOBI_2D_MAX_N),
                         float(JACOBI_1D_MAX_TSTEPS if algorithm == "jacobi_1d" else JACOBI_2D_MAX_TSTEPS)]
        maximum_output = ORACLES[algorithm](maximum_input)
        if (maximum_output is None or len(maximum_output) > workspace
                or any(not math.isfinite(value) for value in maximum_output)):
            raise ValueError(f"{algorithm} maximum-dimension oracle returned an invalid output")
        records.append((maximum_input, len(maximum_output),
                        [_output_token(value) for value in maximum_output],
                        workspace, 0, 0))
    elif algorithm == "syr2k":
        maximum_input = [float(SYR2K_MAX_N), float(SYR2K_MAX_M)]
        maximum_output = ORACLES[algorithm](maximum_input)
        if (maximum_output is None or len(maximum_output) != SYR2K_MAX_OUTPUT_ELEMENTS
                or any(not math.isfinite(value) for value in maximum_output)):
            raise ValueError("syr2k maximum-dimension oracle returned an invalid matrix")
        records.append((maximum_input, len(maximum_output),
                        [_output_token(value) for value in maximum_output],
                        workspace, 0, 0))
    elif algorithm == "trmm":
        for m in range(1, TRMM_MAX_DIM + 1):
            for n in range(1, TRMM_MAX_DIM + 1):
                maximum_input = [float(m), float(n)]
                result, output = trmm_verifier_oracle(maximum_input, workspace)
                if (result != m * n or len(output) != result
                        or any(not math.isfinite(value) for value in output)):
                    raise ValueError("trmm independent verifier oracle returned an invalid bounded matrix")
                records.append((maximum_input, result, [_output_token(value) for value in output],
                                workspace, 0, 0))
    elif algorithm == "fdtd_2d":
        maximum_input = [float(FDTD_2D_MAX_TMAX), float(FDTD_2D_MAX_NX),
                         float(FDTD_2D_MAX_NY)]
        result, output = fdtd_2d_verifier_oracle(maximum_input, workspace)
        if (result != FDTD_2D_MAX_OUTPUT_ELEMENTS or len(output) != result
                or any(not math.isfinite(value) for value in output)):
            raise ValueError("fdtd_2d independent verifier oracle returned an invalid maximum output")
        records.append((maximum_input, result, [_output_token(value) for value in output],
                        workspace, 0, 0))
    elif algorithm == "heat_3d":
        maximum_input = [float(HEAT_3D_MAX_N), float(HEAT_3D_MAX_TSTEPS)]
        result, output = heat_3d_verifier_oracle(maximum_input, workspace)
        if (result != HEAT_3D_MAX_OUTPUT_ELEMENTS or len(output) != result
                or any(not math.isfinite(value) for value in output)):
            raise ValueError("heat_3d independent verifier oracle returned an invalid maximum output")
        records.append((maximum_input, result, [_output_token(value) for value in output],
                        workspace, 0, 0))
    elif algorithm == "himenobmtxpa":
        maximum_input = [float(HIMENO_MAX_SIDE), float(HIMENO_MAX_SIDE),
                         float(HIMENO_MAX_SIDE), float(HIMENO_MAX_ITERATIONS)]
        result, output = himenobmtxpa_verifier_oracle(maximum_input, workspace)
        if (result != HIMENO_MAX_OUTPUT_ELEMENTS or len(output) != result
                or any(not math.isfinite(value) for value in output)):
            raise ValueError("himenobmtxpa independent verifier returned an invalid maximum residual")
        records.append((maximum_input, result, [_output_token(value) for value in output],
                        workspace, 0, 0))
        for capacity in (0, result - 1):
            error_result, error_output = himenobmtxpa_verifier_oracle(
                maximum_input, capacity)
            if error_result != HIMENO_OUTPUT_ERROR or error_output:
                raise ValueError("himenobmtxpa capacity oracle returned an invalid boundary result")
            records.append((maximum_input, error_result, [], capacity, 0, 0))
        null_result, null_output = himenobmtxpa_verifier_oracle(
            maximum_input, result, output_is_null=True)
        if null_result != HIMENO_OUTPUT_ERROR or null_output:
            raise ValueError("himenobmtxpa null-output oracle returned an invalid result")
        records.append((maximum_input, null_result, [], result, 0, 1))
        null_input = [0.0] * HIMENO_INPUT_LENGTH
        null_input_result, null_input_output = himenobmtxpa_verifier_oracle(
            null_input, workspace, input_is_null=True, input_length=HIMENO_INPUT_LENGTH)
        if null_input_result != HIMENO_INVALID_RESULT or null_input_output:
            raise ValueError("himenobmtxpa null-input oracle returned an invalid result")
        records.append((null_input, null_input_result, [], workspace, 1, 0))
        rng_himeno = random.Random(0xB17E)
        for _case_index in range(32):
            inputs = [
                float(rng_himeno.randint(HIMENO_MIN_SIDE, HIMENO_MAX_SIDE)),
                float(rng_himeno.randint(HIMENO_MIN_SIDE, HIMENO_MAX_SIDE)),
                float(rng_himeno.randint(HIMENO_MIN_SIDE, HIMENO_MAX_SIDE)),
                float(rng_himeno.randint(HIMENO_MIN_ITERATIONS, HIMENO_MAX_ITERATIONS)),
            ]
            random_result, random_output = himenobmtxpa_verifier_oracle(inputs, workspace)
            if (random_result != HIMENO_MAX_OUTPUT_ELEMENTS or len(random_output) != random_result
                    or any(not math.isfinite(value) for value in random_output)):
                raise ValueError("himenobmtxpa oracle rejected a generated bounded grid")
            records.append((inputs, random_result, [_output_token(value) for value in random_output],
                            workspace, 0, 0))
    elif algorithm == "polybench_lu":
        maximum_input = [6.0]
        result, output = polybench_lu_verifier_oracle(maximum_input, workspace)
        if (result != 36 or len(output) != result
                or any(not math.isfinite(value) for value in output)):
            raise ValueError("polybench_lu independent verifier oracle returned an invalid maximum matrix")
        records.append((maximum_input, result, [_output_token(value) for value in output],
                        result, 0, 0))
        for capacity in (0, result - 1):
            error_result, error_output = polybench_lu_verifier_oracle(
                maximum_input, capacity)
            if error_result != -2 or error_output:
                raise ValueError("polybench_lu capacity oracle returned an invalid boundary result")
            records.append((maximum_input, error_result, [], capacity, 0, 0))
        null_result, null_output = polybench_lu_verifier_oracle(
            maximum_input, result, output_is_null=True)
        if null_result != -2 or null_output:
            raise ValueError("polybench_lu null-output oracle returned an invalid result")
        records.append((maximum_input, null_result, [], result, 0, 1))
    elif algorithm == "polybench_gramschmidt":
        maximum_input = [6.0, 6.0]
        result, output = polybench_gramschmidt_verifier_oracle(maximum_input, workspace)
        if (result != 72 or len(output) != result
                or any(not math.isfinite(value) for value in output)):
            raise ValueError("PolyBench QR verifier returned an invalid maximum profile")
        records.append((maximum_input, result, [_output_token(value) for value in output],
                        result, 0, 0))
        for capacity in (0, result - 1):
            error_result, error_output = polybench_gramschmidt_verifier_oracle(
                maximum_input, capacity)
            if error_result != -2 or error_output:
                raise ValueError("PolyBench QR capacity oracle returned an invalid result")
            records.append((maximum_input, error_result, [], capacity, 0, 0))
        null_result, null_output = polybench_gramschmidt_verifier_oracle(
            maximum_input, result, output_is_null=True)
        if null_result != -2 or null_output:
            raise ValueError("PolyBench QR null-output oracle returned an invalid result")
        records.append((maximum_input, null_result, [], result, 0, 1))
        null_input_result, null_input_output = polybench_gramschmidt_verifier_oracle(
            [], workspace, input_is_null=True, input_length=0)
        if null_input_result != -1 or null_input_output:
            raise ValueError("PolyBench QR null-input oracle returned an invalid result")
        records.append(([], null_input_result, [], workspace, 1, 0))
    elif algorithm == "polybench_correlation":
        maximum_input = [6.0, 6.0]
        result, output = polybench_correlation_verifier_oracle(maximum_input, workspace)
        if (result != 36 or len(output) != result
                or any(not math.isfinite(value) for value in output)):
            raise ValueError("correlation independent verifier returned an invalid maximum matrix")
        records.append((maximum_input, result, [_output_token(value) for value in output],
                        result, 0, 0))
        for capacity in (0, result - 1):
            error_result, error_output = polybench_correlation_verifier_oracle(maximum_input, capacity)
            if error_result != -2 or error_output:
                raise ValueError("correlation capacity oracle returned an invalid boundary result")
            records.append((maximum_input, error_result, [], capacity, 0, 0))
        null_result, null_output = polybench_correlation_verifier_oracle(
            maximum_input, result, output_is_null=True)
        if null_result != -2 or null_output:
            raise ValueError("correlation null-output oracle returned an invalid result")
        records.append((maximum_input, null_result, [], result, 0, 1))
    elif algorithm == "polybench_seidel_2d":
        maximum_input = [6.0, 4.0]
        result, output = polybench_seidel_2d_verifier_oracle(maximum_input, workspace)
        if (result != 36 or len(output) != result
                or any(not math.isfinite(value) for value in output)):
            raise ValueError("Seidel 2D independent verifier returned an invalid maximum matrix")
        records.append((maximum_input, result, [_output_token(value) for value in output],
                        result, 0, 0))
        for capacity in (0, result - 1):
            error_result, error_output = polybench_seidel_2d_verifier_oracle(maximum_input, capacity)
            if error_result != -2 or error_output:
                raise ValueError("Seidel 2D capacity oracle returned an invalid boundary result")
            records.append((maximum_input, error_result, [], capacity, 0, 0))
        null_result, null_output = polybench_seidel_2d_verifier_oracle(
            maximum_input, result, output_is_null=True)
        if null_result != -2 or null_output:
            raise ValueError("Seidel 2D null-output oracle returned an invalid result")
        records.append((maximum_input, null_result, [], result, 0, 1))
    elif algorithm == "mibench_automotive_basicmath_cubic":
        generated_inputs = (
            [1.0, -6.0, 11.0, -6.0],
            [1.0, -10.5, 32.0, -30.0],
            [1.0, -4.5, 17.0, -30.0],
            [1.0, 0.0, 0.0, -2.0],
            [-1.0, 6.0, -11.0, 6.0],
        )
        for generated_input in generated_inputs:
            result, output = mibench_automotive_basicmath_cubic_verifier_oracle(
                generated_input, workspace)
            if (result not in (1, 3) or len(output) != result
                    or any(not math.isfinite(value) for value in output)):
                raise ValueError("MiBench cubic verifier rejected a supported bounded polynomial")
            records.append((generated_input, result,
                            [_output_token(value) for value in output], result, 0, 0))
        maximum_input = [1.0, -6.0, 11.0, -6.0]
        result, output = mibench_automotive_basicmath_cubic_verifier_oracle(
            maximum_input, workspace)
        if result != 3 or len(output) != result:
            raise ValueError("MiBench cubic verifier failed the three-root output boundary")
        for capacity in (0, result - 1):
            error_result, error_output = mibench_automotive_basicmath_cubic_verifier_oracle(
                maximum_input, capacity)
            if error_result != -2 or error_output:
                raise ValueError("MiBench cubic capacity oracle returned an invalid boundary result")
            records.append((maximum_input, error_result, [], capacity, 0, 0))
        null_result, null_output = mibench_automotive_basicmath_cubic_verifier_oracle(
            maximum_input, result, output_is_null=True)
        if null_result != -2 or null_output:
            raise ValueError("MiBench cubic null-output oracle returned an invalid result")
        records.append((maximum_input, null_result, [], result, 0, 1))
    elif algorithm == "cbench_consumer_mad_imdct36":
        rng_imdct = random.Random(0x1D36)
        for _case_index in range(32):
            generated_input = [rng_imdct.uniform(-16.0, 16.0) for _ in range(18)]
            result, output = cbench_consumer_mad_imdct36_verifier_oracle(
                generated_input, workspace)
            if (result != 36 or len(output) != result
                    or any(not math.isfinite(value) for value in output)):
                raise ValueError("consumer_mad IMDCT36 verifier rejected a bounded coefficient vector")
            records.append((generated_input, result, [_output_token(value) for value in output],
                            workspace, 0, 0))
        boundary_inputs = ([16.0] * 18, [-16.0] * 18)
        for boundary_input in boundary_inputs:
            result, output = cbench_consumer_mad_imdct36_verifier_oracle(
                boundary_input, workspace)
            if result != 36 or len(output) != 36:
                raise ValueError("consumer_mad IMDCT36 verifier rejected an inclusive coefficient bound")
            records.append((boundary_input, result, [_output_token(value) for value in output],
                            workspace, 0, 0))
        null_input = [0.0] * 18
        null_result, null_output = cbench_consumer_mad_imdct36_verifier_oracle(
            null_input, workspace, input_is_null=True, input_length=18)
        if null_result != -1 or null_output:
            raise ValueError("consumer_mad IMDCT36 null-input verifier returned an invalid result")
        records.append((null_input, null_result, [], workspace, 1, 0))
    elif algorithm == "cbench_consumer_lame_mdct_short":
        rng_short_mdct = random.Random(0x5A48)
        for _case_index in range(32):
            generated_input = [rng_short_mdct.uniform(-32768.0, 32768.0) for _ in range(18)]
            result, output = cbench_consumer_lame_mdct_short_verifier_oracle(
                generated_input, workspace)
            if (result != 18 or len(output) != result
                    or any(not math.isfinite(value) for value in output)):
                raise ValueError("consumer_lame short MDCT verifier rejected a bounded work vector")
            records.append((generated_input, result, [_output_token(value) for value in output],
                            workspace, 0, 0))
        for boundary_value in (-32768.0, 32768.0):
            boundary_input = [boundary_value] * 18
            result, output = cbench_consumer_lame_mdct_short_verifier_oracle(
                boundary_input, workspace)
            if result != 18 or len(output) != 18:
                raise ValueError("consumer_lame short MDCT verifier rejected an inclusive input bound")
            records.append((boundary_input, result, [_output_token(value) for value in output],
                            workspace, 0, 0))
        malformed_cases = (
            ([0.0, 0.0], 2, -1),
            ([32768.5] + [0.0] * 17, 18, -1),
        )
        for malformed_input, malformed_length, expected_error in malformed_cases:
            error_result, error_output = cbench_consumer_lame_mdct_short_verifier_oracle(
                malformed_input, workspace, input_length=malformed_length)
            if error_result != expected_error or error_output:
                raise ValueError("consumer_lame short MDCT verifier returned an invalid malformed-input result")
            records.append((malformed_input, error_result, [], workspace, 0, 0))
        valid_input = [1.0] + [0.0] * 17
        for capacity in (0, 17):
            error_result, error_output = cbench_consumer_lame_mdct_short_verifier_oracle(
                valid_input, capacity)
            if error_result != -2 or error_output:
                raise ValueError("consumer_lame short MDCT capacity oracle returned an invalid result")
            records.append((valid_input, error_result, [], capacity, 0, 0))
        null_result, null_output = cbench_consumer_lame_mdct_short_verifier_oracle(
            valid_input, 18, output_is_null=True)
        if null_result != -2 or null_output:
            raise ValueError("consumer_lame short MDCT null-output oracle returned an invalid result")
        records.append((valid_input, null_result, [], 18, 0, 1))
        null_input = [0.0] * 18
        null_result, null_output = cbench_consumer_lame_mdct_short_verifier_oracle(
            null_input, workspace, input_is_null=True, input_length=18)
        if null_result != -1 or null_output:
            raise ValueError("consumer_lame short MDCT null-input oracle returned an invalid result")
        records.append((null_input, null_result, [], workspace, 1, 0))
    elif algorithm == "graphai_gcn_aggregation":
        n, m, d = GRAPHAI_GCN_N_LIMIT, GRAPHAI_GCN_M_LIMIT, GRAPHAI_GCN_D_LIMIT
        maximum_rowptr = [3 * row for row in range(n + 1)]
        maximum_edges = [neighbor for src in range(n)
                         for neighbor in ((src + 1) % n, (src + 3) % n, (src + 5) % n)]
        maximum_left = [(-1) ** vertex for vertex in range(n)]
        maximum_right = [1 + (vertex % 3) for vertex in range(n)]
        maximum_features = [((vertex + feature) % 5) - 2
                            for vertex in range(n) for feature in range(d)]
        maximum_input = ([float(n), float(m), float(d)] + list(map(float, maximum_rowptr))
                         + list(map(float, maximum_edges)) + list(map(float, maximum_left))
                         + list(map(float, maximum_right)) + list(map(float, maximum_features)))
        maximum_result, maximum_output = graphai_gcn_verifier_oracle(maximum_input, workspace)
        if (len(maximum_input) != GRAPHAI_GCN_INPUT_LIMIT
                or maximum_result != GRAPHAI_GCN_OUTPUT_LIMIT
                or len(maximum_output) != maximum_result
                or any(not math.isfinite(value) for value in maximum_output)):
            raise ValueError("GraphAIBench GCN oracle rejected the maximum bounded graph")
        records.append((maximum_input, maximum_result,
                        [_output_token(value) for value in maximum_output], workspace, 0, 0))
        short_result, short_output = graphai_gcn_verifier_oracle(maximum_input, workspace - 1)
        if short_result != -2 or short_output:
            raise ValueError("GraphAIBench GCN oracle returned an invalid short-capacity result")
        records.append((maximum_input, short_result, [], workspace - 1, 0, 0))
        null_result, null_output = graphai_gcn_verifier_oracle(
            maximum_input, workspace, output_is_null=True)
        if null_result != -2 or null_output:
            raise ValueError("GraphAIBench GCN oracle returned an invalid null-output result")
        records.append((maximum_input, null_result, [], workspace, 0, 1))
        invalid_input = list(maximum_input)
        invalid_input[3 + n + 1] = float(n)
        invalid_result, invalid_output = graphai_gcn_verifier_oracle(invalid_input, workspace)
        if invalid_result != -1 or invalid_output:
            raise ValueError("GraphAIBench GCN oracle accepted an out-of-range neighbor")
        records.append((invalid_input, invalid_result, [], workspace, 0, 0))
        null_input_result, null_input_output = graphai_gcn_verifier_oracle(
            [], workspace, input_is_null=True, input_length=0)
        if null_input_result != -1 or null_input_output:
            raise ValueError("GraphAIBench GCN oracle returned an invalid null-input result")
        records.append(([], null_input_result, [], workspace, 1, 0))
    elif algorithm == "graphai_sage_aggregation":
        n, m, d = 8, 24, 4
        rows = [3 * row for row in range(n + 1)]
        cols = [neighbor for src in range(n)
                for neighbor in ((src + 1) % n, (src + 3) % n, (src + 5) % n)]
        features = [((vertex + feature) % 7) - 3
                    for vertex in range(n) for feature in range(d)]
        maximum_input = ([float(n), float(m), float(d)] + list(map(float, rows))
                         + list(map(float, cols)) + list(map(float, features)))
        result, output = graphai_sage_verifier_oracle(maximum_input, workspace)
        if len(maximum_input) != 68 or result != 32 or len(output) != result:
            raise ValueError("GraphAIBench GraphSAGE oracle rejected the maximum bounded graph")
        records.append((maximum_input, result, [_output_token(x) for x in output], workspace, 0, 0))
        short_result, short_output = graphai_sage_verifier_oracle(maximum_input, workspace - 1)
        if short_result != -2 or short_output:
            raise ValueError("GraphAIBench GraphSAGE oracle returned an invalid short-capacity result")
        records.append((maximum_input, short_result, [], workspace - 1, 0, 0))
        null_result, null_output = graphai_sage_verifier_oracle(
            maximum_input, workspace, output_is_null=True)
        if null_result != -2 or null_output:
            raise ValueError("GraphAIBench GraphSAGE oracle returned an invalid null-output result")
        records.append((maximum_input, null_result, [], workspace, 0, 1))
        invalid_input = list(maximum_input)
        invalid_input[3 + n + 1] = float(n)
        invalid_result, invalid_output = graphai_sage_verifier_oracle(invalid_input, workspace)
        if invalid_result != -1 or invalid_output:
            raise ValueError("GraphAIBench GraphSAGE oracle accepted an out-of-range neighbor")
        records.append((invalid_input, invalid_result, [], workspace, 0, 0))
        null_input_result, null_input_output = graphai_sage_verifier_oracle(
            [], workspace, input_is_null=True, input_length=0)
        if null_input_result != -1 or null_input_output:
            raise ValueError("GraphAIBench GraphSAGE oracle returned an invalid null-input result")
        records.append(([], null_input_result, [], workspace, 1, 0))
    elif algorithm == "graphai_gat_aggregation":
        n, m, d = 8, 24, 4
        rows = [3 * row for row in range(n + 1)]
        cols = [neighbor for src in range(n)
                for neighbor in ((src + 1) % n, (src + 3) % n, (src + 5) % n)]
        alpha_left = [(-1) ** k for k in range(d)]
        alpha_right = [((k % 3) - 1) for k in range(d)]
        features = [((vertex + feature) % 5) - 2
                    for vertex in range(n) for feature in range(d)]
        maximum_input = ([float(n), float(m), float(d)] + list(map(float, rows))
                         + list(map(float, cols)) + list(map(float, alpha_left))
                         + list(map(float, alpha_right)) + list(map(float, features)))
        result, output = graphai_gat_verifier_oracle(maximum_input, workspace)
        if len(maximum_input) != 76 or result != 32 or len(output) != result:
            raise ValueError("GraphAIBench GAT oracle rejected the maximum bounded graph")
        records.append((maximum_input, result, [_output_token(x) for x in output], workspace, 0, 0))
        short_result, short_output = graphai_gat_verifier_oracle(maximum_input, workspace - 1)
        if short_result != -2 or short_output:
            raise ValueError("GraphAIBench GAT oracle returned an invalid short-capacity result")
        records.append((maximum_input, short_result, [], workspace - 1, 0, 0))
        null_result, null_output = graphai_gat_verifier_oracle(
            maximum_input, workspace, output_is_null=True)
        if null_result != -2 or null_output:
            raise ValueError("GraphAIBench GAT oracle returned an invalid null-output result")
        records.append((maximum_input, null_result, [], workspace, 0, 1))
        invalid_input = list(maximum_input)
        invalid_input[3 + n + 1] = float(n)
        invalid_result, invalid_output = graphai_gat_verifier_oracle(invalid_input, workspace)
        if invalid_result != -1 or invalid_output:
            raise ValueError("GraphAIBench GAT oracle accepted an out-of-range neighbor")
        records.append((invalid_input, invalid_result, [], workspace, 0, 0))
        null_input_result, null_input_output = graphai_gat_verifier_oracle(
            [], workspace, input_is_null=True, input_length=0)
        if null_input_result != -1 or null_input_output:
            raise ValueError("GraphAIBench GAT oracle returned an invalid null-input result")
        records.append(([], null_input_result, [], workspace, 1, 0))
    elif algorithm == "graphai_frontier_sampler":
        n, m, roots_count = 8, 24, 4
        rows = [3 * row for row in range(n + 1)]
        cols = [neighbor for src in range(n)
                for neighbor in ((src + 1) % n, (src + 3) % n, (src + 5) % n)]
        roots = list(range(roots_count))
        choices = [0] * (21 * roots_count)
        maximum_input = ([float(n), float(m), float(roots_count)]
                         + list(map(float, roots)) + list(map(float, rows))
                         + list(map(float, cols)) + list(map(float, choices)))
        result, output = graphai_frontier_sampler_verifier_oracle(maximum_input, workspace)
        if len(maximum_input) != 124 or result != 88 or len(output) != result:
            raise ValueError("GraphAIBench sampler oracle rejected the maximum bounded graph")
        records.append((maximum_input, result, [_output_token(x) for x in output], workspace, 0, 0))
        short_result, short_output = graphai_frontier_sampler_verifier_oracle(maximum_input, workspace - 1)
        if short_result != -2 or short_output:
            raise ValueError("GraphAIBench sampler oracle returned an invalid short-capacity result")
        records.append((maximum_input, short_result, [], workspace - 1, 0, 0))
        null_result, null_output = graphai_frontier_sampler_verifier_oracle(
            maximum_input, workspace, output_is_null=True)
        if null_result != -2 or null_output:
            raise ValueError("GraphAIBench sampler oracle returned an invalid null-output result")
        records.append((maximum_input, null_result, [], workspace, 0, 1))
        invalid_input = list(maximum_input)
        invalid_input[3 + roots_count + n + 1 + m] = 3.0
        invalid_result, invalid_output = graphai_frontier_sampler_verifier_oracle(invalid_input, workspace)
        if invalid_result != -1 or invalid_output:
            raise ValueError("GraphAIBench sampler oracle accepted an out-of-range edge choice")
        records.append((invalid_input, invalid_result, [], workspace, 0, 0))
        null_input_result, null_input_output = graphai_frontier_sampler_verifier_oracle(
            [], workspace, input_is_null=True, input_length=0)
        if null_input_result != -1 or null_input_output:
            raise ValueError("GraphAIBench sampler oracle returned an invalid null-input result")
        records.append(([], null_input_result, [], workspace, 1, 0))
    elif algorithm == "graphai_cf_sgd_sweep":
        users, items, m, k = 4, 4, 24, 4
        n = users+items
        rows = [6*user for user in range(users+1)] + [m]*items
        cols = [users+((user+edge)%items) for user in range(users) for edge in range(6)]
        ratings = [((user+edge)%7)-3 for user in range(users) for edge in range(6)]
        latents = [(((vertex+factor)%5)-2)/2.0
                   for vertex in range(n) for factor in range(k)]
        maximum_input = ([float(users), float(items), float(m), float(k), 0.001, 0.00000035]
                         + list(map(float, rows)) + list(map(float, cols))
                         + list(map(float, ratings)) + latents)
        result, output = graphai_cf_sgd_sweep_verifier_oracle(maximum_input, workspace)
        if len(maximum_input) != 95 or result != 32 or len(output) != result:
            raise ValueError("GraphAIBench CF oracle rejected the maximum bounded one-sweep graph")
        records.append((maximum_input, result, [_output_token(x) for x in output], workspace, 0, 0))
        short_result, short_output = graphai_cf_sgd_sweep_verifier_oracle(maximum_input, workspace-1)
        if short_result != -2 or short_output:
            raise ValueError("GraphAIBench CF oracle returned an invalid short-capacity result")
        records.append((maximum_input, short_result, [], workspace-1, 0, 0))
        null_result, null_output = graphai_cf_sgd_sweep_verifier_oracle(
            maximum_input, workspace, output_is_null=True)
        if null_result != -2 or null_output:
            raise ValueError("GraphAIBench CF oracle returned an invalid null-output result")
        records.append((maximum_input, null_result, [], workspace, 0, 1))
        invalid_input = list(maximum_input)
        invalid_input[6+n+1] = 0.0
        invalid_result, invalid_output = graphai_cf_sgd_sweep_verifier_oracle(invalid_input, workspace)
        if invalid_result != -1 or invalid_output:
            raise ValueError("GraphAIBench CF oracle accepted a user-to-user rating edge")
        records.append((invalid_input, invalid_result, [], workspace, 0, 0))
        null_input_result, null_input_output = graphai_cf_sgd_sweep_verifier_oracle(
            [], workspace, input_is_null=True, input_length=0)
        if null_input_result != -1 or null_input_output:
            raise ValueError("GraphAIBench CF oracle returned an invalid null-input result")
        records.append(([], null_input_result, [], workspace, 1, 0))
    elif algorithm == "gardenia_symgs":
        n, colors = 8, 8
        order = list(range(n))
        offsets = list(range(n + 1))
        rows = list(range(0, (n + 1) * n, n))
        columns = [v for _u in range(n) for v in range(n)]
        matrix = [4.0 if u == v else -0.25 for u in range(n) for v in range(n)]
        maximum_input = ([float(n), float(n*n), float(colors)]
                         + list(map(float, order)) + list(map(float, offsets))
                         + list(map(float, rows)) + list(map(float, columns))
                         + matrix + [0.0] * n + [1.0] * n)
        result, output = gardenia_symgs_verifier_oracle(maximum_input, workspace)
        if len(maximum_input) != 173 or result != n or len(output) != n:
            raise ValueError("GARDENIA SymGS verifier rejected the maximum bounded CSR profile")
        records.append((maximum_input, result, [_output_token(x) for x in output], workspace, 0, 0))
        short_result, short_output = gardenia_symgs_verifier_oracle(maximum_input, workspace-1)
        if short_result != -2 or short_output:
            raise ValueError("GARDENIA SymGS verifier returned an invalid short-capacity result")
        records.append((maximum_input, short_result, [], workspace-1, 0, 0))
        null_result, null_output = gardenia_symgs_verifier_oracle(maximum_input, workspace, output_is_null=True)
        if null_result != -2 or null_output:
            raise ValueError("GARDENIA SymGS verifier returned an invalid null-output result")
        records.append((maximum_input, null_result, [], workspace, 0, 1))
        invalid_input = list(maximum_input)
        invalid_input[3+n] = 1.0
        invalid_result, invalid_output = gardenia_symgs_verifier_oracle(invalid_input, workspace)
        if invalid_result != -1 or invalid_output:
            raise ValueError("GARDENIA SymGS verifier accepted malformed color offsets")
        records.append((invalid_input, invalid_result, [], workspace, 0, 0))
        null_input_result, null_input_output = gardenia_symgs_verifier_oracle(
            [], workspace, input_is_null=True, input_length=0)
        if null_input_result != -1 or null_input_output:
            raise ValueError("GARDENIA SymGS verifier returned an invalid null-input result")
        records.append(([], null_input_result, [], workspace, 1, 0))
    elif algorithm == "gardenia_sgd":
        users, items, m, k = 7, 1, 24, 4
        rows = [0, 4, 8, 12, 16, 20, 22, 24]
        columns = [0] * m
        ratings = [1.0] * m
        factors = [0.05] * ((users+items)*k)
        maximum_input = ([float(users), float(items), float(m), float(k)]
                         + list(map(float, rows)) + list(map(float, columns))
                         + ratings + factors)
        result, output = gardenia_sgd_verifier_oracle(maximum_input, workspace)
        if len(maximum_input) != 92 or result != 32 or len(output) != result:
            raise ValueError("GARDENIA SGD verifier rejected the maximum bounded rating matrix")
        records.append((maximum_input, result, [_output_token(x) for x in output], workspace, 0, 0))
        short_result, short_output = gardenia_sgd_verifier_oracle(maximum_input, workspace-1)
        if short_result != -2 or short_output:
            raise ValueError("GARDENIA SGD verifier returned an invalid short-capacity result")
        records.append((maximum_input, short_result, [], workspace-1, 0, 0))
        null_result, null_output = gardenia_sgd_verifier_oracle(maximum_input, workspace, output_is_null=True)
        if null_result != -2 or null_output:
            raise ValueError("GARDENIA SGD verifier returned an invalid null-output result")
        records.append((maximum_input, null_result, [], workspace, 0, 1))
        invalid_input = list(maximum_input)
        invalid_input[12] = 1.0
        invalid_result, invalid_output = gardenia_sgd_verifier_oracle(invalid_input, workspace)
        if invalid_result != -1 or invalid_output:
            raise ValueError("GARDENIA SGD verifier accepted an out-of-range item ID")
        records.append((invalid_input, invalid_result, [], workspace, 0, 0))
        null_input_result, null_input_output = gardenia_sgd_verifier_oracle(
            [], workspace, input_is_null=True, input_length=0)
        if null_input_result != -1 or null_input_output:
            raise ValueError("GARDENIA SGD verifier returned an invalid null-input result")
        records.append(([], null_input_result, [], workspace, 1, 0))
    elif algorithm == "parboil_stencil_laplacian":
        rng_stencil = random.Random(0x57E11)
        for _case_index in range(32):
            nx, ny, nz = (rng_stencil.randint(3, 5) for _ in range(3))
            steps = rng_stencil.randint(1, 4)
            generated_input = [float(nx), float(ny), float(nz), float(steps)] + [
                rng_stencil.uniform(-8.0, 8.0) for _ in range(nx * ny * nz)]
            result, output = parboil_stencil_laplacian_verifier_oracle(generated_input, workspace)
            if result != nx * ny * nz or len(output) != result:
                raise ValueError("Parboil stencil verifier rejected a bounded generated grid")
            records.append((generated_input, result, [_output_token(value) for value in output],
                            workspace, 0, 0))

        maximum_input = [5.0, 5.0, 5.0, 4.0] + [
            float(((index * 13) % 17) - 8) for index in range(125)]
        maximum_result, maximum_output = parboil_stencil_laplacian_verifier_oracle(
            maximum_input, workspace)
        if maximum_result != 125 or len(maximum_output) != 125:
            raise ValueError("Parboil stencil verifier rejected the maximum-size profile")
        records.append((maximum_input, maximum_result,
                        [_output_token(value) for value in maximum_output], workspace, 0, 0))
        maximum_short_result, maximum_short_output = parboil_stencil_laplacian_verifier_oracle(
            maximum_input, 124)
        if maximum_short_result != -2 or maximum_short_output:
            raise ValueError("Parboil stencil verifier returned an invalid maximum-grid capacity result")
        records.append((maximum_input, maximum_short_result, [], 124, 0, 0))

        for boundary_value in (-8.0, 8.0):
            boundary_input = [3.0, 3.0, 3.0, 4.0] + [boundary_value] * 27
            boundary_result, boundary_output = parboil_stencil_laplacian_verifier_oracle(
                boundary_input, workspace)
            if boundary_result != 27 or len(boundary_output) != 27:
                raise ValueError("Parboil stencil verifier rejected an inclusive grid-value bound")
            records.append((boundary_input, boundary_result,
                            [_output_token(value) for value in boundary_output], workspace, 0, 0))

        malformed_cases = (
            ([2.0, 3.0, 3.0, 1.0] + [0.0] * 27, 31),
            ([3.0, 3.0, 3.0, 1.0] + [0.0] * 26, 30),
            ([3.0, 3.0, 3.0, 1.0, 8.5] + [0.0] * 26, 31),
            ([3.5, 3.0, 3.0, 1.0] + [0.0] * 27, 31),
        )
        for malformed_input, malformed_length in malformed_cases:
            error_result, error_output = parboil_stencil_laplacian_verifier_oracle(
                malformed_input, workspace, input_length=malformed_length)
            if error_result != -1 or error_output:
                raise ValueError("Parboil stencil verifier returned an invalid malformed-input result")
            records.append((malformed_input, error_result, [], workspace, 0, 0))

        valid_input = [3.0, 3.0, 3.0, 2.0] + [0.0] * 27
        for capacity in (0, 26):
            error_result, error_output = parboil_stencil_laplacian_verifier_oracle(
                valid_input, capacity)
            if error_result != -2 or error_output:
                raise ValueError("Parboil stencil capacity oracle returned an invalid result")
            records.append((valid_input, error_result, [], capacity, 0, 0))
        null_result, null_output = parboil_stencil_laplacian_verifier_oracle(
            valid_input, 27, output_is_null=True)
        if null_result != -2 or null_output:
            raise ValueError("Parboil stencil null-output oracle returned an invalid result")
        records.append((valid_input, null_result, [], 27, 0, 1))
        null_result, null_output = parboil_stencil_laplacian_verifier_oracle(
            valid_input, workspace, input_is_null=True, input_length=len(valid_input))
        if null_result != -1 or null_output:
            raise ValueError("Parboil stencil null-input oracle returned an invalid result")
        records.append((valid_input, null_result, [], workspace, 1, 0))
    elif algorithm == "cbench_lame_mid_side":
        generated_inputs = []
        for count in range(1, 33):
            left = [float(((index * 7 + count) % 33) - 16) / 2.0
                    for index in range(count)]
            right = [float(((index * 11 + 2 * count) % 33) - 16) / 2.0
                     for index in range(count)]
            generated_inputs.append([float(count), *left, *right])
        generated_inputs.extend(([32.0, *([16.0] * 32), *([-16.0] * 32)],
                                 [32.0, *([-16.0] * 32), *([16.0] * 32)]))
        for generated_input in generated_inputs:
            result, output = cbench_lame_mid_side_verifier_oracle(generated_input, workspace)
            if (result != 2 * int(generated_input[0]) or len(output) != result
                    or any(not math.isfinite(value) for value in output)):
                raise ValueError("LAME mid-side verifier rejected a bounded channel pair")
            records.append((generated_input, result, [_output_token(value) for value in output],
                            workspace, 0, 0))
        maximum_input = generated_inputs[-2]
        short_result, short_output = cbench_lame_mid_side_verifier_oracle(
            maximum_input, workspace - 1)
        if short_result != -2 or short_output:
            raise ValueError("LAME mid-side verifier returned an invalid short-capacity result")
        records.append((maximum_input, short_result, [], workspace - 1, 0, 0))
        null_result, null_output = cbench_lame_mid_side_verifier_oracle(
            maximum_input, workspace, output_is_null=True)
        if null_result != -2 or null_output:
            raise ValueError("LAME mid-side verifier returned an invalid null-output result")
        records.append((maximum_input, null_result, [], workspace, 0, 1))
        null_input_result, null_input_output = cbench_lame_mid_side_verifier_oracle(
            maximum_input, workspace, input_is_null=True,
            input_length=len(maximum_input))
        if null_input_result != -1 or null_input_output:
            raise ValueError("LAME mid-side verifier returned an invalid null-input result")
        records.append((maximum_input, null_input_result, [], workspace, 1, 0))
    elif algorithm == "cbench_rsynth_natural_glottal_sample":
        for open_samples in (40, 41, 100, 262, 263):
            for sample_index in (0, open_samples - 1, open_samples, 299):
                generated_input = [float(open_samples), float(sample_index)]
                result, output = cbench_rsynth_natural_glottal_verifier_oracle(
                    generated_input, workspace)
                if (result != 1 or len(output) != 1 or not math.isfinite(output[0])
                        or sample_index >= open_samples and output[0] != 0.0):
                    raise ValueError("RSynth verifier rejected a bounded open/closed phase sample")
                records.append((generated_input, result, [_output_token(output[0])],
                                workspace, 0, 0))
        maximum_input = [263.0, 299.0]
        result, output = cbench_rsynth_natural_glottal_verifier_oracle(maximum_input, workspace)
        if result != 1 or output != [0.0]:
            raise ValueError("RSynth verifier failed the maximum closed-phase sample")
        records.append((maximum_input, result, [_output_token(output[0])], workspace, 0, 0))
    elif algorithm == "cbench_rsynth_impulsive_glottal_sample":
        for nopen in (CBENCH_RSYNTH_IMPULSIVE_MIN_OPEN,
                      CBENCH_RSYNTH_IMPULSIVE_MIN_OPEN + 1,
                      CBENCH_RSYNTH_IMPULSIVE_MAX_OPEN):
            for sample_index in (0, 1, 2, 3, 100,
                                 CBENCH_RSYNTH_IMPULSIVE_MAX_SAMPLE_INDEX):
                generated_input = [float(nopen), float(sample_index)]
                result, output = cbench_rsynth_impulsive_glottal_verifier_oracle(
                    generated_input, workspace)
                if result != 1 or len(output) != 1 or not math.isfinite(output[0]):
                    raise ValueError("RSynth impulsive verifier rejected a bounded resonator sample")
                records.append((generated_input, result, [_output_token(output[0])],
                                workspace, 0, 0))
        invalid_inputs = (
            [], [39.0, 1.0], [264.0, 1.0], [40.0, -1.0],
            [40.0, 300.0], [40.0, 1.0, 0.0], [40.5, 1.0], [40.0],
        )
        for invalid_input in invalid_inputs:
            result, output = cbench_rsynth_impulsive_glottal_verifier_oracle(
                invalid_input, workspace)
            if result != -1 or output:
                raise ValueError("RSynth impulsive verifier accepted malformed input")
            records.append((invalid_input, result, [], workspace, 0, 0))
        valid_input = [40.0, 1.0]
        short_result, short_output = cbench_rsynth_impulsive_glottal_verifier_oracle(
            valid_input, 0)
        if short_result != -2 or short_output:
            raise ValueError("RSynth impulsive verifier returned an invalid short-capacity result")
        records.append((valid_input, short_result, [], 0, 0, 0))
        null_result, null_output = cbench_rsynth_impulsive_glottal_verifier_oracle(
            valid_input, workspace, output_is_null=True)
        if null_result != -2 or null_output:
            raise ValueError("RSynth impulsive verifier returned an invalid null-output result")
        records.append((valid_input, null_result, [], workspace, 0, 1))
    records.append((values, -1, [], workspace, 1, 0))
    if algorithm != "md2_digest":
        records.append(([], -1, [], workspace, 0, 0))

    if algorithm in TRAVELLING_SALESMAN_PYTHON_ALGORITHMS:
        tsp_oracle = ORACLES[algorithm]
        tsp_rng = random.Random(20261017 + sorted(TRAVELLING_SALESMAN_PYTHON_ALGORITHMS).index(algorithm))

        def add_tsp_case(inputs: list[float]) -> None:
            result, output = tsp_oracle(inputs, workspace, False)
            if (result <= 0 or result != len(output) or result > workspace
                    or any(not math.isfinite(value) for value in output)):
                raise ValueError(f"{algorithm} rejected a generated valid ABI case")
            records.append((inputs, result, [_output_token(value) for value in output],
                            workspace, 0, 0))

        if algorithm == "travelling_salesman_python_genetic":
            for _ in range(32):
                population = 2 * tsp_rng.randint(1, 4)
                iterations = tsp_rng.randint(0, 12)
                crossover = tsp_rng.random()
                mutation = tsp_rng.random()
                first = (tsp_rng.randint(-16, 16), tsp_rng.randint(-16, 16))
                second = first
                while second == first:
                    second = (tsp_rng.randint(-16, 16), tsp_rng.randint(-16, 16))
                add_tsp_case([float(population), float(iterations), crossover, mutation,
                              float(first[0]), float(first[1]), float(second[0]), float(second[1])])
        else:
            coordinate_bound = (TSP_BRUTEFORCE_COORDINATE_BOUND
                                if algorithm == "travelling_salesman_python_bruteforce"
                                else TSP_HELD_KARP_COORDINATE_BOUND)
            maximum_cities = (TSP_BRUTEFORCE_MAX_CITIES
                              if algorithm == "travelling_salesman_python_bruteforce"
                              else TSP_HELD_KARP_MAX_CITIES)

            def random_tsp_points(city_count: int) -> list[tuple[int, int]]:
                points: list[tuple[int, int]] = []
                while len(points) < city_count:
                    point = (tsp_rng.randint(-coordinate_bound, coordinate_bound),
                             tsp_rng.randint(-coordinate_bound, coordinate_bound))
                    if point not in points:
                        points.append(point)
                return points

            for city_count in range(2, maximum_cities + 1):
                points = random_tsp_points(city_count)
                add_tsp_case([float(city_count),
                              *[float(coordinate) for point in points for coordinate in point]])
            for _ in range(12):
                city_count = tsp_rng.randint(2, maximum_cities)
                points = random_tsp_points(city_count)
                add_tsp_case([float(city_count),
                              *[float(coordinate) for point in points for coordinate in point]])

    if algorithm == "decision_tree_python_regression":
        if (workspace != DECISION_TREE_MAX_OUTPUT_LENGTH
                or absolute_tolerance != 1e-10 or relative_tolerance != 1e-10):
            raise ValueError("decision_tree_python_regression requires a 13-element workspace and 1e-10 tolerances")

        def add_decision_tree_case(
                inputs: list[float], capacity: int = workspace,
                output_is_null: bool = False, input_is_null: bool = False,
                input_length: int | None = None) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            if (len(inputs) > DECISION_TREE_MAX_PARSEABLE_INPUT_LENGTH
                    or any(type(value) not in (int, float) or not math.isfinite(float(value))
                           for value in inputs)
                    or type(capacity) is not int
                    or not 0 <= capacity <= DECISION_TREE_MAX_OUTPUT_LENGTH
                    or type(output_is_null) is not bool
                    or type(input_is_null) is not bool
                    or type(input_length) is not int
                    or not 0 <= input_length <= DECISION_TREE_MAX_PARSEABLE_INPUT_LENGTH
                    or input_is_null and inputs and input_length < len(inputs)
                    or not input_is_null and input_length != len(inputs)):
                raise ValueError("decision_tree_python_regression generated ABI framing is invalid")
            oracle_inputs = [] if input_is_null else inputs
            result, output = decision_tree_python_regression_abi_verifier_oracle(
                oracle_inputs, output_capacity=capacity, output_is_null=output_is_null,
                input_is_null=input_is_null, input_length=input_length)
            if (result >= 0 and (result != len(output)
                                 or result > DECISION_TREE_MAX_OUTPUT_LENGTH
                                 or output_is_null
                                 or any(not math.isfinite(value) for value in output))
                    or result < 0 and (result not in (
                        DECISION_TREE_INVALID_RESULT, DECISION_TREE_OUTPUT_ERROR) or output)):
                raise ValueError("decision_tree_python_regression oracle returned inconsistent ABI framing")
            checker_inputs = [0.0] * input_length if input_is_null else [float(value) for value in inputs]
            records.append((checker_inputs, result, [_output_token(value) for value in output],
                            capacity, int(input_is_null), int(output_is_null)))
            return result, list(output)

        maximum_input = [
            float(DECISION_TREE_MAX_DEPTH), float(DECISION_TREE_MIN_LEAF_SIZE),
            float(DECISION_TREE_MAX_SAMPLE_COUNT),
            *[float(DECISION_TREE_MIN_VALUE + index)
              for index in range(DECISION_TREE_MAX_SAMPLE_COUNT)],
            *[float(DECISION_TREE_MAX_VALUE - index)
              for index in range(DECISION_TREE_MAX_SAMPLE_COUNT)],
            float(DECISION_TREE_MAX_QUERY_COUNT),
            *[float(DECISION_TREE_MIN_VALUE + index)
              for index in range(DECISION_TREE_MAX_QUERY_COUNT)],
        ]
        if len(maximum_input) != DECISION_TREE_MAX_INPUT_LENGTH:
            raise ValueError("decision_tree_python_regression maximum shape has an unexpected length")
        result, output = add_decision_tree_case(maximum_input)
        if result != DECISION_TREE_MAX_OUTPUT_LENGTH or len(output) != result:
            raise ValueError("decision_tree_python_regression oracle rejected its maximum valid shape")
        for capacity in (0, result - 1, result):
            add_decision_tree_case(maximum_input, capacity=capacity)
        add_decision_tree_case(maximum_input, output_is_null=True)
        add_decision_tree_case([], input_is_null=True, input_length=0)
        add_decision_tree_case(maximum_input, input_is_null=True,
                               input_length=DECISION_TREE_MAX_INPUT_LENGTH)
        add_decision_tree_case(maximum_input + [0.0],
                               input_length=DECISION_TREE_MAX_PARSEABLE_INPUT_LENGTH)
        add_decision_tree_case([0.0, 1.0, 13.0])
        add_decision_tree_case([1.0, 1.0, 2.0, 0.0, 1.0, 0.0, 1.0, 13.0])
        add_decision_tree_case([1.5, 1.0, 2.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0])
        add_decision_tree_case([2.0, 1.0, 2.0, 0.5, 1.0, 0.0, 1.0, 1.0, 0.0])
        add_decision_tree_case([1.0, 1.0, 2.0, -9.0, 1.0, 0.0, 1.0, 1.0, 0.0])
        add_decision_tree_case([1.0, 1.0, 2.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0])
        add_decision_tree_case([0.0, 1.0, 2.0], capacity=0, output_is_null=True)

        rng_decision_tree = random.Random(20261017)
        for index in range(64):
            sample_count = rng_decision_tree.randint(
                DECISION_TREE_MIN_SAMPLE_COUNT, DECISION_TREE_MAX_SAMPLE_COUNT)
            query_count = rng_decision_tree.randint(
                DECISION_TREE_MIN_QUERY_COUNT, DECISION_TREE_MAX_QUERY_COUNT)
            inputs = [
                float(rng_decision_tree.randint(DECISION_TREE_MIN_DEPTH, DECISION_TREE_MAX_DEPTH)),
                float(rng_decision_tree.randint(DECISION_TREE_MIN_LEAF_SIZE, DECISION_TREE_MAX_LEAF_SIZE)),
                float(sample_count),
                *[float(rng_decision_tree.randint(DECISION_TREE_MIN_VALUE, DECISION_TREE_MAX_VALUE))
                  for _ in range(sample_count)],
                *[float(rng_decision_tree.randint(DECISION_TREE_MIN_VALUE, DECISION_TREE_MAX_VALUE))
                  for _ in range(sample_count)],
                float(query_count),
                *[float(rng_decision_tree.randint(DECISION_TREE_MIN_VALUE, DECISION_TREE_MAX_VALUE))
                  for _ in range(query_count)],
            ]
            result, output = add_decision_tree_case(inputs)
            if result != query_count + 1 or len(output) != result:
                raise ValueError("decision_tree_python_regression oracle rejected a generated valid input")
            if index % 16 == 0:
                add_decision_tree_case(inputs, capacity=result - 1)
                add_decision_tree_case(inputs, output_is_null=True)

    if algorithm in {"perceptron_java", "perceptron_python", "perceptron_r", "perceptron_rust"}:
        perceptron_specs = {
            "perceptron_java": (
                perceptron_java_abi_verifier_oracle, PERCEPTRON_JAVA_MAX_SAMPLES,
                PERCEPTRON_JAVA_MAX_FEATURES, PERCEPTRON_JAVA_MAX_QUERIES,
                PERCEPTRON_JAVA_MAX_INPUT_LENGTH, PERCEPTRON_JAVA_MAX_PARSEABLE_INPUT_LENGTH,
                PERCEPTRON_JAVA_MAX_OUTPUT_LENGTH, PERCEPTRON_JAVA_INVALID_RESULT,
                PERCEPTRON_JAVA_OUTPUT_ERROR),
            "perceptron_python": (
                perceptron_python_abi_verifier_oracle, PERCEPTRON_PYTHON_MAX_SAMPLES,
                PERCEPTRON_PYTHON_MAX_FEATURES, PERCEPTRON_PYTHON_MAX_QUERIES,
                PERCEPTRON_PYTHON_MAX_INPUT_LENGTH, PERCEPTRON_PYTHON_MAX_PARSEABLE_INPUT_LENGTH,
                PERCEPTRON_PYTHON_MAX_OUTPUT_LENGTH, PERCEPTRON_PYTHON_INVALID_RESULT,
                PERCEPTRON_PYTHON_OUTPUT_ERROR),
            "perceptron_r": (
                perceptron_r_abi_verifier_oracle, PERCEPTRON_R_MAX_SAMPLES,
                PERCEPTRON_R_MAX_FEATURES, PERCEPTRON_R_MAX_QUERIES,
                PERCEPTRON_R_MAX_INPUT_LENGTH, PERCEPTRON_R_MAX_PARSEABLE_INPUT_LENGTH,
                PERCEPTRON_R_MAX_OUTPUT_LENGTH, PERCEPTRON_R_INVALID_RESULT,
                PERCEPTRON_R_OUTPUT_ERROR),
            "perceptron_rust": (
                perceptron_rust_abi_verifier_oracle, PERCEPTRON_RUST_MAX_SAMPLES,
                PERCEPTRON_RUST_MAX_FEATURES, PERCEPTRON_RUST_MAX_QUERIES,
                PERCEPTRON_RUST_MAX_INPUT_LENGTH, PERCEPTRON_RUST_MAX_PARSEABLE_INPUT_LENGTH,
                PERCEPTRON_RUST_MAX_OUTPUT_LENGTH, PERCEPTRON_RUST_INVALID_RESULT,
                PERCEPTRON_RUST_OUTPUT_ERROR),
        }
        (oracle, max_samples, max_features, max_queries, max_input_length,
         max_parseable_length, max_output_length, invalid_result, output_error) = perceptron_specs[algorithm]
        if (workspace != max_output_length
                or absolute_tolerance != 1e-10 or relative_tolerance != 1e-10
                or max_samples != 8 or max_features != 4 or max_queries != 4
                or max_input_length != 61 or max_parseable_length != 62):
            raise ValueError(f"{algorithm} requires its reviewed output workspace and 1e-10 tolerances")

        def add_perceptron_case(
                inputs: list[float], capacity: int = workspace,
                output_is_null: bool = False, input_is_null: bool = False,
                input_length: int | None = None) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            if (len(inputs) > max_parseable_length
                    or any(type(value) not in (int, float) or not math.isfinite(float(value))
                           for value in inputs)
                    or type(capacity) is not int or not 0 <= capacity <= max_output_length
                    or type(output_is_null) is not bool or type(input_is_null) is not bool
                    or type(input_length) is not int or not 0 <= input_length <= max_parseable_length
                    or input_is_null and inputs and input_length < len(inputs)
                    or not input_is_null and input_length != len(inputs)):
                raise ValueError(f"{algorithm} generated ABI framing is invalid")
            result, output = oracle(
                [] if input_is_null else inputs, input_length=input_length,
                output_capacity=capacity, output_is_null=output_is_null,
                input_is_null=input_is_null)
            if (result >= 0 and (result != len(output) or result > max_output_length
                                 or output_is_null
                                 or any(not math.isfinite(value) for value in output))
                    or result < 0 and (result not in (invalid_result, output_error) or output)):
                raise ValueError(f"{algorithm} oracle returned inconsistent ABI framing")
            checker_inputs = [0.0] * input_length if input_is_null else [float(value) for value in inputs]
            records.append((checker_inputs, result, [_output_token(value) for value in output],
                            capacity, int(input_is_null), int(output_is_null)))
            return result, list(output)

        max_feature_values = [float((index % 5) - 2)
                              for index in range(max_samples * max_features)]
        max_query_values = [float(((index + 2) % 5) - 2)
                            for index in range(max_queries * max_features)]
        if algorithm == "perceptron_java":
            max_labels = [float(index % 2) for index in range(max_samples)]
            max_input = [1.0, 12.0, float(max_samples), float(max_features),
                         *max_feature_values, *max_labels, float(max_queries), *max_query_values]
        elif algorithm == "perceptron_python":
            max_labels = [1.0 if index % 2 else -1.0 for index in range(max_samples)]
            max_input = [1.0, 12.0, float(max_samples), float(max_features),
                         *max_feature_values, *max_labels, float(max_queries), *max_query_values]
        elif algorithm == "perceptron_r":
            max_labels = [float((-2, 0, 2)[index % 3]) for index in range(max_samples)]
            max_input = [1.0, 12.0, float(max_samples), float(max_features),
                         *max_feature_values, *max_labels, float(max_queries), *max_query_values]
        else:
            max_labels = [1.0 if index % 2 else -1.0 for index in range(max_samples)]
            max_input = [12.0, 1.0, float(max_samples), float(max_features),
                         *max_feature_values, *max_labels, float(max_queries), *max_query_values]
        if len(max_input) != max_input_length:
            raise ValueError(f"{algorithm} maximum input shape has an unexpected length")
        result, output = add_perceptron_case(max_input)
        if result != max_output_length or len(output) != result:
            raise ValueError(f"{algorithm} oracle rejected its maximum valid shape")
        for capacity in (0, result - 1, result):
            add_perceptron_case(max_input, capacity=capacity)
        add_perceptron_case(max_input, output_is_null=True)
        add_perceptron_case([], input_is_null=True, input_length=0)
        add_perceptron_case(max_input, input_is_null=True, input_length=max_input_length)
        add_perceptron_case(max_input + [0.0], input_length=max_parseable_length)
        bad_learning_rate = list(max_input)
        bad_learning_rate[1 if algorithm == "perceptron_rust" else 0] = 0.125
        add_perceptron_case(bad_learning_rate)
        bad_sample_count = list(max_input)
        bad_sample_count[2] = float(max_samples + 1)
        add_perceptron_case(bad_sample_count)
        fractional = list(max_input)
        fractional[4] = 0.5
        add_perceptron_case(fractional)
        fractional_count = list(max_input)
        fractional_count[2] = 2.5
        add_perceptron_case(fractional_count)
        out_of_range = list(max_input)
        out_of_range[4] = -3.0
        add_perceptron_case(out_of_range)
        bad_query_count = list(max_input)
        query_count_index = 4 + max_samples * max_features + max_samples
        bad_query_count[query_count_index] = 0.0
        add_perceptron_case(bad_query_count)
        bad_labels = list(max_input)
        label_start = 4 + max_samples * max_features
        if algorithm == "perceptron_java":
            bad_labels[label_start] = 2.0
        elif algorithm == "perceptron_r":
            bad_labels[label_start:label_start + max_samples] = [-2.0] * max_samples
        else:
            bad_labels[label_start] = 0.0
        add_perceptron_case(bad_labels)
        add_perceptron_case(bad_learning_rate, capacity=0, output_is_null=True)
        if algorithm == "perceptron_rust":
            zero_iteration_input = list(max_input)
            zero_iteration_input[0] = 0.0
            result, output = add_perceptron_case(zero_iteration_input)
            if result != max_output_length or len(output) != result:
                raise ValueError("perceptron_rust oracle rejected the zero-iteration boundary")

        rng_perceptron = random.Random(20261017)
        for index in range(48):
            sample_count = rng_perceptron.randint(2, max_samples)
            feature_count = rng_perceptron.randint(1, max_features)
            query_count = rng_perceptron.randint(1, max_queries)
            features = [float(rng_perceptron.randint(-2, 2))
                        for _ in range(sample_count * feature_count)]
            queries = [float(rng_perceptron.randint(-2, 2))
                       for _ in range(query_count * feature_count)]
            if algorithm == "perceptron_java":
                labels = [float(rng_perceptron.randint(0, 1)) for _ in range(sample_count)]
                inputs = [float(rng_perceptron.choice((0.25, 0.5, 0.75, 1.0))),
                          float(rng_perceptron.randint(1, 12)), float(sample_count),
                          float(feature_count), *features, *labels, float(query_count), *queries]
            elif algorithm == "perceptron_python":
                labels = [float(rng_perceptron.choice((-1, 1))) for _ in range(sample_count)]
                inputs = [float(rng_perceptron.choice((0.25, 0.5, 0.75, 1.0))),
                          float(rng_perceptron.randint(1, 12)), float(sample_count),
                          float(feature_count), *features, *labels, float(query_count), *queries]
            elif algorithm == "perceptron_r":
                class_count = 2 if sample_count == 2 else rng_perceptron.randint(2, 3)
                classes = (-2, 2) if class_count == 2 else (-2, 0, 2)
                labels = [float(classes[row % class_count]) for row in range(sample_count)]
                inputs = [float(rng_perceptron.choice((0.25, 0.5, 0.75, 1.0))),
                          float(rng_perceptron.randint(1, 12)), float(sample_count),
                          float(feature_count), *features, *labels, float(query_count), *queries]
            else:
                labels = [float(rng_perceptron.choice((-1, 1))) for _ in range(sample_count)]
                inputs = [float(rng_perceptron.randint(0, 12)),
                          float(rng_perceptron.choice((0.25, 0.5, 0.75, 1.0))),
                          float(sample_count), float(feature_count), *features, *labels,
                          float(query_count), *queries]
            result, output = add_perceptron_case(inputs)
            if result <= 0 or len(output) != result:
                raise ValueError(f"{algorithm} oracle rejected a generated valid input")
            if index % 12 == 0:
                add_perceptron_case(inputs, capacity=result - 1)
                add_perceptron_case(inputs, output_is_null=True)

    if algorithm == "pca":
        if workspace != PCA_MAX_OUTPUT_ELEMENTS:
            raise ValueError("pca requires its reviewed 12-element output workspace")
        rng_pca = random.Random(20261017)
        for index in range(96):
            sample_count = rng_pca.randint(PCA_MIN_SAMPLES, PCA_MAX_SAMPLES)
            direction = -1.5 if index % 2 else 1.5
            inputs = [float(sample_count), 2.0, 1.0]
            for sample_index in range(sample_count):
                x = sample_index - (sample_count - 1) / 2.0 + rng_pca.uniform(-0.1, 0.1)
                y = direction * x + rng_pca.uniform(-0.2, 0.2)
                inputs.extend((x, y))
            output = pca_verifier_oracle(inputs)
            if output is None or len(output) != sample_count + 4:
                raise ValueError("pca oracle rejected a generated valid sample matrix")
            records.append((inputs, len(output), [_output_token(value) for value in output],
                            workspace, 0, 0))

        invalid_matrices = (
            [3.0, 2.0, 1.0, 1.0, 5.0, 2.0, 5.0, 3.0, 5.0],
            [4.0, 2.0, 1.0, -1.0, -1.0, -1.0, 1.0, 1.0, -1.0, 1.0, 1.0],
            [3.0, 2.0, 1.0, 1.0, 5.0, 2.0, 5.0, 3.0, 1001.0],
        )
        for inputs in invalid_matrices:
            if pca_verifier_oracle(inputs) is not None:
                raise ValueError("pca oracle accepted a degenerate or out-of-domain matrix")
            records.append((inputs, -1, [], workspace, 0, 0))

    if algorithm == "principle_component_analysis":
        if (workspace != PRINCIPLE_COMPONENT_ANALYSIS_MAX_OUTPUT_LENGTH
                or absolute_tolerance != 1e-8 or relative_tolerance != 1e-8):
            raise ValueError("principle_component_analysis requires a 38-element workspace and 1e-8 tolerances")

        def add_principle_component_analysis_case(
                inputs: list[float], capacity: int = workspace,
                output_is_null: bool = False, input_is_null: bool = False) -> tuple[int, list[float]]:
            result, output = principle_component_analysis_abi_verifier_oracle(
                inputs, capacity, output_is_null, input_is_null)
            records.append((inputs, result, [_output_token(value) for value in output],
                            capacity, int(input_is_null), int(output_is_null)))
            return result, output

        valid_case = next((case for case in workload["cases"]
                           if case["id"] == "maximum_shape_four_components"), None)
        if valid_case is None:
            raise ValueError("principle_component_analysis maximum fixture is missing")
        maximum_input = [float(value) for value in valid_case["input_values"]]
        maximum_result = valid_case["expected_result"]
        if (len(maximum_input) != 35 or maximum_result != PRINCIPLE_COMPONENT_ANALYSIS_MAX_OUTPUT_LENGTH):
            raise ValueError("principle_component_analysis maximum fixture does not fill its workspace")
        for capacity in (0, maximum_result - 1, maximum_result):
            add_principle_component_analysis_case(maximum_input, capacity)
        add_principle_component_analysis_case(maximum_input, output_is_null=True)
        add_principle_component_analysis_case([], input_is_null=True)
        add_principle_component_analysis_case([], output_is_null=True, input_is_null=True)
        add_principle_component_analysis_case(
            [9.0, 2.0, 1.0, *([0.0] * 18)], 0, output_is_null=True)

    if algorithm == "principal_component_analysis":
        if workspace != PRINCIPAL_COMPONENT_ANALYSIS_MAX_OUTPUT_LENGTH:
            raise ValueError("principal_component_analysis requires its reviewed 34-element output workspace")

        def add_principal_component_analysis_case(
                inputs: list[float], capacity: int = workspace,
                output_is_null: bool = False, input_is_null: bool = False) -> tuple[int, list[float]]:
            if (len(inputs) > PRINCIPAL_COMPONENT_ANALYSIS_MAX_INPUT_LENGTH + 1
                    or any(type(value) not in (int, float) for value in inputs)
                    or type(capacity) is not int
                    or not 0 <= capacity <= workspace
                    or type(output_is_null) is not bool
                    or type(input_is_null) is not bool):
                raise ValueError("principal_component_analysis generated ABI framing is invalid")
            raw_output = (None if input_is_null else
                          principal_component_analysis_verifier_oracle(inputs))
            if raw_output is None or type(raw_output) is int:
                result, output = PRINCIPAL_COMPONENT_ANALYSIS_INVALID_RESULT, []
            elif output_is_null or capacity < len(raw_output):
                result, output = -2, []
            else:
                result, output = len(raw_output), raw_output
            if (result >= 0 and (result != len(output)
                                 or result > PRINCIPAL_COMPONENT_ANALYSIS_MAX_OUTPUT_LENGTH
                                 or any(not math.isfinite(value) for value in output))
                    or result < 0 and (result not in (PRINCIPAL_COMPONENT_ANALYSIS_INVALID_RESULT, -2)
                                       or output)):
                raise ValueError("principal_component_analysis oracle returned inconsistent ABI framing")
            records.append((inputs, result, [_output_token(value) for value in output],
                            capacity, int(input_is_null), int(output_is_null)))
            return result, output

        def stable_principal_component_analysis_inputs(
                sample_count: int, feature_count: int, component_count: int,
                rng: random.Random, noise: float = 0.01) -> list[float]:
            values = [float(sample_count), float(feature_count), float(component_count)]
            for row in range(sample_count):
                for feature in range(feature_count):
                    basis = math.cos(math.pi * (row + 0.5) * (feature + 1) / sample_count)
                    values.append(10.0 * (feature_count - feature) * basis
                                  + rng.uniform(-noise, noise))
            return values

        rng_principal_component_analysis = random.Random(20261017)
        for index in range(96):
            feature_count = rng_principal_component_analysis.randint(
                PRINCIPAL_COMPONENT_ANALYSIS_MIN_FEATURES,
                PRINCIPAL_COMPONENT_ANALYSIS_MAX_FEATURES)
            sample_count = rng_principal_component_analysis.randint(
                feature_count + 1, PRINCIPAL_COMPONENT_ANALYSIS_MAX_SAMPLES)
            component_count = rng_principal_component_analysis.randint(1, feature_count)
            inputs = stable_principal_component_analysis_inputs(
                sample_count, feature_count, component_count,
                rng_principal_component_analysis)
            result, output = add_principal_component_analysis_case(inputs)
            if result != 2 + sample_count * component_count or len(output) != result:
                raise ValueError("principal_component_analysis oracle rejected a generated stable matrix")
            if index % 8 == 0:
                add_principal_component_analysis_case(inputs, result - 1)
            if index % 16 == 0:
                add_principal_component_analysis_case(inputs, output_is_null=True)

        maximum_input = stable_principal_component_analysis_inputs(
            PRINCIPAL_COMPONENT_ANALYSIS_MAX_SAMPLES,
            PRINCIPAL_COMPONENT_ANALYSIS_MAX_FEATURES,
            PRINCIPAL_COMPONENT_ANALYSIS_MAX_FEATURES,
            rng_principal_component_analysis, noise=0.0)
        maximum_result, maximum_output = add_principal_component_analysis_case(maximum_input)
        if (len(maximum_input) != PRINCIPAL_COMPONENT_ANALYSIS_MAX_INPUT_LENGTH
                or maximum_result != PRINCIPAL_COMPONENT_ANALYSIS_MAX_OUTPUT_LENGTH
                or len(maximum_output) != PRINCIPAL_COMPONENT_ANALYSIS_MAX_OUTPUT_LENGTH):
            raise ValueError("principal_component_analysis maximum matrix does not fill its workspace")
        for capacity in (0, maximum_result - 1, maximum_result):
            add_principal_component_analysis_case(maximum_input, capacity)
        add_principal_component_analysis_case(maximum_input, output_is_null=True)
        add_principal_component_analysis_case([], input_is_null=True)
        add_principal_component_analysis_case([], output_is_null=True, input_is_null=True)

        invalid_matrices = (
            [1.0, 2.0, 1.0, 0.0, 1.0],
            [3.0, 2.0, 1.0, 0.0, 1.0, 1.0, 0.0],
            [3.0, 2.0, 0.0, 0.0, 1.0, 1.0, 0.0, 2.0, 2.0],
            [3.0, 2.0, 3.0, 0.0, 1.0, 1.0, 0.0, 2.0, 2.0],
            [3.5, 2.0, 1.0, 0.0, 1.0, 1.0, 0.0, 2.0, 2.0],
            [3.0, 2.0, 1.0, 0.0, 1.0, 1.0, 0.0, 2.0, 101.0],
            [3.0, 2.0, 1.0, 0.0, 1.0, 1.0, 0.0, 2.0, float("nan")],
            [float("nan")] * 9,
            [9.0, 2.0, 1.0, *([0.0] * 18)],
            [0.0] * (PRINCIPAL_COMPONENT_ANALYSIS_MAX_INPUT_LENGTH + 1),
        )
        for inputs in invalid_matrices:
            result, output = add_principal_component_analysis_case(list(inputs))
            if result != PRINCIPAL_COMPONENT_ANALYSIS_INVALID_RESULT or output:
                raise ValueError("principal_component_analysis oracle accepted malformed or unstable input")
        result, output = add_principal_component_analysis_case(
            [0.0] * 9, 0, output_is_null=True)
        if result != PRINCIPAL_COMPONENT_ANALYSIS_INVALID_RESULT or output:
            raise ValueError("principal_component_analysis did not validate input before output checks")

    if algorithm == "ramer_douglas_peucker":
        if workspace != RAMER_DOUGLAS_PECKER_MAX_OUTPUT_LENGTH:
            raise ValueError("ramer_douglas_peucker requires its reviewed 25-element output workspace")

        def add_ramer_douglas_peucker_case(
                inputs: list[float], capacity: int = workspace,
                output_is_null: bool = False, input_is_null: bool = False) -> tuple[int, list[float]]:
            if (len(inputs) > RAMER_DOUGLAS_PEUCKER_MAX_INPUT_LENGTH
                    or any(type(value) not in (int, float) for value in inputs)
                    or type(capacity) is not int
                    or not 0 <= capacity <= workspace
                    or type(output_is_null) is not bool
                    or type(input_is_null) is not bool):
                raise ValueError("ramer_douglas_peucker generated ABI framing is invalid")
            raw_output = (None if input_is_null else
                          ramer_douglas_peucker_verifier_oracle(inputs))
            if raw_output is None or type(raw_output) is int:
                result, output = RAMER_DOUGLAS_PEUCKER_INVALID_RESULT, []
            elif output_is_null or capacity < len(raw_output):
                result, output = -2, []
            else:
                result, output = len(raw_output), raw_output
            if (result >= 0 and (result != len(output)
                                 or result > RAMER_DOUGLAS_PEUCKER_MAX_OUTPUT_LENGTH
                                 or any(not math.isfinite(value) for value in output))
                    or result < 0 and (result not in (RAMER_DOUGLAS_PEUCKER_INVALID_RESULT, -2)
                                       or output)):
                raise ValueError("ramer_douglas_peucker oracle returned inconsistent ABI framing")
            records.append((inputs, result, [_output_token(value) for value in output],
                            capacity, int(input_is_null), int(output_is_null)))
            return result, output

        def curved_ramer_douglas_peucker_inputs(
                point_count: int, epsilon: float, rng: random.Random,
                noise: float = 0.005) -> list[float]:
            values = [float(point_count), float(epsilon)]
            for index in range(point_count):
                x = 8.0 * index
                y = 0.05 * index * index + 0.0007 * index * index * index
                y += rng.uniform(-noise, noise)
                values.extend((x, y))
            return values

        rng_ramer_douglas_peucker = random.Random(20261017)
        for index in range(128):
            point_count = rng_ramer_douglas_peucker.randint(3, RAMER_DOUGLAS_PECKER_MAX_POINTS)
            epsilon = rng_ramer_douglas_peucker.choice((0.0, 0.05, 0.25, 0.75, 1.5))
            inputs = curved_ramer_douglas_peucker_inputs(
                point_count, epsilon, rng_ramer_douglas_peucker)
            result, output = add_ramer_douglas_peucker_case(inputs)
            if result <= 0 or len(output) != result:
                raise ValueError("ramer_douglas_peucker oracle rejected a generated common-domain polyline")
            if index % 8 == 0:
                add_ramer_douglas_peucker_case(inputs, result - 1)
            if index % 16 == 0:
                add_ramer_douglas_peucker_case(inputs, output_is_null=True)

        maximum_input = curved_ramer_douglas_peucker_inputs(
            RAMER_DOUGLAS_PEUCKER_MAX_POINTS, 0.0,
            rng_ramer_douglas_peucker, noise=0.003)
        maximum_result, maximum_output = add_ramer_douglas_peucker_case(maximum_input)
        if (len(maximum_input) != RAMER_DOUGLAS_PEUCKER_MAX_INPUT_LENGTH
                or maximum_result != RAMER_DOUGLAS_PEUCKER_MAX_OUTPUT_LENGTH
                or len(maximum_output) != RAMER_DOUGLAS_PEUCKER_MAX_OUTPUT_LENGTH):
            raise ValueError("ramer_douglas_peucker maximum polyline does not fill its workspace")
        for capacity in (0, maximum_result - 1, maximum_result):
            add_ramer_douglas_peucker_case(maximum_input, capacity)
        add_ramer_douglas_peucker_case(maximum_input, output_is_null=True)
        add_ramer_douglas_peucker_case([], input_is_null=True)
        add_ramer_douglas_peucker_case([], output_is_null=True, input_is_null=True)

        invalid_polylines = (
            [], [0.0, -0.1], [3.0, 0.5, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0],
            [3.0, 0.5, 0.0, 0.0, 11.0, 0.0, 10.0, 1.0],
            [2.0, 0.5, 0.0, 0.0, RAMER_DOUGLAS_PEUCKER_MAX_ABS_COORDINATE + 1.0, 1.0],
            [2.0, 0.5, 0.0, 0.0], [3.0, 0.0, 0.0],
            [3.0, 0.5, 0.0, 0.0, 1e-200, 0.0, 2e-200, 0.0],
            [3.0, float("nan"), 0.0, 0.0, 1.0, 0.0, 2.0, 0.0],
            [13.0, 0.0],
        )
        for inputs in invalid_polylines:
            result, output = add_ramer_douglas_peucker_case(list(inputs))
            if result != RAMER_DOUGLAS_PEUCKER_INVALID_RESULT or output:
                raise ValueError("ramer_douglas_peucker oracle accepted malformed or out-of-domain input")
        result, output = add_ramer_douglas_peucker_case(
            [3.0, -0.1, 0.0, 0.0, 1.0, 1.0, 2.0, 0.0],
            0, output_is_null=True)
        if result != RAMER_DOUGLAS_PEUCKER_INVALID_RESULT or output:
            raise ValueError("ramer_douglas_peucker did not validate input before output checks")

    if algorithm == "kalman_filter":
        if workspace != KALMAN_FILTER_MAX_OUTPUT_ELEMENTS:
            raise ValueError("kalman_filter requires its reviewed 36-element output workspace")

        def add_kalman_filter_case(
                inputs: list[float], capacity: int = workspace,
                output_is_null: bool = False, input_is_null: bool = False) -> tuple[int, list[float]]:
            if (len(inputs) > KALMAN_FILTER_MAX_PARSEABLE_INPUT_LENGTH + 1
                    or any(type(value) not in (int, float) or not math.isfinite(float(value))
                           for value in inputs)
                    or type(capacity) is not int
                    or not 0 <= capacity <= workspace
                    or type(output_is_null) is not bool
                    or type(input_is_null) is not bool):
                raise ValueError("kalman_filter generated ABI framing is invalid")
            oracle_inputs = [] if input_is_null else inputs
            result, output = kalman_filter_abi_verifier_oracle(
                oracle_inputs, capacity, output_is_null)
            if (result >= 0 and (result != len(output)
                                 or result > KALMAN_FILTER_MAX_OUTPUT_ELEMENTS
                                 or output_is_null or capacity < result
                                 or any(not math.isfinite(value) for value in output))
                    or result < 0 and (result not in (-1, -2) or output)):
                raise ValueError("kalman_filter oracle returned inconsistent ABI framing")
            records.append((inputs, result, [_output_token(value) for value in output],
                            capacity, int(input_is_null), int(output_is_null)))
            return result, list(output)

        for case in workload["abi_cases"]:
            inputs = [float(value) for value in case["input_values"]]
            result, output = add_kalman_filter_case(
                inputs, case["output_capacity"], case["output_is_null"])
            if (result != case["expected_result"]
                    or not _matches_output(case["expected_output"], output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"kalman_filter ABI fixture mismatch: {case['id']}")

        rng_kalman_filter = random.Random(20261017)
        for trace_index in range(128):
            step_count = rng_kalman_filter.randint(1, KALMAN_FILTER_MAX_STEPS)
            inputs = [
                float(rng_kalman_filter.randint(KALMAN_FILTER_MIN_STATE_MICRO,
                                                 KALMAN_FILTER_MAX_STATE_MICRO)),
                float(rng_kalman_filter.randint(KALMAN_FILTER_MIN_VARIANCE_MICRO,
                                                 KALMAN_FILTER_MAX_VARIANCE_MICRO)),
                float(rng_kalman_filter.randint(KALMAN_FILTER_MIN_VARIANCE_MICRO,
                                                 KALMAN_FILTER_MAX_VARIANCE_MICRO)),
                float(rng_kalman_filter.randint(KALMAN_FILTER_MIN_MEASUREMENT_NOISE_MICRO,
                                                 KALMAN_FILTER_MAX_VARIANCE_MICRO)),
                float(step_count),
            ]
            inputs.extend(float(rng_kalman_filter.randint(
                KALMAN_FILTER_MIN_STATE_MICRO, KALMAN_FILTER_MAX_STATE_MICRO))
                          for _ in range(step_count))
            result, output = add_kalman_filter_case(inputs)
            if result != 3 * step_count or len(output) != result:
                raise ValueError("kalman_filter oracle rejected a generated valid trace")
            if trace_index % 8 == 0:
                add_kalman_filter_case(inputs, result - 1)
            if trace_index % 16 == 0:
                add_kalman_filter_case(inputs, output_is_null=True)

        maximum_case = next(case for case in workload["cases"]
                            if case["id"] == "maximum_step_count")
        maximum_input = [float(value) for value in maximum_case["input_values"]]
        maximum_result, maximum_output = kalman_filter_abi_verifier_oracle(maximum_input)
        if (maximum_result != KALMAN_FILTER_MAX_OUTPUT_ELEMENTS
                or len(maximum_output) != KALMAN_FILTER_MAX_OUTPUT_ELEMENTS):
            raise ValueError("kalman_filter maximum step count does not fill its workspace")
        for capacity in (0, maximum_result - 1, maximum_result):
            add_kalman_filter_case(maximum_input, capacity)
        add_kalman_filter_case(maximum_input, output_is_null=True)

        malformed_kalman_filter = (
            [], [0.0, 1.0, 0.0, 1.0], [0.0, 1.0, 0.0, 1.0, 0.0],
            [0.0, 1.0, 0.0, 1.0, 13.0, 0.0],
            [0.0, 1.0, 0.0, 1.0, 2.0, 0.0],
            [0.0, -1.0, 0.0, 1.0, 1.0, 0.0],
            [0.0, 1.0, -1.0, 1.0, 1.0, 0.0],
            [0.0, 1.0, 0.0, 0.0, 1.0, 0.0],
            [0.0, 1.0, 0.0, 1.0, 1.0, KALMAN_FILTER_MAX_STATE_MICRO + 1.0],
            [0.0, 1.0, 0.0, 1.0, 1.0, 0.5],
            [0.0] * (KALMAN_FILTER_MAX_PARSEABLE_INPUT_LENGTH + 1),
        )
        for inputs in malformed_kalman_filter:
            result, output = add_kalman_filter_case(list(inputs))
            if result != -1 or output:
                raise ValueError("kalman_filter oracle accepted malformed or out-of-domain input")
        invalid_precedence = [0.0, 1.0, 0.0, 0.0, 1.0, 0.0]
        result, output = add_kalman_filter_case(
            invalid_precedence, 0, output_is_null=True)
        if result != -1 or output:
            raise ValueError("kalman_filter did not validate input before output checks")
        null_input_values = [float(value) for value in workload["cases"][0]["input_values"]]
        result, output = add_kalman_filter_case(null_input_values, input_is_null=True)
        if result != -1 or output:
            raise ValueError("kalman_filter accepted a null input pointer")

    if algorithm == "kalman_filter_r_two_state_simulation":
        if workspace != KALMAN_FILTER_R_MAX_OUTPUT_ELEMENTS:
            raise ValueError("kalman_filter_r_two_state_simulation requires its reviewed 30-element workspace")

        def add_kalman_filter_r_case(
                inputs: list[float], capacity: int = workspace,
                output_is_null: bool = False, input_is_null: bool = False,
                input_length: int | None = None) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            if (len(inputs) > KALMAN_FILTER_R_MAX_PARSEABLE_INPUT_LENGTH + 1
                    or any(type(value) not in (int, float) for value in inputs)
                    or type(capacity) is not int
                    or not 0 <= capacity <= KALMAN_FILTER_R_MAX_OUTPUT_ELEMENTS
                    or type(output_is_null) is not bool
                    or type(input_is_null) is not bool
                    or type(input_length) is not int
                    or not 0 <= input_length <= KALMAN_FILTER_R_MAX_PARSEABLE_INPUT_LENGTH + 1
                    or input_is_null and inputs and input_length < len(inputs)
                    or not input_is_null and input_length != len(inputs)):
                raise ValueError("kalman_filter_r_two_state_simulation generated ABI framing is invalid")
            oracle_inputs = [] if input_is_null else inputs
            result, output = kalman_filter_r_abi_verifier_oracle(
                oracle_inputs, capacity, output_is_null)
            if (result >= 0 and (result != len(output)
                                 or result > KALMAN_FILTER_R_MAX_OUTPUT_ELEMENTS
                                 or output_is_null or capacity < result
                                 or any(not math.isfinite(value) for value in output))
                    or result < 0 and (result not in (KALMAN_FILTER_R_INVALID_RESULT,
                                                      KALMAN_FILTER_R_INVALID_OUTPUT_RESULT)
                                       or output)):
                raise ValueError("kalman_filter_r_two_state_simulation oracle returned inconsistent ABI framing")
            records.append((inputs, result, [_output_token(value) for value in output],
                            capacity, int(input_is_null), int(output_is_null)))
            return result, list(output)

        for case in workload["abi_cases"]:
            inputs = [float(value) for value in case["input_values"]]
            result, output = add_kalman_filter_r_case(
                inputs, case["output_capacity"], case["output_is_null"])
            if (result != case["expected_result"]
                    or not _matches_output(case["expected_output"], output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"kalman_filter_r_two_state_simulation ABI fixture mismatch: {case['id']}")

        rng_kalman_filter_r = random.Random(20261017)
        for trace_index in range(96):
            observation_count = rng_kalman_filter_r.randint(
                KALMAN_FILTER_R_MIN_OBSERVATIONS, KALMAN_FILTER_R_MAX_OBSERVATIONS)
            inputs = [float(rng_kalman_filter_r.randint(-1_000_000, 1_000_000) / 1000)
                      for _ in range(observation_count)]
            result, output = add_kalman_filter_r_case(inputs)
            if result != 2 * observation_count + 6 or len(output) != result:
                raise ValueError("kalman_filter_r_two_state_simulation oracle rejected a valid trace")
            if trace_index % 8 == 0:
                add_kalman_filter_r_case(inputs, result - 1)
            if trace_index % 16 == 0:
                add_kalman_filter_r_case(inputs, output_is_null=True)

        maximum_case = next(case for case in workload["cases"]
                            if case["id"] == "maximum_observation_count")
        maximum_input = [float(value) for value in maximum_case["input_values"]]
        maximum_result, maximum_output = kalman_filter_r_abi_verifier_oracle(maximum_input)
        if (maximum_result != KALMAN_FILTER_R_MAX_OUTPUT_ELEMENTS
                or len(maximum_output) != KALMAN_FILTER_R_MAX_OUTPUT_ELEMENTS):
            raise ValueError("kalman_filter_r_two_state_simulation maximum trace does not fill its workspace")
        for capacity in (0, maximum_result - 1, maximum_result):
            add_kalman_filter_r_case(maximum_input, capacity)
        add_kalman_filter_r_case(maximum_input, output_is_null=True)

        malformed_kalman_filter_r = (
            [], [1000.1], [-1000.1], [float("nan")], [float("inf")], [float("-inf")],
            [0.0] * (KALMAN_FILTER_R_MAX_PARSEABLE_INPUT_LENGTH + 1),
        )
        for inputs in malformed_kalman_filter_r:
            result, output = add_kalman_filter_r_case(list(inputs))
            if result != KALMAN_FILTER_R_INVALID_RESULT or output:
                raise ValueError("kalman_filter_r_two_state_simulation oracle accepted invalid observations")
        invalid_precedence = [1000.1]
        result, output = add_kalman_filter_r_case(
            invalid_precedence, 0, output_is_null=True)
        if result != KALMAN_FILTER_R_INVALID_RESULT or output:
            raise ValueError("kalman_filter_r_two_state_simulation did not validate inputs before output checks")
        null_input_values = [0.0]
        result, output = add_kalman_filter_r_case(null_input_values, input_is_null=True)
        if result != KALMAN_FILTER_R_INVALID_RESULT or output:
            raise ValueError("kalman_filter_r_two_state_simulation accepted a null input pointer")

    if algorithm in RISK_METRICS_ALGORITHM_NAMES:
        input_limit = workload["input"]["maximum_parseable_input_length"]
        output_limit = workload["output"]["maximum_elements"]

        def risk_returns(count: int) -> list[float]:
            return [float((index - (count - 1) / 2) * 0.002) for index in range(count)]

        def add_risk_case(
                inputs: list[float], capacity: int = workspace,
                output_is_null: bool = False, input_is_null: bool = False,
                input_length: int | None = None) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            if (len(inputs) > input_limit + 1
                    or any(type(value) not in (int, float) for value in inputs)
                    or type(capacity) is not int
                    or not 0 <= capacity <= output_limit
                    or type(output_is_null) is not bool
                    or type(input_is_null) is not bool
                    or type(input_length) is not int
                    or not 0 <= input_length <= input_limit + 1
                    or input_is_null and inputs and input_length < len(inputs)
                    or not input_is_null and input_length != len(inputs)):
                raise ValueError(f"{algorithm} generated ABI framing is invalid")
            result, output = risk_metrics_abi_verifier_oracle(
                algorithm, inputs, capacity, output_is_null, input_is_null, input_length)
            if (result >= 0 and (result != len(output) or result > output_limit
                                 or output_is_null or capacity < result
                                 or any(not math.isfinite(value) for value in output))
                    or result < 0 and (result not in (RISK_METRICS_INVALID_RESULT,
                                                      RISK_METRICS_OUTPUT_ERROR)
                                       or output)):
                raise ValueError(f"{algorithm} oracle returned inconsistent ABI framing")
            records.append((inputs, result, [_output_token(value) for value in output],
                            capacity, int(input_is_null), int(output_is_null)))
            return result, list(output)

        generated_valid: list[list[float]] = []
        if algorithm in {"monte_carlo_var", "monte_carlo_expected_shortfall"}:
            for simulation_count, return_count in ((20, 20), (40, 32), (128, 64)):
                returns = risk_returns(return_count)
                draws = [float((index % 9 - 4) * 0.25) for index in range(simulation_count)]
                generated_valid.append([100_000.0, 0.95, 4.0, float(simulation_count),
                                        float(return_count), *returns, *draws])
        elif algorithm == "update_returns":
            for return_count in (2, 20, 60):
                generated_valid.append([float(return_count), *risk_returns(return_count)])
        else:
            for return_count, confidence, horizon in ((20, 0.95, 1.0), (32, 0.8, 4.0), (64, 0.5, 10.0)):
                generated_valid.append([100_000.0, confidence, horizon,
                                        float(return_count), *risk_returns(return_count)])
            if algorithm in {"historical_var", "historical_expected_shortfall",
                             "parametric_var", "parametric_expected_shortfall"}:
                generated_valid.append([100_000.0, 0.95, 1.0, 20.0, *([0.01] * 20)])

        for inputs in generated_valid:
            result, output = add_risk_case(inputs)
            if result <= 0 or len(output) != result:
                raise ValueError(f"{algorithm} oracle rejected a generated valid risk trace")
            for capacity, output_is_null in ((0, False), (result - 1, False), (workspace, True)):
                boundary_result, boundary_output = add_risk_case(
                    inputs, capacity, output_is_null=output_is_null)
                if boundary_result != RISK_METRICS_OUTPUT_ERROR or boundary_output:
                    raise ValueError(f"{algorithm} output boundary did not fail without writes")

        maximum_case = max(
            (case for case in workload["cases"] if case["expected_result"] > 0),
            key=lambda case: len(case["input_values"]))
        maximum_input = [float(value) for value in maximum_case["input_values"]]
        maximum_result, maximum_output = risk_metrics_abi_verifier_oracle(algorithm, maximum_input)
        if (maximum_result != len(maximum_output)
                or maximum_result != maximum_case["expected_result"]
                or maximum_result > output_limit):
            raise ValueError(f"{algorithm} maximum workload case does not match its ABI output bounds")
        add_risk_case(maximum_input, maximum_result)

        if algorithm in {"monte_carlo_var", "monte_carlo_expected_shortfall"}:
            invalid = [
                [], [100_000.0, 0.96, 1.0, 20.0, 20.0, *risk_returns(20), *([0.0] * 20)],
                [100_000.0, 0.95, 1.0, 19.0, 20.0, *risk_returns(20), *([0.0] * 19)],
                [100_000.0, 0.95, 1.0, 20.0, 20.0, *([0.01] * 20), *([0.0] * 20)],
                [100_000.0, 0.95, 1.0, 20.0, 20.0, *risk_returns(20), *([0.0] * 19)],
                [100_000.0, 0.95, 1.0, 20.0, 20.0, *risk_returns(20), *([0.0] * 19), 3.1],
                [100_000.0, 0.95, 1.0, 20.0, 20.0, 0.26, *risk_returns(19), *([0.0] * 20)],
                [100_000.0, 0.95, 1.0, 20.0, 20.0, *risk_returns(20), *([0.0] * 20), 0.0],
                [float("nan"), 0.95, 1.0, 20.0, 20.0, *risk_returns(20), *([0.0] * 20)],
            ]
            parser_overflow = [0.0] * (input_limit + 1)
        elif algorithm == "update_returns":
            invalid = [
                [], [1.0, 0.01], [20.0, *([0.01] * 20)],
                [20.0, 0.26, *risk_returns(19)],
                [20.0, *risk_returns(19)], [61.0, *([0.01 * index for index in range(61)])],
                [20.0, *risk_returns(20), 0.0], [float("nan"), *risk_returns(20)],
            ]
            parser_overflow = [62.0, *([0.001 * index for index in range(62)])]
        else:
            invalid = [
                [], [100_000.0, 0.96, 1.0, 20.0, *risk_returns(20)],
                [100_000.0, 0.95, 0.0, 20.0, *risk_returns(20)],
                [100_000.0, 0.95, 1.0, 19.0, *risk_returns(19)],
                [100_000.0, 0.95, 1.0, 20.0, *risk_returns(19)],
                [100_000.0, 0.95, 1.0, 20.0, 0.26, *risk_returns(19)],
                [100_000.0, 0.95, 1.0, 20.0, *risk_returns(20), 0.0],
                [float("nan"), 0.95, 1.0, 20.0, *risk_returns(20)],
            ]
            if algorithm in {"historical_var", "historical_expected_shortfall", "generate_risk_report"}:
                invalid.append([100_000.0, 0.96, 1.0, 20.0, *risk_returns(20)])
            if algorithm == "generate_risk_report":
                invalid.append([100_000.0, 0.95, 1.0, 20.0, *([0.01] * 20)])
            parser_overflow = [0.0] * (input_limit + 1)
        for inputs in invalid + [parser_overflow]:
            result, output = add_risk_case(list(inputs))
            if result != RISK_METRICS_INVALID_RESULT or output:
                raise ValueError(f"{algorithm} oracle accepted malformed, nonfinite, or oversized input")
        invalid_precedence = [float("nan")]
        result, output = add_risk_case(invalid_precedence, 0, output_is_null=True)
        if result != RISK_METRICS_INVALID_RESULT or output:
            raise ValueError(f"{algorithm} did not validate input before output pointer/capacity")
        valid_for_null = generated_valid[0]
        result, output = add_risk_case(valid_for_null, input_is_null=True)
        if result != RISK_METRICS_INVALID_RESULT or output:
            raise ValueError(f"{algorithm} accepted a null input pointer")

    if algorithm == "muon_optimizer":
        input_limit = MUON_OPTIMIZER_MAX_PARSEABLE_INPUT_LENGTH
        output_limit = MUON_OPTIMIZER_MAX_OUTPUT_ELEMENTS

        def add_muon_case(
                inputs: list[float], capacity: int = workspace,
                output_is_null: bool = False, input_is_null: bool = False,
                input_length: int | None = None) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            if (len(inputs) > input_limit + 1
                    or any(type(value) not in (int, float) for value in inputs)
                    or type(capacity) is not int
                    or not 0 <= capacity <= output_limit
                    or type(output_is_null) is not bool
                    or type(input_is_null) is not bool
                    or type(input_length) is not int
                    or not 0 <= input_length <= input_limit + 1
                    or input_is_null and inputs and input_length < len(inputs)
                    or not input_is_null and input_length != len(inputs)):
                raise ValueError("muon_optimizer generated ABI framing is invalid")
            result, output = muon_optimizer_abi_verifier_oracle(
                inputs, capacity, output_is_null, input_is_null, input_length)
            if (result >= 0 and (result != len(output) or result > output_limit
                                 or output_is_null or capacity < result
                                 or any(not math.isfinite(value) for value in output))
                    or result < 0 and (result not in (MUON_OPTIMIZER_INVALID_RESULT,
                                                      MUON_OPTIMIZER_OUTPUT_ERROR)
                                       or output)):
                raise ValueError("muon_optimizer oracle returned inconsistent ABI framing")
            checker_inputs = [0.0] * input_length if input_is_null else inputs
            records.append((checker_inputs, result, [_output_token(value) for value in output],
                            capacity, int(input_is_null), int(output_is_null)))
            return result, list(output)

        def muon_trace(group_count: int, rows: int, columns: int,
                       call_count: int, ns_steps: int) -> list[float]:
            matrix_elements = rows * columns
            inputs = [float(group_count), float(rows), float(columns), float(call_count),
                      float(ns_steps), 0.05, 0.8]
            for call_index in range(call_count):
                param_id = call_index % group_count
                inputs.append(float(param_id))
                inputs.extend(float((param_id * 10 + call_index + index) / 100.0)
                              for index in range(matrix_elements))
                inputs.extend(float(((index + call_index) % 5 - 2) * 0.001)
                              for index in range(matrix_elements))
            return inputs

        for case in workload["abi_cases"]:
            inputs = [float(value) for value in case["input_values"]]
            result, output = add_muon_case(
                inputs, case["output_capacity"], case["output_is_null"],
                case["input_is_null"], case["input_length"])
            if (result != case["expected_result"]
                    or not _same_float64_sequence(output, case["expected_output"])):
                raise ValueError(f"muon_optimizer ABI workload mismatch: {case['id']}")

        for inputs in (muon_trace(1, 2, 3, 1, 0), muon_trace(2, 4, 4, 8, 5),
                       muon_trace(4, 1, 4, 4, 2), muon_trace(1, 4, 1, 8, 5)):
            result, output = add_muon_case(inputs)
            if result <= 0 or len(output) != result:
                raise ValueError("muon_optimizer oracle rejected a generated valid trace")
            for capacity, output_is_null in ((result, False), (0, False),
                                             (result - 1, False), (output_limit, True)):
                boundary_result, boundary_output = add_muon_case(
                    inputs, capacity, output_is_null=output_is_null)
                if capacity == result and not output_is_null:
                    if boundary_result != result or not _same_float64_sequence(boundary_output, output):
                        raise ValueError("muon_optimizer exact output capacity changed the result")
                elif boundary_result != MUON_OPTIMIZER_OUTPUT_ERROR or boundary_output:
                    raise ValueError("muon_optimizer output boundary did not fail without writes")

        malformed = [
            [], [1.0, 1.0, 1.0, 1.0, 0.0, 0.1, 0.5],
            [1.0, 1.5, 1.0, 1.0, 0.0, 0.1, 0.5, 0.0, 1.0, 0.0, 0.0, 0.0],
            [float("nan")], [0.0] * (input_limit + 1),
        ]
        for inputs in malformed:
            result, output = add_muon_case(inputs)
            if result != MUON_OPTIMIZER_INVALID_RESULT or output:
                raise ValueError("muon_optimizer oracle accepted malformed, nonfinite, or oversized input")
        result, output = add_muon_case([float("nan")], 0, output_is_null=True)
        if result != MUON_OPTIMIZER_INVALID_RESULT or output:
            raise ValueError("muon_optimizer did not validate input before output checks")
        result, output = add_muon_case([], input_is_null=True, input_length=7)
        if result != MUON_OPTIMIZER_INVALID_RESULT or output:
            raise ValueError("muon_optimizer accepted a null input pointer")

    if algorithm == "pseudo_inverse":
        if (workspace != PSEUDO_INVERSE_MAX_OUTPUT_LENGTH
                or absolute_tolerance != 1e-10 or relative_tolerance != 1e-10
                or PSEUDO_INVERSE_MAX_PARSEABLE_INPUT_LENGTH != 7):
            raise ValueError("pseudo_inverse requires its reviewed six-element workspace and 1e-10 tolerances")

        def add_pseudo_inverse_case(
                inputs: list[float], capacity: int = workspace,
                output_is_null: bool = False, input_is_null: bool = False,
                input_length: int | None = None) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            if (len(inputs) > PSEUDO_INVERSE_MAX_PARSEABLE_INPUT_LENGTH + 1
                    or any(type(value) not in (int, float) for value in inputs)
                    or type(capacity) is not int
                    or not 0 <= capacity <= PSEUDO_INVERSE_MAX_OUTPUT_LENGTH
                    or type(output_is_null) is not bool
                    or type(input_is_null) is not bool
                    or type(input_length) is not int
                    or not 0 <= input_length <= PSEUDO_INVERSE_MAX_PARSEABLE_INPUT_LENGTH + 1
                    or input_is_null and inputs and input_length < len(inputs)
                    or not input_is_null and input_length != len(inputs)):
                raise ValueError("pseudo_inverse generated ABI framing is invalid")
            oracle_values = [] if input_is_null else inputs
            result, output = pseudo_inverse_abi_verifier_oracle(
                oracle_values, input_length=input_length, output_capacity=capacity,
                output_is_null=output_is_null, input_is_null=input_is_null)
            if (result >= 0 and (result != len(output)
                                 or result > PSEUDO_INVERSE_MAX_OUTPUT_LENGTH
                                 or output_is_null or capacity < result
                                 or any(not math.isfinite(value) for value in output))
                    or result < 0 and (result not in (PSEUDO_INVERSE_INVALID_RESULT,
                                                      PSEUDO_INVERSE_OUTPUT_ERROR)
                                       or output)):
                raise ValueError("pseudo_inverse oracle returned inconsistent ABI framing")
            checker_inputs = ([0.0] * input_length if input_is_null
                              else [float(value) for value in inputs])
            records.append((checker_inputs, result, [_output_token(value) for value in output],
                            capacity, int(input_is_null), int(output_is_null)))
            return result, list(output)

        valid_inputs = (
            [1.0, 1.0, 2.0],
            [2.0, 1.0, 3.0, 4.0],
            [4.0, 1.0, 1.0, 2.0, -2.0, 1.0],
            [4.0, 1.0, 0.0, 0.0, 0.0, 0.0],
        )
        for inputs in valid_inputs:
            result, output = add_pseudo_inverse_case(inputs)
            if result != 2 + int(inputs[0]) or len(output) != result:
                raise ValueError("pseudo_inverse oracle rejected a valid one-column input")
            for capacity in (0, result - 1, result):
                boundary_result, boundary_output = add_pseudo_inverse_case(inputs, capacity)
                if capacity == result:
                    if (boundary_result != result
                            or not _matches_output(output, boundary_output,
                                                   absolute_tolerance, relative_tolerance)):
                        raise ValueError("pseudo_inverse exact output capacity changed the result")
                elif boundary_result != PSEUDO_INVERSE_OUTPUT_ERROR or boundary_output:
                    raise ValueError("pseudo_inverse short output capacity did not fail without writes")
            null_result, null_output = add_pseudo_inverse_case(inputs, output_is_null=True)
            if null_result != PSEUDO_INVERSE_OUTPUT_ERROR or null_output:
                raise ValueError("pseudo_inverse null output did not fail without writes")

        rng_pseudo_inverse = random.Random(20261017)
        for index in range(64):
            row_count = rng_pseudo_inverse.randint(1, 4)
            column = [float(rng_pseudo_inverse.randint(-4, 4)) for _ in range(row_count)]
            inputs = [float(row_count), 1.0, *column]
            result, output = add_pseudo_inverse_case(inputs)
            if result != row_count + 2 or len(output) != result:
                raise ValueError("pseudo_inverse oracle rejected a generated valid column")
            if index % 16 == 0:
                add_pseudo_inverse_case(inputs, result - 1)
                add_pseudo_inverse_case(inputs, output_is_null=True)

        malformed = (
            [], [1.0, 1.0], [0.0, 1.0, 0.0], [5.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0],
            [1.5, 1.0, 1.0], [2.0, 2.0, 1.0, 0.0, 0.0, 1.0],
            [2.0, 1.0, 1.0], [2.0, 1.0, 1.5, 0.0],
            [1.0, 1.0, 5.0], [float("nan"), 1.0, 0.0],
            [1.0, 1.0, float("inf")], [1.0] * (PSEUDO_INVERSE_MAX_PARSEABLE_INPUT_LENGTH + 1),
        )
        for inputs in malformed:
            result, output = add_pseudo_inverse_case(list(inputs))
            if result != PSEUDO_INVERSE_INVALID_RESULT or output:
                raise ValueError("pseudo_inverse oracle accepted malformed or oversized input")
        result, output = add_pseudo_inverse_case(
            [5.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0], capacity=0, output_is_null=True)
        if result != PSEUDO_INVERSE_INVALID_RESULT or output:
            raise ValueError("pseudo_inverse did not validate input before output checks")
        result, output = add_pseudo_inverse_case([0.0] * 6, input_is_null=True, input_length=6)
        if result != PSEUDO_INVERSE_INVALID_RESULT or output:
            raise ValueError("pseudo_inverse accepted a null input pointer")

    if algorithm == "tdigest":
        if (workspace != TDIGEST_WORKSPACE_ELEMENTS
                or absolute_tolerance != 1e-10 or relative_tolerance != 1e-10
                or (TDIGEST_MIN_COMPRESSION, TDIGEST_MAX_COMPRESSION, TDIGEST_MAX_SAMPLES,
                    TDIGEST_MAX_QUERIES, TDIGEST_MAX_INPUT_LENGTH,
                    TDIGEST_MAX_PARSEABLE_INPUT_LENGTH, TDIGEST_MAX_OUTPUT_LENGTH)
                != (10, 20, 32, 4, 44, 45, 10)):
            raise ValueError("tdigest requires its reviewed ten-element output workspace and 1e-10 tolerances")

        def add_tdigest_case(
                inputs: list[float], capacity: int = workspace,
                output_is_null: bool = False, input_is_null: bool = False,
                input_length: int | None = None) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            if (len(inputs) > TDIGEST_MAX_PARSEABLE_INPUT_LENGTH + 1
                    or any(type(value) not in (int, float) for value in inputs)
                    or type(capacity) is not int
                    or not 0 <= capacity <= workspace
                    or type(output_is_null) is not bool
                    or type(input_is_null) is not bool
                    or type(input_length) is not int
                    or not 0 <= input_length <= TDIGEST_MAX_PARSEABLE_INPUT_LENGTH + 1
                    or input_is_null and inputs and input_length < len(inputs)
                    or not input_is_null and input_length != len(inputs)):
                raise ValueError("tdigest generated ABI framing is invalid")
            oracle_values = [] if input_is_null else inputs
            result, output = tdigest_abi_verifier_oracle(
                oracle_values, input_length=input_length, output_capacity=capacity,
                output_is_null=output_is_null, input_is_null=input_is_null)
            if (result >= 0 and (result != len(output)
                                 or result > TDIGEST_MAX_OUTPUT_LENGTH
                                 or output_is_null or capacity < result
                                 or any(not math.isfinite(value) for value in output))
                    or result < 0 and (result not in (TDIGEST_INVALID_RESULT,
                                                      TDIGEST_OUTPUT_ERROR)
                                       or output)):
                raise ValueError("tdigest oracle returned inconsistent ABI framing")
            checker_inputs = ([0.0] * input_length if input_is_null
                              else [float(value) for value in inputs])
            records.append((checker_inputs, result, [_output_token(value) for value in output],
                            capacity, int(input_is_null), int(output_is_null)))
            return result, list(output)

        def tdigest_input(compression: int, samples: list[int],
                          probabilities: list[float], cdf_values: list[int]) -> list[float]:
            return [float(compression), float(len(samples)), *map(float, samples),
                    float(len(probabilities)), *probabilities,
                    float(len(cdf_values)), *map(float, cdf_values)]

        for case in workload["cases"]:
            inputs = [float(value) for value in case["input_values"]]
            result, output = add_tdigest_case(
                inputs, case["output_capacity"], input_length=case["input_length"])
            if (result != case["expected_result"]
                    or not _matches_output(case["expected_output"], output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"tdigest workload ABI fixture mismatch: {case['id']}")

        maximum_samples = list(range(-8, 8)) * 2
        maximum_input = tdigest_input(10, maximum_samples, [0.0, 0.25, 0.5, 1.0],
                                      [-8, 0, 7, 8])
        if len(maximum_input) != TDIGEST_MAX_INPUT_LENGTH:
            raise ValueError("tdigest maximum input has an unexpected packed length")
        maximum_result, maximum_output = add_tdigest_case(maximum_input)
        if (maximum_result != TDIGEST_MAX_OUTPUT_LENGTH
                or len(maximum_output) != TDIGEST_MAX_OUTPUT_LENGTH):
            raise ValueError("tdigest oracle rejected its maximum valid input")
        for capacity in (0, maximum_result - 1, maximum_result):
            result, output = add_tdigest_case(maximum_input, capacity)
            if capacity == maximum_result:
                if (result != maximum_result
                        or not _matches_output(maximum_output, output,
                                               absolute_tolerance, relative_tolerance)):
                    raise ValueError("tdigest exact output capacity changed the result")
            elif result != TDIGEST_OUTPUT_ERROR or output:
                raise ValueError("tdigest output capacity boundary did not fail without writes")
        result, output = add_tdigest_case(maximum_input, output_is_null=True)
        if result != TDIGEST_OUTPUT_ERROR or output:
            raise ValueError("tdigest null output did not fail without writes")

        rng_tdigest = random.Random(20261017)
        for index in range(96):
            sample_count = rng_tdigest.randint(1, TDIGEST_MAX_SAMPLES)
            quantile_count = rng_tdigest.randint(1, TDIGEST_MAX_QUERIES)
            cdf_count = rng_tdigest.randint(1, TDIGEST_MAX_QUERIES)
            samples = [rng_tdigest.randint(-8, 8) for _ in range(sample_count)]
            probabilities = [rng_tdigest.randint(0, 4) / 4.0
                             for _ in range(quantile_count)]
            cdf_values = [rng_tdigest.randint(-8, 8) for _ in range(cdf_count)]
            inputs = tdigest_input(rng_tdigest.randint(TDIGEST_MIN_COMPRESSION,
                                                        TDIGEST_MAX_COMPRESSION),
                                   samples, probabilities, cdf_values)
            result, output = add_tdigest_case(inputs)
            if result != quantile_count + cdf_count + 2 or len(output) != result:
                raise ValueError("tdigest oracle rejected a generated valid stream")
            if index % 16 == 0:
                add_tdigest_case(inputs, result - 1)
                add_tdigest_case(inputs, output_is_null=True)

        malformed = (
            [], [10.0, 1.0, 5.0, 1.0, 0.5, 1.0],
            [9.0, 1.0, 5.0, 1.0, 0.5, 1.0, 5.0],
            [21.0, 1.0, 5.0, 1.0, 0.5, 1.0, 5.0],
            [10.0, 0.0, 1.0, 0.5, 1.0, 5.0],
            [10.0, 33.0, *([0.0] * 33), 1.0, 0.5, 1.0, 0.0],
            [10.0, 1.0, 9.0, 1.0, 0.5, 1.0, 5.0],
            [10.0, 1.0, 0.5, 1.0, 0.5, 1.0, 5.0],
            [10.0, 1.0, 5.0, 1.0, 0.3, 1.0, 5.0],
            [10.0, 1.0, 5.0, 1.0, 0.5, 1.0, 8.5],
            [10.0, 1.0, float("nan"), 1.0, 0.5, 1.0, 5.0],
            maximum_input + [0.0], [0.0] * (TDIGEST_MAX_PARSEABLE_INPUT_LENGTH + 1),
        )
        for inputs in malformed:
            result, output = add_tdigest_case(list(inputs))
            if result != TDIGEST_INVALID_RESULT or output:
                raise ValueError("tdigest oracle accepted malformed or oversized input")
        result, output = add_tdigest_case(
            [9.0, 1.0, 5.0, 1.0, 0.5, 1.0, 5.0], capacity=0, output_is_null=True)
        if result != TDIGEST_INVALID_RESULT or output:
            raise ValueError("tdigest did not validate input before output checks")
        result, output = add_tdigest_case([0.0] * 7, input_is_null=True, input_length=7)
        if result != TDIGEST_INVALID_RESULT or output:
            raise ValueError("tdigest accepted a null input pointer")

    if algorithm == "local_weighted_learning":
        if workspace != LOCAL_WEIGHTED_LEARNING_MAX_OUTPUT_ELEMENTS:
            raise ValueError("local_weighted_learning requires its reviewed 16-element workspace")

        def add_local_weighted_learning_case(
                inputs: list[float], capacity: int = workspace,
                output_is_null: bool = False, input_is_null: bool = False,
                input_length: int | None = None) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            if (len(inputs) > LOCAL_WEIGHTED_LEARNING_MAX_PARSEABLE_INPUT_LENGTH + 1
                    or any(type(value) not in (int, float) for value in inputs)
                    or type(capacity) is not int
                    or not 0 <= capacity <= LOCAL_WEIGHTED_LEARNING_MAX_OUTPUT_ELEMENTS
                    or type(output_is_null) is not bool
                    or type(input_is_null) is not bool
                    or type(input_length) is not int
                    or not 0 <= input_length <= LOCAL_WEIGHTED_LEARNING_MAX_PARSEABLE_INPUT_LENGTH + 1
                    or input_is_null and inputs
                    or not input_is_null and input_length != len(inputs)):
                raise ValueError("local_weighted_learning generated ABI framing is invalid")
            oracle_inputs = [] if input_is_null else inputs
            result, output = local_weighted_learning_abi_oracle(
                oracle_inputs, capacity, output_is_null, input_is_null, input_length)
            if (result >= 0 and (
                    result != len(output)
                    or result > LOCAL_WEIGHTED_LEARNING_MAX_OUTPUT_ELEMENTS
                    or any(not math.isfinite(value) for value in output))
                    or result < 0 and (result not in (
                        LOCAL_WEIGHTED_LEARNING_INVALID_RESULT,
                        LOCAL_WEIGHTED_LEARNING_OUTPUT_ERROR) or output)):
                raise ValueError("local_weighted_learning oracle returned inconsistent ABI framing")
            checker_inputs = [0.0] * input_length if input_is_null else inputs
            records.append((checker_inputs, result, [_output_token(value) for value in output],
                            capacity, int(input_is_null), int(output_is_null)))
            return result, output

        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if (not isinstance(raw_values, list)
                    or any(type(value) not in (int, float)
                           or not math.isfinite(float(value)) for value in raw_values)):
                raise ValueError(
                    f"local_weighted_learning ABI values are invalid: {case.get('id')}")
            inputs = [float(value) for value in raw_values]
            capacity = case.get("output_capacity")
            output_is_null = case.get("output_is_null")
            input_is_null = case.get("input_is_null")
            input_length = case.get("input_length")
            result, output = add_local_weighted_learning_case(
                inputs, capacity, output_is_null, input_is_null, input_length)
            if (result != case.get("expected_result")
                    or not _matches_output(
                        case.get("expected_output"), output,
                        absolute_tolerance, relative_tolerance)):
                raise ValueError(
                    f"local_weighted_learning ABI fixture mismatch: {case.get('id')}")

        rng_local_weighted = random.Random(20261017)
        for trace_index in range(128):
            sample_count = 2 + trace_index % (LOCAL_WEIGHTED_LEARNING_MAX_N - 1)
            dimension = 1 + trace_index % min(LOCAL_WEIGHTED_LEARNING_MAX_D, sample_count)
            tau = (2.0 if trace_index % 3 == 0 else
                   8.0 if trace_index % 3 == 1 else
                   (32 + rng_local_weighted.randrange(97)) / 16.0)
            matrix = []
            for row_index in range(sample_count):
                if row_index < dimension:
                    row = [1.0 if feature_index == row_index else 0.0
                           for feature_index in range(dimension)]
                else:
                    row = [rng_local_weighted.randrange(-64, 65) / 16.0
                           for _ in range(dimension)]
                matrix.extend(row)
            responses = [rng_local_weighted.randrange(-128, 129) / 16.0
                         for _ in range(sample_count)]
            inputs = [float(sample_count), float(dimension), tau, *matrix, *responses]
            result, output = add_local_weighted_learning_case(inputs)
            if result != sample_count or len(output) != sample_count:
                raise ValueError("local_weighted_learning oracle rejected a generated valid design")
            if trace_index % 16 == 0:
                add_local_weighted_learning_case(inputs, capacity=sample_count - 1)
                add_local_weighted_learning_case(inputs, output_is_null=True)

        maximum_case = next(
            case for case in workload["cases"] if case["id"] == "maximum_sample_count")
        maximum_input = [float(value) for value in maximum_case["input_values"]]
        for capacity in (0, LOCAL_WEIGHTED_LEARNING_MAX_OUTPUT_ELEMENTS - 1,
                         LOCAL_WEIGHTED_LEARNING_MAX_OUTPUT_ELEMENTS, workspace):
            add_local_weighted_learning_case(maximum_input, capacity=capacity)
        add_local_weighted_learning_case(maximum_input, output_is_null=True)
        add_local_weighted_learning_case(maximum_input + [0.0])
        add_local_weighted_learning_case(maximum_input + [0.0, 0.0])

        valid_small = [2.0, 1.0, 2.0, 1.0, 0.0, 1.0, -1.0]
        add_local_weighted_learning_case(valid_small, capacity=1)
        add_local_weighted_learning_case(valid_small, output_is_null=True)
        add_local_weighted_learning_case([], input_is_null=True, input_length=0)
        add_local_weighted_learning_case([], input_is_null=True, output_is_null=True,
                                         input_length=5)
        malformed = (
            [], [1.0, 1.0, 2.0], [2.5, 1.0, 2.0, 1.0, 0.0, 1.0, -1.0],
            [2.0, 5.0, 2.0], [2.0, 3.0, 2.0],
            [2.0, 1.0, 2.0, 0.0, 0.0, 0.0, 0.0],
            [2.0, 1.0, 2.1, 1.0, 0.0, 1.0, -1.0],
            [2.0, 1.0, 2.0, 4.1, 0.0, 1.0, -1.0],
            [2.0, 1.0, 2.0, 1.0, 0.0, 8.1, -1.0],
        )
        for inputs in malformed:
            add_local_weighted_learning_case(inputs)
        add_local_weighted_learning_case(malformed[0], capacity=0, output_is_null=True)

    if algorithm == "linear_discriminant_analysis":
        if workspace != LINEAR_DISCRIMINANT_ANALYSIS_MAX_OUTPUT_ELEMENTS:
            raise ValueError("linear_discriminant_analysis requires its reviewed 16-element workspace")

        def add_linear_discriminant_analysis_case(
                inputs: list[float], capacity: int = workspace,
                output_is_null: bool = False, input_is_null: bool = False,
                input_length: int | None = None) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            if (len(inputs) > LINEAR_DISCRIMINANT_ANALYSIS_MAX_PARSEABLE_INPUT_LENGTH + 1
                    or any(type(value) not in (int, float) for value in inputs)
                    or type(capacity) is not int
                    or not 0 <= capacity <= LINEAR_DISCRIMINANT_ANALYSIS_MAX_OUTPUT_ELEMENTS
                    or type(output_is_null) is not bool
                    or type(input_is_null) is not bool
                    or type(input_length) is not int
                    or not 0 <= input_length <= LINEAR_DISCRIMINANT_ANALYSIS_MAX_PARSEABLE_INPUT_LENGTH + 1
                    or input_is_null and inputs
                    or not input_is_null and input_length != len(inputs)):
                raise ValueError("linear_discriminant_analysis generated ABI framing is invalid")
            oracle_inputs = [] if input_is_null else inputs
            result, output = linear_discriminant_analysis_abi_oracle(
                oracle_inputs, capacity, output_is_null, input_is_null, input_length)
            if (result >= 0 and (result != len(output)
                                 or result > LINEAR_DISCRIMINANT_ANALYSIS_MAX_OUTPUT_ELEMENTS
                                 or any(not math.isfinite(value) for value in output)
                                 or output_is_null)
                    or result < 0 and (result not in (
                        LINEAR_DISCRIMINANT_ANALYSIS_INVALID_RESULT,
                        LINEAR_DISCRIMINANT_ANALYSIS_OUTPUT_ERROR) or output)):
                raise ValueError("linear_discriminant_analysis oracle returned inconsistent ABI framing")
            checker_inputs = [0.0] * input_length if input_is_null else inputs
            records.append((checker_inputs, result, [_output_token(value) for value in output],
                            capacity, int(input_is_null), int(output_is_null)))
            return result, list(output)

        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            inputs = _decode_linear_discriminant_analysis_abi_values(raw_values)
            capacity = case.get("output_capacity", workspace)
            output_is_null = case.get("output_is_null", False)
            input_is_null = case.get("input_is_null", False)
            input_length = case.get("input_length")
            result, output = add_linear_discriminant_analysis_case(
                inputs, capacity, output_is_null, input_is_null, input_length)
            if (result != case.get("expected_result")
                    or not _matches_output(case.get("expected_output"), output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"linear_discriminant_analysis ABI fixture mismatch: {case.get('id')}")

        rng_lda = random.Random(20261018)
        for trace_index in range(128):
            class_count = rng_lda.randint(2, LINEAR_DISCRIMINANT_ANALYSIS_MAX_CLASSES)
            remaining = LINEAR_DISCRIMINANT_ANALYSIS_MAX_TOTAL_SAMPLES
            counts = []
            for class_index in range(class_count):
                minimum_remaining = 2 * (class_count - class_index - 1)
                maximum_count = min(6, remaining - minimum_remaining)
                count = rng_lda.randint(2, maximum_count)
                counts.append(count)
                remaining -= count
            samples = []
            for class_index, count in enumerate(counts):
                center = (class_index - (class_count - 1) / 2.0) * 14.0
                samples.extend(center + 2 * index - (count - 1) for index in range(count))
            inputs = [float(class_count), *(float(count) for count in counts),
                      *(float(value) for value in samples)]
            result, output = add_linear_discriminant_analysis_case(inputs)
            if result <= 0 or result != len(output):
                raise ValueError("linear_discriminant_analysis oracle rejected a generated valid design")
            if trace_index % 16 == 0:
                add_linear_discriminant_analysis_case(inputs, capacity=result - 1)
                add_linear_discriminant_analysis_case(inputs, output_is_null=True)

        maximum_case = next(case for case in workload["cases"]
                            if case["id"] == "maximum_bounded_training_set")
        maximum_input = [float(value) for value in maximum_case["input_values"]]
        maximum_result, maximum_output = linear_discriminant_analysis_abi_oracle(maximum_input)
        if (len(maximum_input) != LINEAR_DISCRIMINANT_ANALYSIS_MAX_VALID_INPUT_LENGTH
                or maximum_result != LINEAR_DISCRIMINANT_ANALYSIS_MAX_OUTPUT_ELEMENTS
                or len(maximum_output) != LINEAR_DISCRIMINANT_ANALYSIS_MAX_TOTAL_SAMPLES):
            raise ValueError("linear_discriminant_analysis maximum workload shape is inconsistent")
        for capacity in (0, maximum_result - 1, maximum_result, workspace):
            add_linear_discriminant_analysis_case(maximum_input, capacity=capacity)
        add_linear_discriminant_analysis_case(maximum_input, output_is_null=True)
        add_linear_discriminant_analysis_case([], input_is_null=True, input_length=0)

        malformed_lda = (
            [], [2.0], [2.0, 2.0, 2.0],
            [2.0, 2.0, 2.0, -1.0, 1.0],
            [2.5, 2.0, 2.0, -1.0, 1.0, 1.0, 3.0],
            [0.0] * (LINEAR_DISCRIMINANT_ANALYSIS_MAX_PARSEABLE_INPUT_LENGTH + 1),
        )
        for inputs in malformed_lda:
            result, output = add_linear_discriminant_analysis_case(list(inputs))
            if result != LINEAR_DISCRIMINANT_ANALYSIS_INVALID_RESULT or output:
                raise ValueError("linear_discriminant_analysis oracle accepted malformed input")

        valid_base = [float(value) for value in workload["cases"][0]["input_values"]]
        for position in range(len(valid_base)):
            for special in (math.nan, math.inf, -math.inf):
                nonfinite = list(valid_base)
                nonfinite[position] = special
                result, output = add_linear_discriminant_analysis_case(nonfinite)
                if result != LINEAR_DISCRIMINANT_ANALYSIS_INVALID_RESULT or output:
                    raise ValueError("linear_discriminant_analysis oracle accepted a non-finite input")
        invalid_nonfinite = list(valid_base)
        invalid_nonfinite[0] = math.nan
        for capacity, output_is_null in ((0, False), (workspace, True)):
            result, output = add_linear_discriminant_analysis_case(
                invalid_nonfinite, capacity=capacity, output_is_null=output_is_null)
            if result != LINEAR_DISCRIMINANT_ANALYSIS_INVALID_RESULT or output:
                raise ValueError("linear_discriminant_analysis did not reject non-finite input before output checks")

    if algorithm == "sir":
        if workspace != SIR_MAX_OUTPUT_ELEMENTS:
            raise ValueError("sir requires its reviewed three-element workspace")

        def add_sir_case(
                inputs: list[float], capacity: int = workspace,
                output_is_null: bool = False, input_is_null: bool = False,
                input_length: int | None = None) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            if (len(inputs) > SIR_MAX_PARSEABLE_INPUT_LENGTH + 1
                    or any(type(value) not in (int, float) for value in inputs)
                    or type(capacity) is not int
                    or not 0 <= capacity <= SIR_MAX_OUTPUT_ELEMENTS
                    or type(output_is_null) is not bool
                    or type(input_is_null) is not bool
                    or type(input_length) is not int
                    or not 0 <= input_length <= SIR_MAX_PARSEABLE_INPUT_LENGTH + 1
                    or input_is_null and inputs
                    or not input_is_null and input_length != len(inputs)):
                raise ValueError("sir generated ABI framing is invalid")
            oracle_inputs = [] if input_is_null else inputs
            result, output = sir_abi_oracle(
                oracle_inputs, capacity, output_is_null, input_is_null, input_length)
            if (result >= 0 and (result != len(output)
                                 or result != SIR_MAX_OUTPUT_ELEMENTS
                                 or any(not math.isfinite(value) for value in output)
                                 or output_is_null)
                    or result < 0 and (result not in (
                        SIR_INVALID_RESULT, SIR_OUTPUT_ERROR) or output)):
                raise ValueError("sir oracle returned inconsistent ABI framing")
            checker_inputs = [0.0] * input_length if input_is_null else inputs
            records.append((checker_inputs, result, [_output_token(value) for value in output],
                            capacity, int(input_is_null), int(output_is_null)))
            return result, list(output)

        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if (not isinstance(raw_values, list)
                    or any(type(value) not in (int, float)
                           or not math.isfinite(float(value)) for value in raw_values)):
                raise ValueError(f"sir ABI values are invalid: {case.get('id')}")
            inputs = [float(value) for value in raw_values]
            result, output = add_sir_case(
                inputs, case.get("output_capacity"), case.get("output_is_null"),
                case.get("input_is_null"), case.get("input_length"))
            if (result != case.get("expected_result")
                    or not _matches_output(case.get("expected_output"), output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"sir ABI fixture mismatch: {case.get('id')}")

        rng_sir = random.Random(20261017)
        for trace_index in range(128):
            inputs = [rng_sir.uniform(0.0, SIR_MAX_POPULATION),
                      rng_sir.uniform(0.0, SIR_MAX_POPULATION),
                      rng_sir.uniform(0.0, SIR_MAX_POPULATION),
                      rng_sir.uniform(0.0, SIR_MAX_BETA),
                      rng_sir.uniform(0.0, SIR_MAX_K),
                      rng_sir.uniform(0.0, SIR_MAX_TIME)]
            result, output = add_sir_case(inputs)
            if result != SIR_MAX_OUTPUT_ELEMENTS or len(output) != SIR_MAX_OUTPUT_ELEMENTS:
                raise ValueError("sir oracle rejected a generated valid input")
            if trace_index % 16 == 0:
                add_sir_case(inputs, capacity=SIR_MAX_OUTPUT_ELEMENTS - 1)
                add_sir_case(inputs, output_is_null=True)

        maximum_input = [SIR_MAX_POPULATION, SIR_MAX_POPULATION,
                         SIR_MAX_POPULATION, SIR_MAX_BETA, SIR_MAX_K, SIR_MAX_TIME]
        for capacity in (0, SIR_MAX_OUTPUT_ELEMENTS - 1, SIR_MAX_OUTPUT_ELEMENTS):
            add_sir_case(maximum_input, capacity=capacity)
        add_sir_case(maximum_input, output_is_null=True)
        add_sir_case([], input_is_null=True, input_length=0)
        add_sir_case([], input_is_null=True, input_length=SIR_INPUT_LENGTH)
        add_sir_case(maximum_input + [0.0])
        add_sir_case(maximum_input + [0.0, 0.0])

        malformed_sir = (
            [], [0.0], [0.0] * (SIR_INPUT_LENGTH - 1),
            [0.0] * (SIR_INPUT_LENGTH + 1),
            [0.0] * (SIR_MAX_PARSEABLE_INPUT_LENGTH + 1),
            [-0.5, 1.0, 0.0, 0.0001, 0.2, 0.0],
            [100.0, 3.0, 5.0, SIR_MAX_BETA + 0.0001, 0.2, 10.0],
            [100.0, 3.0, 5.0, 0.0001, SIR_MAX_K + 0.1, 10.0],
            [100.0, 3.0, 5.0, 0.0001, 0.2, SIR_MAX_TIME + 1.0],
        )
        for inputs in malformed_sir:
            result, output = add_sir_case(list(inputs))
            if result != SIR_INVALID_RESULT or output:
                raise ValueError("sir oracle accepted a malformed or out-of-domain input")

        valid_base = [100.0, 3.0, 5.0, 0.0001, 0.2, 10.0]
        for position in range(SIR_INPUT_LENGTH):
            for special in (math.nan, math.inf, -math.inf):
                nonfinite = list(valid_base)
                nonfinite[position] = special
                result, output = add_sir_case(nonfinite)
                if result != SIR_INVALID_RESULT or output:
                    raise ValueError("sir oracle accepted a non-finite input")
        for special in (math.nan, math.inf, -math.inf):
            nonfinite = list(valid_base)
            nonfinite[0] = special
            for capacity, output_is_null in ((0, False), (SIR_MAX_OUTPUT_ELEMENTS, True)):
                result, output = add_sir_case(
                    nonfinite, capacity, output_is_null=output_is_null)
                if result != SIR_INVALID_RESULT or output:
                    raise ValueError("sir did not reject non-finite input before output checks")

    if algorithm == "k_d_tree":
        for case in workload.get("abi_cases", []):
            inputs = _decode_k_d_tree_abi_values(case.get("input_values"))
            capacity = case.get("output_capacity")
            output_is_null = case.get("output_is_null", False)
            oracle_output = ORACLES[algorithm](inputs)
            if oracle_output is None:
                expected_result, expected_output = -1, []
            elif output_is_null or len(oracle_output) > capacity:
                expected_result, expected_output = -2, []
            else:
                expected_result = len(oracle_output)
                expected_output = [_output_token(value) for value in oracle_output]
            if case.get("expected_result") != expected_result:
                raise ValueError(f"k_d_tree ABI probe mismatch: {case.get('id')}")
            records.append((inputs, expected_result, expected_output, capacity, 0,
                            int(output_is_null)))

    if algorithm == "single_point_crossover":
        for case in workload.get("abi_cases", []):
            inputs = _decode_single_point_crossover_abi_values(case.get("input_values"))
            capacity = case.get("output_capacity")
            output_is_null = case.get("output_is_null", False)
            expected_result, output = single_point_crossover_expected_abi_result(
                inputs, capacity, output_is_null)
            if case.get("expected_result") != expected_result:
                raise ValueError(f"single_point_crossover ABI probe mismatch: {case.get('id')}")
            expected_output = [_output_token(value) for value in output]
            records.append((inputs, expected_result, expected_output, capacity, 0,
                            int(output_is_null)))

    if algorithm == "quaternions":
        oracle = ORACLES[algorithm]

        def add_quaternion_case(inputs: list[float], capacity: int = workspace,
                                output_is_null: bool = False, input_is_null: bool = False,
                                input_length: int | None = None) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            result, output = quaternions_expected_abi_result(
                inputs, capacity, output_is_null, input_is_null, input_length)
            records.append((inputs, result, [_output_token(value) for value in output],
                            capacity, int(input_is_null), int(output_is_null)))
            return result, output

        absolute_tolerance, relative_tolerance = tolerances(workload)
        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if (not isinstance(raw_values, list)
                    or any(type(value) not in (int, float) or not math.isfinite(float(value))
                           for value in raw_values)):
                raise ValueError(f"invalid quaternions ABI input values: {case.get('id')}")
            inputs = [float(value) for value in raw_values]
            capacity = case.get("output_capacity")
            output_is_null = case.get("output_is_null", False)
            input_is_null = case.get("input_is_null", False)
            input_length = case.get("input_length", len(inputs))
            result, output = quaternions_expected_abi_result(
                inputs, capacity, output_is_null, input_is_null, input_length)
            expected = case.get("expected_output")
            if (case.get("expected_result") != result
                    or not isinstance(expected, list)
                    or len(expected) != len(output)
                    or any(type(actual) not in (int, float)
                           or abs(float(actual) - reference)
                           > absolute_tolerance + relative_tolerance * abs(reference)
                           for actual, reference in zip(expected, output))):
                raise ValueError(f"quaternions ABI workload mismatch: {case.get('id')}")
            records.append((inputs, result, [_output_token(value) for value in output],
                            capacity, int(input_is_null), int(output_is_null)))

        rng_quaternions = random.Random(20261017)
        for index in range(64):
            euler_values = [0.0,
                            rng_quaternions.uniform(-3.0, 3.0),
                            rng_quaternions.uniform(-3.0, 3.0),
                            rng_quaternions.uniform(-3.0, 3.0)]
            quaternion_components = [rng_quaternions.uniform(-1.0, 1.0)
                                     for _ in range(4)]
            norm = math.sqrt(sum(value * value for value in quaternion_components))
            if norm == 0.0:
                quaternion_components = [0.5, 0.5, 0.5, 0.5]
            else:
                quaternion_components = [value / norm for value in quaternion_components]
            euler_conversion = [1.0, *quaternion_components]
            if oracle(euler_conversion) is None:
                euler_conversion = [1.0, 0.5, 0.5, 0.5, 0.5]
            hamilton_product = [2.0, *(rng_quaternions.uniform(-1.0, 1.0)
                                       for _ in range(8))]
            for inputs in (euler_values, euler_conversion, hamilton_product):
                result, output = add_quaternion_case(inputs)
                if result > 0:
                    add_quaternion_case(inputs, capacity=result - 1)
                    if index % 16 == 0:
                        add_quaternion_case(inputs, output_is_null=True)

        malformed = (
            [0.0], [0.0, 0.0, 0.0], [1.0, 1.0, 0.0, 0.0],
            [1.0, 1.0, 0.0, 0.0, 0.0, 0.0],
            [2.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
            [2.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
            [3.0, 0.0, 0.0, 0.0], [0.5, 0.0, 0.0, 0.0],
            [0.0, 3.000001, 0.0, 0.0],
            [0.0, math.nan, 0.0, 0.0], [0.0, math.inf, 0.0, 0.0],
        )
        for inputs in malformed:
            add_quaternion_case(inputs)
        add_quaternion_case([0.0, 3.5, 0.0, 0.0], capacity=0, output_is_null=True)
        add_quaternion_case([0.0, 0.0, 0.0, 0.0], input_is_null=True, input_length=4)

    if algorithm == "rmsprop":
        oracle = rmsprop_abi_oracle

        def add_rmsprop_case(inputs: list[float], capacity: int = workspace,
                             output_is_null: bool = False, input_is_null: bool = False,
                             input_length: int | None = None) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            if input_is_null:
                result, output = oracle([], capacity, output_is_null, True, input_length)
                checker_inputs = [0.0] * input_length
            else:
                result, output = oracle(inputs, capacity, output_is_null, False, input_length)
                checker_inputs = inputs
            records.append((checker_inputs, result, [_output_token(value) for value in output],
                            capacity, int(input_is_null), int(output_is_null)))
            return result, output

        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if (not isinstance(raw_values, list)
                    or any(not _sherman_morrison_finite_number(value)
                           for value in raw_values)):
                raise ValueError(f"invalid rmsprop ABI input values: {case.get('id')}")
            inputs = [float(value) for value in raw_values]
            capacity = case.get("output_capacity")
            output_is_null = case.get("output_is_null", False)
            input_is_null = case.get("input_is_null", False)
            input_length = case.get("input_length", len(inputs))
            if (type(capacity) is not int or not 0 <= capacity <= workspace
                    or type(output_is_null) is not bool or type(input_is_null) is not bool
                    or type(input_length) is not int
                    or input_is_null and (inputs or input_length <= 0)
                    or not input_is_null and input_length != len(inputs)):
                raise ValueError(f"invalid rmsprop ABI framing: {case.get('id')}")
            result, output = add_rmsprop_case(
                inputs, capacity, output_is_null, input_is_null, input_length)
            if (type(case.get("expected_result")) is not int
                    or result != case["expected_result"]
                    or not _matches_output(case.get("expected_output"), output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"rmsprop ABI workload mismatch: {case.get('id')}")

        rng_rmsprop = random.Random(20261017)
        for index in range(128):
            count = rng_rmsprop.randint(RMSPROP_MIN_VECTOR_LENGTH, RMSPROP_MAX_VECTOR_LENGTH)
            state_mode = rng_rmsprop.randrange(2)
            learning_rate = 10 ** rng_rmsprop.uniform(
                math.log10(RMSPROP_MIN_LEARNING_RATE), math.log10(RMSPROP_MAX_LEARNING_RATE))
            rho = rng_rmsprop.uniform(RMSPROP_MIN_RHO, RMSPROP_MAX_RHO)
            epsilon = 10 ** rng_rmsprop.uniform(
                math.log10(RMSPROP_MIN_EPSILON), math.log10(RMSPROP_MAX_EPSILON))
            params = [rng_rmsprop.uniform(RMSPROP_MIN_PARAMETER, RMSPROP_MAX_PARAMETER)
                      for _ in range(count)]
            gradients = [rng_rmsprop.uniform(RMSPROP_MIN_GRADIENT, RMSPROP_MAX_GRADIENT)
                         for _ in range(count)]
            moving_average = (
                [rng_rmsprop.uniform(RMSPROP_MIN_MOVING_AVERAGE, RMSPROP_MAX_MOVING_AVERAGE)
                 for _ in range(count)] if state_mode == 1 else [])
            inputs = [float(count), float(state_mode), learning_rate, rho, epsilon,
                      *params, *gradients, *moving_average]
            result, _ = add_rmsprop_case(inputs)
            if count > 0 and index % 16 == 0:
                add_rmsprop_case(inputs, capacity=2 * count - 1)
            if count > 0 and index % 32 == 0:
                add_rmsprop_case(inputs, output_is_null=True)
            if index % 32 == 0:
                add_rmsprop_case([0.0, 0.0, 0.01, 0.9, 1e-8], capacity=0)
                add_rmsprop_case([0.0, 0.0, 0.01, 0.9, 1e-8],
                                 capacity=0, output_is_null=True)

        malformed = (
            [], [0.0], [1.5, 0.0, 0.01, 0.9, 1e-8, 1.0, 0.5],
            [1.0, 0.5, 0.01, 0.9, 1e-8, 1.0, 0.5],
            [1.0, 2.0, 0.01, 0.9, 1e-8, 1.0, 0.5],
            [1.0, 0.0, 0.01, 0.9, 1e-8, 1.0],
            [1.0, 0.0, 0.0, 0.9, 1e-8, 1.0, 0.5],
            [1.0, 0.0, 0.01, 1.0, 1e-8, 1.0, 0.5],
            [1.0, 0.0, 0.01, 0.9, 0.0, 1.0, 0.5],
            [1.0, 0.0, 0.01, 0.9, 1e-8, 100.000001, 0.5],
            [1.0, 0.0, 0.01, 0.9, 1e-8, 1.0, -100.000001],
            [1.0, 1.0, 0.01, 0.9, 1e-8, 1.0, 0.5, -0.000001],
            [1.0, 1.0, 0.01, 0.9, 1e-8, 1.0, 0.5, 10000.000001],
            [0.0, 0.0, 0.01, 0.9, 1e-8, *([0.0] * 97)],
            [1.0, 0.0, 0.01, 0.9, 1e-8, math.nan, 0.5],
            [1.0, 0.0, 0.01, 0.9, 1e-8, 1.0, math.inf],
        )
        for inputs in malformed:
            add_rmsprop_case(inputs)
        add_rmsprop_case([1.0, 0.0, 0.01, 0.9, 1e-8, 1.0, 0.5, 0.0],
                         capacity=64, output_is_null=True)

    if algorithm == "sherman_morrison":
        oracle = sherman_morrison_abi_oracle

        def add_sherman_morrison_case(
                inputs: list[float], capacity: int = workspace,
                output_is_null: bool = False, input_is_null: bool = False,
                input_length: int | None = None) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            if input_is_null:
                result, output = oracle([], capacity, output_is_null, True, input_length)
                checker_inputs = [0.0] * input_length
            else:
                result, output = oracle(inputs, capacity, output_is_null, False, input_length)
                checker_inputs = inputs
            records.append((checker_inputs, result, [_output_token(value) for value in output],
                            capacity, int(input_is_null), int(output_is_null)))
            return result, list(output)

        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if (not isinstance(raw_values, list)
                    or any(type(value) not in (int, float)
                           or not math.isfinite(float(value)) for value in raw_values)):
                raise ValueError(f"invalid sherman_morrison ABI input values: {case.get('id')}")
            inputs = [float(value) for value in raw_values]
            capacity = case.get("output_capacity")
            output_is_null = case.get("output_is_null", False)
            input_is_null = case.get("input_is_null", False)
            input_length = case.get("input_length", len(inputs))
            if (type(capacity) is not int
                    or not 0 <= capacity <= SHERMAN_MORRISON_MAX_OUTPUT_ELEMENTS
                    or type(output_is_null) is not bool or type(input_is_null) is not bool
                    or type(input_length) is not int
                    or not 0 <= input_length <= SHERMAN_MORRISON_MAX_PARSEABLE_INPUT_LENGTH
                    or input_is_null and (inputs or input_length <= 0)
                    or not input_is_null and input_length != len(inputs)):
                raise ValueError(f"invalid sherman_morrison ABI framing: {case.get('id')}")
            result, output = add_sherman_morrison_case(
                inputs, capacity, output_is_null, input_is_null, input_length)
            if (type(case.get("expected_result")) is not int
                    or result != case["expected_result"]
                    or not _matches_output(case.get("expected_output"), output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"sherman_morrison ABI workload mismatch: {case.get('id')}")

        rng_sherman_morrison = random.Random(20261017)
        for index in range(128):
            dimension = rng_sherman_morrison.randint(
                SHERMAN_MORRISON_MIN_DIMENSION, SHERMAN_MORRISON_MAX_DIMENSION)
            coefficient = lambda: float(rng_sherman_morrison.randint(
                SHERMAN_MORRISON_MIN_ENTRY, SHERMAN_MORRISON_MAX_ENTRY))
            matrix = [coefficient() for _ in range(dimension * dimension)]
            u = [coefficient() for _ in range(dimension)]
            v = [coefficient() for _ in range(dimension)]
            inputs = [float(dimension), *matrix, *u, *v]
            result, _ = add_sherman_morrison_case(inputs)
            if result > 0:
                add_sherman_morrison_case(inputs, capacity=result - 1)
                if index % 16 == 0:
                    add_sherman_morrison_case(inputs, output_is_null=True)

        maximum_case = next(case for case in workload["cases"]
                            if case["id"] == "four_by_four_maximum_shape")
        maximum_inputs = [float(value) for value in maximum_case["input_values"]]
        add_sherman_morrison_case(maximum_inputs, capacity=15)
        add_sherman_morrison_case(maximum_inputs, capacity=16)
        add_sherman_morrison_case(maximum_inputs, output_is_null=True)
        malformed_inputs = (
            [], [0.0], [5.0], [1.5], [1.0, 0.5, 0.0, 0.0],
            [1.0, 3.0, 1.0, 1.0], [2.0, 1.0, 0.0, 0.0, 1.0, 1.0, 0.0, 1.0],
            [1.0, 1.0, 1.0, 1.0, 0.0],
            [4.0, *([0.0] * (SHERMAN_MORRISON_MAX_PARSEABLE_INPUT_LENGTH - 1))],
            [1.0, math.nan, 1.0, 1.0], [1.0, math.inf, 1.0, 1.0],
        )
        for inputs in malformed_inputs:
            add_sherman_morrison_case(inputs)
        add_sherman_morrison_case([1.0, 3.0, 1.0, 1.0],
                                  capacity=0, output_is_null=True)

    if algorithm == "linearregressionrawr":
        oracle = linearregressionrawr_abi_oracle

        def add_linearregressionrawr_case(
                inputs: list[float], capacity: int = workspace,
                output_is_null: bool = False, input_is_null: bool = False,
                input_length: int | None = None) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            if input_is_null:
                result, output = oracle([], capacity, output_is_null, True, input_length)
                checker_inputs = [0.0] * input_length
            else:
                result, output = oracle(inputs, capacity, output_is_null, False, input_length)
                checker_inputs = inputs
            records.append((checker_inputs, result, [_output_token(value) for value in output],
                            capacity, int(input_is_null), int(output_is_null)))
            return result, list(output)

        markers = {"NaN": math.nan, "Infinity": math.inf, "-Infinity": -math.inf}
        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if (not isinstance(raw_values, list)
                    or len(raw_values) > LINEARREGRESSIONRAWR_MAX_PARSEABLE_INPUT_LENGTH):
                raise ValueError(f"invalid linearregressionrawr ABI values: {case.get('id')}")
            inputs: list[float] = []
            for value in raw_values:
                if type(value) in (int, float):
                    try:
                        inputs.append(float(value))
                    except OverflowError as error:
                        raise ValueError(
                            f"invalid linearregressionrawr ABI number: {case.get('id')}") from error
                elif isinstance(value, str) and value in markers:
                    inputs.append(markers[value])
                else:
                    raise ValueError(f"invalid linearregressionrawr ABI value: {case.get('id')}")
            capacity = case.get("output_capacity")
            output_is_null = case.get("output_is_null", False)
            input_is_null = case.get("input_is_null", False)
            input_length = case.get("input_length", len(inputs))
            if (type(capacity) is not int
                    or not 0 <= capacity <= LINEARREGRESSIONRAWR_MAX_OUTPUT_ELEMENTS
                    or type(output_is_null) is not bool or type(input_is_null) is not bool
                    or type(input_length) is not int
                    or not 0 <= input_length <= LINEARREGRESSIONRAWR_MAX_PARSEABLE_INPUT_LENGTH
                    or input_is_null and inputs
                    or not input_is_null and input_length != len(inputs)):
                raise ValueError(f"invalid linearregressionrawr ABI framing: {case.get('id')}")
            result, output = add_linearregressionrawr_case(
                inputs, capacity, output_is_null, input_is_null, input_length)
            if (type(case.get("expected_result")) is not int
                    or result != case["expected_result"]
                    or not _matches_output(case.get("expected_output"), output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"linearregressionrawr ABI workload mismatch: {case.get('id')}")

        rng_linearregressionrawr = random.Random(20261017)
        for index in range(128):
            sample_count = rng_linearregressionrawr.randint(
                LINEARREGRESSIONRAWR_MIN_SAMPLE_COUNT,
                LINEARREGRESSIONRAWR_MAX_SAMPLE_COUNT)
            predictors = [0] * sample_count
            positions = list(range(sample_count))
            rng_linearregressionrawr.shuffle(positions)
            for position in range(0, sample_count - 1, 2):
                value = rng_linearregressionrawr.randint(
                    1, LINEARREGRESSIONRAWR_MAX_PREDICTOR)
                predictors[positions[position]] = value
                predictors[positions[position + 1]] = -value
            responses = [rng_linearregressionrawr.randint(
                LINEARREGRESSIONRAWR_MIN_RESPONSE,
                LINEARREGRESSIONRAWR_MAX_RESPONSE) for _ in range(sample_count)]
            inputs = [float(sample_count), *(float(value) for value in predictors),
                      *(float(value) for value in responses)]
            result, _ = add_linearregressionrawr_case(inputs)
            if result == LINEARREGRESSIONRAWR_MAX_OUTPUT_ELEMENTS and index % 8 == 0:
                add_linearregressionrawr_case(inputs, capacity=1)
            if result == LINEARREGRESSIONRAWR_MAX_OUTPUT_ELEMENTS and index % 32 == 0:
                add_linearregressionrawr_case(inputs, output_is_null=True)

        maximum_case = next(case for case in workload["cases"]
                            if case["id"] == "maximum_sample_count")
        maximum_inputs = [float(value) for value in maximum_case["input_values"]]
        add_linearregressionrawr_case(maximum_inputs, capacity=0)
        add_linearregressionrawr_case(maximum_inputs, capacity=1)
        add_linearregressionrawr_case(maximum_inputs, capacity=2)
        add_linearregressionrawr_case(maximum_inputs, output_is_null=True)

        malformed_inputs = (
            [], [0.0], [1.0], [33.0], [2.5], [2.0, -1.0, 1.0, 0.0],
            [2.0, -1.5, 1.5, 0.0, 0.0], [2.0, -5.0, 5.0, 0.0, 0.0],
            [2.0, -1.0, 1.0, -17.0, 17.0], [2.0, -1.0, 0.0, 0.0, 0.0],
            [4.0, 0.0, 0.0, 0.0, 0.0, 1.0, 2.0, 3.0, 4.0],
            [2.0, -1.0, 1.0, 0.0, 0.0, 7.0],
            [2.0, -1.0, 1.0, math.nan, 0.0],
            [2.0, -1.0, 1.0, math.inf, 0.0],
            [2.0, -1.0, 1.0, -math.inf, 0.0],
        )
        for inputs in malformed_inputs:
            add_linearregressionrawr_case(inputs)
        add_linearregressionrawr_case([2.0, -1.5, 1.5, 0.0, 0.0],
                                      capacity=0, output_is_null=True)
        add_linearregressionrawr_case([], input_is_null=True, input_length=0)
        add_linearregressionrawr_case([], input_is_null=True, input_length=1)

    if algorithm in {"median_of_running_array_double", "median_of_running_array_float"}:
        oracle = ORACLES[algorithm]
        is_float = algorithm == "median_of_running_array_float"

        def add_median_double_case(inputs: list[float], capacity: int = workspace,
                                   output_is_null: bool = False, input_is_null: bool = False,
                                   input_length: int | None = None) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            if input_is_null:
                result, output = oracle([], capacity, output_is_null, True, input_length)
                checker_inputs = [0.0] * input_length
            else:
                result, output = oracle(inputs, capacity, output_is_null, False, input_length)
                checker_inputs = inputs
            records.append((checker_inputs, result, [_output_token(value) for value in output],
                            capacity, int(input_is_null), int(output_is_null)))
            return result, output

        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if (not isinstance(raw_values, list)
                    or any(type(value) not in (int, float) or not math.isfinite(float(value))
                           for value in raw_values)):
                raise ValueError(f"invalid median_of_running_array_double ABI values: {case.get('id')}")
            inputs = [float(value) for value in raw_values]
            capacity = case.get("output_capacity")
            output_is_null = case.get("output_is_null", False)
            input_is_null = case.get("input_is_null", False)
            input_length = case.get("input_length", len(inputs))
            result, output = add_median_double_case(
                inputs, capacity, output_is_null, input_is_null, input_length)
            if (result != case.get("expected_result")
                    or not _same_float64_sequence(output, case.get("expected_output"))):
                raise ValueError(f"{algorithm} ABI probe mismatch: {case.get('id')}")

        rng_median = random.Random(20261020)
        special_samples = (-1_000_000.0, 1_000_000.0, -0.0, 0.0)
        for index in range(128):
            sample_count = rng_median.randint(1, 64)
            samples = [rng_median.choice(special_samples) if index % 4 == 0
                       else (median_float32(rng_median.uniform(-1_000_000.0, 1_000_000.0))
                             if is_float else rng_median.uniform(-1_000_000.0, 1_000_000.0))
                       for _ in range(sample_count)]
            inputs = [float(sample_count), *samples]
            result, _ = add_median_double_case(inputs)
            if result > 0:
                add_median_double_case(inputs, capacity=result - 1)
                if index % 16 == 0:
                    add_median_double_case(inputs, output_is_null=True)

        malformed = (
            [], [0.0], [1.5, 0.0], [65.0], [1.0], [1.0, 1.0, 2.0],
            [1.0, -1_000_000.000001], [1.0, 1_000_000.000001],
            [66.0, *([0.0] * 65)],
            [1.0, math.nan], [1.0, math.inf], [1.0, -math.inf],
        )
        if is_float:
            malformed += ([1.0, 0.1],)
        for inputs in malformed:
            add_median_double_case(inputs)

    if algorithm in {"rhumb_distance", "rhumb_bearing", "rhumb_destination"}:
        oracle = ORACLES[algorithm]

        def add_rhumb_case(inputs: list[float], capacity: int = workspace,
                           output_is_null: bool = False, input_is_null: bool = False,
                           input_length: int | None = None) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            if input_is_null:
                result, output = oracle([], capacity, output_is_null, True, input_length)
                checker_inputs = [0.0] * input_length
            else:
                result, output = oracle(inputs, capacity, output_is_null, False, input_length)
                checker_inputs = inputs
            records.append((checker_inputs, result, [_output_token(value) for value in output],
                            capacity, int(input_is_null), int(output_is_null)))
            return result, output

        for case in workload.get("abi_cases", []):
            raw_values = case["input_values"]
            inputs = [float(value) for value in raw_values]
            result, output = add_rhumb_case(
                inputs, case["output_capacity"], case.get("output_is_null", False),
                case.get("input_is_null", False), case["input_length"])
            expected = case.get("expected_output", [])
            if (result != case["expected_result"] or len(output) != len(expected)
                    or any(abs(float(actual) - reference)
                           > absolute_tolerance + relative_tolerance * abs(reference)
                           for actual, reference in zip(expected, output))):
                raise ValueError(f"{algorithm} ABI probe mismatch: {case.get('id')}")

        rng_rhumb = random.Random(20261017)
        for index in range(128):
            if algorithm in {"rhumb_distance", "rhumb_bearing"}:
                inputs = [rng_rhumb.uniform(-85.0, 85.0), rng_rhumb.uniform(-180.0, 180.0),
                          rng_rhumb.uniform(-85.0, 85.0), rng_rhumb.uniform(-180.0, 180.0)]
            else:
                inputs = [rng_rhumb.uniform(-80.0, 80.0), rng_rhumb.uniform(-180.0, 180.0),
                          rng_rhumb.uniform(0.0, 300_000.0), rng_rhumb.uniform(0.0, 360.0)]
            add_rhumb_case(inputs)
            if index % 16 == 0:
                add_rhumb_case(inputs, output_is_null=True)

        valid_probe = ([10.0, 20.0, 30.0, 40.0] if algorithm != "rhumb_destination"
                       else [10.0, 20.0, 100_000.0, 90.0])
        add_rhumb_case(valid_probe, capacity=0)
        add_rhumb_case(valid_probe, capacity=1)
        malformed_inputs = ([], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0, 1.0],
                            [85.000001, 0.0, 0.0, 0.0], [0.0, 180.000001, 0.0, 0.0])
        if algorithm == "rhumb_destination":
            malformed_inputs += ([0.0, 0.0, -1.0, 0.0], [0.0, 0.0, 300_001.0, 0.0],
                                 [0.0, 0.0, 0.0, 360.0001])
        for malformed in malformed_inputs:
            add_rhumb_case(malformed)
        add_rhumb_case([86.0, 0.0, 0.0, 0.0], capacity=0, output_is_null=True)

    if algorithm == "median_filter":
        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if not isinstance(raw_values, list):
                raise ValueError(f"median_filter ABI input must be a list: {case.get('id')}")
            values: list[float] = []
            for value in raw_values:
                if value == "NaN":
                    values.append(math.nan)
                elif value == "Infinity":
                    values.append(math.inf)
                elif value == "-Infinity":
                    values.append(-math.inf)
                elif type(value) in (int, float):
                    values.append(float(value))
                else:
                    raise ValueError(f"unsupported median_filter ABI token in {case.get('id')}")
            capacity = case.get("output_capacity")
            output_is_null = case.get("output_is_null", False)
            if (type(capacity) is not int or not 0 <= capacity <= workspace
                    or type(output_is_null) is not bool):
                raise ValueError(f"invalid median_filter ABI capacity/null flag: {case.get('id')}")
            expected = ORACLES[algorithm](values)
            if expected is None:
                result, encoded = -1, []
            elif output_is_null or len(expected) > capacity:
                result, encoded = -2, []
            else:
                result = len(expected)
                encoded = [_output_token(value) for value in expected]
            if case.get("expected_result") != result:
                raise ValueError(f"median_filter ABI probe mismatch: {case.get('id')}")
            records.append((values, result, encoded, capacity, 0,
                            int(output_is_null)))

    if algorithm == "mutate":
        nonfinite_tokens = {"NaN": math.nan, "Infinity": math.inf,
                            "-Infinity": -math.inf}
        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if not isinstance(raw_values, list):
                raise ValueError(f"mutate ABI input must be a list: {case.get('id')}")
            values: list[float] = []
            for value in raw_values:
                if isinstance(value, str):
                    if value not in nonfinite_tokens:
                        raise ValueError(f"unsupported mutate ABI token in {case.get('id')}")
                    values.append(nonfinite_tokens[value])
                elif type(value) in (int, float):
                    values.append(float(value))
                else:
                    raise ValueError(f"unsupported mutate ABI input in {case.get('id')}")
            capacity = case.get("output_capacity")
            output_is_null = case.get("output_is_null", False)
            if (type(capacity) is not int or not 0 <= capacity <= workspace
                    or type(output_is_null) is not bool):
                raise ValueError(f"invalid mutate ABI capacity/null flag: {case.get('id')}")
            expected = ORACLES[algorithm](values)
            if expected is None:
                result, encoded = -1, []
            elif output_is_null or len(expected) > capacity:
                result, encoded = -2, []
            else:
                result = len(expected)
                encoded = [_output_token(value) for value in expected]
            if case.get("expected_result") != result:
                raise ValueError(f"mutate ABI probe mismatch: {case.get('id')}")
            records.append((values, result, encoded, capacity, 0,
                            int(output_is_null)))

    if algorithm == "koch_snowflake":
        invalid_input = [0.0, 1.0]
        if ORACLES[algorithm](invalid_input) is not None:
            raise ValueError("koch_snowflake must reject a point count below its minimum")
        records.append((invalid_input, -1, [], workspace, 0, 1))

    if algorithm == "rayleigh_quotient":
        oracle = ORACLES[algorithm]

        def add_rayleigh_case(inputs: list[float]) -> None:
            expected_output = oracle(inputs)
            expected_result = -1 if expected_output is None else len(expected_output)
            records.append((inputs, expected_result,
                            [] if expected_output is None else expected_output,
                            workspace, 0, 0))

        rng = random.Random(20261016)
        for _ in range(128):
            dimension = rng.randint(1, 16)
            matrix = [0.0] * (dimension * dimension)
            for row in range(dimension):
                for col in range(row, dimension):
                    value = rng.uniform(-1000.0, 1000.0)
                    matrix[row * dimension + col] = value
                    matrix[col * dimension + row] = value
            vector = [rng.uniform(-100.0, 100.0) for _ in range(dimension)]
            if all(value == 0.0 for value in vector):
                vector[0] = 1.0
            inputs = [float(dimension), *matrix, *vector]
            if len(inputs) > MAX_RAYLEIGH_QUOTIENT_INPUT_LENGTH:
                raise ValueError("rayleigh_quotient generated input exceeds its reviewed bound")
            add_rayleigh_case(inputs)

        boundary_matrix = [1000.0, -1000.0, -1000.0, -1000.0]
        add_rayleigh_case([2.0, *boundary_matrix, -100.0, 100.0])
        invalid_cases = (
            [0.0], [17.0], [1.5], [1.0, 1.0], [1.0, 1.0, 1.0, 0.0],
            [2.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0],
            [1.0, -1000.000001, 1.0], [1.0, 1000.000001, 1.0],
            [1.0, 1.0, -100.000001], [1.0, 1.0, 100.000001],
            [1.0, 1.0, 0.0], [1.0, math.nan, 1.0],
            [1.0, math.inf, 1.0], [1.0, 1.0, math.inf],
        )
        for inputs in invalid_cases:
            if oracle(inputs) is not None:
                raise ValueError("rayleigh_quotient oracle accepted a malformed probe")
            add_rayleigh_case(inputs)
    elif algorithm == "fresnel_diffract":
        oracle = ORACLES[algorithm]

        def add_fresnel_case(inputs: list[float]) -> None:
            expected_output = oracle(inputs)
            expected_result = -1 if expected_output is None else len(expected_output)
            records.append((inputs, expected_result,
                            [] if expected_output is None else expected_output,
                            workspace, 0, 0))

        # The fixed physical prefix is part of this bounded ABI contract.
        for index, replacement in ((0, 3.0), (1, 0.0), (2, 2.0), (3, 15.0)):
            invalid_parameters = list(values)
            invalid_parameters[index] = replacement
            add_fresnel_case(invalid_parameters)

        # Exercise both accepted range endpoints and just-outside values.
        boundary_values = list(values)
        boundary_values[4], boundary_values[8] = 100.0, -100.0
        add_fresnel_case(boundary_values)
        for index, replacement in ((4, 100.000001), (5, -100.000001),
                                   (8, 100.000001), (11, -100.000001)):
            out_of_range = list(values)
            out_of_range[index] = replacement
            add_fresnel_case(out_of_range)

        for special in (math.nan, math.inf, -math.inf):
            nonfinite = list(values)
            nonfinite[4] = special
            add_fresnel_case(nonfinite)

        add_fresnel_case(values[:-1])
        add_fresnel_case([*values, 0.0])
    elif algorithm == "softmax":
        oracle = ORACLES[algorithm]
        for invalid_logit in (20.000001, -20.000001, math.nan, math.inf, -math.inf):
            invalid_input = [invalid_logit]
            if oracle(invalid_input) is not None:
                raise ValueError("softmax oracle must reject out-of-range and non-finite logits")
            records.append((invalid_input, -1, [], workspace, 0, 0))
    elif algorithm == "trig_functions":
        oracle = ORACLES[algorithm]

        def add_trig_case(inputs: list[float]) -> None:
            expected_output = oracle(inputs)
            expected_result = -1 if expected_output is None else len(expected_output)
            records.append((inputs, expected_result,
                            [] if expected_output is None else expected_output,
                            workspace, 0, 0))

        # Valid non-finite x is deliberately represented by one NaN output.
        for special_x in (math.nan, math.inf, -math.inf):
            add_trig_case([0.0, special_x, 1e-9])

        # Cover the accepted finite x endpoints and the immediately out-of-range values.
        for boundary_x in (-10_000.0, 10_000.0):
            add_trig_case([0.0, boundary_x, 1e-9])
        for invalid_x in (-10_000.000001, 10_000.000001):
            add_trig_case([0.0, invalid_x, 1e-9])

        for invalid_selector in (-1.0, 8.0, 1.5, math.nan, math.inf):
            add_trig_case([invalid_selector, 0.0, 1e-9])
        for invalid_tolerance in (0.0, 0.999e-9, 0.010000001, math.nan, math.inf):
            add_trig_case([0.0, 0.0, invalid_tolerance])

        # This operation requires exactly three input values.
        add_trig_case([0.0, 0.0])
    elif algorithm == "verlet":
        oracle = ORACLES[algorithm]

        def add_verlet_case(inputs: list[float]) -> None:
            expected_output = oracle(inputs)
            expected_result = -1 if expected_output is None else len(expected_output)
            records.append((inputs, expected_result,
                            [] if expected_output is None else expected_output,
                            workspace, 0, 0))

        # Every input slot must be finite, even when all other fields are valid.
        valid_input = [2.0, 0.25, -0.5, 2.0]
        for index in range(4):
            for special in (math.nan, math.inf, -math.inf):
                invalid_input = list(valid_input)
                invalid_input[index] = special
                add_verlet_case(invalid_input)

        for invalid_input in (
            [1.5, 0.0, 0.0, 0.0], [1.0, 0.0, 0.0, 0.0],
            [32.5, 0.0, 0.0, 0.0], [2.0, -1.000001, 0.0, 0.0],
            [2.0, 1.000001, 0.0, 0.0], [2.0, 0.0, -1.000001, 0.0],
            [2.0, 0.0, 1.000001, 0.0], [2.0, 0.0, 0.0, -1.0],
            [2.0, 0.0, 0.0, 5.0], [2.0, 0.0, 0.0, 1.5],
            [2.0, 0.0, 0.0],
        ):
            add_verlet_case(invalid_input)
    elif algorithm == "vector2":
        oracle = ORACLES[algorithm]

        def add_vector2_case(inputs: list[float]) -> None:
            expected_output = oracle(inputs)
            expected_result = -1 if expected_output is None else len(expected_output)
            records.append((inputs, expected_result,
                            [] if expected_output is None else expected_output,
                            workspace, 0, 0))

        # Every ABI slot is numeric and finite, including operation selectors and
        # fields that are otherwise unused by a selected operation.
        valid_add = [4.0, 1.25, -2.5, 3.5, 4.25, 0.0]
        for index in range(6):
            for special in (math.nan, math.inf, -math.inf):
                nonfinite = list(valid_add)
                nonfinite[index] = special
                add_vector2_case(nonfinite)

        for invalid_selector in (-1.0, 11.0, 2.5, math.nan, math.inf):
            add_vector2_case([invalid_selector, 0.0, 0.0, 0.0, 0.0, 0.0])

        # Coordinates have a closed [-1000, 1000] domain. Probe each field
        # outside it and include the accepted endpoints on an active operation.
        for index in range(1, 5):
            for invalid_coordinate in (-1000.000001, 1000.000001):
                invalid = list(valid_add)
                invalid[index] = invalid_coordinate
                add_vector2_case(invalid)
        add_vector2_case([4.0, -1000.0, 1000.0, 1000.0, -1000.0, 0.0])

        # Approximate equality uses epsilon in [0, 2000], including both ends.
        for epsilon in (0.0, 2000.0):
            add_vector2_case([1.0, 0.0, 0.0, 1.0, -1.0, epsilon])
        for invalid_epsilon in (-0.000001, 2000.000001):
            add_vector2_case([1.0, 0.0, 0.0, 1.0, -1.0, invalid_epsilon])

        # Multiplication and rotation are the only operations that consume the
        # final field. Their endpoints are valid; just-outside values are not.
        for factor in (-1000.0, 1000.0):
            add_vector2_case([6.0, 1.0, -1.0, 0.0, 0.0, factor])
        for invalid_factor in (-1000.000001, 1000.000001):
            add_vector2_case([6.0, 1.0, -1.0, 0.0, 0.0, invalid_factor])
        angle_limit = 2.0 * math.pi
        for angle in (-angle_limit, angle_limit):
            add_vector2_case([9.0, 1.0, 0.0, 0.0, 0.0, angle])
        for invalid_angle in (-angle_limit - 0.000001, angle_limit + 0.000001):
            add_vector2_case([9.0, 1.0, 0.0, 0.0, 0.0, invalid_angle])

        # Each operation has an unambiguous encoding: unused coordinates and
        # scalar slots must be zero. Cover each distinct validation rule.
        for malformed_unused in (
            [0.0, 1.0, 2.0, 1.0, 2.0, 1.0],
            [2.0, 3.0, 4.0, 1.0, 0.0, 0.0],
            [2.0, 3.0, 4.0, 0.0, 1.0, 0.0],
            [2.0, 3.0, 4.0, 0.0, 0.0, 1.0],
            [3.0, 3.0, 4.0, 1.0, 0.0, 0.0],
            [3.0, 3.0, 4.0, 0.0, 1.0, 0.0],
            [3.0, 3.0, 4.0, 0.0, 0.0, 1.0],
            [4.0, 1.0, 2.0, 3.0, 4.0, 1.0],
            [5.0, 1.0, 2.0, 3.0, 4.0, 1.0],
            [6.0, 1.0, 2.0, 1.0, 0.0, 2.0],
            [6.0, 1.0, 2.0, 0.0, 1.0, 2.0],
            [7.0, 1.0, 2.0, 3.0, 4.0, 1.0],
            [8.0, 1.0, 2.0, 3.0, 4.0, 1.0],
            [9.0, 1.0, 2.0, 1.0, 0.0, 0.5],
            [9.0, 1.0, 2.0, 0.0, 1.0, 0.5],
            [10.0, 1.0, 2.0, 3.0, 4.0, 1.0],
        ):
            add_vector2_case(malformed_unused)

        # The source rejects normalization when computed length is zero,
        # including a nonzero vector whose squared components underflow.
        add_vector2_case([3.0, 0.0, 0.0, 0.0, 0.0, 0.0])
        add_vector2_case([3.0, 1e-200, 0.0, 0.0, 0.0, 0.0])

        # The operation tuple must contain exactly six values.
        add_vector2_case([4.0, 1.0, 2.0, 3.0, 4.0])
        add_vector2_case([4.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0])

        # The shared capacity probe uses a scalar-returning first workload
        # case, so separately reject capacity one for a valid vector result.
        records.append((valid_add, -2, [], 1, 0, 0))
    elif algorithm == "projectile_motion":
        oracle = ORACLES[algorithm]

        def add_projectile_case(inputs: list[float]) -> None:
            expected_output = oracle(inputs)
            expected_result = -1 if expected_output is None else len(expected_output)
            records.append((inputs, expected_result,
                            [] if expected_output is None else expected_output,
                            workspace, 0, 0))

        valid_input = [250.0, 37.0, 12.5, 9.80665]
        # Every parameter must be finite before the trajectory formulas run.
        for index in range(4):
            for special in (math.nan, math.inf, -math.inf):
                nonfinite = list(valid_input)
                nonfinite[index] = special
                add_projectile_case(nonfinite)
    elif algorithm == "momentum":
        oracle = ORACLES[algorithm]

        def add_momentum_invalid_case(inputs: list[float]) -> None:
            if oracle(inputs) is not None:
                raise ValueError("momentum oracle accepted an invalid ABI probe")
            # Keep malformed values out of the JSON workload/recorder path:
            # encode_case intentionally accepts only finite inputs. The C ABI
            # checker can parse these values and verify rejection/no-write.
            records.append((inputs, -1, [], workspace, 0, 0))

        add_momentum_invalid_case([0.0] * 65)
        add_momentum_invalid_case([1_000_000.000001])
        add_momentum_invalid_case([-1_000_000.000001])
        for special in (math.nan, math.inf, -math.inf):
            add_momentum_invalid_case([special])
    elif algorithm == "pid":
        oracle = ORACLES[algorithm]

        def add_pid_invalid_case(inputs: list[float], output_is_null: bool = False) -> None:
            if oracle(inputs) is not None:
                raise ValueError("pid oracle accepted an invalid ABI probe")
            records.append((inputs, -1, [], workspace, 0, int(output_is_null)))

        # The active float64-slice ABI accepts at most 64 input values.
        add_pid_invalid_case([0.0, 0.0, 0.0, 0.5, *([0.0] * 61)])
        # A malformed finite input must be rejected before a null output pointer.
        add_pid_invalid_case([1.00000001, 0.0, 0.0, 0.5, 0.0], output_is_null=True)

        # Probe every parameter class and an error sample with non-finite values.
        valid_input = [0.0, 0.0, 0.0, 0.5, 0.0]
        for index in range(len(valid_input)):
            for special in (math.nan, math.inf, -math.inf):
                invalid_input = list(valid_input)
                invalid_input[index] = special
                add_pid_invalid_case(invalid_input)
    elif algorithm == "joint_probability_distribution":
        oracle = ORACLES[algorithm]

        def add_joint_probability_case(inputs: list[float], output_is_null: bool = False) -> None:
            expected_result, expected_output = oracle(inputs)
            if output_is_null and expected_result >= 0:
                expected_result, expected_output = -2, []
            records.append((inputs, expected_result, expected_output,
                            workspace, 0, int(output_is_null)))

        rng = random.Random(20261017)
        for _ in range(64):
            nx, ny = rng.randint(1, 4), rng.randint(1, 4)
            x_values = rng.sample(range(-1000, 1001), nx)
            y_values = rng.sample(range(-1000, 1001), ny)
            x_probabilities = [rng.uniform(-1_000_000.0, 1_000_000.0) for _ in range(nx)]
            y_probabilities = [rng.uniform(-1_000_000.0, 1_000_000.0) for _ in range(ny)]
            inputs = [float(nx), float(ny), *map(float, x_values), *map(float, y_values),
                      *x_probabilities, *y_probabilities]
            add_joint_probability_case(inputs)

        invalid_inputs = (
            [1.0, 1.0, 1.0, 2.0, 0.5],
            [1.0, 1.0, 1.0, 2.0, 0.5, 0.5, 99.0],
            [1.0, 1.0, 1.5, 2.0, 0.5, 0.5],
            [2.0, 1.0, 1.0, 1.0, 2.0, 0.25, 0.75, 0.5],
            [1.0, 1.0, 1.0, 2.0, 1_000_000.1, 0.5],
            [1.0, 1.0, 1.0, 2.0, math.nan, 0.5],
            [1.0, 1.0, 1.0, 2.0, math.inf, 0.5],
        )
        for inputs in invalid_inputs:
            if oracle(inputs)[0] != -1:
                raise ValueError("joint_probability_distribution oracle accepted a malformed probe")
            add_joint_probability_case(inputs)

        maximum_case = next(case for case in workload["cases"]
                            if case.get("id") == "maximum_support_sizes")
        maximum_values, _, _ = encode_case(
            maximum_case, algorithm, absolute_tolerance, relative_tolerance)
        parseable_limit_input = [*maximum_values, 0.0, 0.0]
        if len(parseable_limit_input) != 20 or oracle(parseable_limit_input)[0] != -1:
            raise ValueError("joint_probability_distribution parseable-limit probe is malformed")
        add_joint_probability_case(parseable_limit_input)

        invalid_before_null_output = [1.0, 1.0, 1.5, 2.0, 0.5, 0.5]
        if oracle(invalid_before_null_output)[0] != -1:
            raise ValueError("joint_probability_distribution oracle accepted an invalid null-output probe")
        add_joint_probability_case(invalid_before_null_output, output_is_null=True)
    elif algorithm == "shreedharacharya":
        oracle = ORACLES[algorithm]

        def add_shreedharacharya_case(inputs: list[float], output_is_null: bool = False) -> None:
            expected_result, expected_output = oracle(inputs)
            if output_is_null and expected_result >= 0:
                expected_result, expected_output = -2, []
            records.append((inputs, expected_result, expected_output,
                            workspace, 0, int(output_is_null)))

        finite_probes = (
            [SHREEDHARACHARYA_MIN_ABS_A, -2e-6, 1e-6],
            [-SHREEDHARACHARYA_MIN_ABS_A, 2e-6, -1e-6],
            [SHREEDHARACHARYA_MAX_COEFFICIENT, 0.0, 0.0],
            [-SHREEDHARACHARYA_MAX_COEFFICIENT, 0.0, 0.0],
            [1.0, 0.0, 1.0],
            [1.0, 2.0, 1.0],
            [0.0, 0.0, 1.0],
            [SHREEDHARACHARYA_MIN_ABS_A * 0.999, 0.0, 0.0],
            [SHREEDHARACHARYA_MAX_COEFFICIENT + 1.0, 0.0, 0.0],
            [1.0, SHREEDHARACHARYA_MAX_COEFFICIENT + 1.0, 0.0],
            [1.0, 0.0, SHREEDHARACHARYA_MAX_COEFFICIENT + 1.0],
        )
        for inputs in finite_probes:
            add_shreedharacharya_case(inputs)

        parseable_limit_input = [1.0, 2.0, 1.0, *([0.0] * 61)]
        if len(parseable_limit_input) != 64 or oracle(parseable_limit_input)[0] != -1:
            raise ValueError("shreedharacharya parseable-limit probe is malformed")
        add_shreedharacharya_case(parseable_limit_input)

        rng = random.Random(20261017)
        for _ in range(64):
            magnitude = 10.0 ** rng.uniform(-6.0, 6.0)
            a = magnitude if rng.randrange(2) else -magnitude
            b = rng.uniform(-SHREEDHARACHARYA_MAX_COEFFICIENT,
                            SHREEDHARACHARYA_MAX_COEFFICIENT)
            c = rng.uniform(-SHREEDHARACHARYA_MAX_COEFFICIENT,
                            SHREEDHARACHARYA_MAX_COEFFICIENT)
            add_shreedharacharya_case([a, b, c])

        for index in range(3):
            for special in (math.nan, math.inf, -math.inf):
                inputs = [1.0, 2.0, 1.0]
                inputs[index] = special
                if oracle(inputs)[0] != -1:
                    raise ValueError("shreedharacharya oracle accepted a non-finite coefficient")
                add_shreedharacharya_case(inputs)

        zero_root_input = [1.0, 0.0, 1.0]
        if oracle(zero_root_input) != (0, []):
            raise ValueError("shreedharacharya oracle must preserve the empty-root result")
        records.append((zero_root_input, 0, [], 0, 0, 0))
        add_shreedharacharya_case(zero_root_input, output_is_null=True)

        invalid_before_null_output = [0.0, 0.0, 1.0]
        if oracle(invalid_before_null_output)[0] != -1:
            raise ValueError("shreedharacharya oracle accepted the invalid null-output probe")
        add_shreedharacharya_case(invalid_before_null_output, output_is_null=True)
    elif algorithm == "rotation_matrix":
        oracle = ORACLES[algorithm]

        def add_rotation_matrix_case(inputs: list[float], output_is_null: bool = False) -> None:
            expected_result, expected_output = oracle(inputs)
            if output_is_null and expected_result >= 0:
                expected_result, expected_output = -2, []
            records.append((inputs, expected_result, expected_output,
                            workspace, 0, int(output_is_null)))

        rng = random.Random(20261017)
        for _ in range(128):
            add_rotation_matrix_case([rng.uniform(-1000.0, 1000.0)])

        for angle in (0.0, -0.0, -1000.0, 1000.0, -999.999999, 999.999999,
                      -1000.000001, 1000.000001):
            add_rotation_matrix_case([angle])
        for special in (math.nan, math.inf, -math.inf):
            add_rotation_matrix_case([special])

        parseable_limit_input = [0.0] * 64
        if len(parseable_limit_input) != 64 or oracle(parseable_limit_input)[0] != -1:
            raise ValueError("rotation_matrix parseable-limit probe is malformed")
        add_rotation_matrix_case(parseable_limit_input)

        invalid_before_null_output = [1000.000001]
        if oracle(invalid_before_null_output)[0] != -1:
            raise ValueError("rotation_matrix oracle accepted invalid input before null output")
        add_rotation_matrix_case(invalid_before_null_output, output_is_null=True)
    elif algorithm == "simple_pendulum_rk4":
        oracle = ORACLES[algorithm]

        def add_simple_pendulum_case(inputs: list[float], output_is_null: bool = False) -> None:
            expected_output = oracle(inputs)
            expected_result = -1 if expected_output is None else len(expected_output)
            if output_is_null and expected_result >= 0:
                expected_result, expected_output = -2, []
            records.append((inputs, expected_result,
                            [] if expected_output is None else expected_output,
                            workspace, 0, int(output_is_null)))

        rng_pendulum = random.Random(20261017)
        for _ in range(128):
            inputs = [
                float(rng_pendulum.randint(10_000, 100_000_000)),
                float(rng_pendulum.randint(100_000, 20_000_000)),
                float(rng_pendulum.randint(-3_141_593, 3_141_593)),
                float(rng_pendulum.randint(-100_000_000, 100_000_000)),
                float(rng_pendulum.randint(1, 100_000)),
            ]
            add_simple_pendulum_case(inputs)

        valid_input = [1_000_000.0, 9_800_000.0, 523_599.0, -1_250_000.0, 20_000.0]
        if oracle(valid_input) is None:
            raise ValueError("simple_pendulum_rk4 oracle rejected a valid capacity probe")
        for capacity in (0, 1, 2):
            result = -2 if capacity < 2 else 2
            output = [] if capacity < 2 else oracle(valid_input)
            records.append((valid_input, result, output, capacity, 0, 0))
        add_simple_pendulum_case(valid_input, output_is_null=True)

        for index in range(5):
            for special in (math.nan, math.inf, -math.inf):
                inputs = list(valid_input)
                inputs[index] = special
                if oracle(inputs) is not None:
                    raise ValueError("simple_pendulum_rk4 oracle accepted a non-finite input")
                add_simple_pendulum_case(inputs)

        fractional_micro_input = list(valid_input)
        fractional_micro_input[2] = 523_599.5
        if oracle(fractional_micro_input) is not None:
            raise ValueError("simple_pendulum_rk4 oracle accepted a fractional micro-unit")
        add_simple_pendulum_case(fractional_micro_input)

        parseable_limit_input = [*valid_input, *([0.0] * 59)]
        if len(parseable_limit_input) != 64 or oracle(parseable_limit_input) is not None:
            raise ValueError("simple_pendulum_rk4 parseable-limit probe is malformed")
        add_simple_pendulum_case(parseable_limit_input)

        invalid_before_null_output = [9_999.0, *valid_input[1:]]
        if len(invalid_before_null_output) != 5 or oracle(invalid_before_null_output) is not None:
            raise ValueError("simple_pendulum_rk4 null-output precedence probe is malformed")
        add_simple_pendulum_case(invalid_before_null_output, output_is_null=True)
    elif algorithm == "piecewise_without_inbuilt":
        oracle = ORACLES[algorithm]

        def add_piecewise_case(inputs: list[float], capacity: int = workspace,
                               output_is_null: bool = False) -> None:
            expected_output = oracle(inputs)
            expected_result = -1 if expected_output is None else len(expected_output)
            output = [] if expected_output is None else expected_output
            if expected_result >= 0 and output_is_null:
                expected_result, output = -2, []
            elif expected_result >= 0 and capacity < expected_result:
                expected_result, output = -2, []
            records.append((inputs, expected_result, output, capacity, 0,
                            int(output_is_null)))

        rng_piecewise = random.Random(20261019)
        for _ in range(128):
            add_piecewise_case([rng_piecewise.uniform(-10.0, 10.0)])

        for value in (-10.0, -0.500001, -0.5, -0.499999, 0.0,
                      0.499999, 0.5, 0.500001, 10.0):
            add_piecewise_case([value])

        for special in (math.nan, math.inf, -math.inf):
            if oracle([special]) is not None:
                raise ValueError("piecewise_without_inbuilt oracle accepted a non-finite input")
            add_piecewise_case([special])

        parseable_limit_input = [0.0] * 64
        if len(parseable_limit_input) != 64 or oracle(parseable_limit_input) is not None:
            raise ValueError("piecewise_without_inbuilt parseable-limit probe is malformed")
        add_piecewise_case(parseable_limit_input)

        valid_capacity_probe = [0.125]
        if oracle(valid_capacity_probe) is None:
            raise ValueError("piecewise_without_inbuilt oracle rejected a valid capacity probe")
        add_piecewise_case(valid_capacity_probe, capacity=0)
        add_piecewise_case(valid_capacity_probe, capacity=1)
        add_piecewise_case(valid_capacity_probe, output_is_null=True)

        invalid_before_null_output = [10.000001]
        if oracle(invalid_before_null_output) is not None:
            raise ValueError("piecewise_without_inbuilt oracle accepted invalid input before null output")
        add_piecewise_case(invalid_before_null_output, capacity=0, output_is_null=True)

        for malformed in ([], [0.0, 0.0]):
            if oracle(malformed) is not None:
                raise ValueError("piecewise_without_inbuilt oracle accepted malformed input framing")
            add_piecewise_case(malformed)
    elif algorithm == "linear_regression_vectorized":
        oracle = ORACLES[algorithm]

        def add_linear_regression_case(inputs: list[float], capacity: int = workspace,
                                       output_is_null: bool = False) -> None:
            expected = oracle(inputs)
            if expected is None:
                result, output = -1, []
            elif output_is_null or len(expected) > capacity:
                result, output = -2, []
            else:
                result, output = len(expected), expected
            records.append((inputs, result, output, capacity, 0, int(output_is_null)))

        rng_regression = random.Random(20261017)
        for _ in range(128):
            sample_count = rng_regression.randint(
                LINEAR_REGRESSION_MIN_SAMPLE_COUNT, LINEAR_REGRESSION_MAX_SAMPLE_COUNT)
            feature_count = rng_regression.randint(
                LINEAR_REGRESSION_MIN_FEATURE_COUNT, LINEAR_REGRESSION_MAX_FEATURE_COUNT)
            iterations = rng_regression.randint(
                LINEAR_REGRESSION_MIN_ITERATIONS, LINEAR_REGRESSION_MAX_ITERATIONS)
            alpha = rng_regression.uniform(LINEAR_REGRESSION_MIN_ALPHA, LINEAR_REGRESSION_MAX_ALPHA)
            features: list[float] = []
            for _row in range(sample_count):
                features.append(1.0)
                features.extend(rng_regression.uniform(
                    LINEAR_REGRESSION_MIN_FEATURE_OR_LABEL,
                    LINEAR_REGRESSION_MAX_FEATURE_OR_LABEL)
                    for _column in range(feature_count - 1))
            labels = [rng_regression.uniform(
                LINEAR_REGRESSION_MIN_FEATURE_OR_LABEL,
                LINEAR_REGRESSION_MAX_FEATURE_OR_LABEL)
                for _row in range(sample_count)]
            inputs = [float(sample_count), float(feature_count), float(iterations), alpha,
                      *features, *labels]
            add_linear_regression_case(inputs)

        valid_probe = [float(value) for value in workload["cases"][0]["input_values"]]
        add_linear_regression_case(valid_probe, capacity=1)
        add_linear_regression_case(valid_probe, output_is_null=True)
        invalid_before_null = [0.0, 2.0, 10.0, 0.001, 1.0, 0.0, 1.0, 0.0]
        if oracle(invalid_before_null) is not None:
            raise ValueError("linear_regression_vectorized oracle accepted invalid input before null output")
        add_linear_regression_case(invalid_before_null, capacity=0, output_is_null=True)
    elif algorithm == "perlin_noise":
        oracle = ORACLES[algorithm]

        def add_perlin_case(inputs: list[float], capacity: int = workspace,
                            output_is_null: bool = False) -> None:
            expected = oracle(inputs)
            if expected is None:
                result, output = -1, []
            elif output_is_null or len(expected) > capacity:
                result, output = PERLIN_NOISE_OUTPUT_ERROR, []
            else:
                result, output = len(expected), expected
            records.append((inputs, result, output, capacity, 0, int(output_is_null)))

        rng_perlin = random.Random(20261017)
        for index in range(128):
            width = rng_perlin.randint(PERLIN_NOISE_MIN_DIMENSION, PERLIN_NOISE_MAX_DIMENSION)
            height = rng_perlin.randint(PERLIN_NOISE_MIN_DIMENSION, PERLIN_NOISE_MAX_DIMENSION)
            octave_count = rng_perlin.randint(PERLIN_NOISE_MIN_OCTAVES, PERLIN_NOISE_MAX_OCTAVES)
            persistence = rng_perlin.choice(PERLIN_NOISE_PERSISTENCE_VALUES)
            seed = rng_perlin.choice((PERLIN_NOISE_MIN_SEED, 1, 12345,
                                      PERLIN_NOISE_MAX_SEED,
                                      rng_perlin.randint(PERLIN_NOISE_MIN_SEED,
                                                         PERLIN_NOISE_MAX_SEED)))
            inputs = [float(width), float(height), float(octave_count), persistence, float(seed)]
            add_perlin_case(inputs)
            if index % 16 == 0:
                add_perlin_case(inputs, output_is_null=True)

        valid_probe = [1.0, 1.0, 1.0, 0.5, 0.0]
        add_perlin_case(valid_probe, capacity=0)
        add_perlin_case(valid_probe, capacity=1)
        add_perlin_case(valid_probe, output_is_null=True)

        invalid_before_null_output = [0.0, 1.0, 1.0, 0.5, 0.0]
        if oracle(invalid_before_null_output) is not None:
            raise ValueError("perlin_noise oracle accepted invalid input before null output")
        add_perlin_case(invalid_before_null_output, capacity=0, output_is_null=True)

        malformed = (
            [], [1.0, 1.0, 1.0, 0.5], [1.0, 1.0, 1.0, 0.5, 0.0, 0.0],
            [1.5, 1.0, 1.0, 0.5, 0.0], [1.0, 1.0, 0.0, 0.5, 0.0],
            [1.0, 1.0, 1.0, 0.25, 0.0], [1.0, 1.0, 1.0, 0.5, -1.0],
        )
        for inputs in malformed:
            add_perlin_case(inputs)
        # The checker distinguishes a null pointer from a one-element input array.
        records.append(([0.0], PERLIN_NOISE_INVALID_RESULT, [], workspace, 1, 0))

    if algorithm == "mean_shift":
        if (workspace != MEAN_SHIFT_WORKSPACE_ELEMENTS
                or absolute_tolerance != 0.0 or relative_tolerance != 0.0):
            raise ValueError("mean_shift requires a 16-element workspace and exact label comparison")
        nonfinite_tokens = {"NaN": math.nan, "Infinity": math.inf, "-Infinity": -math.inf}
        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if not isinstance(raw_values, list):
                raise ValueError(f"mean_shift ABI input must be an array: {case.get('id')}")
            inputs: list[float] = []
            for value in raw_values:
                if isinstance(value, str) and value in nonfinite_tokens:
                    inputs.append(nonfinite_tokens[value])
                elif type(value) in (int, float):
                    inputs.append(float(value))
                else:
                    raise ValueError(f"mean_shift ABI input token is invalid: {case.get('id')}")
            capacity = case.get("output_capacity")
            input_is_null = case.get("input_is_null", False)
            output_is_null = case.get("output_is_null", False)
            input_length = case.get("input_length", len(inputs))
            if (type(capacity) is not int or not 0 <= capacity <= workspace
                    or type(input_is_null) is not bool or type(output_is_null) is not bool
                    or input_is_null and output_is_null
                    or type(input_length) is not int
                    or not 0 <= input_length <= MEAN_SHIFT_MAX_PARSEABLE_INPUT_LENGTH
                    or input_is_null and (inputs or input_length <= 0)
                    or not input_is_null and input_length != len(inputs)):
                raise ValueError(f"mean_shift ABI framing is invalid: {case.get('id')}")
            result, output = mean_shift_oracle(
                inputs, capacity, output_is_null, input_is_null, input_length)
            expected_output = case.get("expected_output")
            if (case.get("expected_result") != result
                    or not isinstance(expected_output, list)
                    or not _same_float64_sequence(expected_output, output)):
                raise ValueError(f"mean_shift ABI workload mismatch: {case.get('id')}")
            checker_inputs = [0.0] * input_length if input_is_null else inputs
            records.append((checker_inputs, result,
                            [_output_token(value) for value in output], capacity,
                            int(input_is_null), int(output_is_null)))

        valid_nonfinite_base = [1.0, 1.0, 1.0, 1.0, 0.01, 0.0]
        for index in range(len(valid_nonfinite_base)):
            for special in (math.nan, math.inf, -math.inf):
                inputs = list(valid_nonfinite_base)
                inputs[index] = special
                result, output = mean_shift_oracle(inputs)
                if result != -1 or output:
                    raise ValueError("mean_shift oracle accepted a nonfinite ABI probe")
                records.append((inputs, -1, [], workspace, 0, 0))

    if algorithm == "k_means_clust":
        if (workspace != K_MEANS_CLUST_MAX_OUTPUT_ELEMENTS
                or absolute_tolerance != 1e-12 or relative_tolerance != 1e-12):
            raise ValueError("k_means_clust requires a 32-element workspace and 1e-12 tolerances")

        def add_k_means_case(inputs: list[float], capacity: int = workspace,
                             output_is_null: bool = False, input_is_null: bool = False,
                             input_length: int | None = None) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            oracle_inputs = [] if input_is_null else inputs
            result, output = k_means_clust_abi_oracle(
                oracle_inputs, capacity, output_is_null, input_is_null, input_length)
            checker_inputs = [0.0] * input_length if input_is_null else inputs
            records.append((checker_inputs, result,
                            [_output_token(value) for value in output], capacity,
                            int(input_is_null), int(output_is_null)))
            return result, output

        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if (not isinstance(raw_values, list)
                    or len(raw_values) > K_MEANS_CLUST_MAX_PARSEABLE_INPUT_LENGTH
                    or any(type(value) not in (int, float) or not math.isfinite(float(value))
                           for value in raw_values)):
                raise ValueError(f"invalid k_means_clust ABI values: {case.get('id')}")
            inputs = [float(value) for value in raw_values]
            capacity = case.get("output_capacity")
            if capacity is None:
                capacity = workspace
            output_is_null = case.get("output_is_null", False)
            input_is_null = case.get("input_is_null", False)
            output_is_null = False if output_is_null is None else output_is_null
            input_is_null = False if input_is_null is None else input_is_null
            input_length = case.get("input_length", len(inputs))
            result, output = k_means_clust_abi_oracle(
                inputs, capacity, output_is_null, input_is_null, input_length)
            expected_output = case.get("expected_output")
            if (case.get("expected_result") != result
                    or not isinstance(expected_output, list)
                    or len(expected_output) != len(output)
                    or any(type(actual) not in (int, float) or not math.isfinite(float(actual))
                           or abs(float(actual) - reference)
                           > absolute_tolerance + relative_tolerance * abs(reference)
                           for actual, reference in zip(expected_output, output))):
                raise ValueError(f"k_means_clust ABI fixture mismatch: {case.get('id')}")
            add_k_means_case(inputs, capacity, output_is_null, input_is_null, input_length)

        rng_k_means = random.Random(20261017)
        maximum_valid: list[float] | None = None
        for index in range(128):
            if index == 0:
                point_count = K_MEANS_CLUST_MAX_POINT_COUNT
                dimension = K_MEANS_CLUST_MAX_DIMENSION
                cluster_count = K_MEANS_CLUST_MAX_CLUSTER_COUNT
            else:
                point_count = rng_k_means.randint(1, K_MEANS_CLUST_MAX_POINT_COUNT)
                dimension = rng_k_means.randint(1, K_MEANS_CLUST_MAX_DIMENSION)
                cluster_count = rng_k_means.randint(1, min(K_MEANS_CLUST_MAX_CLUSTER_COUNT,
                                                           point_count))
            centroids = [[-12 + 8 * cluster]
                         + [rng_k_means.randint(-16, 16) for _ in range(dimension - 1)]
                         for cluster in range(cluster_count)]
            data = [list(centroid) for centroid in centroids]
            data.extend([[rng_k_means.randint(-16, 16) for _ in range(dimension)]
                         for _ in range(point_count - cluster_count)])
            rng_k_means.shuffle(data)
            inputs = [float(point_count), float(dimension), float(cluster_count)]
            inputs.extend(float(value) for point in data for value in point)
            inputs.extend(float(value) for centroid in centroids for value in centroid)
            if index == 0:
                maximum_valid = inputs
                if len(inputs) != K_MEANS_CLUST_MAX_VALID_INPUT_LENGTH:
                    raise ValueError("k_means_clust maximum-shape trace is not 83 values")
            result, output = add_k_means_case(inputs)
            if result <= 0 or len(output) != result:
                raise ValueError("k_means_clust oracle rejected a generated valid trace")
            if index == 0:
                add_k_means_case(inputs, capacity=result)
                add_k_means_case(inputs, capacity=result - 1)
            if index % 16 == 0:
                add_k_means_case(inputs, output_is_null=True)

        assert maximum_valid is not None
        if len(maximum_valid) + 1 != K_MEANS_CLUST_MAX_PARSEABLE_INPUT_LENGTH:
            raise ValueError("k_means_clust maximum parseable shape is not 84 values")
        malformed = (
            [], maximum_valid[:-1], maximum_valid + [0.0],
            [0.0, 1.0, 1.0, 0.0, 0.0],
            [1.5, 1.0, 1.0, 0.0, 0.0],
            [1.0, 0.0, 1.0, 0.0],
            [1.0, 1.0, 5.0, 0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0],
            [1.0, 1.0, 1.0, 0.5, 0.0],
            [1.0, 1.0, 1.0, 17.0, 0.0],
            [2.0, 1.0, 2.0, 0.0, 1.0, 0.0, 16.0],
        )
        for inputs in malformed:
            add_k_means_case(inputs)
        add_k_means_case([2.0, 1.0, 2.0, 0.0, 1.0, 0.0, 16.0],
                         output_is_null=True)
        add_k_means_case([], input_is_null=True, input_length=5)

    if algorithm == "lu_decompose":
        if (workspace != LU_DECOMPOSE_MAX_OUTPUT_ELEMENTS
                or absolute_tolerance != 1e-12 or relative_tolerance != 1e-12):
            raise ValueError("lu_decompose requires a 32-element workspace and 1e-12 tolerances")

        def add_lu_case(inputs: list[float], capacity: int = workspace,
                        output_is_null: bool = False, input_is_null: bool = False,
                        input_length: int | None = None) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            oracle_inputs = [] if input_is_null else inputs
            result, output = lu_decompose_abi_oracle(
                oracle_inputs, capacity, output_is_null, input_is_null, input_length)
            checker_inputs = [0.0] * input_length if input_is_null else inputs
            records.append((checker_inputs, result,
                            [_output_token(value) for value in output], capacity,
                            int(input_is_null), int(output_is_null)))
            return result, output

        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if (not isinstance(raw_values, list)
                    or len(raw_values) > LU_DECOMPOSE_MAX_PARSEABLE_INPUT_LENGTH
                    or any(type(value) not in (int, float) or not math.isfinite(float(value))
                           for value in raw_values)):
                raise ValueError(f"invalid lu_decompose ABI values: {case.get('id')}")
            inputs = [float(value) for value in raw_values]
            capacity = case.get("output_capacity")
            if capacity is None:
                capacity = workspace
            input_is_null = case.get("input_is_null")
            output_is_null = case.get("output_is_null")
            input_is_null = False if input_is_null is None else input_is_null
            output_is_null = False if output_is_null is None else output_is_null
            input_length = case.get("input_length", len(inputs))
            result, output = lu_decompose_abi_oracle(
                inputs, capacity, output_is_null, input_is_null, input_length)
            expected_output = case.get("expected_output")
            if (case.get("expected_result") != result
                    or not isinstance(expected_output, list)
                    or len(expected_output) != len(output)
                    or any(type(actual) not in (int, float) or not math.isfinite(float(actual))
                           or abs(float(actual) - reference)
                           > absolute_tolerance + relative_tolerance * abs(reference)
                           for actual, reference in zip(expected_output, output))):
                raise ValueError(f"lu_decompose ABI fixture mismatch: {case.get('id')}")
            add_lu_case(inputs, capacity, output_is_null, input_is_null, input_length)

        rng_lu = random.Random(20261017)
        maximum_valid: list[float] | None = None
        for index in range(128):
            dimension = (LU_DECOMPOSE_MAX_DIMENSION if index == 0 else
                         rng_lu.randint(1, LU_DECOMPOSE_MAX_DIMENSION))
            matrix = [[rng_lu.randint(-1, 1) for _ in range(dimension)]
                      for _ in range(dimension)]
            for diagonal in range(dimension):
                matrix[diagonal][diagonal] = rng_lu.randint(4, 8)
            inputs = [float(dimension)]
            inputs.extend(float(value) for row in matrix for value in row)
            if index == 0:
                maximum_valid = inputs
                if len(inputs) != LU_DECOMPOSE_MAX_VALID_INPUT_LENGTH:
                    raise ValueError("lu_decompose maximum-shape trace is not 17 values")
            result, output = add_lu_case(inputs)
            if result <= 0 or len(output) != result:
                raise ValueError("lu_decompose oracle rejected a generated valid trace")
            if index == 0:
                add_lu_case(inputs, capacity=result)
                add_lu_case(inputs, capacity=result - 1)
            if index % 16 == 0:
                add_lu_case(inputs, output_is_null=True)

        if maximum_valid is None or len(maximum_valid) + 1 != LU_DECOMPOSE_MAX_PARSEABLE_INPUT_LENGTH:
            raise ValueError("lu_decompose maximum parseable shape is not 18 values")
        malformed = (
            [], maximum_valid[:-1], maximum_valid + [0.0],
            [0.0], [1.5, 0.0], [5.0] + [0.0] * 16,
            [1.0, 0.5], [1.0, 9.0], [2.0, 1.0, 2.0, 2.0, 4.0],
        )
        for inputs in malformed:
            add_lu_case(inputs)
        add_lu_case([2.0, 1.0, 2.0, 2.0, 4.0], output_is_null=True)
        add_lu_case([], input_is_null=True, input_length=2)

    if algorithm == "lu_elimination":
        if (workspace != LU_ELIMINATION_MAX_OUTPUT_ELEMENTS
                or absolute_tolerance != 1e-12 or relative_tolerance != 1e-12):
            raise ValueError("lu_elimination requires a 4-element workspace and 1e-12 tolerances")

        def add_lu_elimination_case(
            inputs: list[float], capacity: int = workspace,
            output_is_null: bool = False, input_is_null: bool = False,
            input_length: int | None = None, require_valid: bool = False,
        ) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            if (len(inputs) > LU_ELIMINATION_MAX_PARSEABLE_INPUT_LENGTH
                    or any(not math.isfinite(value) for value in inputs)):
                raise ValueError("lu_elimination generated input exceeds its finite parseable bound")
            result, output = lu_elimination_abi_oracle(
                [] if input_is_null else inputs, capacity,
                output_is_null, input_is_null, input_length)
            if require_valid and (result < 0 or len(output) != result):
                raise ValueError("lu_elimination oracle rejected a generated valid solve")
            checker_inputs = [0.0] * input_length if input_is_null else inputs
            records.append((checker_inputs, result,
                            [_output_token(value) for value in output], capacity,
                            int(input_is_null), int(output_is_null)))
            return result, output

        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if (not isinstance(raw_values, list)
                    or len(raw_values) > LU_ELIMINATION_MAX_PARSEABLE_INPUT_LENGTH
                    or any(type(value) not in (int, float) or not math.isfinite(float(value))
                           for value in raw_values)):
                raise ValueError(f"invalid lu_elimination ABI values: {case.get('id')}")
            inputs = [float(value) for value in raw_values]
            capacity = case.get("output_capacity")
            if capacity is None:
                capacity = workspace
            input_is_null = case.get("input_is_null")
            output_is_null = case.get("output_is_null")
            input_is_null = False if input_is_null is None else input_is_null
            output_is_null = False if output_is_null is None else output_is_null
            input_length = case.get("input_length", len(inputs))
            result, output = lu_elimination_abi_oracle(
                inputs, capacity, output_is_null, input_is_null, input_length)
            expected_output = case.get("expected_output")
            if (case.get("expected_result") != result
                    or not isinstance(expected_output, list)
                    or len(expected_output) != len(output)
                    or any(type(actual) not in (int, float) or not math.isfinite(float(actual))
                           or abs(float(actual) - reference)
                           > absolute_tolerance + relative_tolerance * abs(reference)
                           for actual, reference in zip(expected_output, output))):
                raise ValueError(f"lu_elimination ABI fixture mismatch: {case.get('id')}")
            add_lu_elimination_case(
                inputs, capacity, output_is_null, input_is_null, input_length)

        rng_lu_elimination = random.Random(20261022)
        maximum_valid: list[float] | None = None
        for index in range(128):
            dimension = (LU_ELIMINATION_MAX_DIMENSION if index == 0 else
                         rng_lu_elimination.randint(1, LU_ELIMINATION_MAX_DIMENSION))
            matrix = [[0] * dimension for _ in range(dimension)]
            for row in range(dimension):
                for column in range(row, dimension):
                    matrix[row][column] = (
                        rng_lu_elimination.choice((-1, 1)) if row == column
                        else rng_lu_elimination.randint(-1, 1))
            rhs = [rng_lu_elimination.randint(-8, 8) for _ in range(dimension)]
            inputs = [float(dimension),
                      *(float(value) for row in matrix for value in row),
                      *(float(value) for value in rhs)]
            if index == 0:
                maximum_valid = inputs
                if len(inputs) != LU_ELIMINATION_MAX_VALID_INPUT_LENGTH:
                    raise ValueError("lu_elimination maximum-shape input is not 21 values")
            result, output = add_lu_elimination_case(inputs, require_valid=True)
            if result != dimension or len(output) != dimension:
                raise ValueError("lu_elimination oracle returned an invalid solution shape")
            if index == 0:
                add_lu_elimination_case(inputs, capacity=result)
                add_lu_elimination_case(inputs, capacity=result - 1)
            if index % 16 == 0:
                add_lu_elimination_case(inputs, output_is_null=True)

        if maximum_valid is None or len(maximum_valid) + 1 != LU_ELIMINATION_MAX_PARSEABLE_INPUT_LENGTH:
            raise ValueError("lu_elimination maximum parseable shape is not 22 values")
        add_lu_elimination_case(maximum_valid + [0.0])
        malformed = (
            [], maximum_valid[:-1], [*maximum_valid, 0.0], [0.0, 0.0],
            [1.5, 0.0, 0.0], [float(LU_ELIMINATION_MAX_DIMENSION + 1)],
            [1.0, 0.5, 0.0], [1.0, 2.0, 0.0],
            [1.0, 1.0, 0.5], [1.0, 1.0, 9.0],
            [2.0, 0.0, 1.0, 1.0, 1.0, 1.0, 2.0],
            [2.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0],
        )
        for inputs in malformed:
            add_lu_elimination_case(inputs)
        add_lu_elimination_case([0.0], capacity=0, output_is_null=True)
        add_lu_elimination_case([0.0], capacity=0)
        add_lu_elimination_case([1.0, 1.0, 5.0], capacity=1, output_is_null=True)
        add_lu_elimination_case([2.0, 1.0, 1.0, 1.0, 0.0, 1.0, 2.0], capacity=1)
        add_lu_elimination_case([2.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0],
                                capacity=0, output_is_null=True)
        add_lu_elimination_case([], input_is_null=True, input_length=1)

    if algorithm == "lu_pivot_decomposition":
        if (workspace != LU_PIVOT_DECOMPOSITION_MAX_OUTPUT_ELEMENTS
                or absolute_tolerance != 1e-12 or relative_tolerance != 1e-12):
            raise ValueError("lu_pivot_decomposition requires a 21-element workspace and 1e-12 tolerances")

        def add_lu_pivot_case(inputs: list[float], capacity: int = workspace,
                              output_is_null: bool = False, input_is_null: bool = False,
                              input_length: int | None = None) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            if (len(inputs) > LU_PIVOT_DECOMPOSITION_MAX_PARSEABLE_INPUT_LENGTH
                    or any(not math.isfinite(value) for value in inputs)):
                raise ValueError("lu_pivot_decomposition generated input exceeds its finite parseable bound")
            result, output = lu_pivot_decomposition_abi_oracle(
                [] if input_is_null else inputs, capacity,
                output_is_null, input_is_null, input_length)
            checker_inputs = [0.0] * input_length if input_is_null else inputs
            records.append((checker_inputs, result,
                            [_output_token(value) for value in output], capacity,
                            int(input_is_null), int(output_is_null)))
            return result, output

        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if (not isinstance(raw_values, list)
                    or len(raw_values) > LU_PIVOT_DECOMPOSITION_MAX_PARSEABLE_INPUT_LENGTH
                    or any(type(value) not in (int, float) or not math.isfinite(float(value))
                           for value in raw_values)):
                raise ValueError(f"invalid lu_pivot_decomposition ABI values: {case.get('id')}")
            inputs = [float(value) for value in raw_values]
            capacity = case.get("output_capacity")
            if capacity is None:
                capacity = workspace
            input_is_null = case.get("input_is_null")
            output_is_null = case.get("output_is_null")
            input_is_null = False if input_is_null is None else input_is_null
            output_is_null = False if output_is_null is None else output_is_null
            input_length = case.get("input_length", len(inputs))
            result, output = lu_pivot_decomposition_abi_oracle(
                inputs, capacity, output_is_null, input_is_null, input_length)
            expected_output = case.get("expected_output")
            if (case.get("expected_result") != result
                    or not isinstance(expected_output, list)
                    or len(expected_output) != len(output)
                    or any(type(actual) not in (int, float) or not math.isfinite(float(actual))
                           or abs(float(actual) - reference)
                           > absolute_tolerance + relative_tolerance * abs(reference)
                           for actual, reference in zip(expected_output, output))):
                raise ValueError(f"lu_pivot_decomposition ABI fixture mismatch: {case.get('id')}")
            add_lu_pivot_case(inputs, capacity, output_is_null,
                              input_is_null, input_length)

        rng_lu_pivot = random.Random(20261017)
        maximum_valid: list[float] | None = None
        for index in range(128):
            dimension = (LU_PIVOT_DECOMPOSITION_MAX_DIMENSION if index == 0 else
                         rng_lu_pivot.randint(1, LU_PIVOT_DECOMPOSITION_MAX_DIMENSION))
            matrix = [[rng_lu_pivot.randint(-1, 1) for _ in range(dimension)]
                      for _ in range(dimension)]
            for diagonal in range(dimension):
                matrix[diagonal][diagonal] = rng_lu_pivot.randint(4, 8)
            inputs = [float(dimension)]
            inputs.extend(float(value) for row in matrix for value in row)
            if index == 0:
                maximum_valid = inputs
                if len(inputs) != LU_PIVOT_DECOMPOSITION_MAX_VALID_INPUT_LENGTH:
                    raise ValueError("lu_pivot_decomposition maximum-shape trace is not 17 values")
            result, output = add_lu_pivot_case(inputs)
            if result <= 0 or len(output) != result:
                raise ValueError("lu_pivot_decomposition oracle rejected a generated valid trace")
            if index == 0:
                add_lu_pivot_case(inputs, capacity=result)
                add_lu_pivot_case(inputs, capacity=result - 1)
            if index % 16 == 0:
                add_lu_pivot_case(inputs, output_is_null=True)

        for inputs in (
            [2.0, 0.0, 2.0, 3.0, 4.0],
            [2.0, 2.0, 1.0, -2.0, 4.0],
            [3.0, 0.0, 1.0, 2.0, 0.0, 0.0, 3.0, 4.0, 5.0, 6.0],
        ):
            result, output = add_lu_pivot_case(inputs)
            if result <= 0 or len(output) != result:
                raise ValueError("lu_pivot_decomposition oracle rejected a pivot trace")

        if (maximum_valid is None
                or len(maximum_valid) + 1 != LU_PIVOT_DECOMPOSITION_MAX_PARSEABLE_INPUT_LENGTH):
            raise ValueError("lu_pivot_decomposition maximum parseable shape is not 18 values")
        malformed = (
            [], maximum_valid[:-1], maximum_valid + [0.0],
            [0.0], [2.5, 1.0, 0.0, 0.0, 1.0],
            [5.0] + [0.0] * 17, [1.0, 0.5], [1.0, 9.0],
            [2.0, 0.0, 1.0, 0.0, 2.0],
            [2.0, 1.0, 2.0, 2.0, 4.0],
        )
        for inputs in malformed:
            add_lu_pivot_case(inputs)
        add_lu_pivot_case([1.0, 5.0], output_is_null=True)
        add_lu_pivot_case([2.0, 4.0, 2.0, 2.0, 3.0], capacity=6)
        add_lu_pivot_case([2.0, 0.0, 1.0, 0.0, 2.0],
                          output_is_null=True, capacity=7)
        add_lu_pivot_case([], input_is_null=True, input_length=2)

    if algorithm == "kohonen_som_trace":
        if (workspace != KOHONEN_SOM_TRACE_MAX_OUTPUT_ELEMENTS
                or absolute_tolerance != 1e-12 or relative_tolerance != 1e-12):
            raise ValueError("kohonen_som_trace requires a 32-element workspace and 1e-12 tolerances")

        def add_kohonen_case(inputs: list[float], capacity: int = workspace,
                             output_is_null: bool = False, input_is_null: bool = False,
                             input_length: int | None = None,
                             require_valid: bool = False) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            if (len(inputs) > KOHONEN_SOM_TRACE_MAX_PARSEABLE_INPUT_LENGTH
                    or any(not math.isfinite(value) for value in inputs)):
                raise ValueError("kohonen_som_trace generated input exceeds its finite parseable bound")
            result, output = kohonen_som_trace_abi_oracle(
                [] if input_is_null else inputs, capacity,
                output_is_null, input_is_null, input_length)
            if require_valid and (result <= 0 or len(output) != result):
                raise ValueError("kohonen_som_trace generated valid input was rejected")
            checker_inputs = [0.0] * input_length if input_is_null else inputs
            records.append((checker_inputs, result,
                            [_output_token(value) for value in output], capacity,
                            int(input_is_null), int(output_is_null)))
            return result, output

        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if (not isinstance(raw_values, list)
                    or len(raw_values) > KOHONEN_SOM_TRACE_MAX_PARSEABLE_INPUT_LENGTH
                    or any(type(value) not in (int, float) or not math.isfinite(float(value))
                           for value in raw_values)):
                raise ValueError(f"invalid kohonen_som_trace ABI values: {case.get('id')}")
            inputs = [float(value) for value in raw_values]
            capacity = case.get("output_capacity")
            if capacity is None:
                capacity = workspace
            input_is_null = case.get("input_is_null")
            output_is_null = case.get("output_is_null")
            input_is_null = False if input_is_null is None else input_is_null
            output_is_null = False if output_is_null is None else output_is_null
            input_length = case.get("input_length", len(inputs))
            result, output = kohonen_som_trace_abi_oracle(
                inputs, capacity, output_is_null, input_is_null, input_length)
            expected_output = case.get("expected_output")
            if (case.get("expected_result") != result
                    or not isinstance(expected_output, list)
                    or len(expected_output) != len(output)
                    or any(type(actual) not in (int, float) or not math.isfinite(float(actual))
                           or abs(float(actual) - reference)
                           > absolute_tolerance + relative_tolerance * abs(reference)
                           for actual, reference in zip(expected_output, output))):
                raise ValueError(f"kohonen_som_trace ABI fixture mismatch: {case.get('id')}")
            add_kohonen_case(inputs, capacity, output_is_null,
                             input_is_null, input_length)

        rng_kohonen = random.Random(20261017)
        for index in range(256):
            node_count = (KOHONEN_SOM_TRACE_MAX_NODES if index == 0 else
                          rng_kohonen.randint(1, KOHONEN_SOM_TRACE_MAX_NODES))
            feature_count = (KOHONEN_SOM_TRACE_MAX_FEATURES if index == 0 else
                             rng_kohonen.randint(1, KOHONEN_SOM_TRACE_MAX_FEATURES))
            radius = (KOHONEN_SOM_TRACE_MAX_RADIUS if index == 0 else
                      rng_kohonen.randint(0, KOHONEN_SOM_TRACE_MAX_RADIUS))
            alpha_code = 16 if index == 0 else rng_kohonen.randint(1, 16)
            sample = [rng_kohonen.randint(-8, 8) for _ in range(feature_count)]
            weights = [rng_kohonen.randint(-8, 8)
                       for _ in range(node_count * feature_count)]
            inputs = [float(node_count), float(feature_count), float(radius),
                      float(alpha_code), *(float(value) for value in sample),
                      *(float(value) for value in weights)]
            result, output = add_kohonen_case(inputs)
            if result <= 0 or len(output) != result:
                raise ValueError("kohonen_som_trace oracle rejected a generated valid update")
            if index == 0:
                if len(inputs) != KOHONEN_SOM_TRACE_MAX_VALID_INPUT_LENGTH:
                    raise ValueError("kohonen_som_trace maximum-shape input is not 40 values")
                add_kohonen_case(inputs, capacity=result)
                add_kohonen_case(inputs, capacity=result - 1)
            if index % 16 == 0:
                add_kohonen_case(inputs, output_is_null=True)

        maximum_valid = [
            8.0, 4.0, 8.0, 16.0, -8.0, 8.0, -8.0, 8.0,
            *([-8.0, 8.0] * (KOHONEN_SOM_TRACE_MAX_NODES
                              * KOHONEN_SOM_TRACE_MAX_FEATURES // 2)),
        ]
        if (len(maximum_valid) != KOHONEN_SOM_TRACE_MAX_VALID_INPUT_LENGTH
                or len(maximum_valid) + 1 != KOHONEN_SOM_TRACE_MAX_PARSEABLE_INPUT_LENGTH):
            raise ValueError("kohonen_som_trace maximum and parseable shapes have unexpected lengths")
        add_kohonen_case(maximum_valid, require_valid=True)
        add_kohonen_case([*maximum_valid, 0.0])

        malformed = (
            [], maximum_valid[:-1], [*maximum_valid, 0.0],
            [0.0, 1.0, 0.0, 8.0], [1.0, 0.0, 0.0, 8.0],
            [9.0, 1.0, 0.0, 8.0], [1.0, 5.0, 0.0, 8.0],
            [1.0, 1.0, -1.0, 8.0, 1.0, 0.0],
            [1.0, 1.0, 0.0, 0.0, 1.0, 0.0],
            [1.0, 1.0, 0.0, 17.0, 1.0, 0.0],
            [1.0, 1.0, 0.0, 8.0, 0.5, 0.0],
            [1.0, 1.0, 0.0, 8.0, 1.0, 9.0],
            [1.0, 1.0, 0.0, 8.0, 1.0, 0.5],
            [1.0, 1.0, 0.0, 8.0, 1.0, 0.0, 0.0],
        )
        for inputs in malformed:
            add_kohonen_case(inputs)
        add_kohonen_case([1.0, 1.0, 0.0, 8.0, 1.0, 0.0],
                         output_is_null=True)
        add_kohonen_case([2.0, 1.0, 0.0, 8.0, 0.0, -1.0, 1.0], capacity=1)
        add_kohonen_case([1.0, 1.0, -1.0, 8.0, 1.0, 0.0],
                         output_is_null=True, capacity=1)
        add_kohonen_case([], input_is_null=True, input_length=6)

    if algorithm == "kohonen_som_topology":
        if (workspace != KOHONEN_SOM_TOPOLOGY_MAX_OUTPUT_ELEMENTS
                or absolute_tolerance != 1e-12 or relative_tolerance != 1e-12):
            raise ValueError("kohonen_som_topology requires a 49-element workspace and 1e-12 tolerances")

        def add_kohonen_topology_case(inputs: list[float], capacity: int = workspace,
                                     output_is_null: bool = False, input_is_null: bool = False,
                                     input_length: int | None = None,
                                     require_valid: bool = False) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            if (len(inputs) > KOHONEN_SOM_TOPOLOGY_MAX_PARSEABLE_INPUT_LENGTH
                    or any(not math.isfinite(value) for value in inputs)):
                raise ValueError("kohonen_som_topology generated input exceeds its finite parseable bound")
            result, output = kohonen_som_topology_abi_oracle(
                [] if input_is_null else inputs, capacity,
                output_is_null, input_is_null, input_length)
            if require_valid and (result <= 0 or len(output) != result):
                raise ValueError("kohonen_som_topology generated valid update was rejected")
            checker_inputs = [0.0] * input_length if input_is_null else inputs
            records.append((checker_inputs, result,
                            [_output_token(value) for value in output], capacity,
                            int(input_is_null), int(output_is_null)))
            return result, output

        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if (not isinstance(raw_values, list)
                    or len(raw_values) > KOHONEN_SOM_TOPOLOGY_MAX_PARSEABLE_INPUT_LENGTH
                    or any(type(value) not in (int, float) or not math.isfinite(float(value))
                           for value in raw_values)):
                raise ValueError(f"invalid kohonen_som_topology ABI values: {case.get('id')}")
            inputs = [float(value) for value in raw_values]
            capacity = case.get("output_capacity")
            if capacity is None:
                capacity = workspace
            input_is_null = case.get("input_is_null")
            output_is_null = case.get("output_is_null")
            input_is_null = False if input_is_null is None else input_is_null
            output_is_null = False if output_is_null is None else output_is_null
            input_length = case.get("input_length", len(inputs))
            result, output = kohonen_som_topology_abi_oracle(
                inputs, capacity, output_is_null, input_is_null, input_length)
            expected_output = case.get("expected_output")
            if (case.get("expected_result") != result
                    or not isinstance(expected_output, list)
                    or len(expected_output) != len(output)
                    or any(type(actual) not in (int, float) or not math.isfinite(float(actual))
                           or abs(float(actual) - reference)
                           > absolute_tolerance + relative_tolerance * abs(reference)
                           for actual, reference in zip(expected_output, output))):
                raise ValueError(f"kohonen_som_topology ABI fixture mismatch: {case.get('id')}")
            add_kohonen_topology_case(inputs, capacity, output_is_null,
                                      input_is_null, input_length)

        rng_kohonen_topology = random.Random(20261018)
        for index in range(256):
            map_size = (KOHONEN_SOM_TOPOLOGY_MAX_MAP_SIZE if index == 0 else
                        rng_kohonen_topology.randint(1, KOHONEN_SOM_TOPOLOGY_MAX_MAP_SIZE))
            feature_count = (KOHONEN_SOM_TOPOLOGY_MAX_FEATURES if index == 0 else
                             rng_kohonen_topology.randint(1, KOHONEN_SOM_TOPOLOGY_MAX_FEATURES))
            radius = (KOHONEN_SOM_TOPOLOGY_MAX_RADIUS if index == 0 else
                      rng_kohonen_topology.randint(0, KOHONEN_SOM_TOPOLOGY_MAX_RADIUS))
            alpha_code = 16 if index == 0 else rng_kohonen_topology.randint(1, 16)
            sample = [rng_kohonen_topology.randint(-8, 8) for _ in range(feature_count)]
            weights = [rng_kohonen_topology.randint(-8, 8)
                       for _ in range(map_size * map_size * feature_count)]
            inputs = [float(map_size), float(feature_count), float(radius),
                      float(alpha_code), *(float(value) for value in sample),
                      *(float(value) for value in weights)]
            result, output = add_kohonen_topology_case(inputs)
            if result <= 0 or len(output) != result:
                raise ValueError("kohonen_som_topology oracle rejected a generated valid update")
            if index == 0:
                if len(inputs) != KOHONEN_SOM_TOPOLOGY_MAX_VALID_INPUT_LENGTH:
                    raise ValueError("kohonen_som_topology maximum-shape input is not 55 values")
                add_kohonen_topology_case(inputs, capacity=result)
                add_kohonen_topology_case(inputs, capacity=result - 1)
            if index % 16 == 0:
                add_kohonen_topology_case(inputs, output_is_null=True)

        maximum_valid = [
            4.0, 3.0, 8.0, 16.0, -8.0, 8.0, -8.0,
            *([-8.0, 8.0] * (KOHONEN_SOM_TOPOLOGY_MAX_MAP_SIZE ** 2
                              * KOHONEN_SOM_TOPOLOGY_MAX_FEATURES // 2)),
        ]
        if (len(maximum_valid) != KOHONEN_SOM_TOPOLOGY_MAX_VALID_INPUT_LENGTH
                or len(maximum_valid) + 1
                    != KOHONEN_SOM_TOPOLOGY_MAX_PARSEABLE_INPUT_LENGTH):
            raise ValueError("kohonen_som_topology maximum and parseable shapes have unexpected lengths")
        add_kohonen_topology_case(maximum_valid, require_valid=True)
        add_kohonen_topology_case([*maximum_valid, 0.0])

        malformed = (
            [], maximum_valid[:-1], [*maximum_valid, 0.0],
            [0.0, 1.0, 0.0, 8.0], [5.0, 1.0, 0.0, 8.0],
            [1.0, 0.0, 0.0, 8.0], [1.0, 4.0, 0.0, 8.0, 0.0, 0.0, 0.0, 0.0, 0.0],
            [1.0, 1.0, -1.0, 8.0, 1.0, 0.0],
            [1.0, 1.0, 9.0, 8.0, 1.0, 0.0],
            [1.0, 1.0, 0.0, 0.0, 1.0, 0.0],
            [1.0, 1.0, 0.0, 17.0, 1.0, 0.0],
            [1.0, 1.0, 0.0, 8.0, 0.5, 0.0],
            [1.0, 1.0, 0.0, 8.0, 1.0, 9.0],
            [1.0, 1.0, 0.0, 8.0, 1.0, 0.5],
        )
        for inputs in malformed:
            add_kohonen_topology_case(inputs)
        add_kohonen_topology_case([1.0, 1.0, 0.0, 8.0, 1.0, 0.0],
                                  output_is_null=True)
        add_kohonen_topology_case([1.0, 1.0, 0.0, 8.0, 1.0, 0.0], capacity=1)
        add_kohonen_topology_case([1.0, 1.0, 9.0, 8.0, 1.0, 0.0],
                                  output_is_null=True, capacity=1)
        add_kohonen_topology_case([], input_is_null=True, input_length=6)

    if algorithm == "qr_decompose":
        if (workspace != QR_DECOMPOSE_MAX_OUTPUT_ELEMENTS
                or absolute_tolerance != 1e-12 or relative_tolerance != 1e-12):
            raise ValueError("qr_decompose requires a 32-element workspace and 1e-12 tolerances")

        def add_qr_decompose_case(inputs: list[float], capacity: int = workspace,
                                  output_is_null: bool = False, input_is_null: bool = False,
                                  input_length: int | None = None,
                                  require_valid: bool = False) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            if (len(inputs) > QR_DECOMPOSE_MAX_PARSEABLE_INPUT_LENGTH
                    or any(not math.isfinite(value) for value in inputs)):
                raise ValueError("qr_decompose generated input exceeds its finite parseable bound")
            result, output = qr_decompose_abi_oracle(
                [] if input_is_null else inputs, capacity,
                output_is_null, input_is_null, input_length)
            if require_valid and (result <= 0 or len(output) != result):
                raise ValueError("qr_decompose generated nonsingular input was rejected")
            checker_inputs = [0.0] * input_length if input_is_null else inputs
            records.append((checker_inputs, result,
                            [_output_token(value) for value in output], capacity,
                            int(input_is_null), int(output_is_null)))
            return result, output

        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if (not isinstance(raw_values, list)
                    or len(raw_values) > QR_DECOMPOSE_MAX_PARSEABLE_INPUT_LENGTH
                    or any(type(value) not in (int, float) or not math.isfinite(float(value))
                           for value in raw_values)):
                raise ValueError(f"invalid qr_decompose ABI values: {case.get('id')}")
            inputs = [float(value) for value in raw_values]
            capacity = case.get("output_capacity")
            if capacity is None:
                capacity = workspace
            input_is_null = case.get("input_is_null")
            output_is_null = case.get("output_is_null")
            input_is_null = False if input_is_null is None else input_is_null
            output_is_null = False if output_is_null is None else output_is_null
            input_length = case.get("input_length", len(inputs))
            result, output = qr_decompose_abi_oracle(
                inputs, capacity, output_is_null, input_is_null, input_length)
            expected_output = case.get("expected_output")
            if (case.get("expected_result") != result
                    or not isinstance(expected_output, list)
                    or len(expected_output) != len(output)
                    or any(type(actual) not in (int, float) or not math.isfinite(float(actual))
                           or abs(float(actual) - reference)
                           > absolute_tolerance + relative_tolerance * abs(reference)
                           for actual, reference in zip(expected_output, output))):
                raise ValueError(f"qr_decompose ABI fixture mismatch: {case.get('id')}")
            add_qr_decompose_case(inputs, capacity, output_is_null,
                                  input_is_null, input_length)

        rng_qr = random.Random(20261019)
        for index in range(256):
            dimension = (QR_DECOMPOSE_MAX_DIMENSION if index == 0 else
                         rng_qr.randint(QR_DECOMPOSE_MIN_DIMENSION,
                                        QR_DECOMPOSE_MAX_DIMENSION))
            matrix = [[0] * dimension for _ in range(dimension)]
            for row in range(dimension):
                for col in range(row, dimension):
                    if row == col:
                        diagonal = rng_qr.randint(1, QR_DECOMPOSE_MAX_MATRIX_VALUE)
                        matrix[row][col] = (diagonal if rng_qr.randrange(2)
                                            else -diagonal)
                    else:
                        matrix[row][col] = rng_qr.randint(
                            QR_DECOMPOSE_MIN_MATRIX_VALUE, QR_DECOMPOSE_MAX_MATRIX_VALUE)
            inputs = [float(dimension),
                      *(float(matrix[row][col])
                        for row in range(dimension) for col in range(dimension))]
            result, output = add_qr_decompose_case(inputs, require_valid=True)
            if result <= 0 or len(output) != result:
                raise ValueError("qr_decompose oracle rejected a generated nonsingular matrix")
            if index == 0:
                if len(inputs) != QR_DECOMPOSE_MAX_VALID_INPUT_LENGTH:
                    raise ValueError("qr_decompose maximum-shape input is not 17 values")
                add_qr_decompose_case(inputs, capacity=result)
                add_qr_decompose_case(inputs, capacity=result - 1)
            if index % 16 == 0:
                add_qr_decompose_case(inputs, output_is_null=True)

        maximum_valid = [
            4.0, 4.0, 1.0, -1.0, 0.0,
            0.0, 3.0, 1.0, -1.0,
            0.0, 0.0, 2.0, 1.0,
            0.0, 0.0, 0.0, 1.0,
        ]
        if (len(maximum_valid) != QR_DECOMPOSE_MAX_VALID_INPUT_LENGTH
                or len(maximum_valid) + 1 != QR_DECOMPOSE_MAX_PARSEABLE_INPUT_LENGTH):
            raise ValueError("qr_decompose maximum and parseable shapes have unexpected lengths")
        add_qr_decompose_case(maximum_valid, require_valid=True)
        add_qr_decompose_case([*maximum_valid, 0.0])

        malformed = (
            [], [1.0], [*maximum_valid, 0.0],
            [0.0], [5.0], [1.5, 0.0], [1.0, 0.5], [1.0, 5.0],
            [2.0, 1.0, 2.0, 2.0, 4.0],
        )
        for inputs in malformed:
            add_qr_decompose_case(inputs)
        add_qr_decompose_case([1.0, -3.0], output_is_null=True)
        add_qr_decompose_case([1.0, -3.0], capacity=1)
        add_qr_decompose_case([2.0, 1.0, 2.0, 2.0, 4.0],
                              output_is_null=True, capacity=1)
        add_qr_decompose_case([], input_is_null=True, input_length=1)

    if algorithm == "qr_eigen_values":
        if (workspace != 2
                or absolute_tolerance != 1e-8 or relative_tolerance != 1e-8):
            raise ValueError("qr_eigen_values requires a 2-element workspace and 1e-8 tolerances")
        for case in workload.get("abi_cases", []):
            inputs = [float(value) for value in case["input_values"]]
            capacity = case.get("output_capacity", workspace)
            input_is_null = case.get("input_is_null", False)
            output_is_null = case.get("output_is_null", False)
            input_length = case.get("input_length", len(inputs))
            result, output = qr_eigen_values_abi_verifier_oracle(
                inputs, capacity, output_is_null, input_is_null, input_length)
            checker_inputs = [0.0] * input_length if input_is_null else inputs
            records.append((checker_inputs, result,
                            [_output_token(value) for value in output], capacity,
                            int(input_is_null), int(output_is_null)))

    if algorithm == "qr_decomposition":
        if (workspace != QR_DECOMPOSITION_MAX_OUTPUT_ELEMENTS
                or absolute_tolerance != 1e-8 or relative_tolerance != 1e-8):
            raise ValueError("qr_decomposition requires a 3-element workspace and 1e-8 tolerances")

        def add_qr_decomposition_case(
            inputs: list[float], capacity: int = workspace,
            output_is_null: bool = False, input_is_null: bool = False,
            input_length: int | None = None, require_valid: bool = False,
        ) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            if (len(inputs) > QR_DECOMPOSITION_MAX_PARSEABLE_INPUT_LENGTH
                    or any(not math.isfinite(value) for value in inputs)):
                raise ValueError("qr_decomposition generated input exceeds its finite parseable bound")
            result, output = qr_decomposition_abi_oracle(
                [] if input_is_null else inputs, capacity,
                output_is_null, input_is_null, input_length)
            if require_valid and (result != QR_DECOMPOSITION_MAX_OUTPUT_ELEMENTS
                                  or len(output) != result):
                raise ValueError("qr_decomposition generated valid matrix was rejected")
            checker_inputs = [0.0] * input_length if input_is_null else inputs
            records.append((checker_inputs, result,
                            [_output_token(value) for value in output], capacity,
                            int(input_is_null), int(output_is_null)))
            return result, output

        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if (not isinstance(raw_values, list)
                    or len(raw_values) > QR_DECOMPOSITION_MAX_PARSEABLE_INPUT_LENGTH
                    or any(type(value) not in (int, float) or not math.isfinite(float(value))
                           for value in raw_values)):
                raise ValueError(f"invalid qr_decomposition ABI values: {case.get('id')}")
            inputs = [float(value) for value in raw_values]
            capacity = case.get("output_capacity")
            if capacity is None:
                capacity = workspace
            input_is_null = case.get("input_is_null")
            output_is_null = case.get("output_is_null")
            input_is_null = False if input_is_null is None else input_is_null
            output_is_null = False if output_is_null is None else output_is_null
            input_length = case.get("input_length", len(inputs))
            result, output = qr_decomposition_abi_oracle(
                inputs, capacity, output_is_null, input_is_null, input_length)
            expected_output = case.get("expected_output")
            if (case.get("expected_result") != result
                    or not isinstance(expected_output, list)
                    or len(expected_output) != len(output)
                    or any(type(actual) not in (int, float) or not math.isfinite(float(actual))
                           or abs(float(actual) - reference)
                           > absolute_tolerance + relative_tolerance * abs(reference)
                           for actual, reference in zip(expected_output, output))):
                raise ValueError(f"qr_decomposition ABI fixture mismatch: {case.get('id')}")
            add_qr_decomposition_case(inputs, capacity, output_is_null,
                                      input_is_null, input_length)

        rng_qr_properties = random.Random(20261020)
        for index in range(256):
            dimension = (QR_DECOMPOSITION_MAX_DIMENSION if index == 0 else
                         rng_qr_properties.randint(QR_DECOMPOSITION_MIN_DIMENSION,
                                                   QR_DECOMPOSITION_MAX_DIMENSION))
            matrix = [[0] * dimension for _ in range(dimension)]
            for row in range(dimension):
                for col in range(dimension):
                    if col < row:
                        matrix[row][col] = 0
                    elif row == col:
                        diagonal = rng_qr_properties.randint(
                            QR_DECOMPOSITION_MIN_MATRIX_VALUE,
                            QR_DECOMPOSITION_MAX_MATRIX_VALUE)
                        while diagonal == 0:
                            diagonal = rng_qr_properties.randint(
                                QR_DECOMPOSITION_MIN_MATRIX_VALUE,
                                QR_DECOMPOSITION_MAX_MATRIX_VALUE)
                        matrix[row][col] = diagonal
                    else:
                        matrix[row][col] = rng_qr_properties.randint(
                            QR_DECOMPOSITION_MIN_MATRIX_VALUE,
                            QR_DECOMPOSITION_MAX_MATRIX_VALUE)
            inputs = [float(dimension),
                      *(float(matrix[row][col])
                        for row in range(dimension) for col in range(dimension))]
            result, output = add_qr_decomposition_case(inputs, require_valid=True)
            if result != QR_DECOMPOSITION_MAX_OUTPUT_ELEMENTS or len(output) != result:
                raise ValueError("qr_decomposition oracle rejected an upper-triangular matrix with nonzero diagonal")
            if index == 0:
                if len(inputs) != QR_DECOMPOSITION_MAX_VALID_INPUT_LENGTH:
                    raise ValueError("qr_decomposition maximum-shape input is not 17 values")
                add_qr_decomposition_case(inputs, capacity=result)
                add_qr_decomposition_case(inputs, capacity=result - 1)
            if index % 16 == 0:
                add_qr_decomposition_case(inputs, output_is_null=True)

        maximum_valid = [
            4.0, 1.0, 1.0, 0.0, 0.0,
            1.0, 0.0, 1.0, 0.0,
            0.0, 1.0, 1.0, 1.0,
            1.0, 0.0, 0.0, 1.0,
        ]
        if (len(maximum_valid) != QR_DECOMPOSITION_MAX_VALID_INPUT_LENGTH
                or len(maximum_valid) + 1
                    != QR_DECOMPOSITION_MAX_PARSEABLE_INPUT_LENGTH):
            raise ValueError("qr_decomposition maximum and parseable shapes have unexpected lengths")
        add_qr_decomposition_case(maximum_valid, require_valid=True)
        add_qr_decomposition_case([*maximum_valid, 0.0])

        malformed = (
            [], [1.0], [*maximum_valid, 0.0],
            [0.0], [5.0], [1.5, 0.0], [1.0, 0.5], [1.0, 2.0],
            [2.0, 1.0, 1.0, 1.0, 1.0],
            [2.0, 0.0, 1.0, 1.0, 0.0],
        )
        for inputs in malformed:
            add_qr_decomposition_case(inputs)
        add_qr_decomposition_case([1.0, 1.0], output_is_null=True)
        add_qr_decomposition_case([1.0, -1.0], capacity=2)
        add_qr_decomposition_case([2.0, 0.0, 1.0, 1.0, 0.0],
                                  output_is_null=True, capacity=2)
        add_qr_decomposition_case([], input_is_null=True, input_length=1)

    if algorithm == "shuffle":
        if (workspace != SHUFFLE_MAX_OUTPUT_ELEMENTS
                or absolute_tolerance != 0.0 or relative_tolerance != 0.0):
            raise ValueError("shuffle requires a 256-element workspace and exact float64 comparisons")

        def add_shuffle_case(
            inputs: list[float], capacity: int = workspace,
            output_is_null: bool = False, input_is_null: bool = False,
            input_length: int | None = None, require_valid: bool = False,
        ) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            if (len(inputs) > SHUFFLE_MAX_PARSEABLE_INPUT_LENGTH
                    or any(not math.isfinite(value) for value in inputs)):
                raise ValueError("shuffle generated input exceeds its finite parseable bound")
            result, output = shuffle_abi_oracle(
                [] if input_is_null else inputs, capacity,
                output_is_null, input_is_null, input_length)
            if require_valid and (result < 0 or len(output) != result):
                raise ValueError("shuffle generated valid input was rejected")
            checker_inputs = [0.0] * input_length if input_is_null else inputs
            records.append((checker_inputs, result,
                            [_output_token(value) for value in output], capacity,
                            int(input_is_null), int(output_is_null)))
            return result, output

        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if (not isinstance(raw_values, list)
                    or len(raw_values) > SHUFFLE_MAX_PARSEABLE_INPUT_LENGTH
                    or any(type(value) not in (int, float) or not math.isfinite(float(value))
                           for value in raw_values)):
                raise ValueError(f"invalid shuffle ABI values: {case.get('id')}")
            inputs = [float(value) for value in raw_values]
            capacity = case.get("output_capacity")
            if capacity is None:
                capacity = workspace
            input_is_null = case.get("input_is_null")
            output_is_null = case.get("output_is_null")
            input_is_null = False if input_is_null is None else input_is_null
            output_is_null = False if output_is_null is None else output_is_null
            input_length = case.get("input_length", len(inputs))
            result, output = shuffle_abi_oracle(
                inputs, capacity, output_is_null, input_is_null, input_length)
            expected_output = case.get("expected_output")
            if (case.get("expected_result") != result
                    or not isinstance(expected_output, list)
                    or len(expected_output) != len(output)
                    or any(type(actual) not in (int, float) or not math.isfinite(float(actual))
                           or float(actual) != reference
                           for actual, reference in zip(expected_output, output))):
                raise ValueError(f"shuffle ABI fixture mismatch: {case.get('id')}")
            add_shuffle_case(inputs, capacity, output_is_null,
                             input_is_null, input_length)

        rng_shuffle = random.Random(20261021)
        for index in range(256):
            count = (SHUFFLE_MAX_LENGTH if index == 0 else
                     rng_shuffle.randint(SHUFFLE_MIN_LENGTH, SHUFFLE_MAX_LENGTH))
            items = [rng_shuffle.randint(SHUFFLE_MIN_VALUE, SHUFFLE_MAX_VALUE)
                     for _ in range(count)]
            offsets = [rng_shuffle.randint(0, count - 1 - swap_index)
                       for swap_index in range(max(count - 1, 0))]
            inputs = [float(count), *(float(value) for value in items),
                      *(float(offset) for offset in offsets)]
            result, output = add_shuffle_case(inputs, require_valid=True)
            if result != count or len(output) != count:
                raise ValueError("shuffle oracle returned an invalid generated permutation")
            if index == 0:
                if len(inputs) != SHUFFLE_MAX_VALID_INPUT_LENGTH:
                    raise ValueError("shuffle maximum-shape input is not 512 values")
                add_shuffle_case(inputs, capacity=result)
                add_shuffle_case(inputs, capacity=result - 1)
            if index % 16 == 0:
                add_shuffle_case(inputs, output_is_null=True)

        maximum_valid = [
            float(SHUFFLE_MAX_LENGTH),
            *(float(value) for value in range(-128, 128)),
            *(float(offset) for offset in range(SHUFFLE_MAX_LENGTH - 1, 0, -1)),
        ]
        if (len(maximum_valid) != SHUFFLE_MAX_VALID_INPUT_LENGTH
                or len(maximum_valid) + 1 != SHUFFLE_MAX_PARSEABLE_INPUT_LENGTH):
            raise ValueError("shuffle maximum and parseable shapes have unexpected lengths")
        add_shuffle_case(maximum_valid, require_valid=True)
        add_shuffle_case([*maximum_valid, 0.0])

        malformed = (
            [], [0.0, 0.0], [2.0, 10.0, 20.0], [1.0, 7.0, 0.0],
            [1.5, 0.0], [float(SHUFFLE_MAX_LENGTH + 1)],
            [1.0, 0.5], [1.0, float(SHUFFLE_MAX_VALUE + 1)],
            [2.0, 10.0, 20.0, 0.5], [2.0, 10.0, 20.0, -1.0],
            [2.0, 10.0, 20.0, 2.0],
        )
        for inputs in malformed:
            add_shuffle_case(inputs)
        add_shuffle_case([0.0], capacity=0, output_is_null=True)
        add_shuffle_case([0.0], capacity=0)
        add_shuffle_case([1.0, 7.0], capacity=1, output_is_null=True)
        add_shuffle_case([2.0, 10.0, 20.0, 0.0], capacity=1)
        add_shuffle_case([2.0, 10.0, 20.0, 2.0], capacity=0,
                         output_is_null=True)
        add_shuffle_case([], input_is_null=True, input_length=1)

    if algorithm == "spirograph":
        if (workspace != SPIROGRAPH_MAX_OUTPUT_ELEMENTS
                or absolute_tolerance != SPIROGRAPH_ABSOLUTE_TOLERANCE
                or relative_tolerance != SPIROGRAPH_RELATIVE_TOLERANCE):
            raise ValueError("spirograph requires a 64-element workspace and 1e-10 absolute tolerance")

        def add_spirograph_case(
            inputs: list[float], capacity: int = workspace,
            output_is_null: bool = False, input_is_null: bool = False,
            input_length: int | None = None, require_valid: bool = False,
        ) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            if (len(inputs) > SPIROGRAPH_MAX_PARSEABLE_INPUT_LENGTH
                    or any(not math.isfinite(value) for value in inputs)):
                raise ValueError("spirograph generated input exceeds its finite parseable bound")
            result, output = spirograph_abi_oracle(
                [] if input_is_null else inputs, capacity,
                output_is_null, input_is_null, input_length)
            if require_valid and (result < 0 or len(output) != result):
                raise ValueError("spirograph oracle rejected a generated valid coordinate trace")
            checker_inputs = [0.0] * input_length if input_is_null else inputs
            records.append((checker_inputs, result,
                            [_output_token(value) for value in output], capacity,
                            int(input_is_null), int(output_is_null)))
            return result, output

        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if (not isinstance(raw_values, list)
                    or len(raw_values) > SPIROGRAPH_MAX_PARSEABLE_INPUT_LENGTH
                    or any(type(value) not in (int, float) or not math.isfinite(float(value))
                           for value in raw_values)):
                raise ValueError(f"invalid spirograph ABI values: {case.get('id')}")
            inputs = [float(value) for value in raw_values]
            capacity = case.get("output_capacity")
            if capacity is None:
                capacity = workspace
            input_is_null = case.get("input_is_null")
            output_is_null = case.get("output_is_null")
            input_is_null = False if input_is_null is None else input_is_null
            output_is_null = False if output_is_null is None else output_is_null
            input_length = case.get("input_length", len(inputs))
            result, output = spirograph_abi_oracle(
                inputs, capacity, output_is_null, input_is_null, input_length)
            expected_output = case.get("expected_output")
            if (case.get("expected_result") != result
                    or not isinstance(expected_output, list)
                    or len(expected_output) != len(output)
                    or any(type(actual) not in (int, float) or not math.isfinite(float(actual))
                           or abs(float(actual) - reference)
                           > absolute_tolerance + relative_tolerance * abs(reference)
                           for actual, reference in zip(expected_output, output))):
                raise ValueError(f"spirograph ABI fixture mismatch: {case.get('id')}")
            add_spirograph_case(
                inputs, capacity, output_is_null, input_is_null, input_length)

        rng_spirograph = random.Random(20261023)
        for index in range(128):
            point_count = (index + 1 if index < SPIROGRAPH_MAX_POINTS else
                           rng_spirograph.randint(SPIROGRAPH_MIN_POINTS, SPIROGRAPH_MAX_POINTS))
            marker_ratio = rng_spirograph.uniform(
                SPIROGRAPH_MIN_MARKER_RATIO, SPIROGRAPH_MAX_MARKER_RATIO)
            inner_ratio = rng_spirograph.uniform(
                SPIROGRAPH_MIN_INNER_RATIO, SPIROGRAPH_MAX_INNER_RATIO)
            rotations = rng_spirograph.uniform(
                SPIROGRAPH_MIN_ROTATIONS, SPIROGRAPH_MAX_ROTATIONS)
            inputs = [float(point_count), marker_ratio, inner_ratio, rotations]
            result, output = add_spirograph_case(inputs, require_valid=True)
            if result != 2 * point_count or len(output) != result:
                raise ValueError("spirograph oracle returned an invalid interleaved output shape")
            if index == 0 or index % 16 == 0:
                add_spirograph_case(inputs, output_is_null=True)
            if index == 31:
                if (len(inputs) != SPIROGRAPH_MAX_VALID_INPUT_LENGTH
                        or len(output) != SPIROGRAPH_MAX_OUTPUT_ELEMENTS):
                    raise ValueError("spirograph maximum-shape case does not produce 64 values")
                add_spirograph_case(inputs, capacity=result)
                add_spirograph_case(inputs, capacity=result - 1)

        maximum_valid = [
            float(SPIROGRAPH_MAX_POINTS), SPIROGRAPH_MAX_MARKER_RATIO,
            SPIROGRAPH_MIN_INNER_RATIO, SPIROGRAPH_MAX_ROTATIONS,
        ]
        if (len(maximum_valid) != SPIROGRAPH_MAX_VALID_INPUT_LENGTH
                or len(maximum_valid) + 1 != SPIROGRAPH_MAX_PARSEABLE_INPUT_LENGTH):
            raise ValueError("spirograph maximum and parseable input lengths are unexpected")
        add_spirograph_case(maximum_valid, require_valid=True)
        add_spirograph_case([*maximum_valid, 0.0])
        malformed = (
            [], [1.0, 0.5, 0.5], [1.0, 0.5, 0.5, 1.0, 0.0],
            [0.0, 0.5, 0.5, 1.0], [1.5, 0.5, 0.5, 1.0],
            [float(SPIROGRAPH_MAX_POINTS + 1), 0.5, 0.5, 1.0],
            [1.0, -0.01, 0.5, 1.0], [1.0, 1.01, 0.5, 1.0],
            [1.0, 0.5, SPIROGRAPH_MIN_INNER_RATIO - 0.001, 1.0],
            [1.0, 0.5, SPIROGRAPH_MAX_INNER_RATIO + 0.001, 1.0],
            [1.0, 0.5, 0.5, -0.01], [1.0, 0.5, 0.5, SPIROGRAPH_MAX_ROTATIONS + 0.01],
        )
        for inputs in malformed:
            add_spirograph_case(inputs)
        add_spirograph_case([1.0, 0.0, 0.5, 1.0], capacity=2, output_is_null=True)
        add_spirograph_case([1.0, 0.0, 0.5, 1.0], capacity=1)
        add_spirograph_case([0.0, 0.5, 0.5, 1.0], capacity=0, output_is_null=True)
        add_spirograph_case([], input_is_null=True, input_length=4)

    if algorithm == "polynomial_regression":
        if (workspace != 8 or absolute_tolerance != 1e-9 or relative_tolerance != 1e-9):
            raise ValueError("polynomial_regression requires an 8-element workspace and 1e-9 tolerances")

        def add_polynomial_case(inputs: list[float], capacity: int = workspace,
                                output_is_null: bool = False, input_is_null: bool = False,
                                input_length: int | None = None) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            result, output = polynomial_regression_abi_oracle(
                [] if input_is_null else inputs, capacity, output_is_null,
                input_is_null, input_length)
            checker_inputs = [0.0] * input_length if input_is_null else inputs
            records.append((checker_inputs, result,
                            [_output_token(value) for value in output], capacity,
                            int(input_is_null), int(output_is_null)))
            return result, output

        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if (not isinstance(raw_values, list)
                    or len(raw_values) > POLYNOMIAL_REGRESSION_MAX_PARSEABLE_INPUT_LENGTH
                    or any(type(value) not in (int, float) or not math.isfinite(float(value))
                           for value in raw_values)):
                raise ValueError(f"invalid polynomial_regression ABI values: {case.get('id')}")
            inputs = [float(value) for value in raw_values]
            capacity = case.get("output_capacity")
            capacity = workspace if capacity is None else capacity
            input_is_null = case.get("input_is_null")
            output_is_null = case.get("output_is_null")
            input_is_null = False if input_is_null is None else input_is_null
            output_is_null = False if output_is_null is None else output_is_null
            input_length = case.get("input_length", len(inputs))
            result, output = polynomial_regression_abi_oracle(
                inputs, capacity, output_is_null, input_is_null, input_length)
            expected = case.get("expected_output")
            if (case.get("expected_result") != result or not isinstance(expected, list)
                    or len(expected) != len(output)
                    or any(type(actual) not in (int, float) or not math.isfinite(float(actual))
                           or abs(float(actual) - reference)
                           > absolute_tolerance + relative_tolerance * abs(reference)
                           for actual, reference in zip(expected, output))):
                raise ValueError(f"polynomial_regression ABI fixture mismatch: {case.get('id')}")
            add_polynomial_case(inputs, capacity, output_is_null, input_is_null, input_length)

        rng_polynomial = random.Random(20261017)
        maximum_valid: list[float] | None = None
        for index in range(128):
            if index == 0:
                degree, training_count, query_count = 3, 5, 4
            else:
                degree = rng_polynomial.randint(
                    POLYNOMIAL_REGRESSION_MIN_DEGREE, POLYNOMIAL_REGRESSION_MAX_DEGREE)
                training_count = rng_polynomial.randint(
                    degree + 1, POLYNOMIAL_REGRESSION_MAX_TRAINING_COUNT)
                query_count = rng_polynomial.randint(
                    POLYNOMIAL_REGRESSION_MIN_QUERY_COUNT, POLYNOMIAL_REGRESSION_MAX_QUERY_COUNT)
            x_train = rng_polynomial.sample(
                range(POLYNOMIAL_REGRESSION_MIN_ABSCISSA,
                      POLYNOMIAL_REGRESSION_MAX_ABSCISSA + 1),
                training_count)
            y_train = [rng_polynomial.randint(
                POLYNOMIAL_REGRESSION_MIN_RESPONSE, POLYNOMIAL_REGRESSION_MAX_RESPONSE)
                for _ in range(training_count)]
            x_query = [rng_polynomial.randint(
                POLYNOMIAL_REGRESSION_MIN_ABSCISSA,
                POLYNOMIAL_REGRESSION_MAX_ABSCISSA)
                for _ in range(query_count)]
            inputs = [float(degree), float(training_count), float(query_count)]
            inputs.extend(float(value) for value in x_train)
            inputs.extend(float(value) for value in y_train)
            inputs.extend(float(value) for value in x_query)
            if index == 0:
                maximum_valid = inputs
                if len(inputs) != POLYNOMIAL_REGRESSION_MAX_VALID_INPUT_LENGTH:
                    raise ValueError("polynomial_regression maximum-shape trace is not 17 values")
            result, output = add_polynomial_case(inputs)
            if result <= 0 or len(output) != result:
                raise ValueError("polynomial_regression oracle rejected a generated valid trace")
            if index == 0:
                add_polynomial_case(inputs, capacity=result)
                add_polynomial_case(inputs, capacity=result - 1)
            if index % 16 == 0:
                add_polynomial_case(inputs, output_is_null=True)

        if (maximum_valid is None
                or len(maximum_valid) + 1 != POLYNOMIAL_REGRESSION_MAX_PARSEABLE_INPUT_LENGTH):
            raise ValueError("polynomial_regression maximum parseable shape is not 18 values")
        malformed = (
            [], maximum_valid[:-1], maximum_valid + [0.0],
            [4.0, 1.0, 1.0, 0.0, 0.0, 0.0],
            [1.5, 2.0, 1.0, 0.0, 1.0, 0.0, 1.0, 2.0],
            [2.0, 2.0, 1.0, 0.0, 1.0, 0.0, 1.0, 2.0],
            [0.0, 1.0, 1.0, 0.0, 0.5, 1.0],
            [0.0, 1.0, 1.0, 3.0, 0.0, 0.0],
        )
        for inputs in malformed:
            add_polynomial_case(inputs)
        duplicate_x = [1.0, 2.0, 1.0, 0.0, 0.0, 1.0, 2.0, 2.0]
        add_polynomial_case(duplicate_x, output_is_null=True)
        add_polynomial_case([], input_is_null=True, input_length=5)

    if algorithm == "soboleva_modified_hyperbolic_tangent":
        if (workspace != 32 or absolute_tolerance != 1e-12 or relative_tolerance != 1e-12):
            raise ValueError("soboleva_modified_hyperbolic_tangent requires a 32-element workspace and 1e-12 tolerances")
        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if (not isinstance(raw_values, list)
                    or any(type(value) not in (int, float)
                           or not math.isfinite(float(value)) for value in raw_values)):
                raise ValueError(f"soboleva_modified_hyperbolic_tangent ABI values are invalid: {case.get('id')}")
            values = [float(value) for value in raw_values]
            capacity = case.get("output_capacity")
            input_is_null = case.get("input_is_null", False)
            output_is_null = case.get("output_is_null", False)
            input_length = case.get("input_length", len(values))
            if (type(capacity) is not int or not 0 <= capacity <= workspace
                    or type(input_is_null) is not bool or type(output_is_null) is not bool
                    or type(input_length) is not int or not 0 <= input_length <= 38
                    or input_is_null and values
                    or not input_is_null and input_length != len(values)
                       and case.get("id") != "input_length_mismatch"):
                raise ValueError(f"soboleva_modified_hyperbolic_tangent ABI framing is invalid: {case.get('id')}")
            result, output = soboleva_modified_hyperbolic_tangent_abi_oracle(
                values, capacity, output_is_null, input_is_null, input_length)
            if (case.get("expected_result") != result
                    or not _matches_output(case.get("expected_output"), output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"soboleva_modified_hyperbolic_tangent ABI fixture mismatch: {case.get('id')}")
            if input_is_null:
                checker_values = [0.0] * input_length
            elif case.get("id") == "input_length_mismatch":
                checker_values = values[:input_length]
            else:
                checker_values = values
            records.append((checker_values, result, [_output_token(value) for value in output],
                            capacity, int(input_is_null), int(output_is_null)))

        rng_soboleva = random.Random(20261017)
        for _ in range(96):
            count = rng_soboleva.randint(1, 32)
            coefficients = [rng_soboleva.uniform(-2.0, 2.0) for _ in range(4)]
            samples = [rng_soboleva.uniform(-20.0, 20.0) for _ in range(count)]
            inputs = [float(count), *coefficients, *samples]
            output = ORACLES[algorithm](inputs)
            if output is None or len(output) != count:
                raise ValueError("soboleva_modified_hyperbolic_tangent oracle rejected a generated valid trace")
            records.append((inputs, count, [_output_token(value) for value in output], workspace, 0, 0))

        finite_base = [1.0, 1.0, 1.0, 1.0, 1.0, 0.0]
        for index in range(len(finite_base)):
            for special in (math.nan, math.inf, -math.inf):
                inputs = list(finite_base)
                inputs[index] = special
                result, output = soboleva_modified_hyperbolic_tangent_abi_oracle(inputs)
                if result != SOBOLEVA_MODIFIED_HYPERBOLIC_TANGENT_INVALID_RESULT or output:
                    raise ValueError("soboleva_modified_hyperbolic_tangent accepted a non-finite value")
                records.append((inputs, -1, [], workspace, 0, 0))

    if algorithm == "pi_monte_carlo_estimation":
        oracle = ORACLES[algorithm]
        rng_pi = random.Random(20261017)
        for _ in range(96):
            simulations = rng_pi.randint(1, 4096)
            seed = rng_pi.getrandbits(32)
            inputs = [float(simulations), float(seed)]
            output = oracle(inputs)
            if output is None or len(output) != 1:
                raise ValueError("pi_monte_carlo_estimation oracle rejected a generated valid trace")
            records.append((inputs, 1, [_output_token(value) for value in output],
                            workspace, 0, 0))
        for special in (math.nan, math.inf, -math.inf):
            for index, inputs in (
                (0, [100.0, 1.0]),
                (1, [100.0, 1.0]),
            ):
                inputs[index] = special
                if oracle(inputs) is not None:
                    raise ValueError("pi_monte_carlo_estimation oracle accepted a non-finite input")
                records.append((inputs, -1, [], workspace, 0, 0))
                records.append((inputs, -1, [], workspace, 0, 1))

    if algorithm == "momentum_sgd":
        oracle = momentum_sgd_abi_oracle

        def add_momentum_case(inputs: list[float], capacity: int = workspace,
                              output_is_null: bool = False, input_is_null: bool = False,
                              input_length: int | None = None) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            if input_is_null:
                result, output = oracle([], capacity, output_is_null, True, input_length)
                checker_inputs = [0.0] * input_length
            else:
                result, output = oracle(inputs, capacity, output_is_null, False, input_length)
                checker_inputs = inputs
            records.append((checker_inputs, result,
                            [_output_token(value) for value in output], capacity,
                            int(input_is_null), int(output_is_null)))
            return result, output

        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if (not isinstance(raw_values, list)
                    or any(type(value) not in (int, float) or not math.isfinite(float(value))
                           for value in raw_values)):
                raise ValueError(f"invalid momentum_sgd ABI input values: {case.get('id')}")
            inputs = [float(value) for value in raw_values]
            capacity = case.get("output_capacity")
            output_is_null = case.get("output_is_null")
            input_is_null = case.get("input_is_null")
            input_length = case.get("input_length")
            result, output = oracle(inputs, capacity, output_is_null, input_is_null, input_length)
            expected_output = case.get("expected_output")
            if (case.get("expected_result") != result
                    or not isinstance(expected_output, list)
                    or len(expected_output) != len(output)
                    or any(type(actual) not in (int, float)
                           or not math.isfinite(float(actual))
                           or abs(float(actual) - reference)
                           > absolute_tolerance + relative_tolerance * abs(reference)
                           for actual, reference in zip(expected_output, output))):
                raise ValueError(f"momentum_sgd ABI workload mismatch: {case.get('id')}")
            add_momentum_case(inputs, capacity, output_is_null, input_is_null, input_length)

        rng_momentum = random.Random(20261017)
        for index in range(96):
            group_count = rng_momentum.randint(
                MOMENTUM_SGD_MIN_GROUP_COUNT, MOMENTUM_SGD_MAX_GROUP_COUNT)
            vector_length = rng_momentum.randint(
                MOMENTUM_SGD_MIN_VECTOR_LENGTH,
                min(MOMENTUM_SGD_MAX_VECTOR_LENGTH,
                    MOMENTUM_SGD_MAX_GROUP_VECTOR_ELEMENTS // group_count))
            call_count = rng_momentum.randint(
                max(group_count, MOMENTUM_SGD_MIN_CALL_COUNT), MOMENTUM_SGD_MAX_CALL_COUNT)
            event_ids = list(range(group_count))
            event_ids.extend(rng_momentum.randrange(group_count)
                             for _ in range(call_count - group_count))
            rng_momentum.shuffle(event_ids)
            inputs = [float(group_count), float(vector_length), float(call_count),
                      rng_momentum.uniform(MOMENTUM_SGD_MIN_LEARNING_RATE,
                                           MOMENTUM_SGD_MAX_LEARNING_RATE),
                      rng_momentum.uniform(MOMENTUM_SGD_MIN_MOMENTUM,
                                           MOMENTUM_SGD_MAX_MOMENTUM)]
            for param_id in event_ids:
                inputs.append(float(param_id))
                inputs.extend(rng_momentum.uniform(MOMENTUM_SGD_MIN_PARAMETER,
                                                   MOMENTUM_SGD_MAX_PARAMETER)
                              for _ in range(vector_length))
                inputs.extend(rng_momentum.uniform(MOMENTUM_SGD_MIN_GRADIENT,
                                                   MOMENTUM_SGD_MAX_GRADIENT)
                              for _ in range(vector_length))
            result, output = add_momentum_case(inputs)
            if result <= 0 or len(output) != result:
                raise ValueError("momentum_sgd oracle rejected a generated valid multi-ID trace")
            if index % 16 == 0:
                add_momentum_case(inputs, output_is_null=True)

        finite_base = [1.0, 1.0, 1.0, 0.1, 0.9, 0.0, 1.0, 0.1]
        for position in range(len(finite_base)):
            for special in (math.nan, math.inf, -math.inf):
                inputs = list(finite_base)
                inputs[position] = special
                result, output = oracle(inputs)
                if result != -1 or output:
                    raise ValueError("momentum_sgd oracle accepted a non-finite input")
                add_momentum_case(inputs)
                if position == 3:
                    add_momentum_case(inputs, output_is_null=True)

    if algorithm == "q_learning":
        oracle = q_learning_abi_oracle

        def add_q_learning_case(inputs: list[float], capacity: int = workspace,
                                output_is_null: bool = False, input_is_null: bool = False,
                                input_length: int | None = None) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            if (len(inputs) > Q_LEARNING_MAX_PARSEABLE_INPUT_LENGTH
                    or any(type(value) not in (int, float) for value in inputs)
                    or type(capacity) is not int
                    or not 0 <= capacity <= Q_LEARNING_MAX_OUTPUT_ELEMENTS
                    or type(output_is_null) is not bool or type(input_is_null) is not bool
                    or type(input_length) is not int
                    or not 0 <= input_length <= Q_LEARNING_MAX_PARSEABLE_INPUT_LENGTH
                    or input_is_null and (inputs or input_length <= 0 or output_is_null)
                    or not input_is_null and input_length != len(inputs)):
                raise ValueError("q_learning generated ABI framing is invalid")
            if input_is_null:
                result, output = oracle([], capacity, output_is_null, True, input_length)
                checker_inputs = [0.0] * input_length
            else:
                result, output = oracle(inputs, capacity, output_is_null, False, input_length)
                checker_inputs = inputs
            if (result >= 0 and (result != Q_LEARNING_MAX_OUTPUT_ELEMENTS
                                 or len(output) != result
                                 or any(not math.isfinite(value) for value in output))
                    or result < 0 and (result not in (-1, -2) or output)):
                raise ValueError("q_learning oracle returned inconsistent output framing")
            records.append((checker_inputs, result, [_output_token(value) for value in output],
                            capacity, int(input_is_null), int(output_is_null)))
            return result, output

        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if (not isinstance(raw_values, list)
                    or any(type(value) not in (int, float) or not math.isfinite(float(value))
                           for value in raw_values)):
                raise ValueError(f"q_learning ABI input values are invalid: {case.get('id')}")
            inputs = [float(value) for value in raw_values]
            capacity = case.get("output_capacity")
            output_is_null = case.get("output_is_null")
            input_is_null = case.get("input_is_null")
            input_length = case.get("input_length")
            result, output = oracle(inputs, capacity, output_is_null, input_is_null, input_length)
            if (case.get("expected_result") != result
                    or not _matches_output(case.get("expected_output"), output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"q_learning ABI fixture mismatch: {case.get('id')}")
            add_q_learning_case(inputs, capacity, output_is_null, input_is_null, input_length)

        rng_q_learning = random.Random(20261017)
        for _ in range(128):
            next_count = rng_q_learning.randint(Q_LEARNING_MIN_NEXT_ACTIONS,
                                                Q_LEARNING_MAX_NEXT_ACTIONS)
            inputs = [
                float(rng_q_learning.choice((0, 1))),
                rng_q_learning.choice((Q_LEARNING_MIN_RATE, Q_LEARNING_MAX_RATE,
                                       rng_q_learning.random())),
                rng_q_learning.choice((Q_LEARNING_MIN_RATE, Q_LEARNING_MAX_RATE,
                                       rng_q_learning.random())),
                rng_q_learning.uniform(Q_LEARNING_MIN_SCALAR, Q_LEARNING_MAX_SCALAR),
                rng_q_learning.uniform(Q_LEARNING_MIN_SCALAR, Q_LEARNING_MAX_SCALAR),
                float(next_count),
                *(rng_q_learning.uniform(Q_LEARNING_MIN_SCALAR, Q_LEARNING_MAX_SCALAR)
                  for _ in range(next_count)),
            ]
            result, output = add_q_learning_case(inputs)
            if result != Q_LEARNING_MAX_OUTPUT_ELEMENTS or len(output) != result:
                raise ValueError("q_learning oracle rejected a generated valid update")

        maximum_valid = [0.0, 1.0, 1.0, Q_LEARNING_MAX_SCALAR,
                         Q_LEARNING_MIN_SCALAR, float(Q_LEARNING_MAX_NEXT_ACTIONS),
                         Q_LEARNING_MIN_SCALAR, -1.0, 0.0, Q_LEARNING_MAX_SCALAR]
        if (len(maximum_valid) != 10
                or len(maximum_valid) + 1 != Q_LEARNING_MAX_PARSEABLE_INPUT_LENGTH):
            raise ValueError("q_learning maximum and parseable shapes have unexpected lengths")
        add_q_learning_case(maximum_valid)
        add_q_learning_case([*maximum_valid, 0.0])
        valid_input = [0.0, 0.5, 0.5, 1.0, 0.0, 0.0]
        add_q_learning_case(valid_input, capacity=0)
        add_q_learning_case(valid_input, capacity=1)
        add_q_learning_case(valid_input, output_is_null=True)
        add_q_learning_case([2.0, 0.5, 0.5, 0.0, 0.0, 0.0], capacity=0,
                            output_is_null=True)

        malformed = (
            [], [0.0, 0.5], [2.0, 0.5, 0.5, 0.0, 0.0, 0.0],
            [0.5, 0.5, 0.5, 0.0, 0.0, 0.0],
            [0.0, -0.01, 0.5, 0.0, 0.0, 0.0],
            [0.0, 0.5, 1.01, 0.0, 0.0, 0.0],
            [0.0, 0.5, 0.5, 0.0, -100.01, 0.0],
            [0.0, 0.5, 0.5, 0.0, 0.0, 5.0],
            [0.0, 0.5, 0.5, 0.0, 0.0, 2.0, 1.0],
            [0.0, 0.5, 0.5, 0.0, 0.0, 0.0, 1.0],
            [0.0, 0.5, 0.5, Q_LEARNING_MAX_SCALAR + 0.01, 0.0, 0.0],
            [0.0, 0.5, 0.5, 0.0, 0.0, 1.0, Q_LEARNING_MIN_SCALAR - 0.01],
        )
        for inputs in malformed:
            add_q_learning_case([float(value) for value in inputs])

        finite_base = [0.0, 0.5, 0.5, 0.0, 0.0, 2.0, -1.0, 1.0]
        for position in range(len(finite_base)):
            for special in (math.nan, math.inf, -math.inf):
                inputs = list(finite_base)
                inputs[position] = special
                result, output = add_q_learning_case(inputs)
                if result != -1 or output:
                    raise ValueError("q_learning oracle accepted a non-finite input")
                if position == 3:
                    add_q_learning_case(inputs, output_is_null=True)
        add_q_learning_case([], input_is_null=True, input_length=6)

    if algorithm == "single_indeterminate_operations":
        oracle = single_indeterminate_operations_abi_oracle
        if workspace != SINGLE_INDETERMINATE_OPERATIONS_MAX_OUTPUT_ELEMENTS:
            raise ValueError("single_indeterminate_operations requires its reviewed 17-element workspace")

        def add_single_indeterminate_operations_case(
            inputs: list[float], capacity: int = workspace,
            output_is_null: bool = False, input_is_null: bool = False,
            input_length: int | None = None,
        ) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            if (len(inputs) > SINGLE_INDETERMINATE_OPERATIONS_MAX_PARSEABLE_INPUT_LENGTH
                    or any(type(value) not in (int, float) for value in inputs)
                    or type(capacity) is not int
                    or not 0 <= capacity <= SINGLE_INDETERMINATE_OPERATIONS_MAX_OUTPUT_ELEMENTS
                    or type(output_is_null) is not bool or type(input_is_null) is not bool
                    or input_is_null and output_is_null
                    or type(input_length) is not int
                    or not 0 <= input_length <= SINGLE_INDETERMINATE_OPERATIONS_MAX_PARSEABLE_INPUT_LENGTH
                    or input_is_null and inputs
                    or not input_is_null and input_length != len(inputs)):
                raise ValueError("single_indeterminate_operations generated ABI framing is invalid")
            if input_is_null:
                result, output = oracle([], capacity, output_is_null, True, input_length)
                checker_inputs = [0.0] * input_length
            else:
                result, output = oracle(inputs, capacity, output_is_null, False, input_length)
                checker_inputs = inputs
            if (result >= 0 and (result != len(output)
                                 or result > SINGLE_INDETERMINATE_OPERATIONS_MAX_OUTPUT_ELEMENTS
                                 or any(not math.isfinite(value) for value in output))
                    or result < 0 and (result not in (-1, -2) or output)):
                raise ValueError("single_indeterminate_operations oracle returned inconsistent framing")
            records.append((checker_inputs, result, [_output_token(value) for value in output],
                            capacity, int(input_is_null), int(output_is_null)))
            return result, output

        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if (not isinstance(raw_values, list)
                    or any(type(value) not in (int, float) or not math.isfinite(float(value))
                           for value in raw_values)):
                raise ValueError(f"single_indeterminate_operations ABI values are invalid: {case.get('id')}")
            inputs = [float(value) for value in raw_values]
            capacity = case.get("output_capacity")
            output_is_null = case.get("output_is_null")
            input_is_null = case.get("input_is_null")
            input_length = case.get("input_length")
            result, output = oracle(inputs, capacity, output_is_null, input_is_null, input_length)
            if (type(case.get("expected_result")) is not int
                    or case["expected_result"] != result
                    or not _matches_output(case.get("expected_output"), output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"single_indeterminate_operations ABI fixture mismatch: {case.get('id')}")
            add_single_indeterminate_operations_case(
                inputs, capacity, output_is_null, input_is_null, input_length)

        rng_polynomial = random.Random(20261022)
        coefficient_choices = (
            SINGLE_INDETERMINATE_OPERATIONS_MIN_COEFFICIENT, -3.5, -1.0, 0.0,
            0.25, 2.0, SINGLE_INDETERMINATE_OPERATIONS_MAX_COEFFICIENT,
        )
        for index in range(128):
            operation = index % 6 if index < 6 else rng_polynomial.randrange(6)
            degree_a = rng_polynomial.randint(SINGLE_INDETERMINATE_OPERATIONS_MIN_DEGREE,
                                              SINGLE_INDETERMINATE_OPERATIONS_MAX_DEGREE)
            coefficients_a = [rng_polynomial.choice(coefficient_choices)
                              for _ in range(degree_a + 1)]
            inputs = [float(operation), float(degree_a), *coefficients_a]
            if operation in (SINGLE_INDETERMINATE_OPERATIONS_OP_ADD,
                             SINGLE_INDETERMINATE_OPERATIONS_OP_SUBTRACT,
                             SINGLE_INDETERMINATE_OPERATIONS_OP_MULTIPLY):
                degree_b = rng_polynomial.randint(SINGLE_INDETERMINATE_OPERATIONS_MIN_DEGREE,
                                                  SINGLE_INDETERMINATE_OPERATIONS_MAX_DEGREE)
                inputs.extend([float(degree_b), *(rng_polynomial.choice(coefficient_choices)
                                                  for _ in range(degree_b + 1))])
            elif operation in (SINGLE_INDETERMINATE_OPERATIONS_OP_EVALUATE,
                               SINGLE_INDETERMINATE_OPERATIONS_OP_INTEGRAL):
                lower = (SINGLE_INDETERMINATE_OPERATIONS_MIN_EVALUATION_POINT
                         if operation == SINGLE_INDETERMINATE_OPERATIONS_OP_EVALUATE
                         else SINGLE_INDETERMINATE_OPERATIONS_MIN_INTEGRAL_CONSTANT)
                upper = (SINGLE_INDETERMINATE_OPERATIONS_MAX_EVALUATION_POINT
                         if operation == SINGLE_INDETERMINATE_OPERATIONS_OP_EVALUATE
                         else SINGLE_INDETERMINATE_OPERATIONS_MAX_INTEGRAL_CONSTANT)
                inputs.append(rng_polynomial.uniform(lower, upper))
            result, output = add_single_indeterminate_operations_case(inputs)
            if result < 0:
                raise ValueError("single_indeterminate_operations oracle rejected a generated valid operation")
            if index == 0 and result > 0:
                add_single_indeterminate_operations_case(inputs, capacity=result)
                add_single_indeterminate_operations_case(inputs, capacity=result - 1)
            if index % 24 == 0:
                add_single_indeterminate_operations_case(inputs, output_is_null=True)

        maximum_product = [float(SINGLE_INDETERMINATE_OPERATIONS_OP_MULTIPLY),
                           float(SINGLE_INDETERMINATE_OPERATIONS_MAX_DEGREE),
                           *([SINGLE_INDETERMINATE_OPERATIONS_MAX_COEFFICIENT]
                             * (SINGLE_INDETERMINATE_OPERATIONS_MAX_DEGREE + 1)),
                           float(SINGLE_INDETERMINATE_OPERATIONS_MAX_DEGREE),
                           *([SINGLE_INDETERMINATE_OPERATIONS_MIN_COEFFICIENT]
                             * (SINGLE_INDETERMINATE_OPERATIONS_MAX_DEGREE + 1))]
        if len(maximum_product) != SINGLE_INDETERMINATE_OPERATIONS_MAX_PARSEABLE_INPUT_LENGTH - 1:
            raise ValueError("single_indeterminate_operations maximum product has unexpected length")
        add_single_indeterminate_operations_case(maximum_product)
        add_single_indeterminate_operations_case([*maximum_product, 0.0])

        malformed = (
            [], [6.0, 0.0, 1.0], [0.0, 9.0, 1.0], [0.0, 1.0, 0.0],
            [0.0, 0.0, 11.0, 0.0, 1.0], [0.5, 0.0, 1.0],
            [3.0, 0.0, 1.0, 2.01], [5.0, 0.0, 1.0, 10.01],
            [4.0, 0.0, 1.0, 0.0], [0.0, 0.0, 1.0, 0.0, 1.0, 0.0],
        )
        for inputs in malformed:
            add_single_indeterminate_operations_case(inputs)
        valid_evaluation = [3.0, 1.0, 1.0, 2.0, -0.5]
        add_single_indeterminate_operations_case(valid_evaluation, capacity=0)
        add_single_indeterminate_operations_case(valid_evaluation, output_is_null=True)
        add_single_indeterminate_operations_case([4.0, 0.0, 0.0], capacity=0)
        add_single_indeterminate_operations_case([4.0, 0.0, 0.0], capacity=0,
                                                 output_is_null=True)
        add_single_indeterminate_operations_case([], input_is_null=True, input_length=3)

        finite_base = [3.0, 1.0, 1.0, 2.0, -0.5]
        for position in range(len(finite_base)):
            for special in (math.nan, math.inf, -math.inf):
                inputs = list(finite_base)
                inputs[position] = special
                result, output = add_single_indeterminate_operations_case(inputs)
                if result != -1 or output:
                    raise ValueError("single_indeterminate_operations oracle accepted nonfinite input")
                if position == 3:
                    add_single_indeterminate_operations_case(inputs, output_is_null=True)

    if algorithm == "montecarlopi":
        oracle = montecarlopi_abi_oracle
        if workspace != MONTECARLOPI_MAX_OUTPUT_ELEMENTS:
            raise ValueError("montecarlopi requires its reviewed one-element workspace")

        def add_montecarlopi_case(
            inputs: list[float], capacity: int = workspace,
            output_is_null: bool = False, input_is_null: bool = False,
            input_length: int | None = None,
        ) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            if (len(inputs) > MONTECARLOPI_MAX_PARSEABLE_INPUT_LENGTH
                    or any(type(value) not in (int, float) for value in inputs)
                    or type(capacity) is not int
                    or not 0 <= capacity <= MONTECARLOPI_MAX_OUTPUT_ELEMENTS
                    or type(output_is_null) is not bool or type(input_is_null) is not bool
                    or input_is_null and output_is_null
                    or type(input_length) is not int
                    or not 0 <= input_length <= MONTECARLOPI_MAX_PARSEABLE_INPUT_LENGTH
                    or input_is_null and (inputs or input_length <= 0)
                    or not input_is_null and input_length != len(inputs)):
                raise ValueError("montecarlopi generated ABI framing is invalid")
            oracle_inputs = [] if input_is_null else inputs
            result, output = oracle(
                oracle_inputs, capacity, output_is_null, input_is_null, input_length)
            if (result >= 0 and (result != len(output)
                                 or result > MONTECARLOPI_MAX_OUTPUT_ELEMENTS
                                 or any(not math.isfinite(value) for value in output))
                    or result < 0 and (result not in (-1, -2) or output)):
                raise ValueError("montecarlopi oracle returned inconsistent ABI framing")
            checker_inputs = [0.0] * input_length if input_is_null else inputs
            records.append((checker_inputs, result, [_output_token(value) for value in output],
                            capacity, int(input_is_null), int(output_is_null)))
            return result, output

        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if (not isinstance(raw_values, list)
                    or any(type(value) not in (int, float) or not math.isfinite(float(value))
                           for value in raw_values)):
                raise ValueError(f"montecarlopi ABI input values are invalid: {case.get('id')}")
            inputs = [float(value) for value in raw_values]
            capacity = case.get("output_capacity")
            output_is_null = case.get("output_is_null")
            input_is_null = case.get("input_is_null")
            input_length = case.get("input_length")
            result, output = oracle(inputs, capacity, output_is_null, input_is_null, input_length)
            if (type(case.get("expected_result")) is not int
                    or case["expected_result"] != result
                    or not _matches_output(case.get("expected_output"), output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"montecarlopi ABI fixture mismatch: {case.get('id')}")
            add_montecarlopi_case(
                inputs, capacity, output_is_null, input_is_null, input_length)

        coordinate_levels = sorted(MONTECARLOPI_SAMPLE_COORDINATE_LEVELS)
        for sample_count in range(MONTECARLOPI_MIN_RANDOM_POINTS,
                                  MONTECARLOPI_MAX_RANDOM_POINTS + 1):
            trace = [float(sample_count)]
            for index in range(sample_count):
                x = coordinate_levels[index % len(coordinate_levels)]
                y = coordinate_levels[(index * 3 + sample_count) % len(coordinate_levels)]
                trace.extend((x, y))
            result, output = add_montecarlopi_case(trace)
            if result != MONTECARLOPI_MAX_OUTPUT_ELEMENTS or len(output) != result:
                raise ValueError("montecarlopi oracle rejected a generated valid sample trace")

        maximum_valid = [float(MONTECARLOPI_MAX_RANDOM_POINTS),
                         *([0.0, 0.25, 0.5, 0.75] * MONTECARLOPI_MAX_RANDOM_POINTS)[:
                           2 * MONTECARLOPI_MAX_RANDOM_POINTS]]
        if len(maximum_valid) != MONTECARLOPI_MAX_VALID_INPUT_LENGTH:
            raise ValueError("montecarlopi maximum sample trace has an unexpected length")
        add_montecarlopi_case(maximum_valid)
        add_montecarlopi_case([*maximum_valid, 0.0])
        add_montecarlopi_case([1.0, 0.0, 0.0], capacity=0)
        add_montecarlopi_case([1.0, 0.0, 0.0], output_is_null=True)
        add_montecarlopi_case([1.0, 1.0, 0.0], output_is_null=True)
        add_montecarlopi_case([], input_is_null=True, input_length=3)

        malformed = (
            [], [1.0], [0.0, 0.0, 0.0], [1.0, 0.0],
            [1.0, 0.0, 0.0, 0.0], [0.5, 0.0, 0.0],
            [65.0, *([0.0, 0.0] * MONTECARLOPI_MAX_RANDOM_POINTS)],
            [1.0, 0.125, 0.0], [1.0, 1.0, 0.0],
        )
        for inputs in malformed:
            add_montecarlopi_case(inputs)

        finite_base = [1.0, 0.0, 0.0]
        for position in range(len(finite_base)):
            for special in (math.nan, math.inf, -math.inf):
                inputs = list(finite_base)
                inputs[position] = special
                result, output = add_montecarlopi_case(inputs)
                if result != -1 or output:
                    raise ValueError("montecarlopi oracle accepted a non-finite input")

    if algorithm == "monte_carlo_simulation":
        oracle = monte_carlo_simulation_abi_oracle
        if workspace != MONTE_CARLO_SIMULATION_MAX_SIMULATIONS:
            raise ValueError("monte_carlo_simulation requires its reviewed 32-element payoff workspace")

        def add_monte_carlo_simulation_case(
                inputs: list[float], capacity: int = MONTE_CARLO_SIMULATION_MAX_OUTPUT_ELEMENTS,
                output_is_null: bool = False, input_is_null: bool = False,
                input_length: int | None = None) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            if (len(inputs) > MONTE_CARLO_SIMULATION_MAX_PARSEABLE_INPUT_LENGTH
                    or any(type(value) not in (int, float) for value in inputs)
                    or type(capacity) is not int
                    or not 0 <= capacity <= MONTE_CARLO_SIMULATION_MAX_OUTPUT_ELEMENTS
                    or type(output_is_null) is not bool or type(input_is_null) is not bool
                    or type(input_length) is not int
                    or not 0 <= input_length <= MONTE_CARLO_SIMULATION_MAX_PARSEABLE_INPUT_LENGTH
                    or input_is_null and (inputs or input_length <= 0)):
                raise ValueError("monte_carlo_simulation generated ABI framing is invalid")
            oracle_inputs = [] if input_is_null else inputs
            result, output = oracle(
                oracle_inputs, capacity, output_is_null, input_is_null, input_length)
            if (result >= 0 and (result != len(output)
                                 or result > MONTE_CARLO_SIMULATION_MAX_OUTPUT_ELEMENTS
                                 or any(not math.isfinite(value) for value in output))
                    or result < 0 and (result not in (-1, -2) or output)):
                raise ValueError("monte_carlo_simulation oracle returned inconsistent ABI framing")
            checker_inputs = ([0.0] * input_length if input_is_null else
                              inputs[:input_length] if input_length <= len(inputs) else
                              [*inputs, *([0.0] * (input_length - len(inputs)))])
            records.append((checker_inputs, result, [_output_token(value) for value in output],
                            capacity, int(input_is_null), int(output_is_null)))
            return result, output

        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if (not isinstance(raw_values, list)
                    or any(type(value) not in (int, float)
                           or not math.isfinite(float(value)) for value in raw_values)):
                raise ValueError(f"monte_carlo_simulation ABI inputs are invalid: {case.get('id')}")
            inputs = [float(value) for value in raw_values]
            capacity = case.get("output_capacity")
            output_is_null = case.get("output_is_null")
            input_is_null = case.get("input_is_null")
            input_length = case.get("input_length")
            result, output = oracle(inputs, capacity, output_is_null, input_is_null, input_length)
            if (type(case.get("expected_result")) is not int
                    or case["expected_result"] != result
                    or not _matches_output(case.get("expected_output"), output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"monte_carlo_simulation ABI fixture mismatch: {case.get('id')}")
            add_monte_carlo_simulation_case(
                inputs, capacity, output_is_null, input_is_null, input_length)

        rng_monte_carlo_simulation = random.Random(20261017)
        normal_levels = (-3.0, -2.0, -1.0, -0.5, 0.0, 0.5, 1.0, 2.0, 3.0)
        for index in range(96):
            steps = MONTE_CARLO_SIMULATION_STEP_COUNTS[index % len(MONTE_CARLO_SIMULATION_STEP_COUNTS)]
            simulations = 1 + (index * 11) % MONTE_CARLO_SIMULATION_MAX_SIMULATIONS
            s0 = (1.0, 10.0, 100.0, 500.0, 1000.0)[index % 5]
            strike = (0.0, 50.0, 100.0, 450.0, 1000.0, 2000.0)[(index // 2) % 6]
            rate = (-0.25, -0.1, 0.0, 0.05, 0.25)[(index // 3) % 5]
            volatility = (0.0, 0.05, 0.2, 0.35, 0.5)[(index // 4) % 5]
            maturity = MONTE_CARLO_SIMULATION_MATURITIES[(index // 5) % len(
                MONTE_CARLO_SIMULATION_MATURITIES)]
            normals = [normal_levels[rng_monte_carlo_simulation.randrange(len(normal_levels))]
                       for _ in range(steps * simulations)]
            inputs = [s0, strike, rate, volatility, maturity, float(steps),
                      float(simulations), *normals]
            result, output = add_monte_carlo_simulation_case(inputs)
            if result != MONTE_CARLO_SIMULATION_MAX_OUTPUT_ELEMENTS or len(output) != result:
                raise ValueError("monte_carlo_simulation oracle rejected a generated valid trace")
            if index % 8 == 0:
                add_monte_carlo_simulation_case(inputs, capacity=0)
            if index % 16 == 0:
                add_monte_carlo_simulation_case(inputs, output_is_null=True)

        maximum_inputs = [1000.0, 0.0, 0.25, 0.5, 2.0, 16.0, 32.0,
                          *([3.0, -3.0, 2.0, -2.0, 1.0, -1.0, 0.0, 0.5,
                             -0.5, 1.5, -1.5, 2.5, -2.5, 0.25, -0.25, 0.0] * 32)]
        maximum_result, maximum_output = add_monte_carlo_simulation_case(maximum_inputs)
        if (len(maximum_inputs) != MONTE_CARLO_SIMULATION_MAX_VALID_INPUT_LENGTH
                or maximum_result != MONTE_CARLO_SIMULATION_MAX_OUTPUT_ELEMENTS
                or len(maximum_output) != MONTE_CARLO_SIMULATION_MAX_OUTPUT_ELEMENTS):
            raise ValueError("monte_carlo_simulation maximum trace has an unexpected shape")
        add_monte_carlo_simulation_case(maximum_inputs, capacity=0)
        add_monte_carlo_simulation_case(maximum_inputs, output_is_null=True)
        add_monte_carlo_simulation_case([], input_is_null=True, input_length=8)
        add_monte_carlo_simulation_case(
            [100.0, 100.0, 0.05, 0.2, 1.0, 4.0, 1.0, *([0.0] * 4)],
            0, output_is_null=True)

        malformed = (
            [], [100.0], [100.0, 100.0, 0.05, 0.2, 1.0, 4.0],
            [0.0, 100.0, 0.05, 0.2, 1.0, 4.0, 1.0, *([0.0] * 4)],
            [100.0, 100.0, 0.05, 0.2, 1.0, 4.0, 1.0, *([0.0] * 3)],
            [100.0, 100.0, 0.05, 0.2, 1.0, 4.0, 1.0, *([0.0] * 5)],
            [100.0, 100.0, 0.05, 0.2, 1.0, 4.0, 1.0, 3.5, 0.0, 0.0, 0.0],
            [100.0, 100.0, 0.05, 0.2, 1.0, 4.0, 1.0, math.nan, 0.0, 0.0, 0.0],
            [100.0, 100.0, 0.05, 0.2, 1.0, 16.0, 32.0, *([0.0] * 513)],
        )
        for inputs in malformed:
            result, output = add_monte_carlo_simulation_case(inputs)
            if result != -1 or output:
                raise ValueError("monte_carlo_simulation oracle accepted malformed input")
        invalid_precedence = [0.0, 100.0, 0.05, 0.2, 1.0, 4.0, 1.0, *([0.0] * 4)]
        result, output = add_monte_carlo_simulation_case(
            invalid_precedence, capacity=0, output_is_null=True)
        if result != -1 or output:
            raise ValueError("monte_carlo_simulation did not validate input before output")
        for position in range(11):
            inputs = [100.0, 100.0, 0.05, 0.2, 1.0, 4.0, 1.0, *([0.0] * 4)]
            inputs[position] = math.inf
            result, output = add_monte_carlo_simulation_case(inputs)
            if result != -1 or output:
                raise ValueError("monte_carlo_simulation oracle accepted nonfinite input")

    if algorithm == "mini_batch_gradient_descent":
        if workspace != MINI_BATCH_GRADIENT_DESCENT_MAX_OUTPUT_LENGTH:
            raise ValueError("mini_batch_gradient_descent requires its reviewed four-element workspace")

        def add_mini_batch_gradient_descent_case(
                inputs: list[float], capacity: int = workspace,
                output_is_null: bool = False, input_is_null: bool = False,
                input_length: int | None = None) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            if (len(inputs) > MINI_BATCH_GRADIENT_DESCENT_MAX_INPUT_LENGTH + 1
                    or any(type(value) not in (int, float) for value in inputs)
                    or type(capacity) is not int
                    or not 0 <= capacity <= MINI_BATCH_GRADIENT_DESCENT_MAX_OUTPUT_LENGTH
                    or type(output_is_null) is not bool or type(input_is_null) is not bool
                    or type(input_length) is not int
                    or not 0 <= input_length <= MINI_BATCH_GRADIENT_DESCENT_MAX_INPUT_LENGTH + 1
                    or input_is_null and (inputs or input_length <= 0)
                    or not input_is_null and input_length != len(inputs)):
                raise ValueError("mini_batch_gradient_descent generated ABI framing is invalid")
            oracle_output = (None if input_is_null else
                             mini_batch_gradient_descent_oracle(inputs))
            if oracle_output is None:
                result, output = -1, []
            elif output_is_null or capacity < len(oracle_output):
                result, output = -2, []
            else:
                result, output = len(oracle_output), oracle_output
            if (result >= 0 and (result != len(output)
                                 or result > MINI_BATCH_GRADIENT_DESCENT_MAX_OUTPUT_LENGTH
                                 or any(not math.isfinite(value) for value in output))
                    or result < 0 and (result not in (-1, -2) or output)):
                raise ValueError("mini_batch_gradient_descent oracle returned inconsistent ABI framing")
            checker_inputs = [0.0] * input_length if input_is_null else inputs
            records.append((checker_inputs, result, [_output_token(value) for value in output],
                            capacity, int(input_is_null), int(output_is_null)))
            return result, output

        rng_mini_batch_gradient_descent = random.Random(20261017)
        for index in range(96):
            samples = MINI_BATCH_GRADIENT_DESCENT_MIN_SAMPLES + index % (
                MINI_BATCH_GRADIENT_DESCENT_MAX_SAMPLES - MINI_BATCH_GRADIENT_DESCENT_MIN_SAMPLES + 1)
            features = MINI_BATCH_GRADIENT_DESCENT_MIN_FEATURES + (index // 2) % (
                MINI_BATCH_GRADIENT_DESCENT_MAX_FEATURES - MINI_BATCH_GRADIENT_DESCENT_MIN_FEATURES + 1)
            epochs = MINI_BATCH_GRADIENT_DESCENT_MIN_EPOCHS + (index // 3) % (
                MINI_BATCH_GRADIENT_DESCENT_MAX_EPOCHS - MINI_BATCH_GRADIENT_DESCENT_MIN_EPOCHS + 1)
            batch_size = 1 + (index // 5) % samples
            learning_rate = (0.0, 0.01, 0.05, 0.125, 0.25)[index % 5]
            matrix = [rng_mini_batch_gradient_descent.uniform(-2.0, 2.0)
                      for _ in range(samples * features)]
            targets = [rng_mini_batch_gradient_descent.uniform(-5.0, 5.0)
                       for _ in range(samples)]
            permutations: list[float] = []
            for _ in range(epochs):
                order = list(range(samples))
                rng_mini_batch_gradient_descent.shuffle(order)
                permutations.extend(float(sample) for sample in order)
            inputs = [float(samples), float(features), float(batch_size), float(epochs),
                      learning_rate, *matrix, *targets, *permutations]
            result, output = add_mini_batch_gradient_descent_case(inputs)
            if result != features + 1 or len(output) != result:
                raise ValueError("mini_batch_gradient_descent oracle rejected a generated valid trace")
            if index % 8 == 0:
                add_mini_batch_gradient_descent_case(inputs, capacity=result - 1)
            if index % 16 == 0:
                add_mini_batch_gradient_descent_case(inputs, output_is_null=True)

        maximum_samples = MINI_BATCH_GRADIENT_DESCENT_MAX_SAMPLES
        maximum_features = MINI_BATCH_GRADIENT_DESCENT_MAX_FEATURES
        maximum_epochs = MINI_BATCH_GRADIENT_DESCENT_MAX_EPOCHS
        maximum_matrix = [((index % 7) - 3) * 0.25
                          for index in range(maximum_samples * maximum_features)]
        maximum_targets = [((index % 5) - 2) * 1.5 for index in range(maximum_samples)]
        maximum_orders = [float(sample)
                          for epoch in range(maximum_epochs)
                          for sample in ((epoch + offset) % maximum_samples
                                         for offset in range(maximum_samples))]
        maximum_inputs = [float(maximum_samples), float(maximum_features), 1.0,
                          float(maximum_epochs), 0.05, *maximum_matrix,
                          *maximum_targets, *maximum_orders]
        maximum_result, maximum_output = add_mini_batch_gradient_descent_case(maximum_inputs)
        if (len(maximum_inputs) != MINI_BATCH_GRADIENT_DESCENT_MAX_INPUT_LENGTH
                or maximum_result != MINI_BATCH_GRADIENT_DESCENT_MAX_OUTPUT_LENGTH
                or len(maximum_output) != MINI_BATCH_GRADIENT_DESCENT_MAX_OUTPUT_LENGTH):
            raise ValueError("mini_batch_gradient_descent maximum trace has an unexpected shape")
        add_mini_batch_gradient_descent_case(maximum_inputs, capacity=0)
        add_mini_batch_gradient_descent_case(maximum_inputs, capacity=3)
        add_mini_batch_gradient_descent_case(maximum_inputs, output_is_null=True)
        add_mini_batch_gradient_descent_case([], input_is_null=True, input_length=5)
        add_mini_batch_gradient_descent_case(
            [], 0, output_is_null=True, input_is_null=True, input_length=5)

        malformed = (
            [], [1.0], [1.0, 1.0, 1.0, 0.0, 0.1],
            [2.0, 1.0, 1.0, 1.0, 0.1, 1.0, 2.0, 1.0, 2.0, 0.0, 0.0, 0.0],
            [2.0, 1.0, 1.0, 1.0, 0.1, 1.0, 2.0, 1.0, 2.0, 0.0, 0.5],
            [2.0, 1.0, 1.0, 1.0, 0.1, 1.0, 2.0, 1.0, 2.0, 0.0, 0.0, 0.0, 0.0],
            [1.0, 1.0, 1.0, 0.0, math.nan, 0.0, 0.0],
            [float(MINI_BATCH_GRADIENT_DESCENT_MAX_SAMPLES),
             float(MINI_BATCH_GRADIENT_DESCENT_MAX_FEATURES), 1.0,
             float(MINI_BATCH_GRADIENT_DESCENT_MAX_EPOCHS), 0.1,
             *([0.0] * (MINI_BATCH_GRADIENT_DESCENT_MAX_INPUT_LENGTH - 5))],
        )
        for inputs in malformed:
            result, output = add_mini_batch_gradient_descent_case(inputs)
            if result != -1 or output:
                raise ValueError("mini_batch_gradient_descent oracle accepted malformed input")
        invalid_precedence = [1.0, 1.0, 1.0, 0.0, -0.1, 0.0, 0.0]
        result, output = add_mini_batch_gradient_descent_case(
            invalid_precedence, capacity=0, output_is_null=True)
        if result != -1 or output:
            raise ValueError("mini_batch_gradient_descent did not validate input before output")
        valid_zero_epoch = [1.0, 1.0, 1.0, 0.0, 0.1, 0.0, 1.0]
        if add_mini_batch_gradient_descent_case(valid_zero_epoch, capacity=0)[0] != -2:
            raise ValueError("mini_batch_gradient_descent did not report insufficient capacity")

    lines = [f"{len(records)} {absolute_tolerance:.17g} {relative_tolerance:.17g} {workspace}\n"]
    for inputs, expected_result, expected_output, capacity, input_null, output_null in records:
        lines.append(f"{len(inputs)} {expected_result} {len(expected_output)} {capacity} "
                     f"{input_null} {output_null}\n")
        if inputs:
            lines.append(" ".join(format(value, ".17g") for value in inputs) + "\n")
        if expected_output:
            lines.append(" ".join(_format_output(value) for value in expected_output) + "\n")
    return "".join(lines), len(records)


def _matches_output(observed: object, expected: list[float | str],
                    absolute_tolerance: float, relative_tolerance: float,
                    *, preserve_signed_zero: bool = False) -> bool:
    if not isinstance(observed, list) or len(observed) != len(expected):
        return False
    for actual, reference in zip(observed, expected):
        if reference == "NaN":
            if actual != "NaN":
                return False
            continue
        if type(actual) not in (int, float) or not math.isfinite(float(actual)):
            return False
        target = float(reference)
        if (preserve_signed_zero and target == 0.0 and float(actual) == 0.0
                and absolute_tolerance == 0.0 and relative_tolerance == 0.0
                and math.copysign(1.0, float(actual)) != math.copysign(1.0, target)):
            return False
        if abs(float(actual) - target) > absolute_tolerance + relative_tolerance * abs(target):
            return False
    return True


def verify(algorithm: str, language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    extra_link_sources = ()
    if language == "elisa" and elisa_compiler:
        runtime = Path(elisa_compiler).resolve().parent.parent / "build/runtime/elisacore_runtime.o"
        if runtime.is_file():
            extra_link_sources = (runtime,)
    manifest = build(algorithm, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="float64_slice_io",
                     extra_link_sources=extra_link_sources)
    checker = manifest["binaries"]["float64_slice_io_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"float64-slice C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete float64-slice corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run(
        [sys.executable, str(ROOT / "benchmarks/run_float64_slice_io.py"),
         "--build-manifest", str(directory / "build.json"), "--samples", "1",
         "--warmups", "0", "--repetitions", "1", "--output", str(output)],
        cwd=ROOT, capture_output=True, text=True, timeout=180,
    )
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    absolute_tolerance, relative_tolerance = tolerances(workload)
    for case, record in zip(workload["cases"], records):
        values, expected_result, expected_output = encode_case(
            case, algorithm, absolute_tolerance, relative_tolerance)
        if (record["algorithm"] != algorithm
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != expected_result
                or record["workload"]["expected_output"] != expected_output
                or record["measurement"]["comparison_model"] != "float64_slice_io_call"
                or record["measurement"]["observed_result"] != expected_result
                or not _matches_output(record["measurement"]["observed_output"], expected_output,
                                       absolute_tolerance, relative_tolerance,
                                       preserve_signed_zero=algorithm in {
                                           "median_of_running_array_double",
                                           "median_of_running_array_float",
                                           "mean_shift"})
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": algorithm, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--algorithm", choices=ALGORITHMS, required=True)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path)
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    algorithm = args.algorithm
    package_dir = {"polybench_lu": "l", "polybench_gramschmidt": "p", "polybench_correlation": "c",
                   "polybench_seidel_2d": "s",
                   "cbench_consumer_mad_imdct36": "m",
                   "cbench_consumer_lame_mdct_short": "m",
                   "cbench_lame_mid_side": "m",
                   "cbench_rsynth_natural_glottal_sample": "m",
                   "tsvc_s2251_carried_scalar_expansion": "t",
                   "tsvc_s1251_per_element_dual_update": "t",
                   "tsvc_s3251_forward_shifted_array_expansion": "t",
                   "tsvc_s2712_comparison_gated_axpy": "t",
                   "tsvc_s2710_nested_scalar_vector_branch_update": "t",
                   "tsvc_s1279_nested_conditional_accumulation": "t",
                   "tsvc_s2275_matrix_vector_axpy_interleave": "t",
                   "tsvc_s482_break_after_update": "t",
                   "tsvc_s441_s443_d_sign_branch_updates": "t",
                   "tsvc_s242_fused_prefix_update": "t",
                   "tsvc_s351_direct_unrolled_saxpy": "t"}.get(algorithm, algorithm[0])
    workload_path = ROOT / "benchmarks" / package_dir / algorithm / "workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    if workload.get("algorithm") != algorithm:
        parser.error("workload algorithm does not match the requested algorithm")
    if algorithm == "tsvc_s111_odd_index_neighbor_update":
        validate_tsvc_s111_odd_index_neighbor_update_workload(workload)
    elif algorithm == "tsvc_vtvtv_triple_product_map":
        validate_tsvc_vtvtv_triple_product_map_workload(workload)
    elif algorithm == "tsvc_s451_sincos_vector_map":
        validate_tsvc_s451_sincos_vector_map_workload(workload)
    elif algorithm == "tsvc_s221_partial_recursive_fused_update":
        validate_tsvc_s221_partial_recursive_fused_update_workload(workload)
    elif algorithm == "tsvc_s222_interleaved_square_recurrence":
        validate_tsvc_s222_interleaved_square_recurrence_workload(workload)
    elif algorithm == "tsvc_s2251_carried_scalar_expansion":
        validate_tsvc_s2251_carried_scalar_expansion_workload(workload)
    elif algorithm == "tsvc_s1251_per_element_dual_update":
        validate_tsvc_s1251_per_element_dual_update_workload(workload)
    elif algorithm == "tsvc_s3251_forward_shifted_array_expansion":
        validate_tsvc_s3251_forward_shifted_array_expansion_workload(workload)
    elif algorithm == "tsvc_s2712_comparison_gated_axpy":
        validate_tsvc_s2712_comparison_gated_axpy_workload(workload)
    elif algorithm == "tsvc_s2710_nested_scalar_vector_branch_update":
        validate_tsvc_s2710_nested_scalar_vector_branch_update_workload(workload)
    elif algorithm == "tsvc_s1279_nested_conditional_accumulation":
        validate_tsvc_s1279_nested_conditional_accumulation_workload(workload)
    elif algorithm == "tsvc_s2275_matrix_vector_axpy_interleave":
        validate_tsvc_s2275_matrix_vector_axpy_interleave_workload(workload)
    elif algorithm == "tsvc_s482_break_after_update":
        validate_tsvc_s482_break_after_update_workload(workload)
    elif algorithm == "tsvc_s441_s443_d_sign_branch_updates":
        validate_tsvc_s441_s443_d_sign_branch_updates_workload(workload)
    elif algorithm == "tsvc_s242_fused_prefix_update":
        validate_tsvc_s242_fused_prefix_update_workload(workload)
    elif algorithm == "tsvc_s351_direct_unrolled_saxpy":
        validate_tsvc_s351_direct_unrolled_saxpy_workload(workload)
    elif algorithm == "tsvc_s275_column_conditional_axpy_recurrence":
        validate_tsvc_s275_column_conditional_axpy_recurrence_workload(workload)
    elif algorithm == "tsvc_s313_dot_product_reduction":
        validate_tsvc_s313_dot_product_reduction_workload(workload)
    elif algorithm == "versabench_beamformer":
        validate_versabench_beamformer_workload(workload)
    elif algorithm == "matmul_f64_4x4":
        validate_matmul_f64_4x4_workload(workload)
    elif algorithm == "misc_fp_convert":
        validate_misc_fp_convert_workload(workload)
    elif algorithm == "misc_dt":
        validate_misc_dt_workload(workload)
    elif algorithm == "trisolv":
        validate_trisolv_workload(workload)
    elif algorithm in {"jacobi_1d", "jacobi_2d"}:
        validate_polybench_jacobi_workload(workload, algorithm)
    elif algorithm == "syr2k":
        validate_syr2k_workload(workload)
    elif algorithm == "trmm":
        validate_trmm_workload(workload)
    elif algorithm == "pca":
        validate_pca_workload(workload)
    elif algorithm == "principal_component_analysis":
        validate_principal_component_analysis_workload(workload)
    elif algorithm == "ramer_douglas_peucker":
        validate_ramer_douglas_peucker_workload(workload)
    elif algorithm == "pid":
        validate_pid_workload(workload)
    elif algorithm == "joint_probability_distribution":
        validate_joint_probability_distribution_workload(workload)
    elif algorithm == "shreedharacharya":
        validate_shreedharacharya_workload(workload)
    elif algorithm == "rotation_matrix":
        validate_rotation_matrix_workload(workload)
    elif algorithm == "simple_pendulum_rk4":
        validate_simple_pendulum_rk4_workload(workload)
    elif algorithm == "koch_snowflake":
        validate_koch_snowflake_workload(workload)
    elif algorithm == "k_d_tree":
        validate_k_d_tree_workload(workload)
    elif algorithm == "linear_regression_vectorized":
        validate_linear_regression_vectorized_workload(workload)
    elif algorithm == "perlin_noise":
        validate_perlin_noise_workload(workload)
    elif algorithm == "single_point_crossover":
        validate_single_point_crossover_workload(workload)
    elif algorithm == "quaternions":
        validate_quaternions_workload(workload)
    elif algorithm == "rmsprop":
        validate_rmsprop_workload(workload)
    elif algorithm == "k_means_clust":
        validate_k_means_clust_workload(workload)
    elif algorithm == "lu_decompose":
        validate_lu_decompose_workload(workload)
    elif algorithm == "lu_elimination":
        validate_lu_elimination_workload(workload)
    elif algorithm == "spirograph":
        validate_spirograph_workload(workload)
    elif algorithm == "sherman_morrison":
        validate_sherman_morrison_workload(workload)
    elif algorithm == "linearregressionrawr":
        validate_linearregressionrawr_workload(workload)
    elif algorithm == "q_learning":
        validate_q_learning_workload(workload)
    elif algorithm == "single_indeterminate_operations":
        validate_single_indeterminate_operations_workload(workload)
    elif algorithm == "montecarlopi":
        validate_montecarlopi_workload(workload)
    elif algorithm == "monte_carlo_simulation":
        validate_monte_carlo_simulation_workload(workload)
    elif algorithm == "mini_batch_gradient_descent":
        validate_mini_batch_gradient_descent_workload(workload)
    elif algorithm in TRAVELLING_SALESMAN_PYTHON_ALGORITHMS:
        validate_travelling_salesman_python_workload(workload, algorithm)
    data, count = checker_records(algorithm, workload)
    build_root = (args.build_dir or ROOT / "build" / "float64_slice_io" / algorithm).resolve()
    build_root.mkdir(parents=True, exist_ok=True)
    (build_root / f"{algorithm}-corpus.txt").write_text(data, encoding="utf-8")
    results, failures = [], []
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        jobs = {
            pool.submit(verify, algorithm, language, build_root / language,
                        args.elisa_compiler, data, count, workload): language
            for language in args.languages
        }
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
                results.append(result)
                print(f"PASS {language}: {count} ABI cases, {result['workload_records']} workload records",
                      flush=True)
            except Exception as error:
                failures.append((language, str(error)))
                print(f"FAIL {language}: {error}", file=sys.stderr, flush=True)
    report = {"algorithm": algorithm, "results": sorted(results, key=lambda result: result["language"]),
              "failures": failures}
    (build_root / "verification.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    return int(bool(failures))


if __name__ == "__main__":
    raise SystemExit(main())
