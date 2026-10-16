#!/usr/bin/env python3
"""Verify byte-output array ports against independent algorithm oracles."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
from decimal import Decimal, ROUND_HALF_UP
import hashlib
from itertools import product
import json
import math
from pathlib import Path
import platform
import random
import struct
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from cholesky_decomposition_oracle import expected_output as cholesky_decomposition_oracle
from depreciation_oracle import expected_output as depreciation_oracle
from brainfuck_oracle import expected_output as brainfuck_oracle
from chaos_machine_oracle import MAX_INPUT_LENGTH as MAX_CHAOS_MACHINE_INPUT_LENGTH
from chaos_machine_oracle import expected_output as chaos_machine_oracle
from canny_oracle import expected_output as canny_oracle
from centroid_decomposition_oracle import MAX_NODES as MAX_CENTROID_NODES
from centroid_decomposition_oracle import MAX_OUTPUT_BYTES as MAX_CENTROID_OUTPUT_BYTES
from centroid_decomposition_oracle import expected_output as centroid_decomposition_oracle
from chacha_oracle import expected_output as chacha_oracle
from gauss_elimination_oracle import expected_output as gauss_elimination_oracle
from choiceset_oracle import MAX_OPERATIONS as MAX_CHOICESET_OPERATIONS
from choiceset_oracle import expected_output as choiceset_oracle
from chudnovsky_algorithm_oracle import MAX_PRECISION as MAX_CHUDNOVSKY_PRECISION
from chudnovsky_algorithm_oracle import expected_output as chudnovsky_algorithm_oracle
from circular_look_scheduling_oracle import MAX_INPUT_LENGTH as MAX_CIRCULAR_LOOK_INPUT_LENGTH
from circular_look_scheduling_oracle import MAX_REQUESTS as MAX_CIRCULAR_LOOK_REQUESTS
from circular_look_scheduling_oracle import expected_output as circular_look_scheduling_oracle
from circular_scan_scheduling_oracle import MAX_INPUT_LENGTH as MAX_CIRCULAR_SCAN_INPUT_LENGTH
from circular_scan_scheduling_oracle import MAX_REQUESTS as MAX_CIRCULAR_SCAN_REQUESTS
from circular_scan_scheduling_oracle import expected_output as circular_scan_scheduling_oracle
from chebyshev_iteration_oracle import MAX_DIMENSION as MAX_CHEBYSHEV_DIMENSION
from chebyshev_iteration_oracle import expected_output as chebyshev_iteration_oracle
from charoccurrence_oracle import MAX_INPUT as MAX_CHAROCCURRENCE_INPUT_LENGTH
from charoccurrence_oracle import expected_output as charoccurrence_oracle
from swap_case_oracle import MAX_INPUT_LENGTH as MAX_SWAP_CASE_INPUT_LENGTH
from swap_case_oracle import expected_output as swap_case_oracle
from entropy_oracle import MAX_TEXT_LENGTH as MAX_ENTROPY_TEXT_LENGTH
from entropy_oracle import expected_result as entropy_oracle
from string_switch_case_oracle import MAX_TEXT_LENGTH as MAX_STRING_SWITCH_CASE_TEXT_LENGTH
from string_switch_case_oracle import expected_output as string_switch_case_oracle
from logarithmic_series_oracle import expected_output as logarithmic_series_oracle
from p_series_oracle import expected_output as p_series_oracle
from proper_fractions_oracle import expected_output as proper_fractions_oracle
from sumset_oracle import expected_output as sumset_oracle
from run_i64_array_bytes_output import MAX_OUTPUT_CAPACITY
from run_i64_array_bytes_output import expected_output as recorder_expected_output
from common_characters_frequency_quotient_oracle import expected_output as common_characters_frequency_quotient_oracle
from remove_duplicate_characters_oracle import MAX_INPUT_LENGTH as MAX_REMOVE_DUPLICATE_CHARACTERS_INPUT_LENGTH
from remove_duplicate_characters_oracle import expected_output as remove_duplicate_characters_oracle
from gronsfeld_oracle import MAX_KEY_LENGTH as MAX_GRONSFELD_KEY_LENGTH
from gronsfeld_oracle import MAX_TEXT_LENGTH as MAX_GRONSFELD_TEXT_LENGTH
from gronsfeld_oracle import expected_output as gronsfeld_oracle
from remove_duplicate_words_oracle import MAX_INPUT_LENGTH as MAX_REMOVE_DUPLICATE_WORDS_INPUT_LENGTH
from remove_duplicate_words_oracle import expected_output as remove_duplicate_words_oracle
from continued_fraction_oracle import MAX_ABS_INPUT as MAX_CONTINUED_FRACTION_ABS_INPUT
from continued_fraction_oracle import MAX_OUTPUT_LENGTH as MAX_CONTINUED_FRACTION_OUTPUT_LENGTH
from continued_fraction_oracle import expected_output as continued_fraction_oracle
from date_to_day_oracle import MAX_INPUT_LENGTH as MAX_DATE_TO_DAY_INPUT_LENGTH
from date_to_day_oracle import expected_output as date_to_day_oracle
from ema_filter_oracle import MAX_INPUT_LENGTH as MAX_EMA_FILTER_INPUT_LENGTH
from ema_filter_oracle import expected_output as ema_filter_oracle
from egyptian_fraction_oracle import MAX_INPUT_LENGTH as MAX_EGYPTIAN_FRACTION_INPUT_LENGTH
from egyptian_fraction_oracle import expected_output as egyptian_fraction_oracle
from count_nucleotide_oracle import MAX_SEQUENCE_LENGTH as MAX_COUNT_NUCLEOTIDE_SEQUENCE_LENGTH
from count_nucleotide_oracle import expected_output as count_nucleotide_oracle
from cramers_rule_2x2_oracle import MAX_INPUT_LENGTH as MAX_CRAMERS_RULE_2X2_INPUT_LENGTH
from cramers_rule_2x2_oracle import OUTPUT_BYTES as CRAMERS_RULE_2X2_OUTPUT_BYTES
from cramers_rule_2x2_oracle import expected_output as cramers_rule_2x2_oracle
from crc_polynomial_division_oracle import MAX_INPUT_LENGTH as MAX_CRC_POLYNOMIAL_DIVISION_INPUT_LENGTH
from crc_polynomial_division_oracle import MAX_OUTPUT_BYTES as MAX_CRC_POLYNOMIAL_DIVISION_OUTPUT_BYTES
from crc_polynomial_division_oracle import expected_output as crc_polynomial_division_oracle
from power_for_huge_numbers_oracle import MAX_INPUT_LENGTH as MAX_POWER_FOR_HUGE_NUMBERS_INPUT_LENGTH
from power_for_huge_numbers_oracle import MAX_OUTPUT_BYTES as MAX_POWER_FOR_HUGE_NUMBERS_OUTPUT_BYTES
from power_for_huge_numbers_oracle import expected_output as power_for_huge_numbers_oracle
from ode_forward_euler_oracle import MAX_INPUT_LENGTH as MAX_ODE_FORWARD_EULER_INPUT_LENGTH
from ode_forward_euler_oracle import OUTPUT_BYTES as ODE_FORWARD_EULER_OUTPUT_BYTES
from ode_forward_euler_oracle import expected_output as ode_forward_euler_oracle
from ode_midpoint_euler_oracle import MAX_INPUT_LENGTH as MAX_ODE_MIDPOINT_EULER_INPUT_LENGTH
from ode_midpoint_euler_oracle import MAX_OUTPUT_BYTES as MAX_ODE_MIDPOINT_EULER_OUTPUT_BYTES
from ode_midpoint_euler_oracle import expected_output as ode_midpoint_euler_oracle
from ode_semi_implicit_euler_oracle import MAX_INPUT_LENGTH as MAX_ODE_SEMI_IMPLICIT_EULER_INPUT_LENGTH
from ode_semi_implicit_euler_oracle import OUTPUT_BYTES as ODE_SEMI_IMPLICIT_EULER_OUTPUT_BYTES
from ode_semi_implicit_euler_oracle import expected_output as ode_semi_implicit_euler_oracle
from graph_coloring_oracle import MAX_VALIDATION_LENGTH as MAX_GRAPH_COLORING_VALIDATION_LENGTH
from graph_coloring_oracle import MAX_OUTPUT_BYTES as MAX_GRAPH_COLORING_OUTPUT_BYTES
from graph_coloring_oracle import expected_output as graph_coloring_oracle
from create_binary_tree_from_inorder_preorder_oracle import MAX_INPUT_LENGTH as MAX_CREATE_BINARY_TREE_INPUT_LENGTH
from create_binary_tree_from_inorder_preorder_oracle import MAX_OUTPUT_BYTES as MAX_CREATE_BINARY_TREE_OUTPUT_BYTES
from create_binary_tree_from_inorder_preorder_oracle import expected_output as create_binary_tree_oracle
from serialize_deserialize_binary_tree_oracle import MAX_INPUT_LENGTH as MAX_SERIALIZE_DESERIALIZE_BINARY_TREE_INPUT_LENGTH
from serialize_deserialize_binary_tree_oracle import MAX_OUTPUT_LENGTH as MAX_SERIALIZE_DESERIALIZE_BINARY_TREE_OUTPUT_LENGTH
from serialize_deserialize_binary_tree_oracle import expected_output as serialize_deserialize_binary_tree_oracle
from string_compression_oracle import MAX_INPUT_LENGTH as MAX_STRING_COMPRESSION_INPUT_LENGTH
from string_compression_oracle import MAX_OUTPUT_LENGTH as MAX_STRING_COMPRESSION_OUTPUT_LENGTH
from string_compression_oracle import expected_output as string_compression_oracle
from flash_sort_oracle import MAX_INPUT_LENGTH as MAX_FLASH_SORT_INPUT_LENGTH
from flash_sort_oracle import MAX_LENGTH as MAX_FLASH_SORT_LENGTH
from flash_sort_oracle import MAX_OUTPUT_BYTES as MAX_FLASH_SORT_OUTPUT_BYTES
from flash_sort_oracle import expected_output as flash_sort_oracle
from coordinate_compression_oracle import MAX_INPUT_LENGTH as MAX_COORDINATE_COMPRESSION_INPUT_LENGTH
from coordinate_compression_oracle import MAX_OUTPUT_LENGTH as MAX_COORDINATE_COMPRESSION_OUTPUT_LENGTH
from coordinate_compression_oracle import expected_output as coordinate_compression_oracle
from convolution_oracle import MAX_INPUT_LENGTH as MAX_CONVOLUTION_INPUT_LENGTH
from convolution_oracle import MAX_OUTPUT_BYTES as MAX_CONVOLUTION_OUTPUT_BYTES
from convolution_oracle import expected_output as convolution_oracle
from damped_oscillator_oracle import MAX_INPUT_LENGTH as MAX_DAMPED_OSCILLATOR_INPUT_LENGTH
from damped_oscillator_oracle import MAX_OUTPUT_BYTES as MAX_DAMPED_OSCILLATOR_OUTPUT_BYTES
from damped_oscillator_oracle import expected_output as damped_oscillator_oracle
from difference_array_oracle import MAX_INPUT_LENGTH as MAX_DIFFERENCE_ARRAY_INPUT_LENGTH
from difference_array_oracle import MAX_OUTPUT_BYTES as MAX_DIFFERENCE_ARRAY_OUTPUT_BYTES
from difference_array_oracle import expected_output as difference_array_oracle
from cusum_detector_oracle import MAX_INPUT_LENGTH as MAX_CUSUM_DETECTOR_INPUT_LENGTH
from cusum_detector_oracle import MAX_OUTPUT_BYTES as MAX_CUSUM_DETECTOR_OUTPUT_BYTES
from cusum_detector_oracle import expected_output as cusum_detector_oracle
from complex_number_multiply_oracle import MAX_INPUT_LENGTH as MAX_COMPLEX_NUMBER_MULTIPLY_INPUT_LENGTH
from complex_number_multiply_oracle import MAX_OUTPUT_LENGTH as MAX_COMPLEX_NUMBER_MULTIPLY_OUTPUT_LENGTH
from complex_number_multiply_oracle import expected_output as complex_number_multiply_oracle
from complex_arithmetic_oracle import MAX_INPUT_LENGTH as MAX_COMPLEX_ARITHMETIC_INPUT_LENGTH
from complex_arithmetic_oracle import OUTPUT_BYTES as MAX_COMPLEX_ARITHMETIC_OUTPUT_BYTES
from complex_arithmetic_oracle import expected_output as complex_arithmetic_oracle
from dice_thrower_oracle import MAX_INPUT_LENGTH as MAX_DICE_THROWER_INPUT_LENGTH
from dice_thrower_oracle import MAX_OUTPUT_BYTES as MAX_DICE_THROWER_OUTPUT_BYTES
from dice_thrower_oracle import expected_output as dice_thrower_oracle
from hampel_filter_oracle import MAX_INPUT_LENGTH as MAX_HAMPEL_FILTER_INPUT_LENGTH
from hampel_filter_oracle import MAX_OUTPUT_BYTES as MAX_HAMPEL_FILTER_OUTPUT_BYTES
from hampel_filter_oracle import expected_output as hampel_filter_oracle
from intersection_of_two_arrays_oracle import MAX_INPUT_LENGTH as MAX_INTERSECTION_OF_TWO_ARRAYS_INPUT_LENGTH
from intersection_of_two_arrays_oracle import MAX_ARRAY_LENGTH as MAX_INTERSECTION_OF_TWO_ARRAYS_ARRAY_LENGTH
from intersection_of_two_arrays_oracle import MAX_OUTPUT_BYTES as MAX_INTERSECTION_OF_TWO_ARRAYS_OUTPUT_BYTES
from intersection_of_two_arrays_oracle import expected_output as intersection_of_two_arrays_oracle
from union_of_two_arrays_oracle import MAX_INPUT_LENGTH as MAX_UNION_OF_TWO_ARRAYS_INPUT_LENGTH
from union_of_two_arrays_oracle import MAX_ARRAY_LENGTH as MAX_UNION_OF_TWO_ARRAYS_ARRAY_LENGTH
from union_of_two_arrays_oracle import MAX_OUTPUT_BYTES as MAX_UNION_OF_TWO_ARRAYS_OUTPUT_BYTES
from union_of_two_arrays_oracle import expected_output as union_of_two_arrays_oracle
from get_products_of_all_other_elements_oracle import MAX_ARRAY_LENGTH as MAX_GET_PRODUCTS_OF_ALL_OTHER_ELEMENTS_ARRAY_LENGTH
from get_products_of_all_other_elements_oracle import MAX_INPUT_LENGTH as MAX_GET_PRODUCTS_OF_ALL_OTHER_ELEMENTS_INPUT_LENGTH
from get_products_of_all_other_elements_oracle import MAX_OUTPUT_BYTES as MAX_GET_PRODUCTS_OF_ALL_OTHER_ELEMENTS_OUTPUT_BYTES
from get_products_of_all_other_elements_oracle import expected_output as get_products_of_all_other_elements_oracle
from correlation_matrix_analysis_oracle import MAX_OUTPUT_BYTES as MAX_CORRELATION_MATRIX_ANALYSIS_OUTPUT_BYTES
from correlation_matrix_analysis_oracle import MAX_VARIABLES as MAX_CORRELATION_MATRIX_ANALYSIS_VARIABLES
from correlation_matrix_analysis_oracle import OBSERVATIONS as CORRELATION_MATRIX_ANALYSIS_OBSERVATIONS
from correlation_matrix_analysis_oracle import expected_output as correlation_matrix_analysis_oracle
from unique_letters_count_oracle import MAX_INPUT_LENGTH as MAX_UNIQUE_LETTERS_COUNT_INPUT_LENGTH
from unique_letters_count_oracle import MAX_OUTPUT_BYTES as MAX_UNIQUE_LETTERS_COUNT_OUTPUT_BYTES
from unique_letters_count_oracle import expected_output as unique_letters_count_oracle
from convex_hull_graham_oracle import MAX_INPUT_LENGTH as MAX_CONVEX_HULL_GRAHAM_INPUT_LENGTH
from convex_hull_graham_oracle import MAX_POINTS as MAX_CONVEX_HULL_GRAHAM_POINTS
from convex_hull_graham_oracle import MAX_OUTPUT_BYTES as MAX_CONVEX_HULL_GRAHAM_OUTPUT_BYTES
from convex_hull_graham_oracle import expected_output as convex_hull_graham_oracle
from sorted_arrays_intersection_oracle import MAX_ARRAY_LENGTH as MAX_SORTED_ARRAYS_INTERSECTION_ARRAY_LENGTH
from sorted_arrays_intersection_oracle import MAX_INPUT_LENGTH as MAX_SORTED_ARRAYS_INTERSECTION_INPUT_LENGTH
from sorted_arrays_intersection_oracle import MAX_OUTPUT_BYTES as MAX_SORTED_ARRAYS_INTERSECTION_OUTPUT_BYTES
from sorted_arrays_intersection_oracle import expected_output as sorted_arrays_intersection_oracle
from compress_oracle import MAX_INPUT_LENGTH as MAX_COMPRESS_INPUT_LENGTH
from compress_oracle import MAX_LENGTH as MAX_COMPRESS_LENGTH
from compress_oracle import MAX_OUTPUT_BYTES as MAX_COMPRESS_OUTPUT_BYTES
from compress_oracle import expected_output as compress_oracle
from dilation_operation_oracle import MAX_DIMENSION as MAX_DILATION_OPERATION_DIMENSION
from dilation_operation_oracle import MAX_INPUT_LENGTH as MAX_DILATION_OPERATION_INPUT_LENGTH
from dilation_operation_oracle import MAX_OUTPUT_BYTES as MAX_DILATION_OPERATION_OUTPUT_BYTES
from dilation_operation_oracle import expected_output as dilation_operation_oracle
from nearest_neighbor_interpolation_oracle import MAX_DIMENSION as MAX_NEAREST_NEIGHBOR_DIMENSION
from nearest_neighbor_interpolation_oracle import MAX_INPUT_LENGTH as MAX_NEAREST_NEIGHBOR_INPUT_LENGTH
from nearest_neighbor_interpolation_oracle import MAX_OUTPUT_BYTES as MAX_NEAREST_NEIGHBOR_OUTPUT_BYTES
from nearest_neighbor_interpolation_oracle import expected_output as nearest_neighbor_interpolation_oracle
from combination_sum_oracle import MAX_CANDIDATES as MAX_COMBINATION_SUM_CANDIDATES
from combination_sum_oracle import MAX_PACKED_INPUT_LENGTH as MAX_COMBINATION_SUM_INPUT_LENGTH
from combination_sum_oracle import MAX_OUTPUT_WORDS as MAX_COMBINATION_SUM_OUTPUT_WORDS
from combination_sum_oracle import MAX_TARGET as MAX_COMBINATION_SUM_TARGET
from combination_sum_oracle import expected_output as combination_sum_oracle
from range_in_sorted_array_oracle import MAX_ARRAY_LENGTH as MAX_RANGE_IN_SORTED_ARRAY_LENGTH
from range_in_sorted_array_oracle import MAX_INPUT_LENGTH as MAX_RANGE_IN_SORTED_ARRAY_INPUT_LENGTH
from range_in_sorted_array_oracle import MAX_OUTPUT_BYTES as MAX_RANGE_IN_SORTED_ARRAY_OUTPUT_BYTES
from range_in_sorted_array_oracle import expected_output as range_in_sorted_array_oracle
from non_empty_subsequences_oracle import MAX_OUTPUT_BYTES as MAX_NON_EMPTY_SUBSEQUENCES_OUTPUT_BYTES
from non_empty_subsequences_oracle import expected_output as non_empty_subsequences_oracle
from particle_swarm_optimization_oracle import MAX_OUTPUT_BYTES as MAX_PARTICLE_SWARM_OUTPUT_BYTES
from particle_swarm_optimization_oracle import expected_output as particle_swarm_oracle
from convolve_1d_oracle import MAX_INPUT_LENGTH as MAX_CONVOLVE_1D_INPUT_LENGTH
from convolve_1d_oracle import MAX_OUTPUT_BYTES as MAX_CONVOLVE_1D_OUTPUT_BYTES
from convolve_1d_oracle import expected_output as convolve_1d_oracle
from depth_first_search_target_route_oracle import MAX_INPUT_LENGTH as MAX_DFS_TARGET_ROUTE_INPUT_LENGTH
from depth_first_search_target_route_oracle import MAX_OUTPUT_BYTES as MAX_DFS_TARGET_ROUTE_OUTPUT_BYTES
from depth_first_search_target_route_oracle import expected_output as depth_first_search_target_route_oracle
from eulerian_path_oracle import MAX_EDGES as MAX_EULERIAN_PATH_EDGES
from eulerian_path_oracle import MAX_INPUT_LENGTH as MAX_EULERIAN_PATH_INPUT_LENGTH
from eulerian_path_oracle import MAX_OUTPUT_BYTES as MAX_EULERIAN_PATH_OUTPUT_BYTES
from eulerian_path_oracle import MAX_VERTICES as MAX_EULERIAN_PATH_VERTICES
from eulerian_path_oracle import expected_output as eulerian_path_oracle
from convolution_fft_oracle import MAX_INPUT_LENGTH as MAX_CONVOLUTION_FFT_INPUT_LENGTH
from convolution_fft_oracle import MAX_OUTPUT_BYTES as MAX_CONVOLUTION_FFT_OUTPUT_BYTES
from convolution_fft_oracle import expected_output as convolution_fft_oracle
from text_justification_oracle import MAX_INPUT_LENGTH as MAX_TEXT_JUSTIFICATION_INPUT_LENGTH
from text_justification_oracle import MAX_OUTPUT_BYTES as MAX_TEXT_JUSTIFICATION_OUTPUT_BYTES
from text_justification_oracle import expected_output as text_justification_oracle
from remove_duplicate_from_string_oracle import MAX_INPUT_LENGTH as MAX_REMOVE_DUPLICATE_FROM_STRING_INPUT_LENGTH
from remove_duplicate_from_string_oracle import MAX_OUTPUT_BYTES as MAX_REMOVE_DUPLICATE_FROM_STRING_OUTPUT_BYTES
from remove_duplicate_from_string_oracle import expected_output as remove_duplicate_from_string_oracle
from max_word_oracle import MAX_INPUT_LENGTH as MAX_MAX_WORD_INPUT_LENGTH
from max_word_oracle import MAX_OUTPUT_BYTES as MAX_MAX_WORD_OUTPUT_BYTES
from max_word_oracle import expected_output as max_word_oracle
from keyword_shifted_alphabet_oracle import MAX_INPUT_LENGTH as MAX_KEYWORD_SHIFTED_ALPHABET_INPUT_LENGTH
from keyword_shifted_alphabet_oracle import MAX_OUTPUT_BYTES as MAX_KEYWORD_SHIFTED_ALPHABET_OUTPUT_BYTES
from keyword_shifted_alphabet_oracle import expected_output as keyword_shifted_alphabet_oracle
from integer_to_english_oracle import MAX_PARSEABLE_INPUT_LENGTH as MAX_INTEGER_TO_ENGLISH_INPUT_LENGTH
from integer_to_english_oracle import MAX_OUTPUT_BYTES as MAX_INTEGER_TO_ENGLISH_OUTPUT_BYTES
from integer_to_english_oracle import I32_MIN as INTEGER_TO_ENGLISH_I32_MIN
from integer_to_english_oracle import I32_MAX as INTEGER_TO_ENGLISH_I32_MAX
from integer_to_english_oracle import expected_output as integer_to_english_oracle
from largest_smallest_words_oracle import MAX_INPUT_LENGTH as MAX_LARGEST_SMALLEST_WORDS_INPUT_LENGTH
from largest_smallest_words_oracle import MAX_OUTPUT_BYTES as MAX_LARGEST_SMALLEST_WORDS_OUTPUT_BYTES
from largest_smallest_words_oracle import expected_output as largest_smallest_words_oracle
from hexa_decimal_to_binary_oracle import MAX_PARSEABLE_INPUT_LENGTH as MAX_HEXA_DECIMAL_TO_BINARY_INPUT_LENGTH
from hexa_decimal_to_binary_oracle import MAX_INPUT_LENGTH as MAX_HEXA_DECIMAL_TO_BINARY_VALID_INPUT_LENGTH
from hexa_decimal_to_binary_oracle import MAX_OUTPUT_BYTES as MAX_HEXA_DECIMAL_TO_BINARY_OUTPUT_BYTES
from hexa_decimal_to_binary_oracle import expected_output as hexa_decimal_to_binary_oracle
from ones_complement_oracle import MAX_INPUT_LENGTH as MAX_ONES_COMPLEMENT_INPUT_LENGTH
from ones_complement_oracle import expected_output as ones_complement_oracle
from rgbto_hex_oracle import MAX_INPUT_LENGTH as MAX_RGBTO_HEX_INPUT_LENGTH
from rgbto_hex_oracle import OUTPUT_LENGTH as RGBTO_HEX_OUTPUT_LENGTH
from rgbto_hex_oracle import expected_output as rgbto_hex_oracle
from ipconverter_oracle import MAX_PARSEABLE_INPUT_LENGTH as MAX_IPCONVERTER_PARSEABLE_INPUT_LENGTH
from ipconverter_oracle import MAX_OUTPUT_LENGTH as MAX_IPCONVERTER_OUTPUT_LENGTH
from ipconverter_oracle import expected_output as ipconverter_oracle
from shortest_palindrome_oracle import MAX_INPUT_LENGTH as MAX_SHORTEST_PALINDROME_PARSEABLE_INPUT_LENGTH
from shortest_palindrome_oracle import MAX_VALID_INPUT_LENGTH as MAX_SHORTEST_PALINDROME_VALID_INPUT_LENGTH
from shortest_palindrome_oracle import MAX_OUTPUT_LENGTH as MAX_SHORTEST_PALINDROME_OUTPUT_LENGTH
from shortest_palindrome_oracle import expected_output as shortest_palindrome_oracle
from reverse_words_in_string_oracle import MAX_INPUT_LENGTH as MAX_REVERSE_WORDS_IN_STRING_INPUT_LENGTH
from reverse_words_in_string_oracle import MAX_PARSEABLE_INPUT_LENGTH as MAX_REVERSE_WORDS_IN_STRING_PARSEABLE_INPUT_LENGTH
from reverse_words_in_string_oracle import MAX_OUTPUT_LENGTH as MAX_REVERSE_WORDS_IN_STRING_OUTPUT_LENGTH
from reverse_words_in_string_oracle import expected_output as reverse_words_in_string_oracle
from numeric_string_sort_oracle import MAX_PARSEABLE_INPUT_LENGTH as MAX_NUMERIC_STRING_SORT_PARSEABLE_INPUT_LENGTH
from numeric_string_sort_oracle import MAX_OUTPUT_LENGTH as MAX_NUMERIC_STRING_SORT_OUTPUT_LENGTH
from numeric_string_sort_oracle import expected_output as numeric_string_sort_oracle
from composite_lfsr_majority_clock_oracle import expected_output as composite_lfsr_majority_clock_oracle
from fibonacci_heap_oracle import MAX_KEYS as MAX_FIBONACCI_HEAP_KEYS
from fibonacci_heap_oracle import expected_output as fibonacci_heap_oracle
from recursive_shuffler_oracle import MAX_INPUT_LENGTH as MAX_RECURSIVE_SHUFFLER_INPUT_LENGTH
from recursive_shuffler_oracle import MAX_VALUES as MAX_RECURSIVE_SHUFFLER_VALUES
from recursive_shuffler_oracle import expected_output as recursive_shuffler_oracle
from fisher_yates_shuffle_oracle import MAX_LENGTH as MAX_FISHER_YATES_VALUES
from fisher_yates_shuffle_oracle import expected_output as fisher_yates_shuffle_oracle
from heaps_oracle import MAX_N as MAX_HEAPS_N
from heaps_oracle import MAX_OUTPUT_BYTES as MAX_HEAPS_OUTPUT_BYTES
from heaps_oracle import expected_output as heaps_oracle
from heaps_algorithm_oracle import I64_MAX as HEAPS_ALGORITHM_I64_MAX
from heaps_algorithm_oracle import I64_MIN as HEAPS_ALGORITHM_I64_MIN
from heaps_algorithm_oracle import MAX_PERMUTATION_LENGTH as MAX_HEAPS_ALGORITHM_LENGTH
from heaps_algorithm_oracle import MAX_OUTPUT_BYTES as MAX_HEAPS_ALGORITHM_OUTPUT_BYTES
from heaps_algorithm_oracle import expected_output as heaps_algorithm_oracle
from cpu_scheduling_algorithms_oracle import MAX_INPUT_LENGTH as MAX_CPU_SCHEDULING_INPUT_LENGTH
from cpu_scheduling_algorithms_oracle import MAX_OUTPUT_BYTES as MAX_CPU_SCHEDULING_OUTPUT_BYTES
from cpu_scheduling_algorithms_oracle import MAX_PROCESSES as MAX_CPU_SCHEDULING_PROCESSES
from cpu_scheduling_algorithms_oracle import expected_output as cpu_scheduling_oracle

ALGORITHMS = ("letter_combinations_of_phone_number", "blake2b", "charoccurrence", "swap_case", "binary_and_operator", "entropy", "rna_transcription", "reverse_words", "string_switch_case", "reverse_complement", "reverse_string", "reverse_letters", "bresenham_line", "check_polygon", "red_black_tree_insert_search", "unique_permutation", "infix_to_prefix", "inverse_fast_fourier_transform", "naive_search", "next_permutation", "gronsfeld_cipher", "a5_cipher", "a5_key_stream_generator", "aatree", "title_case_conversion", "change_brightness", "change_contrast",
              "chaos_machine", "convert_to_negative", "canny", "red_black_tree_unique_key_ops", "weight_conversions", "brainfuck", "p_series",
              "logarithmic_series", "proper_fractions", "sumset", "common_characters_frequency_quotient",
              "remove_duplicate_characters", "gronsfeld", "remove_duplicate_words",
              "continued_fraction", "account_merge", "acronym", "adagrad",
              "cholesky_decomposition", "adam", "adaline_learning", "adams_bashforth",
              "adfgvxcipher", "upper", "all_construct", "depreciation", "allocation_number",
              "booths_algorithm", "association", "auto_correlation", "baconian_cipher",
              "a1z26_cipher", "a1z26_decipher", "centroid_decomposition", "chacha", "chebyshev_iteration", "date_to_day",
              "cross_correlation", "ema_filter", "egyptian_fraction", "count_nucleotide", "atbash_cipher", "choiceset", "chudnovsky_algorithm",
              "serialize_deserialize_binary_tree", "cramers_rule_2x2", "create_binary_tree_from_inorder_preorder",
              "string_compression", "circular_look_scheduling", "circular_scan_scheduling", "flash_sort", "coordinate_compression", "convolution", "damped_oscillator", "difference_array", "cusum_detector", "complex_number_multiply", "complex_arithmetic", "dice_thrower", "hampel_filter", "range_in_sorted_array", "intersection_of_two_arrays", "union_of_two_arrays", "unique_letters_count", "convex_hull_graham", "sorted_arrays_intersection", "compress", "dilation_operation", "nearest_neighbor_interpolation", "combination_sum", "non_empty_subsequences", "particle_swarm_optimization", "convolve_1d", "depth_first_search_target_route", "composite_lfsr_majority_clock", "convolution_fft", "text_justification", "remove_duplicate_from_string", "max_word", "keyword_shifted_alphabet", "integer_to_english", "largest_smallest_words", "hexa_decimal_to_binary", "ones_complement", "rgbto_hex", "binary_to_excess3", "ipconverter", "shortest_palindrome", "reverse_words_in_string", "numeric_string_sort", "get_products_of_all_other_elements", "correlation_matrix_analysis", "crc_polynomial_division", "power_for_huge_numbers", "fibonacci_heap", "ode_forward_euler", "ode_midpoint_euler", "ode_semi_implicit_euler", "gauss_elimination")
ALGORITHMS = (*ALGORITHMS, "recursive_shuffler", "graph_coloring", "fisher_yates_shuffle")
ALGORITHMS = (*ALGORITHMS, "heaps", "heaps_algorithm")
ALGORITHMS = (*ALGORITHMS, "cpu_scheduling_algorithms")
ALGORITHMS = (*ALGORITHMS, "eulerian_path")
WORKSPACE_ALGORITHMS = {"blake2b", "title_case_conversion", "red_black_tree_unique_key_ops",
                        "complex_arithmetic",
                        "weight_conversions", "brainfuck", "p_series", "logarithmic_series",
                        "charoccurrence",
                        "swap_case",
                        "binary_and_operator",
                        "entropy",
                        "rna_transcription",
                        "reverse_words",
                        "string_switch_case",
                        "reverse_complement",
                        "reverse_string", "reverse_letters",
                        "bresenham_line",
                        "red_black_tree_insert_search",
                        "unique_permutation",
                        "infix_to_prefix",
                        "inverse_fast_fourier_transform",
                        "naive_search",
                        "next_permutation",
                        "gronsfeld_cipher",
                        "a5_cipher",
                        "a5_key_stream_generator",
                        "aatree",
                        "change_brightness", "change_contrast",
                        "chaos_machine", "convert_to_negative", "canny",
                        "proper_fractions", "sumset", "common_characters_frequency_quotient",
                        "remove_duplicate_characters", "gronsfeld", "remove_duplicate_words",
                        "continued_fraction", "account_merge", "acronym", "adagrad",
                        "cholesky_decomposition", "adam", "adaline_learning", "adams_bashforth",
                        "adfgvxcipher", "upper", "all_construct", "depreciation", "allocation_number",
                        "booths_algorithm", "association", "auto_correlation", "baconian_cipher",
                        "a1z26_cipher", "a1z26_decipher", "centroid_decomposition", "chacha", "chebyshev_iteration", "date_to_day",
                        "cross_correlation", "ema_filter", "egyptian_fraction", "count_nucleotide", "atbash_cipher", "choiceset", "chudnovsky_algorithm",
                        "serialize_deserialize_binary_tree", "cramers_rule_2x2", "crc_polynomial_division", "power_for_huge_numbers", "ode_forward_euler", "ode_midpoint_euler", "ode_semi_implicit_euler", "gauss_elimination", "create_binary_tree_from_inorder_preorder",
                        "string_compression", "circular_look_scheduling", "circular_scan_scheduling", "flash_sort", "coordinate_compression", "convolution", "damped_oscillator", "difference_array", "cusum_detector", "complex_number_multiply", "dice_thrower", "hampel_filter", "range_in_sorted_array", "intersection_of_two_arrays", "union_of_two_arrays", "unique_letters_count", "convex_hull_graham", "sorted_arrays_intersection", "compress", "dilation_operation", "nearest_neighbor_interpolation", "combination_sum", "non_empty_subsequences", "particle_swarm_optimization", "convolve_1d", "depth_first_search_target_route", "convolution_fft", "text_justification", "remove_duplicate_from_string", "max_word", "keyword_shifted_alphabet", "integer_to_english", "largest_smallest_words", "hexa_decimal_to_binary", "ones_complement", "rgbto_hex", "binary_to_excess3", "ipconverter", "shortest_palindrome", "reverse_words_in_string", "numeric_string_sort", "get_products_of_all_other_elements", "correlation_matrix_analysis", "crc_polynomial_division", "power_for_huge_numbers", "fibonacci_heap", "ode_forward_euler", "ode_midpoint_euler", "ode_semi_implicit_euler"}
WORKSPACE_ALGORITHMS.update({"recursive_shuffler", "graph_coloring", "fisher_yates_shuffle", "heaps", "heaps_algorithm", "cpu_scheduling_algorithms"})
WORKSPACE_ALGORITHMS.add("eulerian_path")
DEFAULT_ALGORITHM = "letter_combinations_of_phone_number"


def blake2b_oracle(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, (tuple, list)) or len(values) > 4096
            or any(type(value) is not int or not 0 <= value <= 255 for value in values)):
        return -1, b""
    return 64, hashlib.blake2b(bytes(values), digest_size=64).digest()


MAX_BINARY_TO_EXCESS3_INPUT_LENGTH = 128
MAX_BINARY_TO_EXCESS3_INTEGER = 1 << 62
MAX_BINARY_TO_EXCESS3_OUTPUT_BYTES = 64


def binary_to_excess3_verifier_oracle(
        values: tuple[int, ...] | list[int], capacity: int | None = None) -> tuple[int, bytes]:
    """Independent bounded oracle for Python's int(text, 2) then format(value, '04b')."""
    if (not isinstance(values, (tuple, list))
            or not 1 <= len(values) <= MAX_BINARY_TO_EXCESS3_INPUT_LENGTH
            or any(type(value) is not int or not 0 <= value <= 127 for value in values)):
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    try:
        number = int(bytes(values).decode("ascii"), 2)
    except ValueError:
        return -1, b""
    if abs(number) > MAX_BINARY_TO_EXCESS3_INTEGER:
        return -1, b""
    output = format(number + 3, "04b").encode("ascii")
    if capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output


