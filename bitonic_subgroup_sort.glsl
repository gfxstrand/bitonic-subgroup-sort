/*
 * Copyright (c) 2021 Jason Ekstrand
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

/** \file bitonic_sub_group_sort.cl
 * An bitonic sub-group sort implementation for GLSL
 */

#define BITONIC_SUB_GROUP_SORT_STEP(type, x, k, j)  \
{                                                   \
    const uint l = i ^ j;                           \
    bool flip = (i & k) != 0 && (k < cluster_size); \
                                                    \
    const type xl = subgroupShuffleXor(x, j);       \
    bool cmp = ascending ? x < xl : x > xl;         \
    x = ((cmp == (i < l)) != flip) ? x : xl;        \
}

#define BITONIC_SUB_GROUP_SORT_DECL(type, suffix, _ascending)        \
type subgroupClusteredSort##suffix(type x, const uint cluster_size)  \
{                                                                    \
    const uint i = gl_SubgroupInvocationID;                          \
    const bool ascending = _ascending;                               \
    if (gl_SubgroupSize >= 2 && cluster_size >= 2) {                 \
        BITONIC_SUB_GROUP_SORT_STEP(type, x,  2,  1)                 \
    }                                                                \
    if (gl_SubgroupSize >= 4 && cluster_size >= 4) {                 \
        BITONIC_SUB_GROUP_SORT_STEP(type, x,  4,  2)                 \
        BITONIC_SUB_GROUP_SORT_STEP(type, x,  4,  1)                 \
    }                                                                \
    if (gl_SubgroupSize >= 8 && cluster_size >= 8) {                 \
        BITONIC_SUB_GROUP_SORT_STEP(type, x,  8,  4)                 \
        BITONIC_SUB_GROUP_SORT_STEP(type, x,  8,  2)                 \
        BITONIC_SUB_GROUP_SORT_STEP(type, x,  8,  1)                 \
    }                                                                \
    if (gl_SubgroupSize >= 16 && cluster_size >= 16) {               \
        BITONIC_SUB_GROUP_SORT_STEP(type, x, 16,  8)                 \
        BITONIC_SUB_GROUP_SORT_STEP(type, x, 16,  4)                 \
        BITONIC_SUB_GROUP_SORT_STEP(type, x, 16,  2)                 \
        BITONIC_SUB_GROUP_SORT_STEP(type, x, 16,  1)                 \
    }                                                                \
    if (gl_SubgroupSize >= 32 && cluster_size >= 32) {               \
        BITONIC_SUB_GROUP_SORT_STEP(type, x, 32, 16)                 \
        BITONIC_SUB_GROUP_SORT_STEP(type, x, 32,  8)                 \
        BITONIC_SUB_GROUP_SORT_STEP(type, x, 32,  4)                 \
        BITONIC_SUB_GROUP_SORT_STEP(type, x, 32,  2)                 \
        BITONIC_SUB_GROUP_SORT_STEP(type, x, 32,  1)                 \
    }                                                                \
    if (gl_SubgroupSize >= 64 && cluster_size >= 64) {               \
        BITONIC_SUB_GROUP_SORT_STEP(type, x, 64, 32)                 \
        BITONIC_SUB_GROUP_SORT_STEP(type, x, 64, 16)                 \
        BITONIC_SUB_GROUP_SORT_STEP(type, x, 64,  8)                 \
        BITONIC_SUB_GROUP_SORT_STEP(type, x, 64,  4)                 \
        BITONIC_SUB_GROUP_SORT_STEP(type, x, 64,  2)                 \
        BITONIC_SUB_GROUP_SORT_STEP(type, x, 64,  1)                 \
    }                                                                \
    return x;                                                        \
}                                                                    \
                                                                     \
type subgroupSort##suffix(type x)                                    \
{                                                                    \
    return subgroupClusteredSort##suffix(x, 64);                     \
}

#define BITONIC_SUB_GROUP_SORT_DECL_TYPED(type)             \
    BITONIC_SUB_GROUP_SORT_DECL(type, Ascending, true)      \
    BITONIC_SUB_GROUP_SORT_DECL(type, Descending, false)

BITONIC_SUB_GROUP_SORT_DECL_TYPED(int)
BITONIC_SUB_GROUP_SORT_DECL_TYPED(uint)
BITONIC_SUB_GROUP_SORT_DECL_TYPED(float)

#ifdef GL_ARB_gpu_shader_fp64
BITONIC_SUB_GROUP_SORT_DECL_TYPED(double)
#endif

#ifdef GL_EXT_shader_explicit_arithmetic_types_int8
BITONIC_SUB_GROUP_SORT_DECL_TYPED(int8_t)
BITONIC_SUB_GROUP_SORT_DECL_TYPED(uint8_t)
#endif

#ifdef GL_EXT_shader_explicit_arithmetic_types_int16
BITONIC_SUB_GROUP_SORT_DECL_TYPED(int16_t)
BITONIC_SUB_GROUP_SORT_DECL_TYPED(uint16_t)
#endif

#ifdef GL_EXT_shader_explicit_arithmetic_types_int32
BITONIC_SUB_GROUP_SORT_DECL_TYPED(int32_t)
BITONIC_SUB_GROUP_SORT_DECL_TYPED(uint32_t)
#endif

#ifdef GL_EXT_shader_explicit_arithmetic_types_int64
BITONIC_SUB_GROUP_SORT_DECL_TYPED(int64_t)
BITONIC_SUB_GROUP_SORT_DECL_TYPED(uint64_t)
#endif

#ifdef GL_EXT_shader_explicit_arithmetic_types_float16
BITONIC_SUB_GROUP_SORT_DECL_TYPED(float16_t)
#endif

#ifdef GL_EXT_shader_explicit_arithmetic_types_float32
BITONIC_SUB_GROUP_SORT_DECL_TYPED(float32_t)
#endif

#ifdef GL_EXT_shader_explicit_arithmetic_types_float64
BITONIC_SUB_GROUP_SORT_DECL_TYPED(float64_t)
#endif

#undef BITONIC_SUB_GROUP_SORT_STEP
#undef BITONIC_SUB_GROUP_SORT_DECL
#undef BITONIC_SUB_GROUP_SORT_DECL_TYPED
