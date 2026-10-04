return function(test, equal)
  local function shader(lines)
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].filetype = "metal"
    vim.cmd("syntax sync fromstart")
    return buf
  end

  local function group(row, token, offset)
    local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
    local col = assert(line:find(token, 1, true), "missing token: " .. token)
    local name = vim.fn.synIDattr(vim.fn.synID(row, col + (offset or 0), 1), "name")
    -- Stop at the first standard group: colorschemes may further link
    -- Keyword -> Statement or Float -> Number, which would hide regressions.
    while name:match("^%l") do
      local link = vim.api.nvim_get_hl(0, { name = name, link = true }).link
      if not link then break end
      name = link
    end
    return name
  end

  test("Metal stages and every address space", function()
    for _, token in ipairs({ "kernel", "vertex", "fragment" }) do
      shader({ token .. " void entry() {}" })
      equal("Keyword", group(1, token))
    end
    for _, token in ipairs({ "device", "constant", "thread", "threadgroup",
      "threadgroup_imageblock", "ray_data", "object_data" }) do
      shader({ "void f(" .. token .. " float* data) {}" })
      equal("StorageClass", group(1, token))
    end
  end)

  test("scalar, vector, packed, matrix, resource and modern Metal types", function()
    for _, token in ipairs({ "uint", "half", "bfloat", "ulong", "uint64_t", "float3", "packed_half3",
      "packed_bfloat4", "char2", "float4x4", "half2x3", "simdgroup_bfloat8x8", "simdgroup_matrix",
      "atomic_uint", "atomic_float", "texture2d", "texture2d_ms_array", "texturecube_array",
      "depth2d_ms", "texture_buffer", "sampler", "imageblock", "uniform", "interpolant", "per_vertex",
      "mesh", "mesh_grid_properties", "ray", "intersector", "intersection_query", "intersection_result_ref",
      "primitive_acceleration_structure", "instance_acceleration_structure", "intersection_function_table",
      "visible_function_table", "triangle_data", "tensor", "tensor_blockwise", "cooperative_tensor",
      "extents", "dextents", "r8unorm", "rgba8unorm", "rgb10a2" }) do
      shader({ token .. " value;" })
      equal("Type", group(1, token))
    end
  end)

  test("attributes across shader stages, including multiline arguments", function()
    for _, name in ipairs({ "buffer", "texture", "sampler", "id", "attribute", "position", "stage_in",
      "thread_position_in_grid", "threads_per_threadgroup", "thread_index_in_simdgroup",
      "color", "depth", "sample_mask", "raster_order_group", "function_constant", "host_name",
      "center_perspective", "centroid_no_perspective", "sample_perspective", "flat", "patch",
      "point_size", "clip_distance", "barycentric_coord", "primitive_id", "intersection", "visible",
      "stitchable", "object", "mesh", "tile", "max_total_threads_per_threadgroup",
      "max_total_threadgroups_per_mesh_grid", "payload", "user", "future_attribute" }) do
      shader({ "float value [[" .. name .. "(0)]];" })
      equal("PreProc", group(1, name))
    end
    shader({ "[[", ' host_name("kernel_device"),', " max_total_threads_per_threadgroup((32 * 2))", "]]", "kernel void f() {}" })
    equal("PreProc", group(2, "host_name"))
    equal("String", group(2, "kernel_device"))
    equal("Number", group(3, "32"))
    equal("Delimiter", group(4, "]]"))
    equal("Keyword", group(5, "kernel"))
  end)

  test("Metal numeric literals include their complete suffix", function()
    for _, value in ipairs({ "0.5h", "0.5H", "1.0bf", "1.0BF", ".5h", "2e-3h", "1.0f", "0x1.fp+2h" }) do
      shader({ "half value = " .. value .. ";" })
      equal("Float", group(1, value, #value - 1))
    end
  end)

  test("built-in calls, scoped enum values and macros", function()
    shader({ "float v = fast::sin(x) + simd_sum(x);", "threadgroup_barrier(mem_flags::mem_threadgroup);",
      "texture2d<float, access::read> input;", "constexpr sampler s(coord::normalized, filter::linear);",
      "auto bits = as_type<uint>(v);", "uint version = __METAL_VERSION__;" })
    equal("Function", group(1, "sin"))
    equal("Function", group(1, "simd_sum"))
    equal("Function", group(2, "threadgroup_barrier"))
    equal("Constant", group(2, "mem_threadgroup"))
    equal("Constant", group(3, "read"))
    equal("Constant", group(4, "linear"))
    equal("Function", group(5, "as_type"))
    equal("Constant", group(6, "__METAL_VERSION__"))
  end)

  test("comments, strings and includes protect Metal-looking text", function()
    shader({ "// kernel device float4 [[buffer(0)]]", "/* texture2d", "threadgroup */",
      'const char* text = "kernel device float4";', 'const char* raw = R"tag(',
      'kernel [[buffer(1)]]', ')tag";', "#include <metal_stdlib>", "#define SCALE 2", "if (true) return;" })
    equal("Comment", group(1, "kernel"))
    equal("Comment", group(2, "texture2d"))
    equal("Comment", group(3, "threadgroup"))
    equal("String", group(4, "kernel"))
    equal("String", group(6, "kernel"))
    equal("String", group(8, "metal_stdlib"))
    equal("Macro", group(9, "#define"))
    equal("Conditional", group(10, "if"))
  end)

  test("ordinary identifiers are not substring-highlighted as Metal keywords", function()
    shader({ "int device_count; int my_float4; int threadgroup_size; int read;", "int meshlets; int tensor_count;" })
    for _, token in ipairs({ "device_count", "my_float4", "threadgroup_size", "read" }) do
      equal("", group(1, token))
    end
    equal("", group(2, "meshlets"))
    equal("", group(2, "tensor_count"))
  end)

  test("highlighting recovers while editing an unfinished shader", function()
    local buf = shader({ "kernel void run(device float* data [[buffer(0)]]) {", "  /* device", "  float4 value;" })
    equal("Comment", group(3, "float4"))
    vim.api.nvim_buf_set_lines(buf, 1, 2, false, { "  /* device */" })
    vim.cmd("syntax sync fromstart")
    equal("Type", group(3, "float4"))
    equal("Keyword", group(1, "kernel"))
  end)

  test("Metal syntax does not leak into ordinary C++ buffers", function()
    shader({ "kernel device float4" })
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "int kernel; int device; int float4;" })
    vim.bo[buf].filetype = "cpp"
    equal("", group(1, "kernel"))
    equal("", group(1, "device"))
    equal("", group(1, "float4"))
  end)
end
