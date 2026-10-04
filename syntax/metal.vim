" Metal Shading Language 4.1 highlighting. No parser or SDK required.
" Language reference: https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf
if exists('b:current_syntax')
  finish
endif
runtime! syntax/cpp.vim
unlet! b:current_syntax

" Inherit C++ comments, strings, preprocessor, control flow and operators.
" These matches also work while editing incomplete shader declarations.
syn match metalFunction '\<\h\w*\>\ze\_s*('
syn match metalFunction '\<\h\w*\>\ze\s*<[^;{}]*>\_s*('
syn keyword metalStage kernel vertex fragment
syn keyword metalAddressSpace device constant thread threadgroup threadgroup_imageblock ray_data object_data
syn keyword metalQualifier coherent
syn keyword metalType uchar ushort uint ulong half bfloat size_t ptrdiff_t
syn keyword metalType int8_t int16_t int32_t int64_t uint8_t uint16_t uint32_t uint64_t
syn keyword metalType atomic atomic_int atomic_uint atomic_bool atomic_ulong atomic_float
syn keyword metalType sampler array array_ref vector matrix packed_vec packed_float
syn keyword metalType imageblock uniform interpolant patch_control_point per_vertex
syn keyword metalType visible_function_table intersection_function_table
syn keyword metalType ray intersector intersection_result intersection_result_ref intersection_query
syn keyword metalType acceleration_structure primitive_acceleration_structure instance_acceleration_structure
syn keyword metalType mesh mesh_grid_properties simdgroup_matrix
syn keyword metalType tensor tensor_blockwise cooperative_tensor extents dextents
syn keyword metalType tensor_inline tensor_offset tensor_handle
syn keyword metalType r8unorm r8snorm r16unorm r16snorm rg8unorm rg8snorm rg16unorm rg16snorm
syn keyword metalType rgba8unorm srgba8unorm rgba8snorm rgba16unorm rgba16snorm rgb10a2 rg11b10f rgb9e5
syn keyword metalType instancing triangle_data world_space_data primitive_motion instance_motion
syn keyword metalType extended_limits curve_data max_levels intersection_function_buffer user_data
syn match metalType '\<\%(packed_\)\?\%(bool\|char\|uchar\|short\|ushort\|int\|uint\|long\|ulong\|half\|float\|bfloat\)[234]\>'
syn match metalType '\<\%(half\|float\)[234]x[234]\>'
syn match metalType '\<simdgroup_\%(half\|float\|bfloat\)8x8\>'
syn match metalType '\<\%(texture\|depth\)\%(1d\|2d\|3d\|cube\)\%(_ms\)\?\%(_array\)\?\>'
syn keyword metalType texture_buffer

" Enum types and their scoped values, without coloring common words such as
" 'read' and 'sample' everywhere in the user's code.
syn keyword metalType access mem_flags memory_order memory_scope coord filter min_filter mag_filter mip_filter
syn keyword metalType address s_address t_address r_address compare_func border_color
syn keyword metalType topology interpolation intersection_type triangle_cull_mode
syn keyword metalType winding curve_type curve_basis geometry_type forced_opacity
syn keyword metalType tensor_access tensor_flags tensor_properties tensor_layout
" Lookbehind: a match starting on the enum name would lose to its keyword.
syn match metalConstant '\%(\<\%(access\|mem_flags\|memory_order\|memory_scope\|coord\|filter\|min_filter\|mag_filter\|mip_filter\|address\|s_address\|t_address\|r_address\|compare_func\|border_color\|topology\|interpolation\|intersection_type\|triangle_cull_mode\|winding\|curve_type\|curve_basis\|geometry_type\|forced_opacity\|tensor_access\|tensor_flags\|tensor_properties\|tensor_layout\)::\s*\)\@<=\h\w*'
syn keyword metalConstant memory_order_relaxed memory_order_acquire memory_order_release memory_order_acq_rel memory_order_seq_cst
syn keyword metalConstant dynamic_extent
syn keyword metalConstant MAXFLOAT HUGE_VALF INFINITY NAN M_PI_F M_PI_2_F M_PI_4_F M_1_PI_F M_2_PI_F
syn keyword metalConstant M_2_SQRTPI_F M_E_F M_LOG2E_F M_LOG10E_F M_LN2_F M_LN10_F M_SQRT2_F M_SQRT1_2_F
syn match metalConstant '\<__METAL_\w*__\>\|\<__metal_\w*__\>'
syn keyword metalNamespace metal raytracing metal_log metal_tensor metal_cooperative_tensor

" All [[attributes]] are recognized structurally, including multi-line lists
" and future additions. Parenthesized arguments retain strings and numbers.
syn region metalAttribute matchgroup=metalAttributeDelimiter start='\[\[' end='\]\]' contains=metalAttributeName,metalAttributeArguments,cComment,cCommentL
syn match metalAttributeName '\<\h\w*\>' contained
syn region metalAttributeArguments matchgroup=metalAttributeDelimiter start='(' end=')' contained contains=metalAttributeArguments,cString,cppString,cNumbers,cppNumbers,metalNumber,cComment,cCommentL
" C's ALLBUT regions (parens, blocks) must not pick up contained attribute items.
syn cluster cParenGroup add=metalAttributeName,metalAttributeArguments

" C++ syntax doesn't recognize every Metal half/bfloat suffix. Match the full
" decimal or hexadecimal literal, including uppercase and exponent forms.
syn match metalNumber '\<\d\+\%(\.\d*\)\?\%([eE][+-]\?\d\+\)\?\c\%(bf\|h\|f\)\>' containedin=cNumbers,cppNumbers
syn match metalNumber '\.\d\+\%([eE][+-]\?\d\+\)\?\c\%(bf\|h\|f\)\>' containedin=cNumbers,cppNumbers
syn match metalNumber '\<0[xX]\x\+\%(\.\x*\)\?[pP][+-]\?\d\+\c\%(bf\|h\|f\)\?\>' containedin=cNumbers,cppNumbers

hi def link metalStage Keyword
hi def link metalAddressSpace StorageClass
hi def link metalQualifier StorageClass
hi def link metalType Type
hi def link metalFunction Function
hi def link metalNamespace Include
hi def link metalConstant Constant
hi def link metalAttributeName PreProc
hi def link metalAttributeDelimiter Delimiter
hi def link metalNumber Float

let b:current_syntax = 'metal'
