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
 * An bitonic sub-group sort implementation for OpenCL
 */

#ifndef BITONIC_SUB_GROUP_SORT_CL
#define BITONIC_SUB_GROUP_SORT_CL

#define BITONIC_SUB_GROUP_SORT_STEP(type, x, k, j)  \
{                                                   \
    const uint l = i ^ j;                           \
    bool flip = (i & k) != 0 && (k < cluster_size); \
                                                    \
    const type xl = intel_sub_group_shuffle(x, l);  \
    bool cmp = ascending ? x < xl : x > xl;         \
    x = ((cmp == (i < l)) != flip) ? x : xl;        \
}

#define BITONIC_SUB_GROUP_SORT_DECL(type, suffix, _ascending)        \
inline type                                                          \
sub_group_sort##suffix##_clustered(type x, const uint cluster_size)  \
{                                                                    \
    const uint sub_group_size = get_sub_group_size();                \
    const uint i = get_sub_group_local_id();                         \
    const bool ascending = _ascending;                               \
    if (sub_group_size >= 2 && cluster_size >= 2) {                  \
        BITONIC_SUB_GROUP_SORT_STEP(type, x,  2,  1)                 \
    }                                                                \
    if (sub_group_size >= 4 && cluster_size >= 4) {                  \
        BITONIC_SUB_GROUP_SORT_STEP(type, x,  4,  2)                 \
        BITONIC_SUB_GROUP_SORT_STEP(type, x,  4,  1)                 \
    }                                                                \
    if (sub_group_size >= 8 && cluster_size >= 8) {                  \
        BITONIC_SUB_GROUP_SORT_STEP(type, x,  8,  4)                 \
        BITONIC_SUB_GROUP_SORT_STEP(type, x,  8,  2)                 \
        BITONIC_SUB_GROUP_SORT_STEP(type, x,  8,  1)                 \
    }                                                                \
    if (sub_group_size >= 16 && cluster_size >= 16) {                \
        BITONIC_SUB_GROUP_SORT_STEP(type, x, 16,  8)                 \
        BITONIC_SUB_GROUP_SORT_STEP(type, x, 16,  4)                 \
        BITONIC_SUB_GROUP_SORT_STEP(type, x, 16,  2)                 \
        BITONIC_SUB_GROUP_SORT_STEP(type, x, 16,  1)                 \
    }                                                                \
    if (sub_group_size >= 32 && cluster_size >= 32) {                \
        BITONIC_SUB_GROUP_SORT_STEP(type, x, 32, 16)                 \
        BITONIC_SUB_GROUP_SORT_STEP(type, x, 32,  8)                 \
        BITONIC_SUB_GROUP_SORT_STEP(type, x, 32,  4)                 \
        BITONIC_SUB_GROUP_SORT_STEP(type, x, 32,  2)                 \
        BITONIC_SUB_GROUP_SORT_STEP(type, x, 32,  1)                 \
    }                                                                \
    if (sub_group_size >= 64 && cluster_size >= 64) {                \
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
inline type                                                          \
sub_group_sort##suffix(type x)                                       \
{                                                                    \
    return sub_group_sort##suffix##_clustered(x, 64);                \
}

#define BITONIC_SUB_GROUP_SORT_DECL_TYPED(type)                      \
    BITONIC_SUB_GROUP_SORT_DECL(type, _##type##_ascending, true)     \
    BITONIC_SUB_GROUP_SORT_DECL(type, _##type##_descending, false)

BITONIC_SUB_GROUP_SORT_DECL_TYPED(char)
BITONIC_SUB_GROUP_SORT_DECL_TYPED(uchar)
BITONIC_SUB_GROUP_SORT_DECL_TYPED(short)
BITONIC_SUB_GROUP_SORT_DECL_TYPED(ushort)
BITONIC_SUB_GROUP_SORT_DECL_TYPED(int)
BITONIC_SUB_GROUP_SORT_DECL_TYPED(uint)
BITONIC_SUB_GROUP_SORT_DECL_TYPED(long)
BITONIC_SUB_GROUP_SORT_DECL_TYPED(ulong)

#ifdef __cplusplus
template <typename T>
BITONIC_SUB_GROUP_SORT_DECL(type, _ascending, true)
BITONIC_SUB_GROUP_SORT_DECL(type, _descending, false)
#endif

#undef BITONIC_SUB_GROUP_SORT_STEP
#undef BITONIC_SUB_GROUP_SORT_DECL
#undef BITONIC_SUB_GROUP_SORT_DECL_TYPED

#endif /* BITONIC_SUB_GROUP_SORT_CL */