def account_merge_verifier_oracle(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    """Independent graph-based oracle for the bounded account-merge contract."""
    if (not isinstance(values, (tuple, list)) or not values or len(values) > 100002
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    account_count = values[0]
    if not 0 <= account_count <= 64:
        return -1, b""

    accounts: list[tuple[bytes, set[bytes]]] = []
    email_owners: dict[bytes, set[int]] = {}
    total_references = 0
    position = 1
    for account_index in range(account_count):
        if position >= len(values) or not 1 <= values[position] <= 64:
            return -1, b""
        name_length = values[position]
        position += 1
        if name_length > len(values) - position:
            return -1, b""
        name_values = values[position:position + name_length]
        if any(not 32 <= byte <= 126 for byte in name_values):
            return -1, b""
        name = bytes(name_values)
        position += name_length
        if position >= len(values) or not 0 <= values[position] <= 1024:
            return -1, b""
        reference_count = values[position]
        position += 1
        total_references += reference_count
        if total_references > 1024:
            return -1, b""
        account_emails: set[bytes] = set()
        for _ in range(reference_count):
            if position >= len(values) or not 1 <= values[position] <= 64:
                return -1, b""
            email_length = values[position]
            position += 1
            if email_length > len(values) - position:
                return -1, b""
            email_values = values[position:position + email_length]
            if any(not 33 <= byte <= 126 for byte in email_values):
                return -1, b""
            email = bytes(email_values)
            account_emails.add(email)
            position += email_length
        accounts.append((name, account_emails))
        for email in account_emails:
            email_owners.setdefault(email, set()).add(account_index)
    if position != len(values):
        return -1, b""

    neighbors = [set() for _ in accounts]
    for owners in email_owners.values():
        for account_index in owners:
            neighbors[account_index].update(owners - {account_index})

    groups: list[tuple[bytes, list[bytes], int]] = []
    visited: set[int] = set()
    for start in range(account_count):
        if start in visited:
            continue
        pending = [start]
        component: list[int] = []
        visited.add(start)
        while pending:
            current = pending.pop()
            component.append(current)
            for neighbor in neighbors[current]:
                if neighbor not in visited:
                    visited.add(neighbor)
                    pending.append(neighbor)
        names = {accounts[index][0] for index in component}
        if len(names) != 1:
            return -1, b""
        emails = sorted(set().union(*(accounts[index][1] for index in component)))
        groups.append((next(iter(names)), emails, min(component)))

    groups.sort(key=lambda group: (group[0], 0 if not group[1] else 1,
                                   group[1][0] if group[1] else b"", group[2]))
    output = bytearray(struct.pack("<H", len(groups)))
    for name, emails, _ in groups:
        output.extend(struct.pack("<HH", len(name), len(emails)))
        output.extend(name)
        for email in emails:
            output.extend(struct.pack("<H", len(email)))
            output.extend(email)
    return len(output), bytes(output)


def acronym_verifier_oracle(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    """Model the pinned literal-space tokenization without using the recorder."""
    if (not isinstance(values, (tuple, list)) or len(values) > 79
            or any(type(value) is not int or not 1 <= value <= 127 for value in values)):
        return -1, b""
    output = bytearray()
    token_start = True
    for value in values:
        if value == 32:
            token_start = True
        elif token_start:
            output.append(value - 32 if 97 <= value <= 122 else value)
            token_start = False
    return len(output), bytes(output)


def adagrad_verifier_oracle(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    """Independent binary64 AdaGrad trace model with integer output encoding."""
    input_scale = 1_000_000_000
    output_scale = 1_000_000
    if (not isinstance(values, (tuple, list)) or not 6 <= len(values) <= 3 + 3 * 256
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    steps, learning_rate_value, epsilon_value = values[:3]
    if (not 1 <= steps <= 256 or len(values) != 3 + 3 * steps
            or not 1 <= learning_rate_value <= input_scale
            or not 1 <= epsilon_value <= 10_000_000):
        return -1, b""
    learning_rate = learning_rate_value / input_scale
    epsilon = epsilon_value / input_scale
    accumulated = [0.0] * 16
    output = bytearray()
    for offset in range(3, len(values), 3):
        group_id, parameter_value, gradient_value = values[offset:offset + 3]
        if (not 0 <= group_id < 16
                or not -1_000_000_000_000_000 <= parameter_value <= 1_000_000_000_000_000
                or not -1_000_000_000_000 <= gradient_value <= 1_000_000_000_000):
            return -1, b""
        gradient = gradient_value / input_scale
        accumulated[group_id] += gradient * gradient
        updated = (parameter_value / input_scale
                   - learning_rate / (math.sqrt(accumulated[group_id]) + epsilon) * gradient)
        output.extend(struct.pack("<q", math.trunc(updated * output_scale)))
    return steps, bytes(output)


def adam_verifier_oracle(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    """Independent binary64 Adam/AdamW trace model with integer output encoding."""
    input_scale = 1_000_000_000
    output_scale = 1_000_000
    max_steps = 256
    max_parameters = 16
    if (not isinstance(values, (tuple, list)) or not 9 <= len(values) <= 7 + max_parameters + max_steps * max_parameters
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    steps, parameter_count, learning_rate_value, beta1_value, beta2_value, epsilon_value, weight_decay_value = values[:7]
    if (not 1 <= steps <= max_steps or not 1 <= parameter_count <= max_parameters
            or len(values) != 7 + parameter_count + steps * parameter_count
            or not 1 <= learning_rate_value <= input_scale
            or not 0 <= beta1_value < input_scale or not 0 <= beta2_value < input_scale
            or not 1 <= epsilon_value <= 10_000_000
            or not 0 <= weight_decay_value <= 100_000_000):
        return -1, b""
    parameter_values = values[7:7 + parameter_count]
    gradient_values = values[7 + parameter_count:]
    if (any(not -1_000_000_000_000_000 <= value <= 1_000_000_000_000_000
            for value in parameter_values)
            or any(not -1_000_000_000_000 <= value <= 1_000_000_000_000
                   for value in gradient_values)):
        return -1, b""
    learning_rate = learning_rate_value / input_scale
    beta1 = beta1_value / input_scale
    beta2 = beta2_value / input_scale
    epsilon = epsilon_value / input_scale
    weight_decay = weight_decay_value / input_scale
    parameters = [value / input_scale for value in parameter_values]
    first_moment = [0.0] * parameter_count
    second_moment = [0.0] * parameter_count
    beta1_power = beta2_power = 1.0
    output: list[int] = []
    for step in range(steps):
        beta1_power *= beta1
        beta2_power *= beta2
        for index in range(parameter_count):
            gradient = gradient_values[step * parameter_count + index] / input_scale
            first_moment[index] = beta1 * first_moment[index] + (1.0 - beta1) * gradient
            second_moment[index] = (beta2 * second_moment[index]
                                    + (1.0 - beta2) * gradient * gradient)
            corrected_first = first_moment[index] / (1.0 - beta1_power)
            corrected_second = second_moment[index] / (1.0 - beta2_power)
            parameters[index] = (parameters[index]
                                 - learning_rate * corrected_first / (math.sqrt(corrected_second) + epsilon)
                                 - learning_rate * weight_decay * parameters[index])
            output.append(math.trunc(parameters[index] * output_scale))
    return len(output), struct.pack("<" + "q" * len(output), *output)


def adaline_learning_verifier_oracle(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    """Model sequential fixed-point ADALINE learning independently of the recorder."""
    if (not isinstance(values, (tuple, list)) or not 5 <= len(values) <= 293
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    sample_count, feature_count, eta_numerator, eta_shift, max_iterations = values[:5]
    if (not 1 <= sample_count <= 32 or not 1 <= feature_count <= 8
            or eta_numerator <= 0 or not 1 <= eta_shift <= 12
            or not 1 <= max_iterations <= 500 or eta_numerator >= 1 << eta_shift
            or len(values) != 5 + sample_count * (feature_count + 1)):
        return -1, b""
    rows: list[tuple[tuple[int, ...], int]] = []
    for offset in range(5, len(values), feature_count + 1):
        row = values[offset:offset + feature_count + 1]
        features, label = tuple(row[:-1]), row[-1]
        if any(not -16 <= feature <= 16 for feature in features) or label not in (-1, 1):
            return -1, b""
        rows.append((features, label))
    scale = 1 << eta_shift
    weights = [scale] * feature_count
    bias = scale
    completed_epochs = 0
    for _ in range(max_iterations):
        mistakes = 0
        for features, label in rows:
            score = bias + sum(feature * weight for feature, weight in zip(features, weights))
            prediction = 1 if score > 0 else -1
            if prediction != label:
                mistakes += 1
                correction = eta_numerator * (label - prediction)
                weights = [weight + correction * feature for weight, feature in zip(weights, features)]
                bias += correction
        completed_epochs += 1
        if mistakes == 0:
            break
    predictions = [1 if bias + sum(feature * weight for feature, weight in zip(features, weights)) > 0 else -1
                   for features, _ in rows]
    outputs = [completed_epochs, *weights, bias, *predictions]
    encoded = b"".join(struct.pack("<i", value) for value in outputs)
    return len(encoded), encoded


def adams_bashforth_verifier_oracle(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    """Independent bounded source model of the four Adams-Bashforth recurrences."""
    if (not isinstance(values, (tuple, list)) or len(values) < 3
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    order, forecast_steps = values[:2]
    initial_scaled = values[2:]
    if (order not in (2, 3, 4, 5) or not 1 <= forecast_steps <= 4
            or len(initial_scaled) != order
            or any(not -100_000 <= value <= 100_000 for value in initial_scaled)):
        return -1, b""
    coefficients = {2: (3, -1), 3: (23, -16, 5),
                    4: (55, -59, 37, -9), 5: (1901, -2774, -2616, -1274, 251)}[order]
    denominator = {2: 2.0, 3: 12.0, 4: 24.0, 5: 720.0}[order]
    xs = [index * 0.25 for index in range(order)]
    ys = [value / 100_000.0 for value in initial_scaled]
    updates = forecast_steps + (order in (3, 5))
    for _ in range(updates):
        derivative_sum = 0.0
        for offset, coefficient in enumerate(coefficients):
            index = len(ys) - 1 - offset
            derivative_sum += coefficient * (xs[index] + ys[index])
        ys.append(ys[-1] + (0.25 / denominator) * derivative_sum)
        xs.append(xs[-1] + 0.25)
    encoded = ",".join(str(math.trunc(value * 1_000_000.0)) for value in ys).encode("ascii")
    return len(encoded), encoded


def adfgvxcipher_verifier_oracle(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    """Independent ASCII ADFGVX oracle with source-compatible partial columns."""
    if (not isinstance(values, (tuple, list)) or not 3 <= len(values) <= 531
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    mode, text_length, key_length = values[:3]
    if mode not in (0, 1) or not 1 <= key_length <= 16:
        return -1, b""
    max_text_length = 256 if mode == 0 else 512
    if (not 0 <= text_length <= max_text_length
            or len(values) != 3 + text_length + key_length):
        return -1, b""
    text = values[3:3 + text_length]
    key_values = values[3 + text_length:]
    if (any(not 0 <= byte <= 127 for byte in text)
            or any(not 65 <= byte <= 90 for byte in key_values)
            or len(set(key_values)) != key_length):
        return -1, b""
    key = bytes(key_values)
    square = (b"NA1C3H", b"8TB2OM", b"E5WRPD", b"4F67GI", b"9J0KLQ", b"SUVXYZ")
    labels = b"ADFGVX"
    if mode == 0:
        normalized = [byte - 32 if 97 <= byte <= 122 else byte for byte in text]
        alphabet = {square[row][column]: bytes((labels[row], labels[column]))
                    for row in range(6) for column in range(6)}
        fractionated = b"".join(alphabet[byte] for byte in normalized
                                if 65 <= byte <= 90 or 48 <= byte <= 57)
        row_count = (len(fractionated) + key_length - 1) // key_length
        grid = [[None] * key_length for _ in range(row_count)]
        for index, label in enumerate(fractionated):
            grid[index // key_length][index % key_length] = label
        ciphertext = bytes(grid[row][column]
                           for column in sorted(range(key_length), key=key.__getitem__)
                           for row in range(row_count) if grid[row][column] is not None)
        return len(ciphertext), ciphertext
    if text_length % 2 or any(byte not in labels for byte in text):
        return -1, b""
    row_count = (text_length + key_length - 1) // key_length
    grid = [[None] * key_length for _ in range(row_count)]
    offset = 0
    for column in sorted(range(key_length), key=key.__getitem__):
        for row in range(row_count):
            if offset < text_length:
                grid[row][column] = text[offset]
                offset += 1
    fractionated = bytes(cell for row in grid for cell in row if cell is not None)
    decode = {bytes((labels[row], labels[column])): square[row][column]
              for row in range(6) for column in range(6)}
    plaintext = bytes(decode[fractionated[index:index + 2]]
                      for index in range(0, len(fractionated), 2))
    return len(plaintext), plaintext


def upper_verifier_oracle(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    """Uppercase ASCII lowercase bytes while enforcing the package's whitespace domain."""
    if (not isinstance(values, (tuple, list)) or len(values) > 256
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    if any(not 0 <= value <= 127 or value in range(9, 14) or value == 32 for value in values):
        return -1, b""
    output = bytes(value - 32 if 97 <= value <= 122 else value for value in values)
    return len(output), output


def all_construct_verifier_oracle(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    """Enumerate ordered target constructions while preserving duplicate bank entries."""
    if (not isinstance(values, (tuple, list)) or not 2 <= len(values) <= 36
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    target_length = values[0]
    if not 0 <= target_length <= 6 or len(values) < target_length + 2:
        return -1, b""
    target_values = values[1:1 + target_length]
    if any(not 97 <= value <= 122 for value in target_values):
        return -1, b""
    target = bytes(target_values)
    position = 1 + target_length
    word_count = values[position]
    position += 1
    if not 0 <= word_count <= 4:
        return -1, b""
    words: list[bytes] = []
    for _ in range(word_count):
        if position >= len(values) or not 1 <= values[position] <= 6:
            return -1, b""
        word_length = values[position]
        position += 1
        if word_length > len(values) - position:
            return -1, b""
        word_values = values[position:position + word_length]
        if any(not 97 <= value <= 122 for value in word_values):
            return -1, b""
        words.append(bytes(word_values))
        position += word_length
    if position != len(values):
        return -1, b""
    paths: list[list[tuple[bytes, ...]]] = [[] for _ in range(target_length + 1)]
    paths[0] = [()]
    for start in range(target_length + 1):
        for word in words:
            end = start + len(word)
            if end <= target_length and target.startswith(word, start):
                paths[end].extend(prefix + (word,) for prefix in paths[start])
    constructions = paths[target_length]
    output = bytearray()
    for construction in constructions:
        output.append(len(construction))
        for word in construction:
            output.append(len(word))
            output.extend(word)
    return len(constructions), bytes(output)


def allocation_number_verifier_oracle(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    """Partition a bounded byte count into one-based contiguous ranges."""
    if (not isinstance(values, (tuple, list)) or len(values) != 2
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    total, partitions = values
    if not 1 <= total <= 1_000_000 or not 1 <= partitions <= 128 or partitions > total:
        return -1, b""
    block = total // partitions
    ranges = []
    for index in range(partitions):
        start = index * block + 1
        end = (index + 1) * block if index + 1 < partitions else total
        ranges.append(f"{start}-{end}")
    output = ",".join(ranges).encode("ascii")
    return len(output), output


def booths_algorithm_verifier_oracle(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    """Return the smallest cyclic ASCII rotation using a direct definition oracle."""
    if (not isinstance(values, (tuple, list)) or not 1 <= len(values) <= 256
            or any(type(value) is not int or not -(2**63) <= value < 2**63
                   or not 0 <= value <= 127 for value in values)):
        return -1, b""
    text = bytes(values)
    output = min(text[index:] + text[:index] for index in range(len(text)))
    return len(output), output


def association_verifier_oracle(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    """Return every nonempty itemset with support at least one, in canonical order."""
    if (not isinstance(values, (tuple, list)) or len(values) < 2
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    transaction_count, item_count = values[:2]
    transactions = values[2:]
    if (not 1 <= transaction_count <= 64 or not 1 <= item_count <= 11
            or len(transactions) != transaction_count
            or any(not 0 <= mask < (1 << item_count) for mask in transactions)):
        return -1, b""
    records = []
    for itemset_mask in range(1, 1 << item_count):
        support_count = sum((transaction & itemset_mask) == itemset_mask
                            for transaction in transactions)
        if support_count:
            records.append((itemset_mask.bit_count(), itemset_mask, support_count))
    records.sort()
    output = b"".join(struct.pack("<qq", mask, support)
                      for _, mask, support in records)
    return len(output), output


def auto_correlation_verifier_oracle(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    """Compute full linear autocorrelation directly from signed integer lags."""
    if (not isinstance(values, (tuple, list)) or not values
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    count, samples = values[0], values[1:]
    if (not 1 <= count <= 64 or len(samples) != count
            or any(not -1_000_000 <= sample <= 1_000_000 for sample in samples)):
        return -1, b""
    output = []
    for lag in range(-(count - 1), count):
        start = max(0, -lag)
        end = min(count, count - lag)
        output.append(sum(samples[index] * samples[index + lag] for index in range(start, end)))
    return len(output) * 8, b"".join(struct.pack("<q", value) for value in output)


def cross_correlation_verifier_oracle(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    """Accumulate every pair into its reversed-y linear-convolution position."""
    if (not isinstance(values, (tuple, list)) or not 4 <= len(values) <= 66
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    x_count, y_count = values[:2]
    if (not 1 <= x_count <= 32 or not 1 <= y_count <= 32
            or len(values) != 2 + x_count + y_count):
        return -1, b""
    x_values = values[2:2 + x_count]
    y_values = values[2 + x_count:]
    if (any(not -1_000_000 <= value <= 1_000_000 for value in x_values)
            or any(not -1_000_000 <= value <= 1_000_000 for value in y_values)):
        return -1, b""
    coefficients = [0] * (x_count + y_count - 1)
    for x_index, x_value in enumerate(x_values):
        for y_index, y_value in enumerate(y_values):
            coefficients[x_index + y_count - 1 - y_index] += x_value * y_value
    encoded = b"".join(struct.pack("<q", value) for value in coefficients)
    return len(encoded), encoded


def baconian_cipher_verifier_oracle(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    """Independent model of the Java, Python, and Rust Baconian dialects."""
    if (not isinstance(values, (tuple, list)) or not 2 <= len(values) <= 1026
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    mode, dialect, *payload = values
    if mode not in (0, 1) or dialect not in (0, 1, 2) or any(not 0 <= byte <= 127 for byte in payload):
        return -1, b""
    standard = tuple(f"{index:05b}".replace("0", "A").replace("1", "B") for index in range(26))
    python_codes = (
        "AAAAA", "AAAAB", "AAABA", "AAABB", "AABAA", "AABAB", "AABBA", "AABBB",
        "ABAAA", "BBBAA", "ABAAB", "ABABA", "ABABB", "ABBAA", "ABBAB", "ABBBA",
        "ABBBB", "BAAAA", "BAAAB", "BAABA", "BAABB", "BBBAB", "BABAA", "BABAB",
        "BABBA", "BABBB",
    )
    if mode == 0:
        output = bytearray()
        for byte in payload:
            upper = byte - 32 if 97 <= byte <= 122 else byte
            if dialect == 0:
                if 65 <= upper <= 90:
                    output.extend(standard[9 if upper == 73 else upper - 65].encode("ascii"))
            elif dialect == 1:
                if byte == 32:
                    output.append(32)
                elif 65 <= upper <= 90:
                    output.extend(python_codes[upper - 65].encode("ascii"))
                else:
                    return -1, b""
            else:
                if 65 <= upper <= 90:
                    index = upper - 65
                    if index >= 24:
                        return -1, b""
                    output.extend(standard[index].encode("ascii"))
                else:
                    output.append(byte)
        return len(output), bytes(output)
    if dialect == 0:
        if len(payload) % 5 or any(byte not in (65, 66) for byte in payload):
            return -1, b""
        output = bytearray()
        for start in range(0, len(payload), 5):
            code = int(bytes(payload[start:start + 5]).replace(b"A", b"0").replace(b"B", b"1"), 2)
            if code > 25:
                return -1, b""
            output.append(73 if code in (8, 9) else 65 + code)
        return len(output), bytes(output)
    if dialect == 1:
        if any(byte not in (32, 65, 66) for byte in payload):
            return -1, b""
        inverse = {code.encode("ascii"): 97 + index for index, code in enumerate(python_codes)}
        words = bytes(payload).split()
        output_words = []
        for word in words:
            if len(word) % 5:
                return -1, b""
            decoded = bytearray()
            for start in range(0, len(word), 5):
                value = inverse.get(word[start:start + 5])
                if value is None:
                    return -1, b""
                decoded.append(value)
            output_words.append(bytes(decoded))
        output = b" ".join(output_words)
        return len(output), output
    inverse = {code.encode("ascii"): 65 + index for index, code in enumerate(standard[:24])}
    encoded = bytes(payload)
    output = bytes(inverse.get(encoded[start:start + 5], 32) for start in range(0, len(encoded), 5))
    return len(output), output


def a1z26_cipher_verifier_oracle(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    """Map an ASCII letter sequence to its one-byte, one-based alphabet positions."""
    if (not isinstance(values, (tuple, list)) or len(values) > 66
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    output = bytearray()
    for value in values:
        if 65 <= value <= 90:
            output.append(value - 64)
        elif 97 <= value <= 122:
            output.append(value - 96)
        else:
            return -1, b""
    return len(output), bytes(output)


def a1z26_decipher_verifier_oracle(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    """Map one-based alphabet positions to lowercase ASCII letters."""
    if (not isinstance(values, (tuple, list)) or len(values) > 66
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)
            or any(not 1 <= value <= 26 for value in values)):
        return -1, b""
    output = bytes(96 + value for value in values)
    return len(output), output


def atbash_cipher_verifier_oracle(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    """Apply case-preserving Atbash to 7-bit ASCII, copying other bytes."""
    if (not isinstance(values, (tuple, list)) or len(values) > 66
            or any(type(value) is not int or not -(2**63) <= value < 2**63
                   or not 0 <= value <= 127 for value in values)):
        return -1, b""
    output = bytearray(values)
    for index, value in enumerate(output):
        if 65 <= value <= 90:
            output[index] = 155 - value
        elif 97 <= value <= 122:
            output[index] = 219 - value
    return len(output), bytes(output)


def title_case_oracle(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    """Model the package's ASCII title-case contract from its packed array."""
    if (not isinstance(values, (tuple, list)) or not values
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    byte_length, text_values = values[0], values[1:]
    if not 0 <= byte_length <= 256 or len(text_values) != byte_length:
        return -1, b""
    if byte_length == 0:
        return 0, b"\0"

    output = bytearray()
    at_word_start = True
    for index, value in enumerate(text_values):
        if 65 <= value <= 90 or 97 <= value <= 122:
            if at_word_start:
                output.append(value - 32 if 97 <= value <= 122 else value)
                at_word_start = False
            else:
                output.append(value + 32 if 65 <= value <= 90 else value)
        elif (value == 32 and not at_word_start and index + 1 < byte_length
              and text_values[index + 1] != 32):
            output.append(32)
            at_word_start = True
        else:
            return -1, b""
    if at_word_start:
        return -1, b""
    output.append(0)
    return byte_length, bytes(output)


def weight_conversions_oracle(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    """Model Ruby's six strings using decimal rounding of each float's shortest repr."""
    if (not isinstance(values, (tuple, list)) or len(values) != 2
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    operation, amount = values
    if not 0 <= operation <= 5 or not -1_000_000 <= amount <= 1_000_000:
        return -1, b""

    def ruby_float_text(value: float) -> str:
        rounded = Decimal(str(value)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
        text = format(rounded, "f")
        return text[:-1] if text.endswith("0") else text

    if operation == 0:
        text = f"{amount} kg = {amount * 1000} g"
    elif operation == 1:
        text = f"{amount} g = {amount // 1000} kg"
    elif operation == 2:
        text = f"{amount} lb = {amount * 16} oz"
    elif operation == 3:
        text = f"{amount} oz = {amount // 16} lb"
    elif operation == 4:
        text = f"{amount} kg = {ruby_float_text(float(amount) * 2.205)} lb"
    else:
        text = f"{amount} lb = {ruby_float_text(float(amount) / 2.205)} kg"
    encoded = text.encode("ascii") + b"\0"
    return len(encoded) - 1, encoded


def red_black_tree_oracle(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    """Model unique-key tree traces with a set and sorted final keys."""
    if (not isinstance(values, (tuple, list)) or not values
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    operation_count = values[0]
    if not 0 <= operation_count <= 128 or len(values) != 1 + 2 * operation_count:
        return -1, b""
    keys: set[int] = set()
    searches: list[int] = []
    for offset in range(1, len(values), 2):
        operation, key = values[offset:offset + 2]
        if operation not in (0, 1, 2) or not -(2**31) <= key <= 2**31 - 1:
            return -1, b""
        if operation == 0:
            if key in keys:
                return -1, b""
            keys.add(key)
        elif operation == 1:
            searches.append(int(key in keys))
        else:
            if key not in keys:
                return -1, b""
            keys.remove(key)
    ordered = sorted(keys)
    output_values = [len(ordered), *ordered, len(searches), *searches]
    output = b"".join(struct.pack("<q", value) for value in output_values)
    return len(output), output


def corpus(workload: dict, algorithm: str) -> tuple[str, int]:
    records: list[tuple[tuple[int, ...], int, bytes, int | None]] = []
    null_input_cases: set[tuple[tuple[int, ...], int | None]] = set()
    if algorithm == "eulerian_path":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if (type(default_capacity) is not int
                or default_capacity < MAX_EULERIAN_PATH_OUTPUT_BYTES):
            raise ValueError("invalid Eulerian-path output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = eulerian_path_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = result, output

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = eulerian_path_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = case.get("capacity_error_result", -2), b""
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        for vertex_count in range(4):
            possible_edges = [(source, destination)
                              for source in range(vertex_count)
                              for destination in range(vertex_count)]
            for edge_mask in range(1 << len(possible_edges)):
                edges = tuple(edge for index, edge in enumerate(possible_edges)
                              if edge_mask & (1 << index))
                values = (vertex_count, len(edges), *(point for edge in edges for point in edge))
                add(values)

        rng = random.Random(20261016)
        for _ in range(256):
            vertex_count = rng.randrange(MAX_EULERIAN_PATH_VERTICES + 1)
            edge_count = rng.randrange(MAX_EULERIAN_PATH_EDGES + 1) if vertex_count else 0
            edges = tuple((rng.randrange(vertex_count), rng.randrange(vertex_count))
                          for _ in range(edge_count))
            values = (vertex_count, edge_count, *(point for edge in edges for point in edge))
            add(values)

        maximum_open_path = (MAX_EULERIAN_PATH_VERTICES,
                             MAX_EULERIAN_PATH_VERTICES - 1,
                             *(point for vertex in range(MAX_EULERIAN_PATH_VERTICES - 1)
                               for point in (vertex, vertex + 1)))
        add(maximum_open_path)
        maximum_loop_multigraph = (1, MAX_EULERIAN_PATH_EDGES,
                                   *([0, 0] * MAX_EULERIAN_PATH_EDGES))
        add(maximum_loop_multigraph)
        add((3, 2, 0, 1, 1, 2), 3 * 8 - 1)
        malformed = (
            (), (0,), (-1, 0), (MAX_EULERIAN_PATH_VERTICES + 1, 0),
            (0, 1, 0, 0), (1, -1), (1, MAX_EULERIAN_PATH_EDGES + 1),
            (2, 1, 0), (1, 1, 1, 0),
            (0, 0, *([0] * (MAX_EULERIAN_PATH_INPUT_LENGTH - 1))),
        )
        for values in malformed:
            add(tuple(values))

        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "dice_thrower":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < MAX_DICE_THROWER_OUTPUT_BYTES:
            raise ValueError("invalid dice-thrower output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = dice_thrower_oracle(values, capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = dice_thrower_oracle(values, capacity)
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        for target in range(9):
            values = (target,)
            result, output = dice_thrower_oracle(values, default_capacity)
            add(values)
            if result > 0:
                add(values, result - 1)
        for malformed in ((), (-1,), (9,), (1, 1), tuple([0] * (MAX_DICE_THROWER_INPUT_LENGTH + 1))):
            add(malformed)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "hampel_filter":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < MAX_HAMPEL_FILTER_OUTPUT_BYTES:
            raise ValueError("invalid Hampel-filter output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = hampel_filter_oracle(values, capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = hampel_filter_oracle(values, capacity)
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)
        for _ in range(128):
            count = rng.randrange(MAX_HAMPEL_FILTER_INPUT_LENGTH)
            samples = tuple(rng.randint(-1000, 1000) for _ in range(count))
            values = (count, *samples)
            result, _ = hampel_filter_oracle(values, default_capacity)
            add(values)
            if result > 0:
                add(values, result - 1)
        maximum_values = (MAX_HAMPEL_FILTER_INPUT_LENGTH - 1,
                          *tuple(-1000 if index % 2 == 0 else 1000
                                 for index in range(MAX_HAMPEL_FILTER_INPUT_LENGTH - 1)))
        add(maximum_values)
        for malformed in ((), (-1,), (129,), (2, 1), (1, 1001),
                          tuple([0] * (MAX_HAMPEL_FILTER_INPUT_LENGTH + 1))):
            add(malformed)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "intersection_of_two_arrays":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < MAX_INTERSECTION_OF_TWO_ARRAYS_OUTPUT_BYTES:
            raise ValueError("invalid two-array intersection output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = intersection_of_two_arrays_oracle(values, capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = intersection_of_two_arrays_oracle(values, capacity)
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)
        for _ in range(128):
            first_length = rng.randint(0, MAX_INTERSECTION_OF_TWO_ARRAYS_ARRAY_LENGTH)
            second_length = rng.randint(0, MAX_INTERSECTION_OF_TWO_ARRAYS_ARRAY_LENGTH)
            first = tuple(sorted(rng.randint(-1000, 1000) for _ in range(first_length)))
            second = tuple(sorted(rng.randint(-1000, 1000) for _ in range(second_length)))
            values = (first_length, *first, second_length, *second)
            add(values)
            minimum_length = min(first_length, second_length)
            if minimum_length > 0:
                add(values, minimum_length * 4 - 1)

        malformed = (
            (), (1,), (-1, 0), (65, 0), (1, 5), (1, 5, 2, 5),
            (2, 3, 1, 0, 0), (1, -(2**31) - 1, 0),
            (1, 2**31, 0), tuple([0] * (MAX_INTERSECTION_OF_TWO_ARRAYS_INPUT_LENGTH + 1)),
        )
        for values in malformed:
            add(values)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "union_of_two_arrays":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < MAX_UNION_OF_TWO_ARRAYS_OUTPUT_BYTES:
            raise ValueError("invalid two-array union output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = union_of_two_arrays_oracle(values, capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = union_of_two_arrays_oracle(values, capacity)
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)
        for _ in range(128):
            first_length = rng.randint(0, MAX_UNION_OF_TWO_ARRAYS_ARRAY_LENGTH)
            second_length = rng.randint(0, MAX_UNION_OF_TWO_ARRAYS_ARRAY_LENGTH)
            first = tuple(sorted(rng.randint(-1000, 1000) for _ in range(first_length)))
            second = tuple(sorted(rng.randint(-1000, 1000) for _ in range(second_length)))
            values = (first_length, *first, second_length, *second)
            add(values)
            if first_length + second_length > 0:
                add(values, (first_length + second_length) * 4 - 1)

        malformed = (
            (), (1,), (-1, 0), (65, 0), (1, 5), (1, 5, 2, 5),
            (2, 3, 1, 0, 0), (1, -(2**31) - 1, 0),
            (1, 2**31, 0), tuple([0] * (MAX_UNION_OF_TWO_ARRAYS_INPUT_LENGTH + 1)),
        )
        for values in malformed:
            add(values)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "get_products_of_all_other_elements":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if (type(default_capacity) is not int
                or default_capacity < MAX_GET_PRODUCTS_OF_ALL_OTHER_ELEMENTS_OUTPUT_BYTES):
            raise ValueError("invalid products-of-other-elements output workspace size")

        def evaluate(values: tuple[int, ...], capacity: int) -> tuple[int, bytes]:
            required_count, output = get_products_of_all_other_elements_oracle(values)
            if required_count < 0:
                return required_count, b""
            if capacity < len(output):
                return -2, b""
            return required_count, output

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = evaluate(values, capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            if (type(capacity) is not int or not 0 <= capacity <= MAX_OUTPUT_CAPACITY
                    or case.get("input_length") not in (None, len(values))
                    or len(values) > MAX_GET_PRODUCTS_OF_ALL_OTHER_ELEMENTS_INPUT_LENGTH
                    or any(type(value) is not int or not -(2**63) <= value < 2**63
                           for value in values)):
                raise ValueError(f"invalid get_products_of_all_other_elements workload case: {case['id']}")
            result, output = evaluate(values, capacity)
            if (case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        for length in range(5):
            for elements in product((-2, -1, 0, 1, 2), repeat=length):
                values = (length, *elements)
                add(values)
        rng = random.Random(20261016)
        for _ in range(128):
            length = rng.randint(0, MAX_GET_PRODUCTS_OF_ALL_OTHER_ELEMENTS_ARRAY_LENGTH)
            elements = tuple(rng.randint(-2, 2) for _ in range(length))
            values = (length, *elements)
            add(values)
            if length >= 2:
                add(values, length * 8 - 1)

        malformed = (
            (), (-1,), (33,), (1,), (2, 1), (1, 0, 1), (2, 3, 0),
            (2, -2, 2, 1), (-(2**63),), (2**63 - 1,),
            (32, *([2] * 33)),
        )
        for values in malformed:
            if len(values) <= MAX_GET_PRODUCTS_OF_ALL_OTHER_ELEMENTS_INPUT_LENGTH:
                add(values)

        null_values = (1, 0)
        null_capacity = 0
        null_key = (null_values, null_capacity)
        if null_key in cases:
            raise ValueError("get_products_of_all_other_elements null-input canary collides with another case")
        cases[null_key] = (-1, b"")
        null_input_cases.add(null_key)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "correlation_matrix_analysis":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if (type(default_capacity) is not int
                or default_capacity < MAX_CORRELATION_MATRIX_ANALYSIS_OUTPUT_BYTES):
            raise ValueError("invalid correlation-matrix output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = correlation_matrix_analysis_oracle(values, capacity)

        def encode_columns(columns: tuple[tuple[int, ...], ...]) -> tuple[int, ...]:
            variable_count = len(columns)
            return (CORRELATION_MATRIX_ANALYSIS_OBSERVATIONS, variable_count,
                    *(columns[col][row] for row in range(CORRELATION_MATRIX_ANALYSIS_OBSERVATIONS)
                      for col in range(variable_count)))

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = correlation_matrix_analysis_oracle(values, capacity)
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)
        for _ in range(128):
            variable_count = rng.randint(2, MAX_CORRELATION_MATRIX_ANALYSIS_VARIABLES)
            columns = tuple(tuple(rng.sample(range(-1000, 1001), CORRELATION_MATRIX_ANALYSIS_OBSERVATIONS))
                            for _ in range(variable_count))
            values = encode_columns(columns)
            result, _ = correlation_matrix_analysis_oracle(values)
            add(values)
            if result > 0:
                add(values, result)
                add(values, result - 1)

        maximum_columns = tuple(
            (1000 - 100 * col, 500 - 50 * col, -500 + 30 * col, -1000 + 100 * col)
            for col in range(MAX_CORRELATION_MATRIX_ANALYSIS_VARIABLES))
        maximum_values = encode_columns(maximum_columns)
        add(maximum_values, MAX_CORRELATION_MATRIX_ANALYSIS_OUTPUT_BYTES)
        add(maximum_values, MAX_CORRELATION_MATRIX_ANALYSIS_OUTPUT_BYTES - 1)

        malformed = (
            (), (4, 1, 1, 2, 3, 4), (3, 2, 1, 2, 3, 4, 5, 6),
            (4, 2, 1, 2, 3, 4, 5), (4, 2, 1, 2, 3, 4, 5, 6, 7, 8, 9),
            (4, 2, 1001, 2, 3, 4, 5, 6, 7, 8),
            (4, 2, 1, 5, 1, 6, 1, 7, 1, 8),
            (4, 6, *([1] * (CORRELATION_MATRIX_ANALYSIS_OBSERVATIONS * 6))),
        )
        for values in malformed:
            add(values)

        null_values = (4, 2, -1000, 1000, -999, 999, -998, 998, -997, 997)
        null_key = (null_values, default_capacity)
        if null_key in cases:
            raise ValueError("correlation-matrix null-input canary collides with another case")
        cases[null_key] = (-1, b"")
        null_input_cases.add(null_key)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "unique_letters_count":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < MAX_UNIQUE_LETTERS_COUNT_OUTPUT_BYTES:
            raise ValueError("invalid unique-letter output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = unique_letters_count_oracle(values, capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = unique_letters_count_oracle(values, capacity)
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)
        for _ in range(128):
            text_length = rng.randint(0, MAX_UNIQUE_LETTERS_COUNT_INPUT_LENGTH)
            text = tuple(rng.randint(0, 127) for _ in range(text_length))
            values = (text_length, *text)
            add(values)
            required_capacity = min(text_length, 26) * 8
            if required_capacity > 0:
                add(values, required_capacity - 1)

        malformed = (
            (), (-1,), (257,), (1,), (2, 65), (0, 65),
            (1, -1), (1, 128),
            tuple([0] * (MAX_UNIQUE_LETTERS_COUNT_INPUT_LENGTH + 2)),
        )
        for values in malformed:
            add(values)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "convex_hull_graham":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < MAX_CONVEX_HULL_GRAHAM_OUTPUT_BYTES:
            raise ValueError("invalid convex-hull output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = convex_hull_graham_oracle(values, capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = convex_hull_graham_oracle(values, capacity)
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)
        for _ in range(128):
            point_count = rng.randint(3, MAX_CONVEX_HULL_GRAHAM_POINTS)
            for _attempt in range(64):
                xs = sorted(rng.sample(range(-2000, 2001), point_count))
                values = tuple(coordinate for x in xs
                               for coordinate in (x, rng.randint(-2000, 2000)))
                result, output = convex_hull_graham_oracle(values, default_capacity)
                if result >= 0:
                    add(values)
                    if output:
                        add(values, len(output) - 1)
                    break
            else:
                raise ValueError("could not generate a valid convex-hull corpus case")

        malformed = (
            (), (0, 0, 1, 1), (0, 0, 1, 1, 2),
            (0, 0, 0, 1, 2, 0), (0, 0, 1, 0, 2, 0),
            (0, 0, 1, 2001, 2, 0),
            tuple([0] * (MAX_CONVEX_HULL_GRAHAM_INPUT_LENGTH + 2)),
            (-(2**63), 0, 0, 1, 1, 2), (0, 0, 1, 2, 2**63 - 1, 0),
        )
        for values in malformed:
            add(values)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "sorted_arrays_intersection":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < MAX_SORTED_ARRAYS_INTERSECTION_OUTPUT_BYTES:
            raise ValueError("invalid sorted-arrays-intersection output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = sorted_arrays_intersection_oracle(values, capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = sorted_arrays_intersection_oracle(values, capacity)
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)
        for _ in range(128):
            arrays = [tuple(sorted(rng.sample(range(-2000, 2001),
                                              rng.randint(0, MAX_SORTED_ARRAYS_INTERSECTION_ARRAY_LENGTH))))
                      for _array_index in range(3)]
            values = tuple(value for array in arrays for value in (len(array), *array))
            add(values)
            minimum_length = min(map(len, arrays))
            if minimum_length > 0:
                add(values, minimum_length * 4 - 1)

        malformed = (
            (), (1,), (-1, 0), (65, 0), (1, 5), (1, 5, 2, 5),
            (2, 3, 1, 0, 0), (1, -(2**31) - 1, 0),
            (1, 2**31, 0), tuple([0] * (MAX_SORTED_ARRAYS_INTERSECTION_INPUT_LENGTH + 1)),
        )
        for values in malformed:
            add(values)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "compress":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < MAX_COMPRESS_OUTPUT_BYTES:
            raise ValueError("invalid compress output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = compress_oracle(values, capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = compress_oracle(values, capacity)
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)
        for _ in range(128):
            count = rng.randint(0, MAX_COMPRESS_LENGTH)
            source: list[int] = []
            for _index in range(count):
                if source and rng.random() < 0.55:
                    source.append(source[-1])
                else:
                    source.append(rng.randint(-1000, 1000))
            values = (count, *source)
            add(values)
            if count > 0:
                add(values, count * 4 - 1)

        malformed = (
            (), (-1,), (MAX_COMPRESS_LENGTH + 1,), (2, 7),
            (1, 7, 8), (1, -(2**31) - 1), (1, 2**31),
            tuple([0] * (MAX_COMPRESS_INPUT_LENGTH + 1)),
        )
        for values in malformed:
            add(values)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "combination_sum":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        maximum_output_bytes = MAX_COMBINATION_SUM_OUTPUT_WORDS * 8
        if type(default_capacity) is not int or default_capacity < maximum_output_bytes:
            raise ValueError("invalid combination-sum output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = combination_sum_oracle(values, capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = combination_sum_oracle(values, capacity)
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)
        for _ in range(128):
            candidate_count = rng.randint(1, MAX_COMBINATION_SUM_CANDIDATES)
            candidates = tuple(sorted(rng.sample(range(1, 25), candidate_count)))
            values = (candidate_count, rng.randint(0, MAX_COMBINATION_SUM_TARGET), *candidates)
            add(values)
            _, output = combination_sum_oracle(values)
            add(values, len(output) - 1)

        malformed = (
            (), (1,), (0, 0, 1), (9, 0, *range(1, 10)),
            (1, -1, 1), (1, MAX_COMBINATION_SUM_TARGET + 1, 1),
            (2, 5, 1), (2, 5, 1, 1), (2, 5, 2, 1),
            (1, 5, 0), (1, 5, 25), (1, 5, 1, 2),
            tuple([1, 1, *([1] * (MAX_COMBINATION_SUM_INPUT_LENGTH - 1))]),
        )
        for values in malformed:
            add(values)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "dilation_operation":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < MAX_DILATION_OPERATION_OUTPUT_BYTES:
            raise ValueError("invalid dilation-operation output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = dilation_operation_oracle(values, capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = dilation_operation_oracle(values, capacity)
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)
        for _ in range(128):
            rows = rng.randint(1, MAX_DILATION_OPERATION_DIMENSION)
            columns = rng.randint(1, MAX_DILATION_OPERATION_DIMENSION)
            image = tuple(rng.randrange(2) for _ in range(rows * columns))
            kernel = tuple(rng.randrange(2) for _ in range(9))
            values = (rows, columns, *image, *kernel)
            add(values)
            add(values, rows * columns * 4 - 1)

        malformed = (
            (), (1, 1), (0, 1, *([0] * 10)),
            (17, 1, *([0] * (17 + 9))),
            (1, 17, *([0] * (17 + 9))),
            (1, 1, 2, *([0] * 9)),
            (1, 1, 0, 0, *([0] * 9)),
            (1, 1, 0, *([0] * 8)),
            tuple([1, 1, *([0] * 265)]),
        )
        for values in malformed:
            add(values)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "nearest_neighbor_interpolation":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < MAX_NEAREST_NEIGHBOR_OUTPUT_BYTES:
            raise ValueError("invalid nearest-neighbor interpolation output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = nearest_neighbor_interpolation_oracle(values, capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = nearest_neighbor_interpolation_oracle(values, capacity)
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)
        for _ in range(128):
            rows = rng.randint(1, MAX_NEAREST_NEIGHBOR_DIMENSION)
            columns = rng.randint(1, MAX_NEAREST_NEIGHBOR_DIMENSION)
            pixels = tuple(rng.randrange(256) for _ in range(rows * columns))
            values = (rows, columns, *pixels)
            add(values)
            output_bytes = ((3 * rows) // 2) * ((3 * columns) // 2)
            add(values, output_bytes - 1)

        malformed = (
            (), (1,), (0, 1, 0), (17, 1, *([0] * 17)),
            (1, 17, *([0] * 17)), (1, 1, 256), (1, 1, 0, 1),
            tuple([1, 1, *([0] * MAX_NEAREST_NEIGHBOR_INPUT_LENGTH)]),
        )
        for values in malformed:
            add(values)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "non_empty_subsequences":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if (type(default_capacity) is not int
                or default_capacity < MAX_NON_EMPTY_SUBSEQUENCES_OUTPUT_BYTES):
            raise ValueError("invalid non-empty-subsequences output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = non_empty_subsequences_oracle(list(values))
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = result, output

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = non_empty_subsequences_oracle(list(values))
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)
            if result >= 0:
                add(values, len(output) - 1)

        rng = random.Random(20261016)
        for length in range(1, 9):
            for _ in range(24):
                values = (length, *(rng.choice((0, 65, 97, 233, 0x1F642))
                                    for _ in range(length)))
                add(values)
                _, output = non_empty_subsequences_oracle(list(values))
                add(values, len(output) - 1)

        malformed = (
            (), (0,), (1,), (1, 65, 66), (2, 65),
            (1, 0xD800), (1, 0xDFFF), (1, 0x110000),
            (8, *([65] * 9)),
        )
        for values in malformed:
            add(values)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "range_in_sorted_array":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < MAX_RANGE_IN_SORTED_ARRAY_OUTPUT_BYTES:
            raise ValueError("invalid range-in-sorted-array output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = range_in_sorted_array_oracle(values, capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = range_in_sorted_array_oracle(values, capacity)
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)
        for _ in range(128):
            count = rng.randrange(MAX_RANGE_IN_SORTED_ARRAY_LENGTH + 1)
            values_array = sorted(rng.randint(-(2**31), 2**31 - 1) for _ in range(count))
            key = rng.randint(-(2**31), 2**31 - 1)
            values = (count, *values_array, key)
            add(values)
            add(values, MAX_RANGE_IN_SORTED_ARRAY_OUTPUT_BYTES - 1)
        max_values = (MAX_RANGE_IN_SORTED_ARRAY_LENGTH,
                      *tuple(range(-(2**31), -(2**31) + MAX_RANGE_IN_SORTED_ARRAY_LENGTH)),
                      2**31 - 1)
        add(max_values)
        for malformed in ((), (0,), (-1, 0), (513, 0), (2, 1, 0, 1),
                          (1, 2**31, 0), (1, 0, 2**31), (1, 0),
                          tuple([0] * (MAX_RANGE_IN_SORTED_ARRAY_INPUT_LENGTH + 1))):
            add(malformed)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "complex_arithmetic":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < MAX_COMPLEX_ARITHMETIC_OUTPUT_BYTES:
            raise ValueError("invalid complex-arithmetic output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = complex_arithmetic_oracle(values, capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = complex_arithmetic_oracle(values, capacity)
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)
        for _ in range(128):
            operation = rng.randrange(6)
            if operation == 3:
                br = rng.randint(-50, 50)
                bi = rng.randint(-50, 50)
                if br == 0 and bi == 0:
                    br = 1
                qr = rng.randint(-100, 100)
                qi = rng.randint(-100, 100)
                ar = qr * br - qi * bi
                ai = qr * bi + qi * br
            else:
                ar, ai, br, bi = (rng.randint(-100_000, 100_000) for _ in range(4))
            values = (operation, ar, ai, br, bi)
            add(values)
            add(values, MAX_COMPLEX_ARITHMETIC_OUTPUT_BYTES - 1)

        malformed = (
            (), (0, 1, 2, 3), (0, 1, 2, 3, 4, 5),
            (-1, 0, 0, 0, 0), (6, 0, 0, 0, 0),
            (0, 100_001, 0, 0, 0), (0, 0, -100_001, 0, 0),
            (3, 1, 1, 0, 0), (3, 1, 1, 2, 1),
            (0, -(2**63), 0, 0, 0),
        )
        for values in malformed:
            add(values)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "complex_number_multiply":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < MAX_COMPLEX_NUMBER_MULTIPLY_OUTPUT_LENGTH:
            raise ValueError("invalid complex-number output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = complex_number_multiply_oracle(values, capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = complex_number_multiply_oracle(values, capacity)
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)
        for _ in range(128):
            left_real = rng.randint(-32767, 32767)
            left_imaginary = rng.randint(-32767, 32767)
            right_real = rng.randint(-32767, 32767)
            right_imaginary = rng.randint(-32767, 32767)
            left = f"{left_real}+{left_imaginary}i".encode("ascii")
            right = f"{right_real}+{right_imaginary}i".encode("ascii")
            values = (len(left), len(right), *left, *right)
            add(values)

        max_left = b"32767+32767i"
        max_right = b"-32767+32767i"
        maximum_values = (len(max_left), len(max_right), *max_left, *max_right)
        add(maximum_values, MAX_COMPLEX_NUMBER_MULTIPLY_OUTPUT_LENGTH)
        add(maximum_values, 1)
        for values in (
            (), (4,), (3, 4), (4, 4, *b"1+1i", *b"1+1i"),
            (4, 4, *b"1++i", *b"1+1i"),
            (4, 4, *b"1+1i", *b"1+1i", 0),
            (4, 4, *b"1+1i", *b"1+1i"[:-1], 128),
            (8, 4, *b"32768+0i", *b"1+0i"),
            (9, 4, *b"-32768+0i", *b"1+0i"),
            (65, 4, *([48] * 65), *b"1+0i"),
            tuple([0] * (MAX_COMPLEX_NUMBER_MULTIPLY_INPUT_LENGTH + 1)),
        ):
            add(values)

        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "cusum_detector":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < MAX_CUSUM_DETECTOR_OUTPUT_BYTES:
            raise ValueError("invalid CUSUM detector output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = cusum_detector_oracle(values, capacity)
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = cusum_detector_oracle(values, capacity)
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)
        for _ in range(128):
            count = rng.randrange(MAX_CUSUM_DETECTOR_INPUT_LENGTH - 4)
            target = rng.randint(-1000, 1000)
            sigma = rng.randint(1, 1000)
            allowance = rng.randint(0, 1000)
            threshold = rng.randint(1, 1000)
            samples = [rng.randint(-1000, 1000) for _ in range(count)]
            add((count, target, sigma, allowance, threshold, *samples))
        for malformed in ((), (0,), (129, 0, 1, 0, 1), (1, 0, 1, 0, 1),
                           (1, 0, 0, 0, 1, 0), (0, 0, 1, 0, 1, 7),
                           (1, 0, 1, 0, 1, 1001)):
            add(malformed)
        add((1, 0, 1, 0, 1, 1), 7)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "difference_array":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < MAX_DIFFERENCE_ARRAY_OUTPUT_BYTES:
            raise ValueError("invalid difference-array output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = difference_array_oracle(values, capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = difference_array_oracle(values, capacity)
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)
        for _ in range(128):
            length = rng.randint(1, 64)
            update_count = rng.randint(0, 64)
            values = [length, update_count]
            values.extend(rng.randint(-1_000_000, 1_000_000) for _ in range(length))
            for _ in range(update_count):
                left = rng.randrange(length)
                right = rng.randrange(left, length)
                values.extend((left, right, rng.randint(-1_000_000, 1_000_000)))
            add(tuple(values))

        maximum_values = (64, 64, *([1_000_000] * 64),
                          *(item for _ in range(64) for item in (0, 63, 1_000_000)))
        add(maximum_values, MAX_DIFFERENCE_ARRAY_OUTPUT_BYTES)
        add(maximum_values, MAX_DIFFERENCE_ARRAY_OUTPUT_BYTES - 1)
        for values in (
            (), (1,), (0, 0), (65, 0), (1, -1, 0), (1, 65, 0),
            (1, 0, 1_000_001), (1, 0, 0, 0), (1, 1, 0, 1, 0, 1),
            (1, 1, 0, 0, 0, 1), (1, 1, 0, 0, 1, 1_000_001),
            (1, 1, 0, 0, 0, 2**63),
            tuple([1, 64, 0] + [0, 0, 0] * 64),
            tuple([0] * (MAX_DIFFERENCE_ARRAY_INPUT_LENGTH + 1)),
        ):
            add(values)

        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "damped_oscillator":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < MAX_DAMPED_OSCILLATOR_OUTPUT_BYTES:
            raise ValueError("invalid damped-oscillator output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = damped_oscillator_oracle(values, capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = damped_oscillator_oracle(values, capacity)
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)
        for _ in range(256):
            add((rng.randint(1, 1024), rng.randint(0, 1024),
                 rng.randint(-1024, 1024), rng.randint(-1024, 1024),
                 rng.randint(1, 1024)))

        for values in (
            (1, 0, -1024, -1024, 1),
            (1024, 1024, 1024, 1024, 1024),
            (0, 0, 0, 0, 1), (1025, 0, 0, 0, 1),
            (1, -1, 0, 0, 1), (1, 1025, 0, 0, 1),
            (1, 0, -1025, 0, 1), (1, 0, 0, 1025, 1),
            (1, 0, 0, 0, 0), (1, 0, 0, 0, 1025),
            (), (1, 0, 0, 0), (1, 0, 0, 0, 1, 1),
            (2**63, 0, 0, 0, 1), (-(2**63), 0, 0, 0, 1),
        ):
            add(values)
        add((1024, 1024, 1024, -1024, 1024), MAX_DAMPED_OSCILLATOR_OUTPUT_BYTES - 1)

        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "convolution":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < MAX_CONVOLUTION_OUTPUT_BYTES:
            raise ValueError("invalid convolution output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = convolution_oracle(values, capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = convolution_oracle(values, capacity)
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)
        for _ in range(128):
            a_count = rng.randint(1, 64)
            b_count = rng.randint(1, 64)
            values = (a_count, b_count,
                      *(rng.randint(-1_000_000, 1_000_000) for _ in range(a_count + b_count)))
            add(values)

        maximum_values = (64, 64, *([1_000_000] * 128))
        add(maximum_values, MAX_CONVOLUTION_OUTPUT_BYTES)
        add(maximum_values, MAX_CONVOLUTION_OUTPUT_BYTES - 1)
        for values in (
            (), (1, 1, 1), (0, 1, 1, 1), (65, 1), (1, 65),
            (1, 1, 1_000_001, 0), (1, 1, -(2**63), 0),
            (1, 1, 2**63, 0), (65, 64, *([0] * 129)),
            tuple([0] * (MAX_CONVOLUTION_INPUT_LENGTH + 1)),
        ):
            add(values)

        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "coordinate_compression":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < MAX_COORDINATE_COMPRESSION_OUTPUT_LENGTH:
            raise ValueError("invalid coordinate-compression output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = coordinate_compression_oracle(values, capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = coordinate_compression_oracle(values, capacity)
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)
        for _ in range(128):
            count = rng.randrange(MAX_COORDINATE_COMPRESSION_INPUT_LENGTH)
            add((count, *(rng.randint(-(2**31), 2**31 - 1) for _ in range(count))))

        maximum_values = (MAX_COORDINATE_COMPRESSION_INPUT_LENGTH - 1,
                          *range(-(MAX_COORDINATE_COMPRESSION_INPUT_LENGTH - 1) // 2,
                                 MAX_COORDINATE_COMPRESSION_INPUT_LENGTH // 2))
        add(maximum_values, MAX_COORDINATE_COMPRESSION_OUTPUT_LENGTH)
        add(maximum_values, MAX_COORDINATE_COMPRESSION_OUTPUT_LENGTH - 1)
        for values in (
            (), (-1,), (129,), (2, 1),
            (1, 2**31), (1, -(2**31) - 1),
            (MAX_COORDINATE_COMPRESSION_INPUT_LENGTH, *range(MAX_COORDINATE_COMPRESSION_INPUT_LENGTH)),
            (0, 0),
        ):
            add(values)

        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "flash_sort":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < MAX_FLASH_SORT_OUTPUT_BYTES:
            raise ValueError("invalid Flash Sort output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = flash_sort_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = flash_sort_oracle(values)
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_output = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)
        valid_lengths = (0, 1, *range(3, MAX_FLASH_SORT_LENGTH + 1))
        for _ in range(128):
            length = rng.choice(valid_lengths)
            add(tuple(rng.randint(-1_000_000, 1_000_000) for _ in range(length)))

        maximum_values = tuple(range(-32, 32))
        add(maximum_values, MAX_FLASH_SORT_OUTPUT_BYTES)
        add(maximum_values, MAX_FLASH_SORT_OUTPUT_BYTES - 1)
        for values in (
            (0, 1), (7, 7), (7, 1),
            (-1_000_001,), (1_000_001,),
            (MAX_FLASH_SORT_LENGTH + 1,),
            tuple([0] * (MAX_FLASH_SORT_INPUT_LENGTH + 1)),
        ):
            add(values)

        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "string_compression":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < MAX_STRING_COMPRESSION_OUTPUT_LENGTH:
            raise ValueError("invalid string-compression output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = string_compression_oracle(values, capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = string_compression_oracle(values, capacity)
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        for codepoint in range(128):
            add((codepoint,))
        for length in range(7):
            for values in product((0, 49, 65), repeat=length):
                add(values)

        rng = random.Random(20261016)
        for _ in range(128):
            add(tuple(rng.randrange(128) for _ in range(rng.randrange(MAX_STRING_COMPRESSION_INPUT_LENGTH + 1))))

        maximum_output = tuple(range(MAX_STRING_COMPRESSION_OUTPUT_LENGTH))
        add(maximum_output, MAX_STRING_COMPRESSION_OUTPUT_LENGTH)
        add(maximum_output, MAX_STRING_COMPRESSION_OUTPUT_LENGTH - 1)
        add((65, 65), 1)
        for values in ((-1,), (128,), tuple([65] * (MAX_STRING_COMPRESSION_INPUT_LENGTH + 1))):
            add(values)

        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "chudnovsky_algorithm":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid Chudnovsky output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = chudnovsky_algorithm_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = chudnovsky_algorithm_oracle(values)
            capacity = case.get("workspace_bytes", default_capacity)
            expected_result = -2 if result >= 0 and capacity < len(output) else result
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        for precision in range(1, MAX_CHUDNOVSKY_PRECISION + 1):
            add((precision,))
        for values in ((), (0,), (-1,), (MAX_CHUDNOVSKY_PRECISION + 1,), (2, 3),
                       (2**63,), (-(2**63),)):
            add(values)
        for capacity in range(MAX_CHUDNOVSKY_PRECISION):
            add((MAX_CHUDNOVSKY_PRECISION,), capacity)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "cramers_rule_2x2":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < CRAMERS_RULE_2X2_OUTPUT_BYTES:
            raise ValueError("invalid Cramer's rule output workspace size")
        absolute_tolerance = workload["output"].get("absolute_tolerance", 0.0)
        relative_tolerance = workload["output"].get("relative_tolerance", 0.0)

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = cramers_rule_2x2_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = cramers_rule_2x2_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            actual = (struct.unpack("<dd", output) if result == 2 else ())
            expected = case.get("expected_output", [])
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != result
                    or len(expected) != len(actual)
                    or any(not math.isclose(a, b, abs_tol=absolute_tolerance,
                                            rel_tol=relative_tolerance)
                           for a, b in zip(actual, expected))):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)
        for _ in range(128):
            while True:
                a1 = rng.randint(-1_000_000, 1_000_000)
                b1 = rng.randint(-1_000_000, 1_000_000)
                if a1 != 0 or b1 != 0:
                    break
            while True:
                a2, b2 = rng.randint(-1_000_000, 1_000_000), rng.randint(-1_000_000, 1_000_000)
                if a1 * b2 != a2 * b1:
                    break
            add((a1, b1, rng.randint(-1_000_000, 1_000_000),
                 a2, b2, rng.randint(-1_000_000, 1_000_000)))

        for values in (
            (), (1, 2, 3, 4, 5), (1, 2, 3, 4, 5, 6, 7),
            (1_000_001, 0, 0, 0, 1, 0), (0, 0, 0, 0, 0, 0),
            (1, 2, 3, 2, 4, 6), (1, 2, 3, 2, 4, 7),
            (-(2**63), 0, 0, 0, 1, 0),
            (1,) * (MAX_CRAMERS_RULE_2X2_INPUT_LENGTH + 1),
        ):
            add(values)
        capacity_probe = (1, 1, 3, 1, -1, 1)
        add(capacity_probe, CRAMERS_RULE_2X2_OUTPUT_BYTES)
        add(capacity_probe, CRAMERS_RULE_2X2_OUTPUT_BYTES - 1)
        null_key = ((3, 2, 13, 2, -1, 4), default_capacity)
        if null_key in cases:
            raise ValueError("Cramer's rule null-input canary collides with another case")
        cases[null_key] = (-1, b"")
        null_input_cases.add(null_key)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "power_for_huge_numbers":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if (type(default_capacity) is not int
                or default_capacity < MAX_POWER_FOR_HUGE_NUMBERS_OUTPUT_BYTES):
            raise ValueError("invalid huge-power output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = power_for_huge_numbers_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = power_for_huge_numbers_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            if (case.get("input_length") not in (None, len(values))
                    or len(values) > MAX_POWER_FOR_HUGE_NUMBERS_INPUT_LENGTH
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)
        for _ in range(128):
            values = (rng.randint(1, 10_000), rng.randint(0, 128))
            add(values)
            result, _ = power_for_huge_numbers_oracle(values)
            if result > 0:
                add(values, result - 1)

        for values in (
            (), (2,), (2, 10, 7), (0, 0), (-1, 2), (10_001, 1),
            (2, -1), (2, 129), (2**63,), (-(2**63),),
            (1,) * (MAX_POWER_FOR_HUGE_NUMBERS_INPUT_LENGTH + 1),
        ):
            add(values)
        capacity_probe = (10_000, 128)
        add(capacity_probe, MAX_POWER_FOR_HUGE_NUMBERS_OUTPUT_BYTES - 1)
        add(capacity_probe, MAX_POWER_FOR_HUGE_NUMBERS_OUTPUT_BYTES)
        null_values = next(
            ((base, exponent)
             for base in range(9_999, 9_979, -1)
             for exponent in range(128, 119, -1)
             if ((base, exponent), default_capacity) not in cases),
            None,
        )
        if null_values is None or power_for_huge_numbers_oracle(null_values)[0] < 0:
            raise ValueError("unable to select a valid unique huge-power NULL canary")
        null_key = (null_values, default_capacity)
        cases[null_key] = (-1, b"")
        null_input_cases.add(null_key)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "ode_forward_euler":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if (type(default_capacity) is not int
                or default_capacity < ODE_FORWARD_EULER_OUTPUT_BYTES):
            raise ValueError("invalid forward-Euler output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = ode_forward_euler_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = ode_forward_euler_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            if (case.get("input_length") not in (None, len(values))
                    or len(values) > MAX_ODE_FORWARD_EULER_INPUT_LENGTH
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)
        for _ in range(128):
            add((rng.randint(1, 16), rng.randint(1, 4),
                 rng.randint(-10, 10), rng.randint(-10, 10)))

        for values in (
            (), (1,), (1, 1, 0), (1, 1, 0, 0, 99),
            (0, 1, 0, 0), (17, 1, 0, 0), (1, 0, 0, 0),
            (1, 5, 0, 0), (1, 1, -11, 0), (1, 1, 0, 11),
            (2**63,), (-(2**63),), (1,) * (MAX_ODE_FORWARD_EULER_INPUT_LENGTH + 1),
        ):
            add(values)
        capacity_probe = (1, 1, 2, -1)
        add(capacity_probe, ODE_FORWARD_EULER_OUTPUT_BYTES - 1)
        add(capacity_probe, ODE_FORWARD_EULER_OUTPUT_BYTES)
        null_key = ((3, 2, 0, 1), default_capacity)
        if null_key in cases:
            raise ValueError("forward-Euler null-input canary collides with another case")
        cases[null_key] = (-1, b"")
        null_input_cases.add(null_key)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "ode_midpoint_euler":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if (type(default_capacity) is not int
                or default_capacity < MAX_ODE_MIDPOINT_EULER_OUTPUT_BYTES):
            raise ValueError("invalid midpoint-Euler output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = ode_midpoint_euler_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = ode_midpoint_euler_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            if (case.get("input_length") not in (None, len(values))
                    or len(values) > MAX_ODE_MIDPOINT_EULER_INPUT_LENGTH
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)
        for _ in range(128):
            add((rng.randint(1, 8), rng.randint(1, 4),
                 rng.randint(-10, 10), rng.randint(-10, 10)))

        for values in (
            (), (1,), (1, 1, 0), (1, 4, 0, 0, 9),
            (0, 1, 0, 0), (9, 1, 0, 0), (1, 0, 0, 0),
            (1, 5, 0, 0), (1, 1, -11, 0), (1, 1, 0, 11),
            (2**63,), (-(2**63),), (1,) * (MAX_ODE_MIDPOINT_EULER_INPUT_LENGTH + 1),
        ):
            add(values)
        capacity_probe = (1, 1, 1, 2)
        add(capacity_probe, MAX_ODE_MIDPOINT_EULER_OUTPUT_BYTES - 1)
        add(capacity_probe, MAX_ODE_MIDPOINT_EULER_OUTPUT_BYTES)
        null_key = ((8, 3, 9, -8), default_capacity)
        if null_key in cases:
            raise ValueError("midpoint-Euler null-input canary collides with another case")
        cases[null_key] = (-1, b"")
        null_input_cases.add(null_key)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "ode_semi_implicit_euler":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if (type(default_capacity) is not int
                or default_capacity < ODE_SEMI_IMPLICIT_EULER_OUTPUT_BYTES):
            raise ValueError("invalid semi-implicit-Euler output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = ode_semi_implicit_euler_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = ode_semi_implicit_euler_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            if (case.get("input_length") not in (None, len(values))
                    or len(values) > MAX_ODE_SEMI_IMPLICIT_EULER_INPUT_LENGTH
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)
        for _ in range(128):
            add((rng.randint(1, 8), rng.randint(1, 4),
                 rng.randint(-10, 10), rng.randint(-10, 10)))

        for values in (
            (), (1,), (1, 1, 0), (1, 1, 0, 0, 9),
            (0, 1, 0, 0), (9, 1, 0, 0), (1, 0, 0, 0),
            (1, 5, 0, 0), (1, 1, -11, 0), (1, 1, 0, 11),
            (2**63,), (-(2**63),), (1,) * (MAX_ODE_SEMI_IMPLICIT_EULER_INPUT_LENGTH + 1),
        ):
            add(values)
        capacity_probe = (2, 1, 1, 0)
        add(capacity_probe, ODE_SEMI_IMPLICIT_EULER_OUTPUT_BYTES - 1)
        add(capacity_probe, ODE_SEMI_IMPLICIT_EULER_OUTPUT_BYTES)
        null_key = ((3, 2, 0, 1), default_capacity)
        if null_key in cases:
            raise ValueError("semi-implicit-Euler null-input canary collides with another case")
        cases[null_key] = (-1, b"")
        null_input_cases.add(null_key)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "crc_polynomial_division":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if (type(default_capacity) is not int
                or default_capacity < MAX_CRC_POLYNOMIAL_DIVISION_OUTPUT_BYTES):
            raise ValueError("invalid CRC polynomial division output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = crc_polynomial_division_oracle(values, capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = crc_polynomial_division_oracle(values, capacity)
            if (case.get("input_length") not in (None, len(values))
                    or len(values) > MAX_CRC_POLYNOMIAL_DIVISION_INPUT_LENGTH + 1
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)
        for _ in range(128):
            operation = rng.randrange(2)
            maximum_length = 64 if operation == 0 else 79
            message_length = rng.randint(1, maximum_length)
            polynomial_length = rng.randint(2, 16)
            values = (operation, message_length, polynomial_length,
                      *(rng.randrange(2) for _ in range(message_length)),
                      1, *(rng.randrange(2) for _ in range(polynomial_length - 2)), 1)
            add(values)
            expected_count, _ = crc_polynomial_division_oracle(values)
            if expected_count > 1:
                add(values, expected_count - 1)

        malformed = (
            (), (0,), (0, 1), (2, 1, 2, 1, 1), (0, 0, 2, 1, 1),
            (0, 65, 2), (1, 80, 2), (0, 1, 1, 1, 1), (0, 1, 17),
            (0, 2, 3, 1, 0, 1), (0, 2, 2, 1, 2, 1, 1),
            (0, 1, 2, 1, 1, 2), (0, 1, 2, 1, 0, 1),
            (0, 1, 2, 1, 1, 0), (1,) * (MAX_CRC_POLYNOMIAL_DIVISION_INPUT_LENGTH + 1),
        )
        for values in malformed:
            add(values)

        check_capacity_probe = (1, 1, 2, 1, 1, 1)
        add(check_capacity_probe)
        add(check_capacity_probe, 0)

        null_values = (0, 1, 2, 1, 1, 1)
        null_key = (null_values, default_capacity)
        if null_key in cases:
            raise ValueError("CRC polynomial division null-input canary collides with another case")
        cases[null_key] = (-1, b"")
        null_input_cases.add(null_key)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "choiceset":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid Choiceset output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = choiceset_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = choiceset_oracle(values)
            capacity = case.get("workspace_bytes", default_capacity)
            expected_result = -2 if result >= 0 and capacity < len(output) else result
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)
        for _ in range(128):
            keys: list[int] = []
            operations: list[int] = []
            for _ in range(rng.randrange(0, 65)):
                choices = [1, 2, 3] + ([4] if keys else [])
                operation = rng.choice(choices)
                if operation == 1:
                    key = rng.randrange(-32, 33)
                    if key not in keys and len(keys) < 256:
                        keys.append(key)
                elif operation == 2:
                    key = rng.randrange(-32, 33)
                elif operation == 3:
                    key = rng.randrange(-32, 33)
                    if key in keys:
                        index = keys.index(key)
                        keys[index] = keys[-1]
                        keys.pop()
                else:
                    key = rng.randrange(1, len(keys) + 1)
                operations.extend((operation, key))
            values = (len(operations) // 2, *operations)
            add(values)

        for values in ((), (-1,), (MAX_CHOICESET_OPERATIONS + 1,), (1, 1),
                       (1, 9, 0), (1, 1, 1_000_000_001), (1, 4, 1),
                       (2, 1, 5, 4, 0), (1, 2, 2**63)):
            add(values)
        add((2, 1, 5, 2, 5), 15)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "circular_look_scheduling":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid Circular LOOK output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = circular_look_scheduling_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = circular_look_scheduling_oracle(values)
            capacity = case.get("workspace_bytes", default_capacity)
            expected_result = -2 if result >= 0 and capacity < len(output) else result
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        for max_cylinder in range(1, 4):
            requests_domain = range(-1, max_cylinder + 1)
            for start in range(max_cylinder):
                for moving_up in (0, 1):
                    for request_count in range(4):
                        for requests in product(requests_domain, repeat=request_count):
                            add((max_cylinder, start, moving_up, request_count, *requests))
        rng = random.Random(20261016)
        for _ in range(128):
            max_cylinder = rng.randint(1, 128)
            start = rng.randrange(max_cylinder)
            moving_up = rng.randrange(2)
            request_count = rng.randrange(MAX_CIRCULAR_LOOK_REQUESTS + 1)
            requests = [rng.randint(-128, 255) for _ in range(request_count)]
            add((max_cylinder, start, moving_up, request_count, *requests))
        for values in ((), (1,), (0, 0, 1, 0), (1, 1, 1, 0),
                       (8, 4, 2, 0), (8, 4, 1, -1), (8, 4, 1, 65),
                       (8, 4, 1, 1), (8, 4, 1, 0, 0), (8, 4, 1, 1, -129),
                       (8, 4, 1, 1, 256), (2**63, 0, 1, 0),
                       (1,) * (MAX_CIRCULAR_LOOK_INPUT_LENGTH + 1)):
            add(values)
        add((8, 4, 1, 3, 1, 6, 7), 2)
        add((1, 0, 1, 0), 0)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "circular_scan_scheduling":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid Circular SCAN output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = circular_scan_scheduling_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = circular_scan_scheduling_oracle(values)
            capacity = case.get("workspace_bytes", default_capacity)
            expected_result = -2 if result >= 0 and capacity < len(output) else result
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        for disk_size in range(1, 4):
            requests_domain = range(-1, disk_size + 1)
            for start in range(disk_size):
                for moving_up in (0, 1):
                    for request_count in range(4):
                        for requests in product(requests_domain, repeat=request_count):
                            add((disk_size, start, moving_up, request_count, *requests))
        rng = random.Random(20261016)
        for _ in range(128):
            disk_size = rng.randint(1, 128)
            start = rng.randrange(disk_size)
            moving_up = rng.randrange(2)
            request_count = rng.randrange(MAX_CIRCULAR_SCAN_REQUESTS + 1)
            requests = [rng.randint(-128, 127) for _ in range(request_count)]
            add((disk_size, start, moving_up, request_count, *requests))
        for values in ((), (1,), (0, 0, 1, 0), (1, 1, 1, 0),
                       (8, 4, 2, 0), (8, 4, 1, -1), (8, 4, 1, 65),
                       (8, 4, 1, 1), (8, 4, 1, 0, 0), (8, 4, 1, 1, -129),
                       (8, 4, 1, 1, 128), (2**63, 0, 1, 0),
                       (1,) * (MAX_CIRCULAR_SCAN_INPUT_LENGTH + 1)):
            add(values)
        add((8, 4, 1, 3, -1, 4, 7), 2)
        add((1, 0, 1, 0), 0)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "particle_swarm_optimization":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if (type(default_capacity) is not int
                or default_capacity < MAX_PARTICLE_SWARM_OUTPUT_BYTES):
            raise ValueError("invalid particle-swarm output workspace size")
        absolute_tolerance = workload["output"].get("absolute_tolerance", 0.0)
        relative_tolerance = workload["output"].get("relative_tolerance", 0.0)

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = particle_swarm_oracle(list(values))
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = result, output

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = particle_swarm_oracle(list(values))
            if result >= 0 and capacity < len(output):
                result, output = case.get("capacity_error_result", -2), b""
            actual_vector = (struct.unpack("<" + "d" * (len(output) // 8), output)
                             if result >= 0 else ())
            declared_vector = case.get("expected_output", [])
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != result
                    or not isinstance(declared_vector, list)
                    or len(declared_vector) != len(actual_vector)
                    or any(type(value) not in (int, float) or not math.isfinite(value)
                           for value in declared_vector)
                    or any(abs(actual - expected) > absolute_tolerance
                           + relative_tolerance * abs(expected)
                           for actual, expected in zip(actual_vector, declared_vector))):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        for seed in (7, 101):
            add((seed,))
        add((1,), MAX_PARTICLE_SWARM_OUTPUT_BYTES - 1)
        add((1,), 0)
        for values in ((), (-1,), (0,), (1, 42), (MAX_PARTICLE_SWARM_OUTPUT_BYTES, 0)):
            add(values)
        null_key = ((2,), default_capacity)
        cases[null_key] = (-1, b"")
        null_input_cases.add(null_key)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "convolve_1d":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if (type(default_capacity) is not int
                or default_capacity < MAX_CONVOLVE_1D_OUTPUT_BYTES):
            raise ValueError("invalid convolve_1d output workspace size")
        absolute_tolerance = workload["output"].get("absolute_tolerance", 0.0)
        relative_tolerance = workload["output"].get("relative_tolerance", 0.0)

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = convolve_1d_oracle(list(values))
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = result, output

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = convolve_1d_oracle(list(values))
            if result >= 0 and capacity < len(output):
                result, output = case.get("capacity_error_result", -2), b""
            actual_vector = (struct.unpack("<" + "d" * (len(output) // 8), output)
                             if result >= 0 else ())
            declared_vector = case.get("expected_output", [])
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != result
                    or not isinstance(declared_vector, list)
                    or len(declared_vector) != len(actual_vector)
                    or any(type(value) not in (int, float) or not math.isfinite(value)
                           for value in declared_vector)
                    or any(abs(actual - expected) > absolute_tolerance
                           + relative_tolerance * abs(expected)
                           for actual, expected in zip(actual_vector, declared_vector))):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "depth_first_search_target_route":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if (type(default_capacity) is not int
                or default_capacity < MAX_DFS_TARGET_ROUTE_OUTPUT_BYTES):
            raise ValueError("invalid DFS target-route output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = depth_first_search_target_route_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = result, output

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = depth_first_search_target_route_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = case.get("capacity_error_result", -2), b""
            if (case.get("input_length") not in (None, len(values))
                    or len(values) > MAX_DFS_TARGET_ROUTE_INPUT_LENGTH + 1
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        # Exercise the ABI's null-input guard independently of the empty-array fixture.
        null_values = (1, 99, 99, 99, 0)
        null_key = (null_values, default_capacity)
        cases[null_key] = (-2, b"")
        null_input_cases.add(null_key)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "convolution_fft":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if (type(default_capacity) is not int
                or default_capacity < MAX_CONVOLUTION_FFT_OUTPUT_BYTES):
            raise ValueError("invalid convolution_fft output workspace size")
        absolute_tolerance = workload["output"].get("absolute_tolerance", 0.0)
        relative_tolerance = workload["output"].get("relative_tolerance", 0.0)
        if (not math.isfinite(absolute_tolerance) or absolute_tolerance < 0
                or not math.isfinite(relative_tolerance) or relative_tolerance < 0):
            raise ValueError("convolution_fft tolerances must be finite and nonnegative")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = convolution_fft_oracle(values, capacity)
            cases[(values, capacity)] = result, output

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            if type(capacity) is not int or not 0 <= capacity <= MAX_OUTPUT_CAPACITY:
                raise ValueError(f"invalid output capacity in {case['id']}")
            result, output = convolution_fft_oracle(values, capacity)
            actual_vector = (struct.unpack("<" + "d" * (len(output) // 8), output)
                             if result >= 0 else ())
            declared_vector = case.get("expected_output", [])
            if (case.get("input_length") not in (None, len(values))
                    or len(values) > MAX_CONVOLUTION_FFT_INPUT_LENGTH
                    or case["expected_result"] != result
                    or not isinstance(declared_vector, list)
                    or len(declared_vector) != len(actual_vector)
                    or any(type(value) not in (int, float) or not math.isfinite(value)
                           for value in declared_vector)
                    or any(abs(actual - expected) > absolute_tolerance
                           + relative_tolerance * abs(expected)
                           for actual, expected in zip(actual_vector, declared_vector))):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        null_values = (1, 1, 63, 62)
        null_key = (null_values, default_capacity)
        cases[null_key] = (-1, b"")
        null_input_cases.add(null_key)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "text_justification":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if (type(default_capacity) is not int
                or default_capacity < MAX_TEXT_JUSTIFICATION_OUTPUT_BYTES):
            raise ValueError("invalid text_justification output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = text_justification_oracle(values, capacity)

        for values in ((), (-256, 0), (256, 0), (0, -1), (0, 256),
                       (-(2**63), 0), (2**63 - 1, 0)):
            add(values, default_capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            if (type(capacity) is not int or not 0 <= capacity <= MAX_OUTPUT_CAPACITY
                    or case.get("input_length") not in (None, len(values))
                    or len(values) > MAX_TEXT_JUSTIFICATION_INPUT_LENGTH
                    or any(type(value) is not int for value in values)):
                raise ValueError(f"invalid text_justification workload case: {case['id']}")
            result, output = text_justification_oracle(values, capacity)
            if (case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        null_values = (1, 1, 97)
        null_key = (null_values, default_capacity)
        cases[null_key] = (-1, b"")
        null_input_cases.add(null_key)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "remove_duplicate_from_string":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if (type(default_capacity) is not int
                or default_capacity < MAX_REMOVE_DUPLICATE_FROM_STRING_OUTPUT_BYTES):
            raise ValueError("invalid remove_duplicate_from_string output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = remove_duplicate_from_string_oracle(values, capacity)

        for values in ((), (-1,), (513,), (-(2**63),), (2**63 - 1,)):
            add(values, default_capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            if (type(capacity) is not int or not 0 <= capacity <= MAX_OUTPUT_CAPACITY
                    or case.get("input_length") not in (None, len(values))
                    or len(values) > MAX_REMOVE_DUPLICATE_FROM_STRING_INPUT_LENGTH
                    or any(type(value) is not int for value in values)):
                raise ValueError(f"invalid remove_duplicate_from_string workload case: {case['id']}")
            result, output = remove_duplicate_from_string_oracle(values, capacity)
            if (case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        null_values = (0,)
        null_key = (null_values, default_capacity)
        cases[null_key] = (-1, b"")
        null_input_cases.add(null_key)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "max_word":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < MAX_MAX_WORD_OUTPUT_BYTES:
            raise ValueError("invalid max_word output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = max_word_oracle(values, capacity)

        for values in ((), (0,), (-1,), (513,), (-(2**63),), (2**63 - 1,)):
            add(values, default_capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            if (type(capacity) is not int or not 0 <= capacity <= MAX_OUTPUT_CAPACITY
                    or case.get("input_length") not in (None, len(values))
                    or len(values) > MAX_MAX_WORD_INPUT_LENGTH
                    or any(type(value) is not int for value in values)):
                raise ValueError(f"invalid max_word workload case: {case['id']}")
            result, output = max_word_oracle(values, capacity)
            if (case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        null_values = (1, 65)
        null_key = (null_values, default_capacity)
        cases[null_key] = (-1, b"")
        null_input_cases.add(null_key)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "keyword_shifted_alphabet":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if (type(default_capacity) is not int
                or default_capacity < MAX_KEYWORD_SHIFTED_ALPHABET_OUTPUT_BYTES):
            raise ValueError("invalid keyword_shifted_alphabet output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = keyword_shifted_alphabet_oracle(values, capacity)

        for values in ((), (0,), (2, 1, 1, 97, 65), (0, 0, 1, 65),
                       (0, 1, 0, 97), (-(2**63),), (2**63 - 1,)):
            add(values, default_capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            if (type(capacity) is not int or not 0 <= capacity <= MAX_OUTPUT_CAPACITY
                    or case.get("input_length") not in (None, len(values))
                    or len(values) > MAX_KEYWORD_SHIFTED_ALPHABET_INPUT_LENGTH
                    or any(type(value) is not int for value in values)):
                raise ValueError(f"invalid keyword_shifted_alphabet workload case: {case['id']}")
            result, output = keyword_shifted_alphabet_oracle(values, capacity)
            if (case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        null_values = (0, 1, 1, 97, 65)
        null_key = (null_values, default_capacity)
        cases[null_key] = (-1, b"")
        null_input_cases.add(null_key)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "integer_to_english":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if (type(default_capacity) is not int
                or default_capacity < MAX_INTEGER_TO_ENGLISH_OUTPUT_BYTES):
            raise ValueError("invalid integer_to_english output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = integer_to_english_oracle(values, capacity)

        for values in ((), (INTEGER_TO_ENGLISH_I32_MIN - 1,),
                       (INTEGER_TO_ENGLISH_I32_MAX + 1,), (-(2**63),),
                       (2**63 - 1,), (0, 0)):
            add(values, default_capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            if (type(capacity) is not int or not 0 <= capacity <= MAX_OUTPUT_CAPACITY
                    or case.get("input_length") not in (None, len(values))
                    or len(values) > MAX_INTEGER_TO_ENGLISH_INPUT_LENGTH
                    or any(type(value) is not int for value in values)):
                raise ValueError(f"invalid integer_to_english workload case: {case['id']}")
            result, output = integer_to_english_oracle(values, capacity)
            if (case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        null_values = (0, 0)
        null_key = (null_values, default_capacity)
        cases[null_key] = (-1, b"")
        null_input_cases.add(null_key)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "largest_smallest_words":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if (type(default_capacity) is not int
                or default_capacity < MAX_LARGEST_SMALLEST_WORDS_OUTPUT_BYTES):
            raise ValueError("invalid largest_smallest_words output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = largest_smallest_words_oracle(values, capacity)

        for values in ((), (0,), (1,), (1, 32), (513,), (2, 65),
                       (1, 65, 66), (1, 9), (-(2**63),), (2**63 - 1,)):
            add(values, default_capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            if (type(capacity) is not int or not 0 <= capacity <= MAX_OUTPUT_CAPACITY
                    or case.get("input_length") not in (None, len(values))
                    or len(values) > MAX_LARGEST_SMALLEST_WORDS_INPUT_LENGTH
                    or any(type(value) is not int for value in values)):
                raise ValueError(f"invalid largest_smallest_words workload case: {case['id']}")
            result, output = largest_smallest_words_oracle(values, capacity)
            if (case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        null_values = (1, 65)
        null_key = (null_values, default_capacity)
        cases[null_key] = (-1, b"")
        null_input_cases.add(null_key)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "hexa_decimal_to_binary":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if (type(default_capacity) is not int
                or default_capacity < MAX_HEXA_DECIMAL_TO_BINARY_OUTPUT_BYTES):
            raise ValueError("invalid hexa_decimal_to_binary output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = hexa_decimal_to_binary_oracle(values, capacity)

        for values in ((), (0,), (71,), (43,), (45,), (43, 43, 49),
                       (45, 56, 48, 48, 48, 48, 48, 48, 49),
                       tuple([48] * MAX_HEXA_DECIMAL_TO_BINARY_VALID_INPUT_LENGTH),
                       tuple([48] * MAX_HEXA_DECIMAL_TO_BINARY_INPUT_LENGTH),
                       (56, 48, 48, 48, 48, 48, 48, 48),
                       (-(2**63),), (2**63 - 1,)):
            add(values, default_capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            if (type(capacity) is not int or not 0 <= capacity <= MAX_OUTPUT_CAPACITY
                    or case.get("input_length") not in (None, len(values))
                    or len(values) > MAX_HEXA_DECIMAL_TO_BINARY_INPUT_LENGTH
                    or any(type(value) is not int for value in values)):
                raise ValueError(f"invalid hexa_decimal_to_binary workload case: {case['id']}")
            result, output = hexa_decimal_to_binary_oracle(values, capacity)
            if (case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        null_values = (50,)
        null_key = (null_values, default_capacity)
        cases[null_key] = (-1, b"")
        null_input_cases.add(null_key)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "ones_complement":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < MAX_ONES_COMPLEMENT_INPUT_LENGTH:
            raise ValueError("invalid ones_complement output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = ones_complement_oracle(list(values), capacity)

        for values in ((), (48, 50), (47,), (-1,),
                       tuple([48] * (MAX_ONES_COMPLEMENT_INPUT_LENGTH + 1)),
                       (-(2**63),), (2**63 - 1,)):
            add(values, default_capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            if (type(capacity) is not int or not 0 <= capacity <= MAX_OUTPUT_CAPACITY
                    or case.get("input_length") not in (None, len(values))
                    or len(values) > MAX_ONES_COMPLEMENT_INPUT_LENGTH + 1
                    or any(type(value) is not int for value in values)):
                raise ValueError(f"invalid ones_complement workload case: {case['id']}")
            result, output = ones_complement_oracle(list(values), capacity)
            if (case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        null_values = (48, 49)
        null_key = (null_values, default_capacity)
        cases[null_key] = (-1, b"")
        null_input_cases.add(null_key)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "rgbto_hex":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if (type(default_capacity) is not int
                or default_capacity < RGBTO_HEX_OUTPUT_LENGTH):
            raise ValueError("invalid rgbto_hex output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = rgbto_hex_oracle(list(values), capacity)

        for values in ((), (1,), (1, 2), (1, 2, 3, 4), (1, -1, 3),
                       (1, 256, 3), (-(2**63),), (2**63 - 1,)):
            add(values, default_capacity)
        add((255, 99, 71), RGBTO_HEX_OUTPUT_LENGTH - 1)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            if (type(capacity) is not int or not 0 <= capacity <= MAX_OUTPUT_CAPACITY
                    or case.get("input_length") not in (None, len(values))
                    or len(values) > MAX_RGBTO_HEX_INPUT_LENGTH + 1
                    or any(type(value) is not int for value in values)):
                raise ValueError(f"invalid rgbto_hex workload case: {case['id']}")
            result, output = rgbto_hex_oracle(list(values), capacity)
            if (case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        null_values = (1, 2, 3)
        null_key = (null_values, default_capacity)
        if null_key in cases:
            raise ValueError("rgbto_hex null-input canary collides with workload case")
        cases[null_key] = (-1, b"")
        null_input_cases.add(null_key)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "reverse_words_in_string":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if (type(default_capacity) is not int
                or default_capacity < MAX_REVERSE_WORDS_IN_STRING_OUTPUT_LENGTH):
            raise ValueError("invalid reverse_words_in_string output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = reverse_words_in_string_oracle(list(values), capacity)

        for values in ((), (0,), (-1,), (257, *([97] * 257)),
                       (3, 97, 98), (1, -1), (1, 128),
                       (2**63 - 1,), (-(2**63),)):
            add(values)
        capacity_text = tuple(map(ord, "one two three"))
        add((len(capacity_text), *capacity_text), 12)

        rng = random.Random(0x7E5E5)
        for _ in range(32):
            text = tuple(rng.randrange(128)
                         for _ in range(rng.randint(0, MAX_REVERSE_WORDS_IN_STRING_INPUT_LENGTH - 1)))
            add((len(text), *text))

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            if (type(capacity) is not int or not 0 <= capacity <= MAX_OUTPUT_CAPACITY
                    or case.get("input_length") not in (None, len(values))
                    or len(values) > MAX_REVERSE_WORDS_IN_STRING_PARSEABLE_INPUT_LENGTH
                    or any(type(value) is not int for value in values)):
                raise ValueError(f"invalid reverse_words_in_string workload case: {case['id']}")
            result, output = reverse_words_in_string_oracle(list(values), capacity)
            if (case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        null_text = tuple(map(ord, "null pointer"))
        null_values = (len(null_text), *null_text)
        null_key = (null_values, default_capacity)
        if null_key in cases:
            raise ValueError("reverse_words_in_string null-input canary collides with another case")
        cases[null_key] = (-1, b"")
        null_input_cases.add(null_key)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "numeric_string_sort":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if (type(default_capacity) is not int
                or default_capacity < MAX_NUMERIC_STRING_SORT_OUTPUT_LENGTH):
            raise ValueError("invalid numeric_string_sort output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = numeric_string_sort_oracle(list(values), capacity)

        for values in ((), (0,), (-1,), (65,), (1,), (1, 0),
                       (1, 33, *([49] * 33)), (1, 1, 128), (1, 1, 45),
                       (2, 3, 48, 48, 49, 1, 49),
                       (2, 1, 48, 2, 48, 48),
                       (0, 99), (2**63 - 1,), (-(2**63),)):
            add(values)
        add((3, 1, 49, 2, 49, 48, 2, 49, 48), 5)

        rng = random.Random(0x51A7_50A7)
        for _ in range(32):
            numbers = rng.sample(range(1, 10**9), rng.randint(0, 12))
            tokens = [str(number).rjust(rng.randint(len(str(number)), 12), "0")
                      for number in numbers]
            packed = [len(tokens)]
            for token in tokens:
                encoded = token.encode("ascii")
                packed.extend((len(encoded), *encoded))
            add(tuple(packed))

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            if (type(capacity) is not int or not 0 <= capacity <= MAX_OUTPUT_CAPACITY
                    or case.get("input_length") not in (None, len(values))
                    or len(values) > MAX_NUMERIC_STRING_SORT_PARSEABLE_INPUT_LENGTH
                    or any(type(value) is not int for value in values)):
                raise ValueError(f"invalid numeric_string_sort workload case: {case['id']}")
            result, output = numeric_string_sort_oracle(list(values), capacity)
            if (case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        null_values = (3, 1, 55, 2, 49, 49, 3, 49, 50, 51)
        null_key = (null_values, default_capacity)
        if null_key in cases:
            raise ValueError("numeric_string_sort null-input canary collides with another case")
        cases[null_key] = (-1, b"")
        null_input_cases.add(null_key)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "shortest_palindrome":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if (type(default_capacity) is not int
                or default_capacity < MAX_SHORTEST_PALINDROME_OUTPUT_LENGTH):
            raise ValueError("invalid shortest_palindrome output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = shortest_palindrome_oracle(list(values), capacity)

        for values in ((), (32,), (126,), (32, 126), (97, 98, 99, 100),
                       tuple([98] * 63 + [97]), tuple([97, 128]), (31,), (127,),
                       (-(2**63),), (2**63 - 1,), tuple([65] * MAX_SHORTEST_PALINDROME_PARSEABLE_INPUT_LENGTH)):
            add(values)
        add(tuple(map(ord, "abcd")), 6)

        rng = random.Random(0x5A07E57)
        for _ in range(32):
            values = tuple(rng.randint(32, 126)
                           for _ in range(rng.randint(0, MAX_SHORTEST_PALINDROME_VALID_INPUT_LENGTH)))
            add(values)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            if (type(capacity) is not int or not 0 <= capacity <= MAX_OUTPUT_CAPACITY
                    or case.get("input_length") not in (None, len(values))
                    or len(values) > MAX_SHORTEST_PALINDROME_PARSEABLE_INPUT_LENGTH
                    or any(type(value) is not int for value in values)):
                raise ValueError(f"invalid shortest_palindrome workload case: {case['id']}")
            result, output = shortest_palindrome_oracle(list(values), capacity)
            if (case["expected_result"] != result
                    or ("expected_output_hex" in case
                        and case["expected_output_hex"].lower() != output.hex())):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        null_values = tuple(map(ord, "null-input-canary"))
        null_key = (null_values, default_capacity)
        if null_key in cases:
            raise ValueError("shortest_palindrome null-input canary collides with another case")
        cases[null_key] = (-1, b"")
        null_input_cases.add(null_key)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "ipconverter":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if (type(default_capacity) is not int
                or default_capacity < MAX_IPCONVERTER_OUTPUT_LENGTH):
            raise ValueError("invalid ipconverter output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = ipconverter_oracle(list(values), capacity)

        for values in ((), (0,), (0, 0), (2, 9, *map(ord, "127.0.0.1")),
                       (0, 8, *map(ord, "127.0.0.1")),
                       (0, 11, *map(ord, "127.0.0.256")),
                       (0, 9, *map(ord, "127.0.0.x")),
                       (0, 7, 49, 46, 49, 46, 128, 46, 49),
                       (1, 35, *map(ord, "01111111.00000000.00000000.00000001")),
                       (1, 34, *map(ord, "1111111.00000000.00000000.0000001")),
                       (1, 36, *([49] * 36)), (-(2**63),), (2**63 - 1,)):
            add(values)
        add((0, 11, *map(ord, "10.20.30.40")), 0)

        rng = random.Random(0x1C0A7)
        for _ in range(20):
            octets = [rng.randrange(256) for _ in range(4)]
            decimal_text = ".".join(str(value) for value in octets)
            decimal_values = (0, len(decimal_text), *map(ord, decimal_text))
            add(decimal_values)
            binary_text = ".".join(f"{value:08b}" for value in octets)
            binary_values = (1, len(binary_text), *map(ord, binary_text))
            add(binary_values)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            if (type(capacity) is not int or not 0 <= capacity <= MAX_OUTPUT_CAPACITY
                    or case.get("input_length") not in (None, len(values))
                    or len(values) > MAX_IPCONVERTER_PARSEABLE_INPUT_LENGTH
                    or any(type(value) is not int for value in values)):
                raise ValueError(f"invalid ipconverter workload case: {case['id']}")
            result, output = ipconverter_oracle(list(values), capacity)
            if (case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        null_values = (0, 11, *map(ord, "10.20.30.40"))
        null_key = (null_values, default_capacity)
        if null_key in cases:
            raise ValueError("ipconverter null-input canary collides with workload case")
        cases[null_key] = (-1, b"")
        null_input_cases.add(null_key)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "binary_to_excess3":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if (type(default_capacity) is not int
                or default_capacity < MAX_BINARY_TO_EXCESS3_OUTPUT_BYTES):
            raise ValueError("invalid binary_to_excess3 output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = binary_to_excess3_verifier_oracle(values, capacity)

        malformed = ((), (32,), (50,), (49, 50), (49, 95, 49), (49, 95),
                     (48, 98, 95), (43,), (45,), (48, 120, 49), (128,), (-1,))
        for values in malformed:
            add(values)
        add(tuple(map(ord, "1010")), 3)

        rng = random.Random(0xB1A2E3)
        for _ in range(24):
            length = rng.randint(1, 96)
            text = "".join(rng.choice("01") for _ in range(length))
            add(tuple(map(ord, text)))

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            if (type(capacity) is not int or not 0 <= capacity <= MAX_OUTPUT_CAPACITY
                    or case.get("input_length") not in (None, len(values))
                    or len(values) > MAX_BINARY_TO_EXCESS3_INPUT_LENGTH + 1
                    or any(type(value) is not int for value in values)):
                raise ValueError(f"invalid binary_to_excess3 workload case: {case['id']}")
            result, output = binary_to_excess3_verifier_oracle(values, capacity)
            if (case["expected_result"] != result
                    or ("expected_output_hex" in case
                        and case["expected_output_hex"].lower() != output.hex())):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        null_values = tuple(map(ord, "101101"))
        null_key = (null_values, default_capacity)
        if null_key in cases:
            raise ValueError("binary_to_excess3 null-input canary collides with workload case")
        cases[null_key] = (-1, b"")
        null_input_cases.add(null_key)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "chebyshev_iteration":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid Chebyshev output workspace size")
        absolute_tolerance = workload["output"].get("absolute_tolerance", 0.0)
        relative_tolerance = workload["output"].get("relative_tolerance", 0.0)

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = chebyshev_iteration_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = chebyshev_iteration_oracle(values)
            capacity = case.get("workspace_bytes", default_capacity)
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_vector = ([struct.unpack_from("<d", output, offset)[0]
                                for offset in range(0, len(output), 8)]
                               if result >= 0 and capacity >= len(output) else [])
            declared_vector = case.get("expected_output")
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or not isinstance(declared_vector, list)
                    or len(declared_vector) != len(expected_vector)
                    or any(abs(actual - expected) > absolute_tolerance + relative_tolerance * abs(expected)
                           for actual, expected in zip(declared_vector, expected_vector))):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)
        for _ in range(96):
            n = rng.randrange(1, MAX_CHEBYSHEV_DIMENSION + 1)
            matrix = [[0] * n for _ in range(n)]
            row_sums = [0] * n
            for row in range(n):
                for column in range(row + 1, n):
                    value = rng.randrange(-250_000, 250_001)
                    matrix[row][column] = value
                    matrix[column][row] = value
                    row_sums[row] += abs(value)
                    row_sums[column] += abs(value)
            diagonals = [row_sums[row] + rng.randrange(2_000_000, 8_000_001)
                         for row in range(n)]
            for row in range(n):
                matrix[row][row] = diagonals[row]
            min_bound = min(diagonals[row] - row_sums[row] for row in range(n)) - 1
            max_bound = max(diagonals[row] + row_sums[row] for row in range(n)) + 1
            b = [rng.randrange(-5_000_000, 5_000_001) for _ in range(n)]
            x0 = [rng.randrange(-3_000_000, 3_000_001) for _ in range(n)]
            inputs = (n, *(item for row in matrix for item in row), *b, *x0,
                      min_bound, max_bound, 64, 100)
            add(inputs)

        maximum_output = tuple(workload["cases"][6]["input_values"])
        add(maximum_output, default_capacity - 1)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "chacha":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid ChaCha output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = chacha_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = chacha_oracle(values)
            capacity = case.get("workspace_bytes", default_capacity)
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_output = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)
        for _ in range(256):
            add(tuple(rng.getrandbits(32) for _ in range(16)))
        add(tuple([0] * 16))
        add(tuple([0xffff_ffff] * 16))
        for values in ((), tuple(range(15)), tuple(range(17)),
                       tuple([-1] + [0] * 15), tuple([0xffff_ffff + 1] + [0] * 15),
                       tuple([-(2**63)] + [0] * 15), tuple([2**63 - 1] + [0] * 15)):
            add(values)
        add(tuple(range(16)), 63)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "atbash_cipher":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes", 66)
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid Atbash output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = atbash_cipher_verifier_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = atbash_cipher_verifier_oracle(values)
            capacity = case.get("workspace_bytes", default_capacity)
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        for first in range(128):
            add((first,))
            for second in range(128):
                add((first, second))
        rng = random.Random(20261030)
        for _ in range(128):
            add(tuple(rng.randrange(128) for _ in range(rng.randrange(67))))
        maximum = tuple(range(66))
        add(maximum, 66)
        add(maximum, 65)
        add((65,), 1)
        add((65,), 0)
        for values in ((-1,), (128,), tuple([65] * 67), (-(2**63),), (2**63 - 1,)):
            add(values)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "count_nucleotide":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes", 15)
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid count-nucleotide output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = count_nucleotide_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = count_nucleotide_oracle(values)
            capacity = case.get("workspace_bytes", default_capacity)
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        for codepoint in range(128):
            add((1, codepoint))
        rng = random.Random(20261029)
        alphabet = (65, 67, 71, 84, 78, 97, 99, 103, 116, 0, 32, 63, 127)
        for _ in range(128):
            count = rng.randrange(MAX_COUNT_NUCLEOTIDE_SEQUENCE_LENGTH + 1)
            add((count, *(rng.choice(alphabet) for _ in range(count))))
        balanced = (1000, *([65] * 250), *([67] * 250), *([71] * 250), *([84] * 250))
        add(balanced, 15)
        add(balanced, 14)
        malformed = (
            (), (0, 65), (-1,), (1001, *([65] * 1001)),
            (2, 65), (1, 65, 67), (1, 128), (1, -1),
            (-(2**63), 0), (2**63 - 1, 0),
            (1000, *([65] * 1001)),
        )
        for values in malformed:
            add(values)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "egyptian_fraction":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes", 12)
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid Egyptian-fraction output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = egyptian_fraction_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = egyptian_fraction_oracle(values)
            capacity = case.get("workspace_bytes", default_capacity)
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        for denominator in range(1, 11):
            for numerator in range(denominator + 1):
                add((numerator, denominator))
        add((3, 7), 12)
        add((3, 7), 11)
        malformed = (
            (), (1,), (1, 2, 3), (0, 0), (1, 0), (-1, 2), (11, 10),
            (-(2**63), 1), (2**63 - 1, 1),
        )
        for values in malformed:
            add(values)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "ema_filter":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes", 32)
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid EMA filter output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = ema_filter_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = ema_filter_oracle(values)
            capacity = case.get("workspace_bytes", default_capacity)
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        for alpha_units in range(1, 1025):
            add((alpha_units, 4, 1_000_000, -1_000_000, 1_000_000, -1_000_000))
        rng = random.Random(20261028)
        for _ in range(128):
            count = rng.randrange(5)
            samples = tuple(rng.randrange(-1_000_000, 1_000_001) for _ in range(count))
            add((rng.randrange(1, 1025), count, *samples))
        maximum = (512, 4, 1_000_000, -1_000_000, 1_000_000, -1_000_000)
        add(maximum, 32)
        add(maximum, 31)
        add((1024, 0), 0)
        malformed = (
            (), (0, 0), (1025, 0), (512, -1), (512, 5, 0, 1, 2, 3, 4),
            (512, 1), (512, 0, 1), (512, 1, 1_000_001),
            (512, 1, -1_000_001), (-(2**63), 0), (2**63 - 1, 0),
            tuple([512, 1] + [0] * MAX_EMA_FILTER_INPUT_LENGTH),
        )
        for values in malformed:
            add(values)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "cross_correlation":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes", 504)
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid cross-correlation output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = cross_correlation_verifier_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = cross_correlation_verifier_oracle(values)
            capacity = case.get("workspace_bytes", default_capacity)
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261027)
        for _ in range(96):
            x_count = rng.randrange(1, 33)
            y_count = rng.randrange(1, 33)
            x_values = [rng.randrange(-1_000_000, 1_000_001) for _ in range(x_count)]
            y_values = [rng.randrange(-1_000_000, 1_000_001) for _ in range(y_count)]
            add((x_count, y_count, *x_values, *y_values))
        maximum = (32, 32, *([1_000_000] * 64))
        add(maximum, 504)
        add(maximum, 503)
        add((1, 1, -7, 6), 8)
        add((1, 1, -7, 6), 7)
        for values in ((), (0, 1, 7), (1, 0, 7), (33, 1, *([0] * 34)),
                       (1, 33, *([0] * 34)), (1, 1, 7), (1, 1, 7, 8, 9),
                       (1, 1, 1_000_001, 0), (1, 1, 0, -1_000_001)):
            add(values)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "date_to_day":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes", 9)
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid date-to-day output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = date_to_day_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = date_to_day_oracle(values)
            capacity = case.get("workspace_bytes", default_capacity)
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261026)
        start_ordinal = dt.date(1, 1, 1).toordinal()
        end_ordinal = dt.date(9999, 12, 31).toordinal()
        for index in range(128):
            date = dt.date.fromordinal(rng.randrange(start_ordinal, end_ordinal + 1))
            day = f"{date.day:02d}" if index % 2 else str(date.day)
            month = f"{date.month:02d}" if index % 3 else str(date.month)
            encoded = f"{day}/{month}/{date.year:04d}".encode("ascii") + b"\0"
            add(tuple(encoded))
        add(tuple(b"28/2/1900\0"), 9)
        add(tuple(b"28/2/1900\0"), 8)
        for values in ((), (0,), tuple(b"1/1/2000"), tuple(b"1/1/2000\0\0"),
                       tuple(b"1-1-2000\0"), tuple(b"1/1/0000\0"),
                       tuple(b"31/4/2024\0"), tuple(b"01/01/10000\0"),
                       tuple([49, 47, 49, 47, 50, 48, 48, 49, 256, 0])):
            add(values)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm in {"a1z26_cipher", "a1z26_decipher"}:
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes", 66)
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid A1Z26 output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            oracle = (a1z26_cipher_verifier_oracle if algorithm == "a1z26_cipher"
                      else a1z26_decipher_verifier_oracle)
            result, output = oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            oracle = (a1z26_cipher_verifier_oracle if algorithm == "a1z26_cipher"
                      else a1z26_decipher_verifier_oracle)
            result, output = oracle(values)
            capacity = case.get("workspace_bytes", default_capacity)
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        if algorithm == "a1z26_cipher":
            for value in range(128):
                add((value,))
            alphabet = (0, 49, 65, 90, 97, 122, 127)
            for first in alphabet:
                for second in alphabet:
                    add((first, second))
        else:
            for value in range(-1, 29):
                add((value,))
            alphabet = (0, 1, 13, 26, 27, 28)
            for first in alphabet:
                for second in alphabet:
                    add((first, second))
        rng = random.Random(20261025)
        for _ in range(512):
            length = rng.randrange(67)
            if algorithm == "a1z26_cipher":
                values = tuple(rng.choice((rng.randrange(65, 91), rng.randrange(97, 123), rng.randrange(128)))
                               for _ in range(length))
            else:
                values = tuple(rng.randrange(-1, 29) for _ in range(length))
            add(values)
        maximum = tuple([65] * 66) if algorithm == "a1z26_cipher" else tuple([26] * 66)
        probe = (65,) if algorithm == "a1z26_cipher" else (1,)
        add(maximum, 66)
        add(maximum, 65)
        add(probe, 1)
        add(probe, 0)
        malformed = ((tuple([65] * 67), (-1,), (128,), (2**63 - 1,), (-(2**63),))
                     if algorithm == "a1z26_cipher" else
                     (tuple([1] * 67), (-1,), (0,), (27,), (2**63 - 1,), (-(2**63),)))
        for values in malformed:
            add(values)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "baconian_cipher":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes", 5120)
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid Baconian cipher output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = baconian_cipher_verifier_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = baconian_cipher_verifier_oracle(values)
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        for dialect in range(3):
            for mode in range(2):
                for byte in range(128):
                    add((mode, dialect, byte))
        standard_groups = [tuple(65 + (1 if bit == "B" else 0)
                                for bit in f"{index:05b}".replace("0", "A").replace("1", "B"))
                           for index in range(26)]
        python_groups = [tuple(code.encode("ascii")) for code in (
            "AAAAA", "AAAAB", "AAABA", "AAABB", "AABAA", "AABAB", "AABBA", "AABBB",
            "ABAAA", "BBBAA", "ABAAB", "ABABA", "ABABB", "ABBAA", "ABBAB", "ABBBA",
            "ABBBB", "BAAAA", "BAAAB", "BAABA", "BAABB", "BBBAB", "BABAA", "BABAB",
            "BABBA", "BABBB")]
        add((1, 0, *(byte for group in standard_groups for byte in group)))
        add((1, 1, *(byte for group in python_groups for byte in group)))
        add((1, 2, *(byte for group in standard_groups[:24] for byte in group)))
        rng = random.Random(20261024)
        for _ in range(96):
            dialect = rng.randrange(3)
            mode = rng.randrange(2)
            length = rng.randrange(0, 129)
            alphabet = (b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz 0123456789!?"
                        if dialect == 1 else
                        b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz 0123456789!?")
            payload = tuple(rng.choice(alphabet) for _ in range(length))
            add((mode, dialect, *payload))
        add((0, 1, *([65] * 1024)), 5120)
        add((0, 1, *([65] * 1024)), 5119)
        add((0, 0, 65), 5)
        add((0, 0, 65), 4)
        for values in ((), (0,), (0, 0, 128), (0, 3, 65), (2, 0, 65),
                       (0, 1, 65, 33), (1, 0, 66, 66, 65, 66, 65),
                       (1, 1, 66, 66, 66, 66, 66), (0, 2, 89),
                       (1, 2, 65, 65, 65, 65, 65, 65)):
            add(values)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "auto_correlation":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes", 1016)
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid auto-correlation output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = auto_correlation_verifier_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = auto_correlation_verifier_oracle(values)
            capacity = case.get("workspace_bytes", default_capacity)
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261023)
        for _ in range(96):
            count = rng.randrange(1, 65)
            add((count, *(rng.randrange(-1_000_000, 1_000_001) for _ in range(count))))
        maximum = (64, *([1_000_000 if index % 2 == 0 else -1_000_000 for index in range(64)]))
        add(maximum, 1016)
        add(maximum, 1015)
        for values in ((), (0,), (65, 0), (1,), (1, 1_000_001),
                       (1, -1_000_001), (2, 0), (1, 0, 0)):
            add(values)
        add((1, -3), 8)
        add((1, -3), 7)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "association":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes", 32752)
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid association output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = association_verifier_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = association_verifier_oracle(values)
            capacity = case.get("workspace_bytes", default_capacity)
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        for values in ((1, 1, 1), (3, 3, 1, 2, 4), (4, 4, 0, 0, 0, 0)):
            add(values)
        maximum = (64, 11, *([2047] * 64))
        add(maximum, 32752)
        add(maximum, 32751)
        for values in ((), (0, 1), (1, 0), (65, 1, 0), (1, 12, 0),
                       (2, 2, 0), (1, 1, -1), (1, 1, 2), (1, 1, 0, 0)):
            add(values)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "booths_algorithm":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes", 256)
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid Booth rotation output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = booths_algorithm_verifier_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = booths_algorithm_verifier_oracle(values)
            capacity = case.get("workspace_bytes", default_capacity)
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        for byte in range(128):
            add((byte,))
        rng = random.Random(20261022)
        for _ in range(128):
            length = rng.randrange(1, 65)
            add(tuple(rng.randrange(128) for _ in range(length)))
        add(tuple([127] * 256))
        add(tuple(range(127, -1, -1)) + tuple(range(127, -1, -1)))
        for values in ((), (-1,), (128,), tuple([65] * 257),
                       (-(2**63),), (2**63 - 1,)):
            add(values)
        add((97, 98), 2)
        add((97, 98), 1)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "allocation_number":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes", 2048)
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid allocation-number output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = allocation_number_verifier_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = allocation_number_verifier_oracle(values)
            capacity = case.get("workspace_bytes", default_capacity)
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        for values in ((1, 1), (127, 127), (1_000_000, 1), (999_999, 127), (1_000_000, 128)):
            add(values)
        for values in ((), (1,), (0, 1), (10, 0), (2, 3), (-1, 1),
                       (1_000_001, 1), (1000, 129), (10, 1000)):
            add(values)
        probe = (10, 3)
        probe_result, probe_output = allocation_number_verifier_oracle(probe)
        add(probe, probe_result)
        add(probe, probe_result - 1)
        maximum = (1_000_000, 128)
        maximum_result, _ = allocation_number_verifier_oracle(maximum)
        add(maximum, maximum_result)
        add(maximum, maximum_result - 1)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "depreciation":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes", 128)
        absolute_tolerance = workload["output"].get("absolute_tolerance", 1.0e-9)
        relative_tolerance = workload["output"].get("relative_tolerance", 1.0e-12)
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid depreciation output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = depreciation_oracle(values, capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = depreciation_oracle(values, capacity)
            expected_values = case.get("expected_output", [])
            actual_values = (struct.unpack("<" + "d" * (len(output) // 8), output)
                             if output else ())
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != result
                    or len(expected_values) != len(actual_values)
                    or any(not math.isclose(actual, expected, abs_tol=absolute_tolerance,
                                            rel_tol=relative_tolerance)
                           for actual, expected in zip(actual_values, expected_values))):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        for values in (
            (0, 1, 1_000_000, 0), (1, 1, 1_000_000, 0, 1_000_000),
            (2, 1_000_000, 0, 2, -1, 3), (3, 1, 1_000_000, 0),
            (4, 1, 1_000_000, 0),
            (), (0, 0, 1_000_000, 0), (0, 17, 1_000_000, 0),
            (0, 1, -1, 0), (0, 1, 1_000_000_000_001, 0),
            (0, 1, 1_000_000, 1_000_001), (1, 1, 1_000_000, 0, 0),
            (2, 1_000_000, 0, 2, 40, 40),
            (4, 1, 1_000_000, 0, 7),
        ):
            add(values)
        maximum = (0, 16, 1_000_000_000_000, 0)
        add(maximum, 128)
        add(maximum, 127)
        exact = (0, 5, 100_000_000, 10_000_000)
        add(exact, 40)
        add(exact, 39)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "all_construct":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes", 53248)
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid all-construct output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = all_construct_verifier_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = all_construct_verifier_oracle(values)
            capacity = case.get("workspace_bytes", default_capacity)
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        maximum = tuple([6, *([97] * 6), 4, *([1, 97] * 4)])
        maximum_result, maximum_output = all_construct_verifier_oracle(maximum)
        add(maximum)
        add(maximum, len(maximum_output) - 1)
        for values in (
            (), (0,), (7, *([97] * 7), 0), (1, 97), (0, 5),
            (1, 65, 0), (1, 97, 1), (1, 97, 1, 0),
            (1, 97, 1, 7, *([97] * 7)), (1, 97, 1, 1, 65),
            (0, 0, 0),
        ):
            add(values)
        add((0, 0), 1)
        add((0, 0), 0)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "upper":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes", 256)
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid uppercase output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = upper_verifier_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = upper_verifier_oracle(values)
            capacity = case.get("workspace_bytes", default_capacity)
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        for byte in range(128):
            add((byte,))
        add(tuple([97] * 256))
        for values in (
            (-1,), (128,), (9,), (10,), (11,), (12,), (13,), (32,),
            tuple([65] * 257), (-(2**63),), (2**63 - 1,),
        ):
            add(values)
        add((97,), 1)
        add((97,), 0)
        add((), 0)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "adfgvxcipher":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes", 512)
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid ADFGVX output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = adfgvxcipher_verifier_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = adfgvxcipher_verifier_oracle(values)
            capacity = case.get("workspace_bytes", default_capacity)
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        for byte in range(128):
            add((0, 1, 1, byte, 65))
        maximum_plaintext = tuple([0, 256, 16] + [65] * 256 + list(range(65, 81)))
        maximum_ciphertext = tuple([1, 512, 16] + list((b"ADFGVX" * 86)[:512]) + list(range(65, 81)))
        add(maximum_plaintext)
        add(maximum_ciphertext)

        def encrypted_label_input(fractionated: bytes, key: bytes) -> tuple[int, ...]:
            row_count = (len(fractionated) + len(key) - 1) // len(key)
            grid: list[list[int | None]] = [[None] * len(key) for _ in range(row_count)]
            for index, label in enumerate(fractionated):
                grid[index // len(key)][index % len(key)] = label
            transposed = [grid[row][column]
                          for column in sorted(range(len(key)), key=key.__getitem__)
                          for row in range(row_count) if grid[row][column] is not None]
            return (1, len(transposed), len(key), *transposed, *key)

        labels = b"ADFGVX"
        partial_column_decrypt = encrypted_label_input(b"ADFGVXADFGVX", b"ZEBRA")
        all_square_pairs = b"".join(bytes((row, column)) for row in labels for column in labels)
        all_pair_decrypt = encrypted_label_input(all_square_pairs, b"A")
        add(partial_column_decrypt)
        add(all_pair_decrypt)
        for values in (
            (), (2, 0, 1, 65), (0, 1, 0, 65), (0, 1, 17, 65),
            (0, 2, 1, 65, 66), (0, 1, 1, 128, 65),
            (0, 257, 1, *([65] * 257), 66),
            (0, 1, 1, 65, 97),
            (1, 1, 1, 65, 65), (1, 3, 1, 65, 68, 71, 65),
            (1, 2, 1, 65, 66, 65),
        ):
            add(values)
        add((0, 1, 1, 65, 65), 2)
        add((0, 1, 1, 65, 65), 1)
        add((1, 2, 1, 65, 68, 65), 0)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "centroid_decomposition":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if (type(default_capacity) is not int or default_capacity < 0
                or default_capacity > MAX_OUTPUT_CAPACITY):
            raise ValueError("invalid centroid-decomposition output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = centroid_decomposition_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        def encode_edges(node_count: int, edges: list[tuple[int, int]]) -> tuple[int, ...]:
            return (node_count, *(endpoint for edge in edges for endpoint in edge))

        def prufer_tree(node_count: int, code: tuple[int, ...]) -> list[tuple[int, int]]:
            degree = [1] * node_count
            for node in code:
                degree[node] += 1
            edges: list[tuple[int, int]] = []
            for node in code:
                leaf = next(index for index, count in enumerate(degree) if count == 1)
                edges.append((leaf, node))
                degree[leaf] -= 1
                degree[node] -= 1
            remaining = [index for index, count in enumerate(degree) if count == 1]
            edges.append((remaining[0], remaining[1]))
            return edges

        # Every labeled tree through five vertices exercises different topology
        # and centroid ties. Prüfer enumeration is independent of the ports.
        add((1,))
        for node_count in range(2, 6):
            for code in product(range(node_count), repeat=node_count - 2):
                edges = prufer_tree(node_count, code)
                add(encode_edges(node_count, edges))
                add(encode_edges(node_count, [(right, left) for left, right in reversed(edges)]))

        rng = random.Random(20261016)
        for _ in range(96):
            node_count = rng.randrange(1, MAX_CENTROID_NODES + 1)
            edges = [(rng.randrange(node), node) for node in range(1, node_count)]
            rng.shuffle(edges)
            edges = [(right, left) if rng.randrange(2) else (left, right)
                     for left, right in edges]
            add(encode_edges(node_count, edges))

        malformed = (
            (), (0,), (MAX_CENTROID_NODES + 1,), (2, 0),
            (2, 0, 2), (2, 1, 1), (3, 0, 1, 1),
            (3, 0, 1, 1, 0), (4, 0, 1, 1, 2, 2, 0),
            (-(2**63),), (2**63 - 1,),
        )
        for values in malformed:
            add(values)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = centroid_decomposition_oracle(values)
            capacity = case.get("workspace_bytes", default_capacity)
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_output = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        max_path = encode_edges(MAX_CENTROID_NODES,
                                [(node - 1, node) for node in range(1, MAX_CENTROID_NODES)])
        add(max_path, MAX_CENTROID_OUTPUT_BYTES - 1)
        add(max_path, 0)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "canny":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or not 1 <= default_capacity <= MAX_OUTPUT_CAPACITY:
            raise ValueError("invalid Canny output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = canny_oracle(list(values))
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for pixel in range(256):
            add((1, pixel))
        for pattern in range(1 << 9):
            add((3, *(255 if pattern & (1 << index) else 0 for index in range(9))))
        rng = random.Random(20261020)
        for _ in range(96):
            side = rng.randrange(1, 17)
            add((side, *(rng.randrange(256) for _ in range(side * side))))

        malformed = (
            (), (0,), (17,), (3, 0, 1), (1, -1), (1, 256),
            (-(1 << 63),), ((1 << 63) - 1,),
        )
        for values in malformed:
            add(values)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = canny_oracle(list(values))
            capacity = case.get("workspace_bytes", default_capacity)
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_output = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        add((8, *([0] * 64)), 0)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "cholesky_decomposition":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes", 288)
        absolute_tolerance = workload["output"].get("absolute_tolerance", 1.0e-9)
        relative_tolerance = workload["output"].get("relative_tolerance", 1.0e-9)
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid Cholesky output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = cholesky_decomposition_oracle(values, capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = cholesky_decomposition_oracle(values, capacity)
            expected_vector = case.get("expected_output", [])
            actual_vector = (struct.unpack("<" + "d" * (len(output) // 8), output)
                             if output else ())
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != result
                    or len(expected_vector) != len(actual_vector)
                    or any(not math.isclose(actual, expected, abs_tol=absolute_tolerance,
                                            rel_tol=relative_tolerance)
                           for actual, expected in zip(actual_vector, expected_vector))):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        for values in (
            (), (0,), (7,), (2, 4_000_000, 1_000_000, 1_000_000),
            (1, 1_000_000_001), (1, -(2**63)), (1, 2**63 - 1),
            (2, 1_000_000, 2_000_000, 2_000_000, 1_000_000),
        ):
            add(values)
        add((1, 4_000_000), 7)
        add((1, 4_000_000), 0)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "adagrad":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes", 2048)
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid AdaGrad output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = adagrad_verifier_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = adagrad_verifier_oracle(values)
            capacity = case.get("workspace_bytes", default_capacity)
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or ("expected_output_hex" in case
                        and case["expected_output_hex"].lower() != expected_bytes.hex())):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        add((1, 100_000_000, 10, 0, 1_000_000_000, 100_000_000))
        add((2, 100_000_000, 10, 2, 0, 250_000_000, 2, 500_000_000, -250_000_000))
        add((1, 1, 1, 15, -1_000_000_000_000_000, -1_000_000_000_000))
        upper_bound_trace = (1, 1_000_000_000, 10_000_000, 15,
                             1_000_000_000_000_000, 1_000_000_000_000)
        add(upper_bound_trace)
        add((1, 100_000_000, 10, 0, 1_000_000_000, 100_000_000), 8)
        for values in (
            (), (1, 1, 1), (0, 1, 1, 0, 0, 0), (257, 1, 1),
            (1, 0, 1, 0, 0, 0), (1, 1_000_000_001, 1, 0, 0, 0),
            (1, 1, 10_000_001, 0, 0, 0), (1, 1, 1, 16, 0, 0),
            (1, 1, 1, 0, 1_000_000_000_000_001, 0),
            (1, 1, 1, 0, 0, 1_000_000_000_001),
            (-(2**63), 1, 1, 0, 0, 0), (2**63 - 1, 1, 1, 0, 0, 0),
        ):
            add(values)
        add((1, 100_000_000, 10, 0, 1_000_000_000, 100_000_000), 7)
        add((1, 100_000_000, 10, 0, 1_000_000_000, 100_000_000), 0)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "adam":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes", 32768)
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid Adam output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = adam_verifier_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = adam_verifier_oracle(values)
            capacity = case.get("workspace_bytes", default_capacity)
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or ("expected_output_hex" in case
                        and case["expected_output_hex"].lower() != expected_bytes.hex())):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        add((1, 1, 1_000_000_000, 0, 0, 10_000_000, 100_000_000,
             1_000_000_000_000_000, 1_000_000_000_000))
        maximum_trace = tuple([256, 16, 1_000_000, 900_000_000, 999_000_000, 10, 0]
                              + [0] * 16 + [0] * (256 * 16))
        add(maximum_trace)
        one_parameter = (1, 1, 1_000_000, 900_000_000, 999_000_000, 10, 0,
                         100_000_000, 200_000_000)
        add(one_parameter, 8)
        add(one_parameter, 7)
        for values in (
            (), (1, 1, 1, 1, 1, 1, 0), (0, 1, 1, 0, 0, 1, 0, 0),
            (257, 1, 1, 0, 0, 1, 0, 0), (1, 0, 1, 0, 0, 1, 0),
            (1, 17, 1, 0, 0, 1, 0), (1, 1, 0, 0, 0, 1, 0, 0, 0),
            (1, 1, 1_000_000_001, 0, 0, 1, 0, 0, 0),
            (1, 1, 1, -1, 0, 1, 0, 0, 0),
            (1, 1, 1, 1_000_000_000, 0, 1, 0, 0, 0),
            (1, 1, 1, 0, 0, 0, 0, 0, 0),
            (1, 1, 1, 0, 0, 1, 100_000_001, 0, 0),
            (1, 1, 1, 0, 0, 1, 0, 1_000_000_000_000_001, 0),
            (1, 1, 1, 0, 0, 1, 0, 0, 1_000_000_000_001),
            (-(2**63), 1, 1, 0, 0, 1, 0, 0, 0),
        ):
            add(values)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "adams_bashforth":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes", 2048)
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid Adams-Bashforth output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = adams_bashforth_verifier_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = adams_bashforth_verifier_oracle(values)
            capacity = case.get("workspace_bytes", default_capacity)
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        for order in (2, 3, 4, 5):
            add((order, 4, *([0] * order)))
            add((order, 1, *([-100_000, 100_000, -25_000, 50_000, 75_000][:order])))
        for values in (
            (), (2, 1), (1, 1, 0), (6, 1, 0, 0, 0, 0, 0),
            (2, 0, 0, 0), (2, 5, 0, 0), (2, 1, -100_001, 0),
            (2, 1, 0, 100_001), (-(2**63), 1, 0, 0),
        ):
            add(values)
        probe = (2, 1, 100_000, 100_000)
        probe_result, probe_output = adams_bashforth_verifier_oracle(probe)
        add(probe, len(probe_output))
        add(probe, max(0, len(probe_output) - 1))
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "adaline_learning":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes", 168)
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid ADALINE output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = adaline_learning_verifier_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = adaline_learning_verifier_oracle(values)
            capacity = case.get("workspace_bytes", default_capacity)
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        max_rows = tuple([32, 8, 1, 1, 1] + [value for _ in range(32) for value in ([0] * 8 + [1])])
        add(max_rows)
        add(max_rows, 167)
        small = (1, 1, 1, 1, 1, 0, 1)
        add(small, 16)
        add(small, 15)
        for values in (
            (), (0, 1, 1, 1, 1, 0, 1), (33, 1, 1, 1, 1),
            (1, 0, 1, 1, 1, 1), (1, 9, 1, 1, 1),
            (1, 1, 0, 1, 1, 0, 1), (1, 1, 2, 1, 1, 0, 1),
            (1, 1, 1, 0, 1, 0, 1), (1, 1, 1, 13, 1, 0, 1),
            (1, 1, 1, 1, 0, 0, 1), (1, 1, 1, 1, 501, 0, 1),
            (1, 1, 1, 1, 1, 0, 0), (1, 1, 1, 1, 1, 17, 1),
            (1, 1, 1, 1, 1, 0, 2),
        ):
            add(values)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "acronym":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = 79

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = acronym_verifier_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for length in range(5):
            for text in product((9, 32, 33, 45, 65, 97, 127), repeat=length):
                add(tuple(text))

        for byte in range(1, 128):
            add((byte,))
        add(tuple([97] * 79))

        malformed = (
            (-1,), (0,), (128,), (-(1 << 63),), tuple([65] * 80),
        )
        for values in malformed:
            add(values)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = acronym_verifier_oracle(values)
            capacity = case.get("workspace_bytes", len(output))
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        add((), 0)
        add((65, 32, 66), 1)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "account_merge":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes", 75000)

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = account_merge_verifier_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        def encode_accounts(accounts: list[tuple[bytes, list[bytes]]]) -> tuple[int, ...]:
            values = [len(accounts)]
            for name, emails in accounts:
                values.extend((len(name), *name, len(emails)))
                for email in emails:
                    values.extend((len(email), *email))
            return tuple(values)

        add((0,))
        valid_accounts = (
            [(b"Alice", [])],
            [(b"Sam", [b"x@example.test"]),
             (b"Sam", [b"x@example.test", b"y@example.test"])],
            [(b"Riley", [b"one@x.test", b"two@x.test"]),
             (b"Riley", [b"two@x.test", b"three@x.test"]),
             (b"Riley", [b"three@x.test", b"four@x.test"])],
            [(b"Lee", []), (b"Sam", [b"z@x.test"]),
             (b"Lee", []), (b"Sam", [b"a@x.test"])],
            [(b"A", [b"same@x.test", b"same@x.test", b"b@x.test"])],
        )
        for accounts in valid_accounts:
            add(encode_accounts(accounts))

        malformed = (
            (), (-1,), (65,), (1,), (1, 0), (1, 1),
            (1, 1, 31, 0), (1, 1, 65, -1), (1, 1, 65, 1025),
            (1, 1, 65, 1), (1, 1, 65, 1, 0),
            (1, 1, 65, 1, 1, 32), (1, 1, 65, 1, 1, 128),
            (0, 0), (1, 1, 65, 0, 99),
            encode_accounts([(b"First", [b"shared@x.test"]),
                             (b"Second", [b"shared@x.test"])]),
        )
        for values in malformed:
            add(values)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = account_merge_verifier_oracle(values)
            capacity = case.get("workspace_bytes", default_capacity)
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        add((0,), 1)
        add(encode_accounts([(b"A", [])]), 6)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "continued_fraction":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes", MAX_CONTINUED_FRACTION_OUTPUT_LENGTH)

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = continued_fraction_oracle(list(values), capacity)
            cases[(values, capacity)] = (result, output)

        for numerator in range(-12, 13):
            for denominator in range(-12, 13):
                if denominator != 0:
                    add((numerator, denominator))

        boundaries = (-MAX_CONTINUED_FRACTION_ABS_INPUT, -1, 0, 1,
                      MAX_CONTINUED_FRACTION_ABS_INPUT)
        for numerator in boundaries:
            for denominator in boundaries:
                if denominator != 0:
                    add((numerator, denominator))

        for values in (
            (832040, 514229), (-832040, 514229),
            (514229, 832040), (-514229, -832040),
            (), (1,), (1, 2, 3), (1, 0),
            (MAX_CONTINUED_FRACTION_ABS_INPUT + 1, 1),
            (1, MAX_CONTINUED_FRACTION_ABS_INPUT + 1),
            (-(MAX_CONTINUED_FRACTION_ABS_INPUT + 1), 1),
            (1, -(MAX_CONTINUED_FRACTION_ABS_INPUT + 1)),
            (-(1 << 63), 1), ((1 << 63) - 1, 1),
        ):
            add(values)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = continued_fraction_oracle(list(values), capacity)
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        add((9, 4), 7)
        add((5, 0), 0)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "remove_duplicate_words":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes", MAX_REMOVE_DUPLICATE_WORDS_INPUT_LENGTH)

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = remove_duplicate_words_oracle(list(values))
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for length in range(4):
            for text in product((0, 9, 10, 13, 32, 65, 66, 97, 98), repeat=length):
                add((length, *text))

        add((MAX_REMOVE_DUPLICATE_WORDS_INPUT_LENGTH,
             *([97] * MAX_REMOVE_DUPLICATE_WORDS_INPUT_LENGTH)))

        malformed = (
            (), (-1,), (MAX_REMOVE_DUPLICATE_WORDS_INPUT_LENGTH + 1,),
            (2, 65), (1, 128), (1, 256), (1, -1),
            (0, *([65] * (MAX_REMOVE_DUPLICATE_WORDS_INPUT_LENGTH + 1))),
        )
        for values in malformed:
            add(values)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = remove_duplicate_words_oracle(list(values))
            capacity = case.get("workspace_bytes", default_capacity)
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        add((1, 65), 0)
        add((3, 9, 32, 13), 0)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "gronsfeld":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = MAX_GRONSFELD_TEXT_LENGTH

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = gronsfeld_oracle(list(values))
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for text_byte in range(1, 128):
            for digit in (0, 1, 9):
                add((text_byte, 0, 48 + digit))

        text_examples = (b"Attack at Dawn!", b"aZ-z A!9", b"123!?", bytes(range(1, 128)))
        key_examples = (b"0", b"123", b"987654", b"9876543210" * 6 + b"9876")
        for text in text_examples:
            for key in key_examples:
                add((*text, 0, *key))
        add((*([65] * MAX_GRONSFELD_TEXT_LENGTH), 0,
             *([57] * MAX_GRONSFELD_KEY_LENGTH)))

        malformed = (
            (), (65, 66), (65, 0), (0,), (0, 0),
            (-(1 << 63), 0, 48), (128, 0, 48),
            (65, 0, -1), (65, 0, 58),
            (*([65] * (MAX_GRONSFELD_TEXT_LENGTH + 1)), 0, 48),
            (0, 0, *([48] * (MAX_GRONSFELD_KEY_LENGTH + 1))),
        )
        for values in malformed:
            add(values)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = gronsfeld_oracle(list(values))
            capacity = case.get("workspace_bytes", len(output))
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        add((65, 0, 48), 0)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "remove_duplicate_characters":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = 128

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = remove_duplicate_characters_oracle(list(values))
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for length in range(6):
            for text in product((0, 1, 65, 127), repeat=length):
                add((length, *text))

        add((128, *range(128)))
        add((4096, *([*range(128)] * 32)))

        malformed = (
            (), (-1,), (MAX_REMOVE_DUPLICATE_CHARACTERS_INPUT_LENGTH + 1,),
            (2, 65), (1, 128), (1, 256), (1, -1),
            (0, *([65] * (MAX_REMOVE_DUPLICATE_CHARACTERS_INPUT_LENGTH + 1))),
        )
        for values in malformed:
            add(values)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = remove_duplicate_characters_oracle(list(values))
            capacity = case.get("workspace_bytes", default_capacity)
            expected_result = -2 if result >= 0 and capacity < len(output) else result
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        add((3, 65, 66, 67), 2)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "common_characters_frequency_quotient":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes", 64)

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = common_characters_frequency_quotient_oracle(list(values))
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        small_strings = ("", "a", "b", "aa", "ab", "ba", "bb")
        for string_count in range(4):
            for selected in product(small_strings, repeat=string_count):
                values = [string_count]
                for string in selected:
                    values.extend((len(string), *map(ord, string)))
                add(tuple(values))

        add((1, 64, *([ord("z")] * 64)))
        maximum = [16]
        for _ in range(16):
            maximum.extend((32, *([ord("q")] * 32)))
        add(tuple(maximum))

        too_many_characters = [9]
        for _ in range(9):
            too_many_characters.extend((64, *([ord("a")] * 64)))
        malformed = (
            (), (-1,), (17,), (1,), (2, 1, 97), (1, -1), (1, 65),
            (1, 1, 65), (1, 1, 32), (1, 0, 97),
            tuple(too_many_characters), (17, *([0] * 1041)),
        )
        for values in malformed:
            add(values)
        add((2, 2, 97, 97, 1, 98), 0)
        add((2, 2, 97, 97, 1, 98), 1)
        add((2, 2, 97, 97, 1, 65), 0)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = common_characters_frequency_quotient_oracle(list(values))
            capacity = case.get("workspace_bytes", default_capacity)
            expected_result = -2 if result >= 0 and capacity < len(output) else result
            expected_output = b"" if result >= 0 and capacity < len(output) else output
            if (case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "letter_combinations_of_phone_number":
        cases: dict[tuple[int, ...], tuple[int, bytes]] = {}
        for length in range(5):
            for values in product(range(2, 10), repeat=length):
                cases[values] = recorder_expected_output(list(values))
        rng = random.Random(20261014)
        for _ in range(256):
            length = rng.randrange(0, 7)
            values = tuple(rng.randrange(2, 10) for _ in range(length))
            cases[values] = recorder_expected_output(list(values))
        for values in ((0,), (1,), (10,), (-1,), (2, 1), (7, 10), (2, 3, 0),
                       (2, 3, 4, 5, 6, 7, 8)):
            cases[values] = recorder_expected_output(list(values))
        for case in workload["cases"]:
            values = tuple(case["input_values"])
            oracle = recorder_expected_output(list(values))
            if case["expected_result"] != oracle[0]:
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            cases[values] = oracle
        records.extend((values, count, output, None)
                       for values, (count, output) in sorted(cases.items()))
        # A zero-capacity call for a valid one-digit input must fail without writing.
        records.append(((2,), -2, b"", 0))
    elif algorithm == "blake2b":
        cases: dict[tuple[int, ...], tuple[int, bytes]] = {}
        rng = random.Random(20261015)
        lengths = (0, 1, 7, 8, 63, 64, 127, 128, 129, 255, 256, 257, 4095, 4096)
        for index, length in enumerate(lengths):
            values = tuple((index * 29 + offset * 73 + 11) & 255 for offset in range(length))
            cases[values] = blake2b_oracle(values)
        for _ in range(32):
            values = tuple(rng.randrange(256) for _ in range(rng.randrange(0, 513)))
            cases[values] = blake2b_oracle(values)
        for values in ((-1,), (256,), tuple(rng.randrange(256) for _ in range(4097))):
            cases[values] = blake2b_oracle(values)
        records.extend((values, count, output, 64)
                       for values, (count, output) in sorted(cases.items()))
        for case in workload["cases"]:
            values = tuple(case["input_values"])
            oracle = blake2b_oracle(values)
            capacity = case.get("workspace_bytes", 64)
            expected_count = (case.get("capacity_error_result", -2)
                              if capacity < len(oracle[1]) else oracle[0])
            expected_bytes = b"" if capacity < len(oracle[1]) else oracle[1]
            if (case["expected_result"] != expected_count
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            records.append((values, expected_count, expected_bytes, capacity))
        # A nonzero undersized buffer also must remain untouched after returning -2.
        records.append(((97, 98, 99), -2, b"", 63))
    elif algorithm == "title_case_conversion":
        cases: dict[tuple[int, ...], tuple[int, bytes]] = {}
        workload_records: list[tuple[tuple[int, ...], int, bytes, int]] = []
        for letter in range(ord("A"), ord("Z") + 1):
            for other in range(ord("a"), ord("z") + 1):
                values = (2, letter, other)
                cases[values] = title_case_oracle(values)
        valid_texts = (
            (), (ord("a"),), (ord("Z"),),
            (ord("h"), ord("E"), ord("L"), ord("L"), ord("o")),
            (ord("a"), 32, ord("b")),
            tuple((ord("a") if index == 0 or index % 2 == 0 else ord("B"))
                  for index in range(256)),
            tuple([ord("a")] + [value for _ in range(127)
                                 for value in (32, ord("B"))]),
        )
        for text_values in valid_texts:
            values = (len(text_values), *text_values)
            cases[values] = title_case_oracle(values)
        rng = random.Random(20261016)
        for _ in range(256):
            word_count = rng.randrange(1, 9)
            words = []
            remaining = rng.randrange(1, 257)
            for word_index in range(word_count):
                separators_left = word_count - word_index - 1
                max_word_length = max(1, remaining - separators_left)
                word_length = rng.randrange(1, min(20, max_word_length) + 1)
                words.extend(rng.choice((rng.randrange(65, 91), rng.randrange(97, 123)))
                             for _ in range(word_length))
                remaining -= word_length
                if separators_left:
                    words.append(32)
                    remaining -= 1
            text_values = tuple(words)
            values = (len(text_values), *text_values)
            cases[values] = title_case_oracle(values)
        malformed = (
            (), (-1,), (257,), (2, 97), (1, -1), (1, 256), (1, 0),
            (1, 32), (2, 32, 65), (2, 65, 32), (3, 65, 32, 32),
            (3, 65, 33, 66), (3, 65, 32, 66, 67),
        )
        for values in malformed:
            cases[values] = title_case_oracle(values)
        for case in workload["cases"]:
            values = tuple(case["input_values"])
            count, output = title_case_oracle(values)
            capacity = case.get("workspace_bytes", len(bytes.fromhex(case["expected_output_hex"])))
            expected_count = case.get("capacity_error_result", -2) if capacity < len(output) else count
            expected_output = b"" if capacity < len(output) else output
            if (case["expected_result"] != expected_count
                    or case.get("expected_output_hex", "").lower() != expected_output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            workload_records.append((values, expected_count, expected_output, capacity))
        records.extend((values, count, output, 257)
                       for values, (count, output) in sorted(cases.items()))
        records.extend(workload_records)
        # A valid empty payload and a valid one-letter payload both require a terminator.
        empty = (0,)
        letter = (1, ord("a"))
        records.append((empty, -2, b"", 0))
        records.append((letter, -2, b"", 1))
        records.append(((2, 97), -1, b"", 0))
    elif algorithm == "weight_conversions":
        cases: dict[tuple[int, ...], tuple[int, bytes]] = {}
        for operation in range(6):
            for amount in range(-32, 33):
                values = (operation, amount)
                cases[values] = weight_conversions_oracle(values)
            for amount in (-1_000_000, -1001, -17, -1, 0, 1, 16, 1000, 1001, 1_000_000):
                values = (operation, amount)
                cases[values] = weight_conversions_oracle(values)
        rng = random.Random(20261017)
        for _ in range(256):
            values = (rng.randrange(6), rng.randrange(-1_000_000, 1_000_001))
            cases[values] = weight_conversions_oracle(values)
        malformed = (
            (), (0,), (0, 0, 0), (-1, 0), (6, 0),
            (0, -1_000_001), (5, 1_000_001),
        )
        for values in malformed:
            cases[values] = weight_conversions_oracle(values)
        records.extend((values, count, output, 64)
                       for values, (count, output) in sorted(cases.items()))
        for case in workload["cases"]:
            values = tuple(case["input_values"])
            oracle = weight_conversions_oracle(values)
            capacity = case.get("workspace_bytes", 64)
            expected_count = -2 if capacity < len(oracle[1]) else oracle[0]
            expected_output = b"" if capacity < len(oracle[1]) else oracle[1]
            if (case["expected_result"] != expected_count
                    or case.get("expected_output_hex", "").lower() != expected_output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            records.append((values, expected_count, expected_output, capacity))
        records.append(((4, 1), -2, b"", 0))
        records.append(((4, 1), -2, b"", 1))
        records.append(((6, 0), -1, b"", 0))
    elif algorithm == "p_series":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes", 4953)
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid P-series output workspace size")

        def add(values: tuple[int, ...], capacity: int) -> None:
            result, output = p_series_oracle(list(values))
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for nth_term in range(-256, 257):
            for power in range(8):
                add((nth_term, power), default_capacity)
        for values in ((), (1,), (5, 2, 1), (-257, 2), (257, 2), (5, -1), (5, 8),
                       (2**63, 0), (-(2**63) - 1, 0)):
            add(values, default_capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = p_series_oracle(list(values))
            capacity = case.get("workspace_bytes", len(output))
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_output = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") != len(values)
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        # Exercise a small capacity failure independently of the publication workload.
        add((1, 0), 1)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "logarithmic_series":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes", 3240)
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid logarithmic-series output workspace size")

        def add(values: tuple[int, ...], capacity: int) -> None:
            result, output = logarithmic_series_oracle(list(values))
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for x_value in range(-10, 11):
            for n_terms in range(-64, 257):
                add((x_value, n_terms), default_capacity)
        for values in ((), (3,), (3, 5, 0), (-11, 1), (11, 1), (1, -65), (1, 257),
                       (2**63, 0), (-(2**63) - 1, 0)):
            add(values, default_capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = logarithmic_series_oracle(list(values))
            capacity = case.get("workspace_bytes", len(output))
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_output = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") != len(values)
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        # Exercise a short positive capacity and a nonempty output failure.
        add((3, 1), 7)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "proper_fractions":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes", 1892)
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid proper-fractions output workspace size")

        def add(values: tuple[int, ...], capacity: int) -> None:
            result, output = proper_fractions_oracle(list(values))
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for denominator in range(257):
            add((denominator,), default_capacity)
        for values in ((), (10, 1), (-1,), (257,), (-(2**63),), (2**63 - 1,)):
            add(values, default_capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = proper_fractions_oracle(list(values))
            capacity = case.get("workspace_bytes", len(output))
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_output = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") != len(values)
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        # Exercise a nonempty output failure at a small positive capacity.
        add((2,), 3)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "sumset":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes", 24006)
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid sumset output workspace size")

        def add(values: tuple[int, ...], capacity: int) -> None:
            result, output = sumset_oracle(list(values))
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        small_sets = [tuple(value - 2 for value, include in enumerate(flags) if include)
                      for flags in product((0, 1), repeat=5)]
        for set_a, set_b in product(small_sets, repeat=2):
            values = (len(set_a), len(set_b), *set_a, *set_b)
            add(values, default_capacity)

        malformed = (
            (), (1,), (-1, 0), (0, -1), (65, 0), (0, 65), (1, 1),
            (1, 0, -1001), (1, 0, 1001), (0, 1, -1001), (0, 1, 1001),
            (1, 1, 1001, 0), (1, 1, 0, -1001), (2, 1, 0, 1),
            (-(2**63), 0), (2**63, 0), (1, 0, -(2**63)),
        )
        for values in malformed:
            add(values, default_capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = sumset_oracle(list(values))
            capacity = case.get("workspace_bytes", default_capacity)
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_output = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") != len(values)
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        # Check a short capacity against a nonempty result and the smallest empty-result buffer.
        add((2, 2, 1, 5, 2, 6), 6)
        add((0, 0), 0)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "charoccurrence":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid charoccurrence output workspace size")

        def add(values: tuple[int, ...], capacity: int) -> None:
            result, output = charoccurrence_oracle(list(values))
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for codepoint in range(128):
            add((codepoint,), default_capacity)
        add((), 0)
        add((0, 0, 1, 1, 127, 127), default_capacity)
        add(tuple(range(MAX_CHAROCCURRENCE_INPUT_LENGTH)), default_capacity)
        malformed = (
            (-1,), (128,), (-(2**63),), (2**63 - 1,),
            tuple([65] * (MAX_CHAROCCURRENCE_INPUT_LENGTH + 1)),
        )
        for values in malformed:
            add(values, default_capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = charoccurrence_oracle(list(values))
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_output = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") != len(values)
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        add((65,), 3)
        null_input_key = ((65,), default_capacity - 1)
        cases[null_input_key] = (-1, b"")
        null_input_cases.add(null_input_key)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "serialize_deserialize_binary_tree":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid binary-tree serialization output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = serialize_deserialize_binary_tree_oracle(values, capacity)
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = serialize_deserialize_binary_tree_oracle(values, capacity)
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)

        def tree_tokens(node_count: int) -> list[str]:
            if node_count == 0:
                return ["null"]
            left_count = rng.randrange(node_count)
            value = rng.choice((-2**31, -1, 0, 1, 2**31 - 1, rng.randrange(-1000, 1001)))
            return ([str(value)] + tree_tokens(left_count)
                    + tree_tokens(node_count - left_count - 1))

        for _ in range(128):
            node_count = rng.randrange(0, 48)
            values = tuple(",".join(tree_tokens(node_count)).encode("ascii"))
            add(values)

        # 127 signed-i32 minimum values and all 128 null children reach the maximum output size.
        maximum_tokens: list[str] = []
        for _ in range(127):
            maximum_tokens.extend((str(-(2**31)), "null"))
        maximum_tokens.append("null")
        maximum_values = tuple(",".join(maximum_tokens).encode("ascii"))
        add(maximum_values, MAX_SERIALIZE_DESERIALIZE_BINARY_TREE_OUTPUT_LENGTH)
        add(maximum_values, MAX_SERIALIZE_DESERIALIZE_BINARY_TREE_OUTPUT_LENGTH - 1)

        malformed = (
            (), (ord("1"), ord(","), ord("n")),
            tuple(b"1,,null,null"), tuple(b"1,null,null,2"),
            tuple(b"2147483648,null,null"), tuple(b"--1,null,null"),
            tuple([ord("1")] * (MAX_SERIALIZE_DESERIALIZE_BINARY_TREE_INPUT_LENGTH + 1)),
            tuple(b"0,null,null"),
        )
        for values in malformed:
            add(values)

        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "create_binary_tree_from_inorder_preorder":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < MAX_CREATE_BINARY_TREE_OUTPUT_BYTES:
            raise ValueError("invalid traversal-built tree output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = create_binary_tree_oracle(values, capacity)
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = create_binary_tree_oracle(values, capacity)
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)

        def make_tree(count: int, pool: list[int]) -> tuple[int, object, object] | None:
            if count == 0:
                return None
            left_count = rng.randrange(count)
            value = pool.pop()
            left = make_tree(left_count, pool)
            right = make_tree(count - left_count - 1, pool)
            return value, left, right

        def traversals(node: object) -> tuple[list[int], list[int]]:
            if node is None:
                return [], []
            value, left, right = node
            left_pre, left_in = traversals(left)
            right_pre, right_in = traversals(right)
            return [value, *left_pre, *right_pre], [*left_in, value, *right_in]

        for _ in range(128):
            count = rng.randrange(MAX_CREATE_BINARY_TREE_INPUT_LENGTH // 2 + 1)
            pool = rng.sample(range(-1_000_000, 1_000_001), count)
            tree = make_tree(count, pool)
            preorder, inorder = traversals(tree)
            add((count, *preorder, *inorder))

        maximum_pool = list(range(MAX_CREATE_BINARY_TREE_INPUT_LENGTH // 2))
        maximum_tree = make_tree(MAX_CREATE_BINARY_TREE_INPUT_LENGTH // 2, maximum_pool)
        maximum_preorder, maximum_inorder = traversals(maximum_tree)
        maximum_values = (len(maximum_preorder), *maximum_preorder, *maximum_inorder)
        add(maximum_values, MAX_CREATE_BINARY_TREE_OUTPUT_BYTES)
        add(maximum_values, MAX_CREATE_BINARY_TREE_OUTPUT_BYTES - 1)

        for values in (
            (), (-1,), (64, *range(64), *range(64)),
            (2, 1, 1, 1, 1), (3, 1, 2, 3, 3, 1, 2),
            (1, 2**31, 2**31), (1, -(2**31) - 1, -(2**31) - 1),
            (1, 2**63 - 1, 2**63 - 1),
            (1,) * (MAX_CREATE_BINARY_TREE_INPUT_LENGTH + 1),
        ):
            add(values)

        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "binary_and_operator":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}

        def add(values: tuple[int, ...], capacity: int) -> None:
            result, output = recorder_expected_output(list(values), algorithm)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for first in (0, 1, 2, 7, 31, 255, 2**31 - 1):
            for second in (0, 1, 3, 16, 255, 2**30, 2**31 - 1):
                values = (first, second)
                result, output = recorder_expected_output(list(values), algorithm)
                add(values, max(0, result))
        malformed = ((), (0,), (1, 2, 3), (-1, 0), (0, -1), (2**31, 0), (0, 2**31))
        for values in malformed:
            add(values, 33)
        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = recorder_expected_output(list(values), algorithm)
            capacity = case.get("workspace_bytes", len(output))
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_output_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_output_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)
        add((2**31 - 1, 2**30), 32)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "entropy":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}

        def add(values: tuple[int, ...], capacity: int) -> None:
            result, output = entropy_oracle(list(values))
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        # Exercise every possible single ASCII input byte and both legal payload sizes.
        for codepoint in range(128):
            add((1, codepoint), 13)
        add((1, 97), 11)
        signed_line_case = next(
            tuple(case["input_values"])
            for case in workload["cases"]
            if case["id"] == "insufficient_capacity_for_signed_line"
        )
        add(signed_line_case, 13)
        add(signed_line_case, 12)
        add(tuple([MAX_ENTROPY_TEXT_LENGTH, *(
            (97, 65, 32, 33, 98, 66, 63, 99, 67, 95)[index % 10]
            for index in range(MAX_ENTROPY_TEXT_LENGTH)
        )]), 13)

        malformed = (
            (), (1,), (0,), (1, 128), (1, -1), (3, 97, 98),
            (-(2**63), 97), (1, 97, 98),
            tuple([MAX_ENTROPY_TEXT_LENGTH + 1] + [97] * (MAX_ENTROPY_TEXT_LENGTH + 1)),
            (2**63, 97),
        )
        for values in malformed:
            add(values, 13)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = entropy_oracle(list(values))
            capacity = case.get("workspace_bytes", len(output))
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_output = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") != len(values)
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "rna_transcription":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}

        def add(values: tuple[int, ...], capacity: int) -> None:
            result, output = recorder_expected_output(list(values), algorithm)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        alphabet = (ord("A"), ord("C"), ord("G"), ord("T"))
        for length in range(6):
            for payload in product(alphabet, repeat=length):
                values = (0, *payload)
                result, output = recorder_expected_output(list(values), algorithm)
                add(values, max(0, result))

        add(tuple([0, *((65, 67, 71, 84)[index % 4]
                        for index in range(1000))]), 1000)
        malformed = (
            (), (1,), (1, 65), (0, 97), (0, 78), (0, 256), (0, -1),
            (0, 65, 256), (-(2**63), 65),
            tuple([0, *([65] * 1001)]),
        )
        for values in malformed:
            add(values, 1000)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = recorder_expected_output(list(values), algorithm)
            capacity = case.get("workspace_bytes", len(output))
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_output_bytes = b"" if result >= 0 and capacity < len(output) else output
            declared_output = case.get("expected_output", "").encode("utf-8")
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or declared_output != expected_output_bytes):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        add((0, 65), 0)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "gronsfeld_cipher":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = 256

        def add(values: tuple[int, ...], capacity: int) -> None:
            result, output = recorder_expected_output(list(values), algorithm)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for text_byte in range(1, 128):
            for digit in range(10):
                add((text_byte, 0, 48 + digit), default_capacity)
        text_examples = (
            b"Hello, World!", b"ATTACK", b"a a-a", b"123!?", b"Zz9. ",
        )
        key_examples = (b"0", b"123", b"987654", b"9876543210" * 6 + b"9876")
        for text in text_examples:
            for key in key_examples:
                add((*text, 0, *key), default_capacity)
        add((*([65] * 256), 0, *([57] * 64)), default_capacity)
        add((*([33] * 256), 0), default_capacity)

        malformed = (
            (), (65, 66), (65, 0), (65, 0, 120),
            (65, 0, 49, 0), (128, 0, 49), (0, *([49] * 65)),
            (*([65] * 257), 0, 49), (-(2**63), 0, 49),
        )
        for values in malformed:
            add(values, default_capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = recorder_expected_output(list(values), algorithm)
            capacity = case.get("workspace_bytes", len(output))
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        add((65, 0, 49), 0)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "a5_cipher":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = 128

        def add(values: tuple[int, ...], capacity: int) -> None:
            result, output = recorder_expected_output(list(values), algorithm)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        def signed_i64(value: int) -> int:
            value &= (1 << 64) - 1
            return value if value < (1 << 63) else value - (1 << 64)

        plaintext_patterns = (
            (0, 0, 0, 0),
            (-1, -1, -1, -1),
            (1, 0, 0, 0),
            (0, 0, 0, -(1 << 63)),
            tuple(signed_i64(0xAAAAAAAAAAAAAAAA if index % 2 == 0
                             else 0x5555555555555555) for index in range(4)),
        )
        keys = (0, 1, -(1 << 63), -1)
        frames = (0, 1, (1 << 21), (1 << 22) - 1)
        for block_count in range(1, 5):
            for key in keys:
                for frame in frames:
                    for pattern in plaintext_patterns:
                        words = pattern * block_count
                        add((key, frame, block_count, *words), default_capacity)

        for values in (
            (), (0,), (0, 0), (0, 0, 0), (0, 0, 1),
            (0, 0, 1, 0, 0, 0),
            (0, 0, -1, *([0] * 4)),
            (0, 0, 5, *([0] * 20)),
            (0, 1 << 22, 1, 0, 0, 0, 0),
            (-(1 << 63), 0, 1, 0, 0, 0, 0),
        ):
            add(values, default_capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = recorder_expected_output(list(values), algorithm)
            capacity = case.get("workspace_bytes", len(output))
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        add((0, 0, 1, 0, 0, 0, 0), 31)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "a5_key_stream_generator":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = 116

        def add(values: tuple[int, ...], capacity: int) -> None:
            result, output = recorder_expected_output(list(values), algorithm)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for stream_count in range(1, 5):
            for key in (0, 1, -(1 << 63), -1):
                for frame in (0, 1, 1 << 21, (1 << 22) - 1):
                    add((key, frame, stream_count), default_capacity)

        for values in (
            (), (0,), (0, 0), (0, 0, 0), (0, 0, -1), (0, 0, 5),
            (0, 0, 1, 0), (0, 0, 4, 0),
        ):
            add(values, default_capacity)
        add((0, 1 << 22, 1), default_capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = recorder_expected_output(list(values), algorithm)
            capacity = case.get("workspace_bytes", len(output))
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        add((0, 0, 1), 28)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "aatree":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = 1024

        def add(values: tuple[int, ...], capacity: int) -> None:
            result, output = recorder_expected_output(list(values), algorithm)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        def pack(operations: tuple[tuple[int, int], ...] | list[tuple[int, int]]) -> tuple[int, ...]:
            return (len(operations), *(value for operation in operations for value in operation))

        add((0,), default_capacity)
        add(pack([(0, key) for key in range(1, 33)] +
                 [(2, 16), (2, 99), (3, 0), (4, 0)]), default_capacity)
        add(pack([(0, key) for key in (4, 2, 6, 1, 3, 5, 7)] +
                 [(3, 0), (4, 0), (1, 4), (3, 0), (1, 2), (2, 5), (4, 0)]),
            default_capacity)
        add(pack([(0, key) for key in (-(1 << 31), 0, (1 << 31) - 1)] +
                 [(3, 0), (4, 0), (2, -(1 << 31)), (1, 0), (2, 0)]),
            default_capacity)
        add(pack([(0, key) for key in range(256)]), default_capacity)

        malformed = (
            (), (-1,), (257,), (1,), (0, 0),
            (1, 5, 0), (1, 0, 1 << 31), (1, 1, -(1 << 31) - 1),
            (1, 3, 1), (1, 4, -1), (2, 0, 7, 0, 7),
            (1, 1, 7), (1, 3, 0), (1, 4, 0),
        )
        for values in malformed:
            add(values, default_capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = recorder_expected_output(list(values), algorithm)
            capacity = case.get("workspace_bytes", len(output))
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        add((1, 0, 1), 3)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "next_permutation":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = 512

        def add(values: tuple[int, ...], capacity: int) -> None:
            result, output = recorder_expected_output(list(values), algorithm)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for length in range(6):
            for sequence in product((-1, 0, 1), repeat=length):
                add((length, *sequence), default_capacity)
        add((128, *range(128)), default_capacity)

        malformed = (
            (), (-1,), (129,), (2, 7), (1, 2**31), (1, -(2**31) - 1),
            (1, 2**63), (1, -(2**63)),
        )
        for values in malformed:
            add(values, default_capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = recorder_expected_output(list(values), algorithm)
            capacity = case.get("workspace_bytes", len(output))
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        add((1, 4), 3)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "naive_search":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = 256

        def add(values: tuple[int, ...], capacity: int) -> None:
            result, output = recorder_expected_output(list(values), algorithm)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        alphabet = (1, 65)
        for text_length in range(5):
            for pattern_length in range(4):
                for text in product(alphabet, repeat=text_length):
                    for pattern in product(alphabet, repeat=pattern_length):
                        values = (text_length, pattern_length, *text, *pattern)
                        add(values, default_capacity)

        add((255, 0, *([65] * 255)), default_capacity)
        add((255, 1, *([65] * 255), 65), default_capacity)
        malformed = (
            (), (0,), (0, 0, 65), (256, 0), (-1, 0),
            (1, 1, 0, 65), (1, 1, 128, 65), (1, 1, -1, 65),
            (2, 2, 65, 66, 65),
        )
        for values in malformed:
            add(values, default_capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = recorder_expected_output(list(values), algorithm)
            capacity = case.get("workspace_bytes", len(output))
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        add((1, 1, 65, 65), 0)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "inverse_fast_fourier_transform":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = 512

        def add(values: tuple[int, ...], capacity: int) -> None:
            result, output = recorder_expected_output(list(values), algorithm)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for count in (1, 2, 4, 8, 16, 32, 64):
            zero = (count, *(0 for _ in range(2 * count)))
            add(zero, default_capacity)
            impulse = (count, 1000, 0,
                       *(component for _ in range(count - 1) for component in (0, 0)))
            add(impulse, default_capacity)
            alternating = (count, *(component for index in range(count)
                                     for component in ((1000, -1000) if index % 2 == 0
                                                       else (-1000, 1000))))
            add(alternating, default_capacity)
        for components in product((-1, 0, 1), repeat=4):
            add((2, *components), default_capacity)
        for components in product((-1, 0, 1), repeat=8):
            add((4, *components), default_capacity)

        malformed = (
            (), (0,), (1,), (3, 1, 0, 2, 0, 3, 0),
            (2, 1, 0), (2, 1, 0, 2, 0, 3),
            (1, 1001, 0), (1, -1001, 0), (64, *([0] * 127)),
            (65, *([0] * 130)),
        )
        for values in malformed:
            add(values, default_capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = recorder_expected_output(list(values), algorithm)
            capacity = case.get("workspace_bytes", len(output))
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_output = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        add((1, 7, -11), 7)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "infix_to_prefix":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = 256

        def add(values: tuple[int, ...], capacity: int) -> None:
            result, output = recorder_expected_output(list(values), algorithm)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for operand in b"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz":
            add((operand,), default_capacity)
        operators = b"+-*/^"
        for left in b"a0Z9":
            for right in b"b1Y8":
                for operator in operators:
                    expression = (40, left, operator, right, 41)
                    add(expression, default_capacity)

        nested = b"a"
        for _ in range(6):
            nested = b"(" + nested + b"+" + nested + b")"
            add(tuple(nested), default_capacity)

        malformed = (
            (), (32,), (97, 43, 98), (40, 41), (40, 97, 43, 41),
            (40, 97, 43, 98), (40, 97, 37, 98, 41),
            (40, 97, 43, 128, 41), (0, 0, 0),
            tuple([65] * 257),
        )
        for values in malformed:
            add(values, default_capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = recorder_expected_output(list(values), algorithm)
            capacity = case.get("workspace_bytes", len(output))
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_output = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        add(tuple(b"(a+b)"), 2)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "unique_permutation":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = 4320

        def add(values: tuple[int, ...], capacity: int) -> None:
            result, output = recorder_expected_output(list(values), algorithm)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        alphabet = (0, 65, 66, 127)
        for length in range(7):
            for sequence in product(alphabet, repeat=length):
                values = (length, *sequence)
                add(values, default_capacity)
        maximum_distinct = (6, 33, 34, 35, 36, 37, 38)
        add(maximum_distinct, default_capacity)

        malformed = (
            (), (1,), (-1,), (7, 65), (2, 65), (1, -1), (1, 128),
            (1, 2**63),
        )
        for values in malformed:
            add(values, default_capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = recorder_expected_output(list(values), algorithm)
            capacity = case.get("workspace_bytes", len(output))
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        add((0,), 0)
        add((1, 65), 0)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "red_black_tree_insert_search":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = 1040

        def add(values: tuple[int, ...], capacity: int) -> None:
            result, output = recorder_expected_output(list(values), algorithm)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        operations = ((0, -1), (0, 0), (0, 1), (1, -1), (1, 0), (1, 1))
        for operation_count in range(4):
            for trace in product(operations, repeat=operation_count):
                values = (operation_count, *(item for pair in trace for item in pair))
                add(values, default_capacity)

        maximum_trace = [128]
        for key in range(64):
            maximum_trace.extend((0, key))
            maximum_trace.extend((1, key))
        add(tuple(maximum_trace), default_capacity)

        malformed = (
            (), (-1,), (129,), (1, 2, 5), (1, 0, 5, 1),
            (1, 2, 5), (1, 0, 2**31), (1, 0, -(2**31) - 1),
            (2**63, 0),
        )
        for values in malformed:
            add(values, default_capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = recorder_expected_output(list(values), algorithm)
            capacity = case.get("workspace_bytes", len(output))
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        add((0,), 15)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "check_polygon":
        cases: dict[tuple[int, ...], tuple[int, bytes]] = {}
        for values in product(range(1, 17), repeat=3):
            packed = tuple(values)
            cases[packed] = recorder_expected_output(list(packed), algorithm)
        fixed_cases = (
            (1, 1, 1), (1, 2, 3), (1, 2, 4), (1_000_000_000,) * 3,
            (1, 999_999_999, 1_000_000_000),
            tuple([1] * 255 + [256]),
            tuple([1] * 255 + [255]),
        )
        for values in fixed_cases:
            cases[values] = recorder_expected_output(list(values), algorithm)
        malformed = (
            (), (1,), (1, 2), (0, 1, 1), (-1, 1, 1),
            (1, 1, 1_000_000_001), (2**63, 1, 1),
            tuple([1] * 257),
        )
        for values in malformed:
            cases[values] = recorder_expected_output(list(values), algorithm)
        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = recorder_expected_output(list(values), algorithm)
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            cases[values] = (result, output)
        records.extend((values, result, output, None)
                       for values, (result, output) in sorted(cases.items()))
    elif algorithm == "bresenham_line":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}

        def add(values: tuple[int, ...], capacity: int) -> None:
            result, output = recorder_expected_output(list(values), algorithm)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for x0, y0 in ((0, 0), (-5, 3), (4, -7)):
            for x1 in range(x0 - 8, x0 + 9):
                for y1 in range(y0 - 8, y0 + 9):
                    add((x0, y0, x1, y1), 32776)

        malformed = (
            (), (0,), (0, 0, 1), (0, 0, 1, 2, 3),
            (-1_000_001, 0, 0, 0), (0, 0, 1_000_001, 0),
            (0, 0, 4097, 0), (-(2**63), 0, 0, 0),
        )
        for values in malformed:
            add(values, 32776)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = recorder_expected_output(list(values), algorithm)
            capacity = case.get("workspace_bytes", len(output))
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        add((0, 0, 1, 0), 7)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "reverse_letters":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid reverse_letters output workspace size")

        def add(values: tuple[int, ...], capacity: int) -> None:
            result, output = recorder_expected_output(list(values), algorithm)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for byte in range(33, 127):
            add((1, byte), default_capacity)
        for payload in product((33, 48, 65, 90, 97, 109, 122, 126), repeat=3):
            add((3, *payload), default_capacity)
        for left in range(33, 127):
            for right in range(33, 127):
                add((3, left, 32, right), default_capacity)
        maximum = tuple((33 + (index % 94)) if index % 27 != 26 else 32 for index in range(256))
        maximum = tuple(byte for i, byte in enumerate(maximum) if not (byte == 32 and (i == 0 or i == 255 or maximum[i-1] == 32)))
        add((len(maximum), *maximum), default_capacity)

        malformed = (
            (), (-1,), (257,), (1,), (0, 65), (1, 0), (2, 65, 32),
            (2, 32, 65), (3, 65, 32, 32), (3, 65, 32, 127),
            (1, 2**63), (1, -(2**63) - 1),
        )
        for values in malformed:
            add(values, default_capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = recorder_expected_output(list(values), algorithm)
            capacity = case.get("workspace_bytes", default_capacity)
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_output = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)
        add((1, 65), 1)
        add((3, 65, 32, 66), 4)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "reverse_string":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid reverse_string output workspace size")

        def add(values: tuple[int, ...], capacity: int) -> None:
            result, output = recorder_expected_output(list(values), algorithm)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        printable = tuple(range(33, 127))
        for byte in printable:
            add((1, byte), default_capacity)
        for payload in product((33, 48, 65, 90, 97, 109, 122, 126), repeat=3):
            values = (len(payload), *payload)
            add(values, default_capacity)
        maximum = tuple(printable[index % len(printable)]
                        for index in range(256))
        add((len(maximum), *maximum), default_capacity)

        malformed = (
            (), (-1,), (257,), (1,), (0, 65), (1, 0), (1, 32), (1, 127),
            (1, 2**63), (1, -(2**63) - 1),
        )
        for values in malformed:
            add(values, default_capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = recorder_expected_output(list(values), algorithm)
            capacity = case.get("workspace_bytes", default_capacity)
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_output = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        add((1, 65), 1)
        add((1, 32), 0)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "reverse_complement":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}

        def add(values: tuple[int, ...], capacity: int) -> None:
            result, output = recorder_expected_output(list(values), algorithm)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        alphabet = (65, 67, 71, 84)
        for length in range(6):
            for sequence in product(alphabet, repeat=length):
                values = tuple(sequence)
                result, output = recorder_expected_output(list(values), algorithm)
                add(values, max(0, result))

        maximum = tuple(alphabet[index % len(alphabet)]
                        for index in range(1000))
        add(maximum, 1000)
        malformed = (
            (-1,), (97,), (78,), (85,), (65, 256), (65, -1),
            tuple([65] * 1001), (2**63,),
        )
        for values in malformed:
            add(values, 1000)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = recorder_expected_output(list(values), algorithm)
            capacity = case.get("workspace_bytes", len(output))
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_output_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_output_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        add((65,), 0)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "string_switch_case":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid string_switch_case output workspace size")

        def add(values: tuple[int, ...], capacity: int) -> None:
            cases[(values, capacity)] = string_switch_case_oracle(list(values), capacity)

        examples = (
            b"", b"a", b"ABC", b"one two", b"The first letters are capitalized",
            b"alpha,beta gamma!delta", b"one\ttwo\x1c\x1fthree", b"123 foo 9BAR",
            b"a---b...c", b"  leading and trailing  ", b"punctuation!!!only???",
        )
        for mode in range(9):
            separators = (0, 43, 47, 95, 127) if mode in (3, 4) else (0,)
            for separator in separators:
                for payload in examples:
                    add((mode, separator, len(payload), *payload), default_capacity)
                for codepoint in range(128):
                    add((mode, separator, 1, codepoint), default_capacity)

        maximum_text = tuple((97, 65, 33, 32)[index % 4]
                             for index in range(MAX_STRING_SWITCH_CASE_TEXT_LENGTH))
        for mode in range(9):
            separator = 95 if mode == 3 else 45 if mode == 4 else 0
            add((mode, separator, len(maximum_text), *maximum_text), default_capacity)

        malformed = (
            (), (0, 0), (9, 0, 0), (0, 128, 0), (0, 1, 0),
            (3, -1, 0), (3, 128, 0), (3, 43, -1), (3, 43, 1025),
            (3, 43, 1), (0, 0, 1, -1), (0, 0, 1, 128),
            (5, 0, 0, 65), (0, 0, 2, 65),
            tuple([0, 0, MAX_STRING_SWITCH_CASE_TEXT_LENGTH + 1]),
            tuple([0, 0, MAX_STRING_SWITCH_CASE_TEXT_LENGTH,
                   *([97] * (MAX_STRING_SWITCH_CASE_TEXT_LENGTH - 1))]),
            (2**63, 0, 0),
        )
        for values in malformed:
            add(values, default_capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = string_switch_case_oracle(list(values), capacity)
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        add((0, 0, 1, 65), 0)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "reverse_words":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}

        def add(values: tuple[int, ...], capacity: int) -> None:
            result, output = recorder_expected_output(list(values), algorithm)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        payloads = {b""}
        printable = tuple(range(33, 127))
        payloads.update(bytes((value,)) for value in printable)
        for values in product((33, 48, 65, 90, 97, 109, 122, 126), repeat=3):
            payloads.add(bytes(values))
        for first in (b"a", b"A", b"!", b"~"):
            for second in (b"b", b"Z", b"?", b"."):
                payloads.add(first + b" " + second)
                payloads.add(first + b" " + b"word" + b" " + second)
        payloads.update((b"A" * 256, (b"a " * 127) + b"b"))
        for payload in payloads:
            values = (len(payload), *payload)
            result, output = recorder_expected_output(list(values), algorithm)
            add(values, max(0, len(output)))

        malformed_payloads = (
            (-1,), (257,), (1,), (0, 65), (1, 32), (2, 32, 65), (2, 65, 32),
            (3, 65, 32, 32), (3, 65, 9, 66), (1, 0), (1, 127),
            (1, 2**63), (1, -(2**63) - 1),
        )
        for values in malformed_payloads:
            add(values, 257)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = recorder_expected_output(list(values), algorithm)
            capacity = case.get("workspace_bytes", len(output))
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        add((1, 65), 1)
        add((3, 65, 32, 32), 0)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "swap_case":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid swap_case output workspace size")

        def add(values: tuple[int, ...], capacity: int) -> None:
            cases[(values, capacity)] = swap_case_oracle(list(values), capacity)

        for codepoint in range(128):
            add((codepoint,), default_capacity)
        add((), 0)
        add(tuple((65, 97, 33, 0)[index % 4]
                  for index in range(MAX_SWAP_CASE_INPUT_LENGTH)), default_capacity)
        malformed = (
            (-1,), (128,), (-(2**63),), (2**63 - 1,),
            tuple([65] * (MAX_SWAP_CASE_INPUT_LENGTH + 1)),
        )
        for values in malformed:
            add(values, default_capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = swap_case_oracle(list(values), capacity)
            if (case.get("input_length") != len(values)
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        add((65,), 0)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "brainfuck":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes", 8192)
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid Brainfuck output workspace size")

        def add(values: tuple[int, ...], capacity: int) -> None:
            result, output = brainfuck_oracle(list(values))
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        # Exhaust short straight-line programs across every instruction, ignored text,
        # and common input-byte values; the published workload covers loops and limits.
        alphabet = (ord("+"), ord("-"), ord("<"), ord(">"), ord("."), ord(","), ord("x"))
        input_variants = ((), (0,), (1,), (255,))
        for length in range(4):
            for commands in product(alphabet, repeat=length):
                for input_bytes in input_variants:
                    values = (length, *commands, len(input_bytes), *input_bytes)
                    add(values, default_capacity)

        malformed = (
            (), (1,), (-1, 0), (0, -1), (0, 1025), (1, 43),
            (1, 0, 0), (1, 43, 1), (2, 46, 46, 1, 256),
            (2, 46, 46, 2, 1), (1, 93, 0), (1, 91, 0),
        )
        for values in malformed:
            add(values, default_capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = brainfuck_oracle(list(values))
            capacity = case.get("workspace_bytes", default_capacity)
            expected_result = (case.get("capacity_error_result", -2)
                               if result >= 0 and capacity < len(output) else result)
            expected_output = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") != len(values)
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        # Exercise a zero-capacity failure independently of the publication workload.
        add((1, ord("."), 0), 0)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "red_black_tree_unique_key_ops":
        cases: dict[tuple[int, ...], tuple[int, bytes]] = {}
        fixed_traces = (
            (0,),
            (5, 0, -(2**31), 1, -(2**31), 1, 2**31 - 1, 2, -(2**31), 1, 2**31 - 1),
            (8, 0, 10, 0, 5, 0, 15, 0, 1, 0, 7, 2, 5, 1, 5, 1, 10),
            (8, 0, 4, 0, 2, 0, 6, 0, 1, 2, 4, 0, 4, 1, 4, 2, 2),
            (3, 1, 0, 1, 7, 1, -9),
        )
        for values in fixed_traces:
            cases[values] = red_black_tree_oracle(values)
        full_tree = (128, *(item for key in range(128) for item in (0, key)))
        cases[full_tree] = red_black_tree_oracle(full_tree)
        delete_rebalance = [128]
        delete_rebalance.extend(item for key in range(42) for item in (0, key))
        delete_rebalance.extend(item for key in range(42) for item in (2, key))
        delete_rebalance.extend(item for key in range(44) for item in (1, key))
        delete_rebalance_trace = tuple(delete_rebalance)
        cases[delete_rebalance_trace] = red_black_tree_oracle(delete_rebalance_trace)

        rng = random.Random(20261017)
        for _ in range(128):
            keys: set[int] = set()
            operations: list[tuple[int, int]] = []
            for _ in range(rng.randrange(0, 129)):
                operation = rng.choice((0, 1, 2) if keys else (0, 1))
                if operation == 0:
                    key = rng.randrange(-(2**31), 2**31)
                    while key in keys:
                        key = rng.randrange(-(2**31), 2**31)
                    keys.add(key)
                elif operation == 1:
                    key = (rng.choice(tuple(sorted(keys))) if keys and rng.randrange(2)
                           else rng.randrange(-(2**31), 2**31))
                else:
                    key = rng.choice(tuple(sorted(keys)))
                    keys.remove(key)
                operations.append((operation, key))
            values = (len(operations), *(item for pair in operations for item in pair))
            cases[values] = red_black_tree_oracle(values)

        malformed = (
            (), (-1,), (129,), (2, 0, 7), (1, 0, 7, 1),
            (2, 0, 7, 0, 7), (1, 2, 7), (1, 3, 7),
            (1, 1, 2**31), (1, 1, -(2**31) - 1),
        )
        for values in malformed:
            cases[values] = red_black_tree_oracle(values)

        workspace_bytes = workload.get("workspace", {}).get("bytes", 2048)
        if type(workspace_bytes) is not int or workspace_bytes < 0:
            raise ValueError("invalid red-black-tree output workspace size")
        records.extend((values, count, output, workspace_bytes)
                       for values, (count, output) in sorted(cases.items()))
        for case in workload["cases"]:
            values = tuple(case["input_values"])
            oracle = red_black_tree_oracle(values)
            capacity = case.get("workspace_bytes", len(oracle[1]))
            expected_count = (case.get("capacity_error_result", -2)
                              if capacity < len(oracle[1]) else oracle[0])
            expected_bytes = b"" if capacity < len(oracle[1]) else oracle[1]
            if (case["expected_result"] != expected_count
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            records.append((values, expected_count, expected_bytes, capacity))
        records.append(((0,), -2, b"", 0))
        records.append(((0,), -2, b"", 15))
    elif algorithm == "chaos_machine":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid chaos-machine output workspace size")

        def add(values: tuple[int, ...], capacity: int) -> None:
            result, output = chaos_machine_oracle(list(values))
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for seed in range(64):
            add((1, seed, 8), default_capacity)
        rng = random.Random(20261018)
        for _ in range(256):
            seeds = tuple(rng.randrange(0, 1_000_001) for _ in range(rng.randrange(0, 9)))
            add((len(seeds), *seeds, rng.randrange(0, 17)), default_capacity)
        add((0, 16), default_capacity)
        add((64, *range(64), 64), default_capacity)

        malformed = (
            (), (-1, 0), (65, 0), (2, 1, 0), (1, -1, 1),
            (1, 1_000_001, 1), (0, -1), (0, 65),
            (64, *range(64), 65),
            tuple([1, *([0] * (MAX_CHAOS_MACHINE_INPUT_LENGTH + 1))]),
        )
        for values in malformed:
            add(values, default_capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = chaos_machine_oracle(list(values))
            capacity = case.get("workspace_bytes", default_capacity)
            expected_count = (case.get("capacity_error_result", -2)
                              if result >= 0 and capacity < len(output) else result)
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_count
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        add((0, 3), 11)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "composite_lfsr_majority_clock":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if default_capacity != 32:
            raise ValueError("invalid composite-LFSR output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            cases[(values, capacity)] = composite_lfsr_majority_clock_oracle(values, capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            expected_count, expected_bytes = composite_lfsr_majority_clock_oracle(values, capacity)
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_count
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)
        widths = (19, 22, 23)
        for _ in range(128):
            values = tuple(rng.randrange(1 << width) for width in widths)
            add(values)
            add(values, default_capacity - 1)
        for malformed in ((), (0,), (0, 0), (0, 0, 0, 0),
                          (-1, 0, 0), (1 << 19, 0, 0), (0, 1 << 22, 0),
                          (0, 0, 1 << 23)):
            add(malformed)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "convert_to_negative":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid image-negative output workspace size")

        def add(values: tuple[int, ...], capacity: int) -> None:
            result, output = recorder_expected_output(list(values), algorithm)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        # Exercise every channel byte and the maximum count-prefixed vector.
        add((256, *range(256)), default_capacity)
        add((0,), default_capacity)
        add((5, 0, 1, 127, 254, 255), default_capacity)
        add((5, 0, 1, 127, 254, 255), 4)
        add((4095, *([0, 1, 127, 128, 254, 255] * 682 + [0, 1, 127])), default_capacity)
        malformed = (
            (), (-1,), (1,), (2, 0), (1, -1), (1, 256),
            (4096,), (-(2**63),), (2**63 - 1,),
            tuple([1] + [0] * 4096),
        )
        for values in malformed:
            add(values, default_capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = recorder_expected_output(list(values), algorithm)
            capacity = case.get("workspace_bytes", default_capacity)
            expected_count = (case.get("capacity_error_result", -2)
                              if result >= 0 and capacity < len(output) else result)
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_count
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        add((3, 7, 8, 9), 2)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm in {"change_brightness", "change_contrast"}:
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < 0:
            raise ValueError("invalid image point transform output workspace size")

        def add(values: tuple[int, ...], capacity: int) -> None:
            result, output = recorder_expected_output(list(values), algorithm)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        # Every legal level is checked against every byte value.
        for level in range(-255, 256):
            add((level, *range(256)), default_capacity)
        add((0,), 0)
        add((255, *([0] * 4095)), default_capacity)
        add((0, 128), 0)
        malformed = (
            (), (-256, 0), (256, 0), (0, -1), (0, 256),
            (-(2**63), 0), (2**63 - 1, 0),
            tuple([0] + [127] * 4096),
        )
        for values in malformed:
            add(values, default_capacity)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            result, output = recorder_expected_output(list(values), algorithm)
            capacity = case.get("workspace_bytes", default_capacity)
            expected_count = (case.get("capacity_error_result", -2)
                              if result >= 0 and capacity < len(output) else result)
            expected_bytes = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_count
                    or case.get("expected_output_hex", "").lower() != expected_bytes.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "cpu_scheduling_algorithms":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < MAX_CPU_SCHEDULING_OUTPUT_BYTES:
            raise ValueError("invalid CPU-scheduling output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = cpu_scheduling_oracle(values, output_capacity=capacity)
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = cpu_scheduling_oracle(values, output_capacity=capacity)
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)
        for _ in range(256):
            mode = rng.randrange(6)
            count = rng.randrange(MAX_CPU_SCHEDULING_PROCESSES + 1)
            quantum = rng.randrange(1, 33)
            identifiers = rng.sample(range(MAX_CPU_SCHEDULING_PROCESSES), count)
            values = [mode, count, quantum]
            for process_id in identifiers:
                values.extend((process_id, rng.randrange(257), rng.randrange(1, 33),
                               rng.randrange(-32, 33)))
            add(tuple(values))

        for values in (
            (), (0, 0), (6, 0, 1), (0, -1, 1), (0, 33, 1), (5, 0, 0),
            (0, 1, 2), (0, 2, 2, 1, 0, 1, 0, 1),
            tuple([0, 0, 1] + [0] * (MAX_CPU_SCHEDULING_INPUT_LENGTH - 3)),
        ):
            add(tuple(values))
        capacity_probe = (0, 1, 2, 0, 0, 1, 0)
        probe_output_length = len(cpu_scheduling_oracle(capacity_probe)[1])
        add(capacity_probe, probe_output_length - 1)
        add(capacity_probe, probe_output_length)
        null_key = (capacity_probe, default_capacity + 1)
        if null_key in cases:
            raise ValueError("CPU-scheduling null-input canary collides with another case")
        cases[null_key] = (-1, b"")
        null_input_cases.add(null_key)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "heaps":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < MAX_HEAPS_OUTPUT_BYTES:
            raise ValueError("invalid heaps output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = heaps_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = result, output

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = heaps_oracle(values)
            expected_result = -2 if result >= 0 and capacity < len(output) else result
            expected_output = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        for n in range(MAX_HEAPS_N + 1):
            add((n,))
        for values in ((), (-1,), (MAX_HEAPS_N + 1,), (3, 0)):
            add(values)
        null_key = ((MAX_HEAPS_N,), default_capacity + 1)
        if null_key in cases:
            raise ValueError("heaps null-input canary collides with another case")
        cases[null_key] = (-1, b"")
        null_input_cases.add(null_key)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "heaps_algorithm":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < MAX_HEAPS_ALGORITHM_OUTPUT_BYTES:
            raise ValueError("invalid heaps-algorithm output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = heaps_algorithm_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = result, output

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = heaps_algorithm_oracle(values)
            expected_result = -2 if result >= 0 and capacity < len(output) else result
            expected_output = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)
        for length in range(1, MAX_HEAPS_ALGORITHM_LENGTH + 1):
            values = tuple(rng.randint(HEAPS_ALGORITHM_I64_MIN, HEAPS_ALGORITHM_I64_MAX)
                           for _ in range(length))
            add(values)
        for _ in range(128):
            length = rng.randint(1, MAX_HEAPS_ALGORITHM_LENGTH)
            values = tuple(rng.choice((HEAPS_ALGORITHM_I64_MIN, HEAPS_ALGORITHM_I64_MAX,
                                       rng.randint(-10**12, 10**12)))
                           for _ in range(length))
            add(values)
        for values in ((), tuple(range(MAX_HEAPS_ALGORITHM_LENGTH + 1))):
            add(values)
        null_key = ((HEAPS_ALGORITHM_I64_MIN, HEAPS_ALGORITHM_I64_MAX), default_capacity + 1)
        if null_key in cases:
            raise ValueError("heaps-algorithm null-input canary collides with another case")
        cases[null_key] = (-1, b"")
        null_input_cases.add(null_key)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "fisher_yates_shuffle":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < MAX_FISHER_YATES_VALUES * 4:
            raise ValueError("invalid Fisher–Yates output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = fisher_yates_shuffle_oracle(list(values))
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = fisher_yates_shuffle_oracle(list(values))
            expected_result = -2 if result >= 0 and capacity < len(output) else result
            expected_output = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)
        for count in range(MAX_FISHER_YATES_VALUES + 1):
            values = (rng.randint(1, 2_147_483_646),
                      *(rng.randint(-(2**31), 2**31 - 1) for _ in range(count)))
            add(values)
        for _ in range(128):
            count = rng.randint(0, MAX_FISHER_YATES_VALUES)
            values = (rng.randint(1, 2_147_483_646),
                      *(rng.randint(-(2**31), 2**31 - 1) for _ in range(count)))
            add(values)
            if count:
                add(values, count * 4 - 1)
        malformed = (
            (), (0,), (2_147_483_647,), (1, -(2**31) - 1),
            (1, 2**31), (1, *range(MAX_FISHER_YATES_VALUES + 1)),
            tuple([1] + [0] * (MAX_FISHER_YATES_VALUES + 1)),
        )
        for values in malformed:
            add(values)
        capacity_probe = (2, 10, 20)
        add(capacity_probe, 7)
        add(capacity_probe, 8)
        null_key = ((314159, 271828), default_capacity)
        if null_key in cases:
            raise ValueError("Fisher–Yates null-input canary collides with another case")
        cases[null_key] = (-1, b"")
        null_input_cases.add(null_key)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "graph_coloring":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if (type(default_capacity) is not int
                or default_capacity < MAX_GRAPH_COLORING_OUTPUT_BYTES):
            raise ValueError("invalid graph-coloring output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = graph_coloring_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = graph_coloring_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            if (case.get("input_length") not in (None, len(values))
                    or len(values) > MAX_GRAPH_COLORING_VALIDATION_LENGTH
                    or case["expected_result"] != result
                    or case.get("expected_output_hex", "").lower() != output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)
        for _ in range(128):
            vertex_count = rng.randint(1, 8)
            color_count = rng.randint(1, 4)
            masks = [0] * vertex_count
            for vertex in range(vertex_count):
                for neighbor in range(vertex + 1, vertex_count):
                    if rng.randrange(2):
                        masks[vertex] |= 1 << neighbor
                        masks[neighbor] |= 1 << vertex
            values = (vertex_count, color_count, *masks)
            add(values)

        for values in (
            (), (1,), (2, 3), (2, 3, 2), (1, 1, 0, 0),
            (0, 1), (9, 2), (1, 0, 0), (1, 5, 0),
            (2, 3, -1, 0), (2, 3, 4, 0), (2, 3, 1, 0),
            (2, 3, 2, 0),
            (8, 4, *(0 for _ in range(MAX_GRAPH_COLORING_VALIDATION_LENGTH - 2))),
        ):
            add(values)
        capacity_probe = (2, 3, 2, 1)
        add(capacity_probe, MAX_GRAPH_COLORING_OUTPUT_BYTES - 1)
        add(capacity_probe, MAX_GRAPH_COLORING_OUTPUT_BYTES)
        complete_eight_vertex_masks = tuple(
            ((1 << 8) - 1) ^ (1 << vertex) for vertex in range(8)
        )
        null_key = ((8, 4, *complete_eight_vertex_masks), default_capacity)
        if null_key in cases:
            raise ValueError("graph-coloring null-input canary collides with another case")
        cases[null_key] = (-1, b"")
        null_input_cases.add(null_key)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "recursive_shuffler":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes")
        if type(default_capacity) is not int or default_capacity < MAX_RECURSIVE_SHUFFLER_VALUES * 4:
            raise ValueError("invalid recursive-shuffler output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = recursive_shuffler_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = result, output

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = recursive_shuffler_oracle(values)
            expected_result = (-2 if result >= 0 and capacity < len(output) else result)
            expected_output = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)
        for count in range(MAX_RECURSIVE_SHUFFLER_VALUES + 1):
            values = (rng.randint(1, 2_147_483_646),
                      *(rng.randint(-(2**31), 2**31 - 1) for _ in range(count)))
            add(values)
        for _ in range(128):
            count = rng.randint(0, MAX_RECURSIVE_SHUFFLER_VALUES)
            values = (rng.randint(1, 2_147_483_646),
                      *(rng.randint(-(2**31), 2**31 - 1) for _ in range(count)))
            add(values)
            if count:
                add(values, count * 4 - 1)
        malformed = (
            (), (0,), (2_147_483_647,), (1, -(2**31) - 1),
            (1, 2**31), (1, *range(MAX_RECURSIVE_SHUFFLER_VALUES + 1)),
            tuple([1] + [0] * MAX_RECURSIVE_SHUFFLER_INPUT_LENGTH),
        )
        for values in malformed:
            add(values)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "fibonacci_heap":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
        default_capacity = workload.get("workspace", {}).get("bytes", MAX_FIBONACCI_HEAP_KEYS * 8)
        if type(default_capacity) is not int or default_capacity < MAX_FIBONACCI_HEAP_KEYS * 8:
            raise ValueError("invalid Fibonacci-heap output workspace size")

        def add(values: tuple[int, ...], capacity: int = default_capacity) -> None:
            result, output = fibonacci_heap_oracle(list(values))
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = result, output

        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = fibonacci_heap_oracle(list(values))
            expected_result = (-2 if result >= 0 and capacity < len(output) else result)
            expected_output = b"" if result >= 0 and capacity < len(output) else output
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)

        rng = random.Random(20261016)
        for _ in range(256):
            count = rng.randint(0, MAX_FIBONACCI_HEAP_KEYS)
            add(tuple(rng.choice((-(2**63), 2**63 - 1, rng.randint(-10**12, 10**12)))
                      for _ in range(count)))
        add(tuple(range(MAX_FIBONACCI_HEAP_KEYS)))
        add(tuple(range(MAX_FIBONACCI_HEAP_KEYS - 1, -1, -1)))
        for malformed in (tuple([0] * (MAX_FIBONACCI_HEAP_KEYS + 1)),):
            add(malformed)
        add((2, 1, 3), 23)
        # Invalid keys take precedence over an undersized output buffer.
        add((2**31,), 0)
        null_key = ((), 0)
        if null_key in cases:
            raise ValueError("Fibonacci-heap null-input canary collides with another case")
        cases[null_key] = fibonacci_heap_oracle([])
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    elif algorithm == "gauss_elimination":
        cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}

        def add(values: tuple[int, ...], capacity: int) -> None:
            result, output = gauss_elimination_oracle(values)
            if result >= 0 and capacity < len(output):
                result, output = -2, b""
            cases[(values, capacity)] = (result, output)

        default_capacity = workload.get("workspace", {}).get("bytes", 64)
        for case in workload["cases"]:
            values = tuple(case["input_values"])
            capacity = case.get("workspace_bytes", default_capacity)
            result, output = gauss_elimination_oracle(values)
            expected_result, expected_output = result, output
            if result >= 0 and capacity < len(output):
                expected_result, expected_output = -2, b""
            if (case.get("input_length") not in (None, len(values))
                    or case["expected_result"] != expected_result
                    or case.get("expected_output_hex", "").lower() != expected_output.hex()):
                raise ValueError(f"workload oracle mismatch: {case['id']}")
            add(values, capacity)
        for malformed in ((), (-1,), (9,), (2, 0, 0),
                          (2, *([0] * 72))):
            add(tuple(malformed), default_capacity)
        add((2, 0, 2, 1, 1, -2, 2), 15)
        records.extend((values, result, output, capacity)
                       for (values, capacity), (result, output) in sorted(cases.items()))
    else:
        raise ValueError(f"no corpus for {algorithm}")
    lines = [str(len(records)) + "\n"]
    if workload.get("output", {}).get("kind") == "float64_vector":
        absolute_tolerance = workload["output"].get("absolute_tolerance", 0.0)
        relative_tolerance = workload["output"].get("relative_tolerance", 0.0)
        lines.append(f"float64_vector {absolute_tolerance:.17g} {relative_tolerance:.17g}\n")
    for values, count, output, capacity in records:
        values_text = "" if not values else " " + " ".join(map(str, values))
        encoded = output.hex() if output else "-"
        header = f"{len(values)} {count} {len(output)}"
        if algorithm in WORKSPACE_ALGORITHMS:
            assert capacity is not None
            header += f" {capacity}"
        null_input = (values, capacity) in null_input_cases
        header += f" {int(null_input)}"
        lines.append(f"{header}{values_text} {encoded}\n")
    return "".join(lines), len(records)


def verify(algorithm: str, language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    link_shims = ((ROOT / "benchmarks/harness/elisa_empty_stack_arena_free.c",)
                  if algorithm == "canny" and language == "elisa" else ())
    manifest = build(algorithm, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_bytes_output",
                     extra_link_sources=link_shims)
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"byte-output C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")
    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([sys.executable, str(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
                               "--build-manifest", str(directory / "build.json"),
                               "--samples", "1", "--warmups", "0", "--repetitions", "1",
                               "--output", str(output)], cwd=ROOT, capture_output=True,
                              text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    for case, record in zip(workload["cases"], records):
        values = case["input_values"]
        output_capacity = (
            case.get(
                "workspace_bytes",
                workload.get("workspace", {}).get("bytes")
                        if algorithm in {"fibonacci_heap", "heaps", "heaps_algorithm", "graph_coloring", "fisher_yates_shuffle", "charoccurrence", "coordinate_compression", "flash_sort", "string_compression", "create_binary_tree_from_inorder_preorder", "serialize_deserialize_binary_tree", "cramers_rule_2x2", "crc_polynomial_division", "power_for_huge_numbers", "ode_forward_euler", "ode_midpoint_euler", "ode_semi_implicit_euler", "recursive_shuffler", "convolution", "damped_oscillator", "difference_array", "cusum_detector", "complex_number_multiply", "complex_arithmetic", "dice_thrower", "hampel_filter", "range_in_sorted_array", "intersection_of_two_arrays", "union_of_two_arrays", "unique_letters_count", "convex_hull_graham", "sorted_arrays_intersection", "compress", "dilation_operation", "nearest_neighbor_interpolation", "composite_lfsr_majority_clock", "combination_sum", "non_empty_subsequences", "particle_swarm_optimization", "convolve_1d", "depth_first_search_target_route", "convolution_fft", "swap_case", "string_switch_case", "reverse_string", "common_characters_frequency_quotient", "remove_duplicate_characters", "remove_duplicate_words", "continued_fraction", "account_merge", "adagrad", "adam", "cholesky_decomposition", "depreciation", "chebyshev_iteration", "choiceset", "chudnovsky_algorithm", "circular_look_scheduling", "circular_scan_scheduling", "adaline_learning", "adams_bashforth", "adfgvxcipher", "upper", "all_construct", "allocation_number", "booths_algorithm", "association", "auto_correlation", "baconian_cipher", "a1z26_cipher", "a1z26_decipher", "centroid_decomposition", "chacha", "date_to_day", "cross_correlation", "ema_filter", "egyptian_fraction", "count_nucleotide", "atbash_cipher", "correlation_matrix_analysis"}
                else (len(bytes.fromhex(case["expected_output_hex"]))
                      if "expected_output_hex" in case
                      else len(case.get("expected_output", "").encode("utf-8"))),
            )
            if algorithm in WORKSPACE_ALGORITHMS else None
        )
        if (record["algorithm"] != algorithm
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or (algorithm in WORKSPACE_ALGORITHMS
                    and record["workload"]["output_capacity"] != output_capacity)
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": algorithm, "language": language, "status": "passed", "oracle_cases": case_count,
            "source_sha256": manifest["source_sha256"], "workload_records": len(records),
            "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--algorithm", choices=ALGORITHMS, default=DEFAULT_ALGORITHM)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/i64_array_bytes_output")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    algorithm = args.algorithm
    workload = json.loads((ROOT / "benchmarks" / algorithm[0] / algorithm / "workload.json")
                          .read_text(encoding="utf-8"))
    data, case_count = corpus(workload, algorithm)
    corpus_path = directory / f"{algorithm}-corpus.txt"
    corpus_path.write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, algorithm, language, directory / algorithm / language,
                                args.elisa_compiler, data, case_count, workload): language
                for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                print(f"FAIL {algorithm}/{language}: {error}", file=sys.stderr)
                return 1
            results.append(result)
            print(f"PASS {algorithm}/{language}: {case_count} oracle inputs, "
                  f"{result['workload_records']} workload records", flush=True)
    report = {"algorithm": algorithm, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "results": sorted(results, key=lambda item: item["language"])}
    report_path = (directory / "verification.json" if algorithm == DEFAULT_ALGORITHM
                   else directory / f"{algorithm}-verification.json")
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
