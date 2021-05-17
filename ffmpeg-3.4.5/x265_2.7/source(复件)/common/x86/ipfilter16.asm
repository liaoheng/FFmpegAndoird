;*****************************************************************************
;* Copyright (C) 2013-2017 MulticoreWare, Inc
;*
;* Authors: Nabajit Deka <nabajit@multicorewareinc.com>
;*          Murugan Vairavel <murugan@multicorewareinc.com>
;*          Min Chen <chenm003@163.com>
;*
;* This program is free software; you can redistribute it and/or modify
;* it under the terms of the GNU General Public License as published by
;* the Free Software Foundation; either version 2 of the License, or
;* (at your option) any later version.
;*
;* This program is distributed in the hope that it will be useful,
;* but WITHOUT ANY WARRANTY; without even the implied warranty of
;* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;* GNU General Public License for more details.
;*
;* You should have received a copy of the GNU General Public License
;* along with this program; if not, write to the Free Software
;* Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02111, USA.
;*
;* This program is also available under a commercial proprietary license.
;* For more information, contact us at license @ x265.com.
;*****************************************************************************/

%include "x86inc.asm"
%include "x86util.asm"


%define INTERP_OFFSET_PP        pd_32
%define INTERP_SHIFT_PP         6

%if BIT_DEPTH == 10
    %define INTERP_SHIFT_PS         2
    %define INTERP_OFFSET_PS        pd_n32768
    %define INTERP_SHIFT_SP         10
    %define INTERP_OFFSET_SP        pd_524800
%elif BIT_DEPTH == 12
    %define INTERP_SHIFT_PS         4
    %define INTERP_OFFSET_PS        pd_n131072
    %define INTERP_SHIFT_SP         8
    %define INTERP_OFFSET_SP        pd_524416
%else
    %error Unsupport bit depth!
%endif


SECTION_RODATA 32

tab_c_524800:     times 4 dd 524800
tab_c_n8192:      times 8 dw -8192
pd_524800:        times 8 dd 524800

ALIGN 32
tab_LumaCoeffV:   times 4 dw 0, 0
                  times 4 dw 0, 64
                  times 4 dw 0, 0
                  times 4 dw 0, 0

                  times 4 dw -1, 4
                  times 4 dw -10, 58
                  times 4 dw 17, -5
                  times 4 dw 1, 0

                  times 4 dw -1, 4
                  times 4 dw -11, 40
                  times 4 dw 40, -11
                  times 4 dw 4, -1

                  times 4 dw 0, 1
                  times 4 dw -5, 17
                  times 4 dw 58, -10
                  times 4 dw 4, -1
ALIGN 32
tab_LumaCoeffVer: times 8 dw 0, 0
                  times 8 dw 0, 64
                  times 8 dw 0, 0
                  times 8 dw 0, 0

                  times 8 dw -1, 4
                  times 8 dw -10, 58
                  times 8 dw 17, -5
                  times 8 dw 1, 0

                  times 8 dw -1, 4
                  times 8 dw -11, 40
                  times 8 dw 40, -11
                  times 8 dw 4, -1

                  times 8 dw 0, 1
                  times 8 dw -5, 17
                  times 8 dw 58, -10
                  times 8 dw 4, -1

SECTION .text
cextern pd_8
cextern pd_32
cextern pw_pixel_max
cextern pd_524416
cextern pd_n32768
cextern pd_n131072
cextern pw_2000
cextern idct8_shuf2

%macro PROCESS_LUMA_VER_W4_4R_sse2 0
    movq       m0, [r0]
    movq       m1, [r0 + r1]
    punpcklwd  m0, m1                          ;m0=[0 1]
    pmaddwd    m0, [r6 + 0 *16]                ;m0=[0+1]  Row1

    lea        r0, [r0 + 2 * r1]
    movq       m4, [r0]
    punpcklwd  m1, m4                          ;m1=[1 2]
    pmaddwd    m1, [r6 + 0 *16]                ;m1=[1+2]  Row2

    movq       m5, [r0 + r1]
    punpcklwd  m4, m5                          ;m4=[2 3]
    pmaddwd    m2, m4, [r6 + 0 *16]            ;m2=[2+3]  Row3
    pmaddwd    m4, [r6 + 1 * 16]
    paddd      m0, m4                          ;m0=[0+1+2+3]  Row1

    lea        r0, [r0 + 2 * r1]
    movq       m4, [r0]
    punpcklwd  m5, m4                          ;m5=[3 4]
    pmaddwd    m3, m5, [r6 + 0 *16]            ;m3=[3+4]  Row4
    pmaddwd    m5, [r6 + 1 * 16]
    paddd      m1, m5                          ;m1 = [1+2+3+4]  Row2

    movq       m5, [r0 + r1]
    punpcklwd  m4, m5                          ;m4=[4 5]
    pmaddwd    m6, m4, [r6 + 1 * 16]
    paddd      m2, m6                          ;m2=[2+3+4+5]  Row3
    pmaddwd    m4, [r6 + 2 * 16]
    paddd      m0, m4                          ;m0=[0+1+2+3+4+5]  Row1

    lea        r0, [r0 + 2 * r1]
    movq       m4, [r0]
    punpcklwd  m5, m4                          ;m5=[5 6]
    pmaddwd    m6, m5, [r6 + 1 * 16]
    paddd      m3, m6                          ;m3=[3+4+5+6]  Row4
    pmaddwd    m5, [r6 + 2 * 16]
    paddd      m1, m5                          ;m1=[1+2+3+4+5+6]  Row2

    movq       m5, [r0 + r1]
    punpcklwd  m4, m5                          ;m4=[6 7]
    pmaddwd    m6, m4, [r6 + 2 * 16]
    paddd      m2, m6                          ;m2=[2+3+4+5+6+7]  Row3
    pmaddwd    m4, [r6 + 3 * 16]
    paddd      m0, m4                          ;m0=[0+1+2+3+4+5+6+7]  Row1 end

    lea        r0, [r0 + 2 * r1]
    movq       m4, [r0]
    punpcklwd  m5, m4                          ;m5=[7 8]
    pmaddwd    m6, m5, [r6 + 2 * 16]
    paddd      m3, m6                          ;m3=[3+4+5+6+7+8]  Row4
    pmaddwd    m5, [r6 + 3 * 16]
    paddd      m1, m5                          ;m1=[1+2+3+4+5+6+7+8]  Row2 end

    movq       m5, [r0 + r1]
    punpcklwd  m4, m5                          ;m4=[8 9]
    pmaddwd    m4, [r6 + 3 * 16]
    paddd      m2, m4                          ;m2=[2+3+4+5+6+7+8+9]  Row3 end

    movq       m4, [r0 + 2 * r1]
    punpcklwd  m5, m4                          ;m5=[9 10]
    pmaddwd    m5, [r6 + 3 * 16]
    paddd      m3, m5                          ;m3=[3+4+5+6+7+8+9+10]  Row4 end
%endmacro

;--------------------------------------------------------------------------------------------------------------
; void interp_8tap_vert_%1_%2x%3(pixel *src, intptr_t srcStride, pixel *dst, intptr_t dstStride, int coeffIdx)
;--------------------------------------------------------------------------------------------------------------
%macro FILTER_VER_LUMA_sse2 3
INIT_XMM sse2
cglobal interp_8tap_vert_%1_%2x%3, 5, 7, 8

    add       r1d, r1d
    add       r3d, r3d
    lea       r5, [r1 + 2 * r1]
    sub       r0, r5
    shl       r4d, 6

%ifdef PIC
    lea       r5, [tab_LumaCoeffV]
    lea       r6, [r5 + r4]
%else
    lea       r6, [tab_LumaCoeffV + r4]
%endif

%ifidn %1,pp
    mova      m7, [INTERP_OFFSET_PP]
%define SHIFT 6
%elifidn %1,ps
    mova      m7, [INTERP_OFFSET_PS]
  %if BIT_DEPTH == 10
    %define SHIFT 2
  %elif BIT_DEPTH == 12
    %define SHIFT 4
  %endif
%endif

    mov         r4d, %3/4
.loopH:
%assign x 0
%rep %2/4
    PROCESS_LUMA_VER_W4_4R_sse2

    paddd     m0, m7
    paddd     m1, m7
    paddd     m2, m7
    paddd     m3, m7

    psrad     m0, SHIFT
    psrad     m1, SHIFT
    psrad     m2, SHIFT
    psrad     m3, SHIFT

    packssdw  m0, m1
    packssdw  m2, m3

%ifidn %1,pp
    pxor      m1, m1
    CLIPW2    m0, m2, m1, [pw_pixel_max]
%endif

    movh      [r2 + x], m0
    movhps    [r2 + r3 + x], m0
    lea       r5, [r2 + 2 * r3]
    movh      [r5 + x], m2
    movhps    [r5 + r3 + x], m2

    lea       r5, [8 * r1 - 2 * 4]
    sub       r0, r5
%assign x x+8
%endrep

    lea       r0, [r0 + 4 * r1 - 2 * %2]
    lea       r2, [r2 + 4 * r3]

    dec         r4d
    jnz       .loopH

    RET
%endmacro

;-------------------------------------------------------------------------------------------------------------
; void interp_8tap_vert_pp_%2x%3(pixel *src, intptr_t srcStride, pixel *dst, intptr_t dstStride, int coeffIdx)
;-------------------------------------------------------------------------------------------------------------
    FILTER_VER_LUMA_sse2 pp, 4, 4
    FILTER_VER_LUMA_sse2 pp, 8, 8
    FILTER_VER_LUMA_sse2 pp, 8, 4
    FILTER_VER_LUMA_sse2 pp, 4, 8
    FILTER_VER_LUMA_sse2 pp, 16, 16
    FILTER_VER_LUMA_sse2 pp, 16, 8
    FILTER_VER_LUMA_sse2 pp, 8, 16
    FILTER_VER_LUMA_sse2 pp, 16, 12
    FILTER_VER_LUMA_sse2 pp, 12, 16
    FILTER_VER_LUMA_sse2 pp, 16, 4
    FILTER_VER_LUMA_sse2 pp, 4, 16
    FILTER_VER_LUMA_sse2 pp, 32, 32
    FILTER_VER_LUMA_sse2 pp, 32, 16
    FILTER_VER_LUMA_sse2 pp, 16, 32
    FILTER_VER_LUMA_sse2 pp, 32, 24
    FILTER_VER_LUMA_sse2 pp, 24, 32
    FILTER_VER_LUMA_sse2 pp, 32, 8
    FILTER_VER_LUMA_sse2 pp, 8, 32
    FILTER_VER_LUMA_sse2 pp, 64, 64
    FILTER_VER_LUMA_sse2 pp, 64, 32
    FILTER_VER_LUMA_sse2 pp, 32, 64
    FILTER_VER_LUMA_sse2 pp, 64, 48
    FILTER_VER_LUMA_sse2 pp, 48, 64
    FILTER_VER_LUMA_sse2 pp, 64, 16
    FILTER_VER_LUMA_sse2 pp, 16, 64

;-------------------------------------------------------------------------------------------------------------
; void interp_8tap_vert_ps_%2x%3(pixel *src, intptr_t srcStride, pixel *dst, intptr_t dstStride, int coeffIdx)
;-------------------------------------------------------------------------------------------------------------
    FILTER_VER_LUMA_sse2 ps, 4, 4
    FILTER_VER_LUMA_sse2 ps, 8, 8
    FILTER_VER_LUMA_sse2 ps, 8, 4
    FILTER_VER_LUMA_sse2 ps, 4, 8
    FILTER_VER_LUMA_sse2 ps, 16, 16
    FILTER_VER_LUMA_sse2 ps, 16, 8
    FILTER_VER_LUMA_sse2 ps, 8, 16
    FILTER_VER_LUMA_sse2 ps, 16, 12
    FILTER_VER_LUMA_sse2 ps, 12, 16
    FILTER_VER_LUMA_sse2 ps, 16, 4
    FILTER_VER_LUMA_sse2 ps, 4, 16
    FILTER_VER_LUMA_sse2 ps, 32, 32
    FILTER_VER_LUMA_sse2 ps, 32, 16
    FILTER_VER_LUMA_sse2 ps, 16, 32
    FILTER_VER_LUMA_sse2 ps, 32, 24
    FILTER_VER_LUMA_sse2 ps, 24, 32
    FILTER_VER_LUMA_sse2 ps, 32, 8
    FILTER_VER_LUMA_sse2 ps, 8, 32
    FILTER_VER_LUMA_sse2 ps, 64, 64
    FILTER_VER_LUMA_sse2 ps, 64, 32
    FILTER_VER_LUMA_sse2 ps, 32, 64
    FILTER_VER_LUMA_sse2 ps, 64, 48
    FILTER_VER_LUMA_sse2 ps, 48, 64
    FILTER_VER_LUMA_sse2 ps, 64, 16
    FILTER_VER_LUMA_sse2 ps, 16, 64


%macro PROCESS_LUMA_VER_W4_4R 0
    movq       m0, [r0]
    movq       m1, [r0 + r1]
    punpcklwd  m0, m1                          ;m0=[0 1]
    pmaddwd    m0, [r6 + 0 *16]                ;m0=[0+1]  Row1

    lea        r0, [r0 + 2 * r1]
    movq       m4, [r0]
    punpcklwd  m1, m4                          ;m1=[1 2]
    pmaddwd    m1, [r6 + 0 *16]                ;m1=[1+2]  Row2

    movq       m5, [r0 + r1]
    punpcklwd  m4, m5                          ;m4=[2 3]
    pmaddwd    m2, m4, [r6 + 0 *16]            ;m2=[2+3]  Row3
    pmaddwd    m4, [r6 + 1 * 16]
    paddd      m0, m4                          ;m0=[0+1+2+3]  Row1

    lea        r0, [r0 + 2 * r1]
    movq       m4, [r0]
    punpcklwd  m5, m4                          ;m5=[3 4]
    pmaddwd    m3, m5, [r6 + 0 *16]            ;m3=[3+4]  Row4
    pmaddwd    m5, [r6 + 1 * 16]
    paddd      m1, m5                          ;m1 = [1+2+3+4]  Row2

    movq       m5, [r0 + r1]
    punpcklwd  m4, m5                          ;m4=[4 5]
    pmaddwd    m6, m4, [r6 + 1 * 16]
    paddd      m2, m6                          ;m2=[2+3+4+5]  Row3
    pmaddwd    m4, [r6 + 2 * 16]
    paddd      m0, m4                          ;m0=[0+1+2+3+4+5]  Row1

    lea        r0, [r0 + 2 * r1]
    movq       m4, [r0]
    punpcklwd  m5, m4                          ;m5=[5 6]
    pmaddwd    m6, m5, [r6 + 1 * 16]
    paddd      m3, m6                          ;m3=[3+4+5+6]  Row4
    pmaddwd    m5, [r6 + 2 * 16]
    paddd      m1, m5                          ;m1=[1+2+3+4+5+6]  Row2

    movq       m5, [r0 + r1]
    punpcklwd  m4, m5                          ;m4=[6 7]
    pmaddwd    m6, m4, [r6 + 2 * 16]
    paddd      m2, m6                          ;m2=[2+3+4+5+6+7]  Row3
    pmaddwd    m4, [r6 + 3 * 16]
    paddd      m0, m4                          ;m0=[0+1+2+3+4+5+6+7]  Row1 end

    lea        r0, [r0 + 2 * r1]
    movq       m4, [r0]
    punpcklwd  m5, m4                          ;m5=[7 8]
    pmaddwd    m6, m5, [r6 + 2 * 16]
    paddd      m3, m6                          ;m3=[3+4+5+6+7+8]  Row4
    pmaddwd    m5, [r6 + 3 * 16]
    paddd      m1, m5                          ;m1=[1+2+3+4+5+6+7+8]  Row2 end

    movq       m5, [r0 + r1]
    punpcklwd  m4, m5                          ;m4=[8 9]
    pmaddwd    m4, [r6 + 3 * 16]
    paddd      m2, m4                          ;m2=[2+3+4+5+6+7+8+9]  Row3 end

    movq       m4, [r0 + 2 * r1]
    punpcklwd  m5, m4                          ;m5=[9 10]
    pmaddwd    m5, [r6 + 3 * 16]
    paddd      m3, m5                          ;m3=[3+4+5+6+7+8+9+10]  Row4 end
%endmacro

;--------------------------------------------------------------------------------------------------------------
; void interp_8tap_vert_pp_%1x%2(pixel *src, intptr_t srcStride, pixel *dst, intptr_t dstStride, int coeffIdx)
;--------------------------------------------------------------------------------------------------------------
%macro FILTER_VER_LUMA_PP 2
INIT_XMM sse4
cglobal interp_8tap_vert_pp_%1x%2, 5, 7, 8 ,0-gprsize

    add       r1d, r1d
    add       r3d, r3d
    lea       r5, [r1 + 2 * r1]
    sub       r0, r5
    shl       r4d, 6

%ifdef PIC
    lea       r5, [tab_LumaCoeffV]
    lea       r6, [r5 + r4]
%else
    lea       r6, [tab_LumaCoeffV + r4]
%endif

    mova      m7, [INTERP_OFFSET_PP]

    mov       dword [rsp], %2/4
.loopH:
    mov       r4d, (%1/4)
.loopW:
    PROCESS_LUMA_VER_W4_4R

    paddd     m0, m7
    paddd     m1, m7
    paddd     m2, m7
    paddd     m3, m7

    psrad     m0, INTERP_SHIFT_PP
    psrad     m1, INTERP_SHIFT_PP
    psrad     m2, INTERP_SHIFT_PP
    psrad     m3, INTERP_SHIFT_PP

    packssdw  m0, m1
    packssdw  m2, m3

    pxor      m1, m1
    CLIPW2    m0, m2, m1, [pw_pixel_max]

    movh      [r2], m0
    movhps    [r2 + r3], m0
    lea       r5, [r2 + 2 * r3]
    movh      [r5], m2
    movhps    [r5 + r3], m2

    lea       r5, [8 * r1 - 2 * 4]
    sub       r0, r5
    add       r2, 2 * 4

    dec       r4d
    jnz       .loopW

    lea       r0, [r0 + 4 * r1 - 2 * %1]
    lea       r2, [r2 + 4 * r3 - 2 * %1]

    dec       dword [rsp]
    jnz       .loopH
    RET
%endmacro

;-------------------------------------------------------------------------------------------------------------
; void interp_8tap_vert_pp_%1x%2(pixel *src, intptr_t srcStride, pixel *dst, intptr_t dstStride, int coeffIdx)
;-------------------------------------------------------------------------------------------------------------
    FILTER_VER_LUMA_PP 4, 4
    FILTER_VER_LUMA_PP 8, 8
    FILTER_VER_LUMA_PP 8, 4
    FILTER_VER_LUMA_PP 4, 8
    FILTER_VER_LUMA_PP 16, 16
    FILTER_VER_LUMA_PP 16, 8
    FILTER_VER_LUMA_PP 8, 16
    FILTER_VER_LUMA_PP 16, 12
    FILTER_VER_LUMA_PP 12, 16
    FILTER_VER_LUMA_PP 16, 4
    FILTER_VER_LUMA_PP 4, 16
    FILTER_VER_LUMA_PP 32, 32
    FILTER_VER_LUMA_PP 32, 16
    FILTER_VER_LUMA_PP 16, 32
    FILTER_VER_LUMA_PP 32, 24
    FILTER_VER_LUMA_PP 24, 32
    FILTER_VER_LUMA_PP 32, 8
    FILTER_VER_LUMA_PP 8, 32
    FILTER_VER_LUMA_PP 64, 64
    FILTER_VER_LUMA_PP 64, 32
    FILTER_VER_LUMA_PP 32, 64
    FILTER_VER_LUMA_PP 64, 48
    FILTER_VER_LUMA_PP 48, 64
    FILTER_VER_LUMA_PP 64, 16
    FILTER_VER_LUMA_PP 16, 64

%macro FILTER_VER_LUMA_AVX2_4x4 1
INIT_YMM avx2
cglobal interp_8tap_vert_%1_4x4, 4, 6, 7
    mov             r4d, r4m
    add             r1d, r1d
    add             r3d, r3d
    shl             r4d, 7

%ifdef PIC
    lea             r5, [tab_LumaCoeffVer]
    add             r5, r4
%else
    lea             r5, [tab_LumaCoeffVer + r4]
%endif

    lea             r4, [r1 * 3]
    sub             r0, r4

%ifidn %1,pp
    vbroadcasti128  m6, [pd_32]
%elifidn %1, sp
    vbroadcasti128  m6, [INTERP_OFFSET_SP]
%else
    vbroadcasti128  m6, [INTERP_OFFSET_PS]
%endif

    movq            xm0, [r0]
    movq            xm1, [r0 + r1]
    punpcklwd       xm0, xm1
    movq            xm2, [r0 + r1 * 2]
    punpcklwd       xm1, xm2
    vinserti128     m0, m0, xm1, 1                  ; m0 = [2 1 1 0]
    pmaddwd         m0, [r5]
    movq            xm3, [r0 + r4]
    punpcklwd       xm2, xm3
    lea             r0, [r0 + 4 * r1]
    movq            xm4, [r0]
    punpcklwd       xm3, xm4
    vinserti128     m2, m2, xm3, 1                  ; m2 = [4 3 3 2]
    pmaddwd         m5, m2, [r5 + 1 * mmsize]
    pmaddwd         m2, [r5]
    paddd           m0, m5
    movq            xm3, [r0 + r1]
    punpcklwd       xm4, xm3
    movq            xm1, [r0 + r1 * 2]
    punpcklwd       xm3, xm1
    vinserti128     m4, m4, xm3, 1                  ; m4 = [6 5 5 4]
    pmaddwd         m5, m4, [r5 + 2 * mmsize]
    pmaddwd         m4, [r5 + 1 * mmsize]
    paddd           m0, m5
    paddd           m2, m4
    movq            xm3, [r0 + r4]
    punpcklwd       xm1, xm3
    lea             r0, [r0 + 4 * r1]
    movq            xm4, [r0]
    punpcklwd       xm3, xm4
    vinserti128     m1, m1, xm3, 1                  ; m1 = [8 7 7 6]
    pmaddwd         m5, m1, [r5 + 3 * mmsize]
    pmaddwd         m1, [r5 + 2 * mmsize]
    paddd           m0, m5
    paddd           m2, m1
    movq            xm3, [r0 + r1]
    punpcklwd       xm4, xm3
    movq            xm1, [r0 + 2 * r1]
    punpcklwd       xm3, xm1
    vinserti128     m4, m4, xm3, 1                  ; m4 = [A 9 9 8]
    pmaddwd         m4, [r5 + 3 * mmsize]
    paddd           m2, m4

%ifidn %1,ss
    psrad           m0, 6
    psrad           m2, 6
%else
    paddd           m0, m6
    paddd           m2, m6
%ifidn %1,pp
    psrad           m0, INTERP_SHIFT_PP
    psrad           m2, INTERP_SHIFT_PP
%elifidn %1, sp
    psrad           m0, INTERP_SHIFT_SP
    psrad           m2, INTERP_SHIFT_SP
%else
    psrad           m0, INTERP_SHIFT_PS
    psrad           m2, INTERP_SHIFT_PS
%endif
%endif

    packssdw        m0, m2
    pxor            m1, m1
%ifidn %1,pp
    CLIPW           m0, m1, [pw_pixel_max]
%elifidn %1, sp
    CLIPW           m0, m1, [pw_pixel_max]
%endif

    vextracti128    xm2, m0, 1
    lea             r4, [r3 * 3]
    movq            [r2], xm0
    movq            [r2 + r3], xm2
    movhps          [r2 + r3 * 2], xm0
    movhps          [r2 + r4], xm2
    RET
%endmacro

FILTER_VER_LUMA_AVX2_4x4 pp
FILTER_VER_LUMA_AVX2_4x4 ps
FILTER_VER_LUMA_AVX2_4x4 sp
FILTER_VER_LUMA_AVX2_4x4 ss

%macro FILTER_VER_LUMA_AVX2_8x8 1
INIT_YMM avx2
%if ARCH_X86_64 == 1
cglobal interp_8tap_vert_%1_8x8, 4, 6, 12
    mov             r4d, r4m
    add             r1d, r1d
    add             r3d, r3d
    shl             r4d, 7

%ifdef PIC
    lea             r5, [tab_LumaCoeffVer]
    add             r5, r4
%else
    lea             r5, [tab_LumaCoeffVer + r4]
%endif

    lea             r4, [r1 * 3]
    sub             r0, r4

%ifidn %1,pp
    vbroadcasti128  m11, [pd_32]
%elifidn %1, sp
    vbroadcasti128  m11, [INTERP_OFFSET_SP]
%else
    vbroadcasti128  m11, [INTERP_OFFSET_PS]
%endif

    movu            xm0, [r0]                       ; m0 = row 0
    movu            xm1, [r0 + r1]                  ; m1 = row 1
    punpckhwd       xm2, xm0, xm1
    punpcklwd       xm0, xm1
    vinserti128     m0, m0, xm2, 1
    pmaddwd         m0, [r5]
    movu            xm2, [r0 + r1 * 2]              ; m2 = row 2
    punpckhwd       xm3, xm1, xm2
    punpcklwd       xm1, xm2
    vinserti128     m1, m1, xm3, 1
    pmaddwd         m1, [r5]
    movu            xm3, [r0 + r4]                  ; m3 = row 3
    punpckhwd       xm4, xm2, xm3
    punpcklwd       xm2, xm3
    vinserti128     m2, m2, xm4, 1
    pmaddwd         m4, m2, [r5 + 1 * mmsize]
    pmaddwd         m2, [r5]
    paddd           m0, m4
    lea             r0, [r0 + r1 * 4]
    movu            xm4, [r0]                       ; m4 = row 4
    punpckhwd       xm5, xm3, xm4
    punpcklwd       xm3, xm4
    vinserti128     m3, m3, xm5, 1
    pmaddwd         m5, m3, [r5 + 1 * mmsize]
    pmaddwd         m3, [r5]
    paddd           m1, m5
    movu            xm5, [r0 + r1]                  ; m5 = row 5
    punpckhwd       xm6, xm4, xm5
    punpcklwd       xm4, xm5
    vinserti128     m4, m4, xm6, 1
    pmaddwd         m6, m4, [r5 + 2 * mmsize]
    paddd           m0, m6
    pmaddwd         m6, m4, [r5 + 1 * mmsize]
    paddd           m2, m6
    pmaddwd         m4, [r5]
    movu            xm6, [r0 + r1 * 2]              ; m6 = row 6
    punpckhwd       xm7, xm5, xm6
    punpcklwd       xm5, xm6
    vinserti128     m5, m5, xm7, 1
    pmaddwd         m7, m5, [r5 + 2 * mmsize]
    paddd           m1, m7
    pmaddwd         m7, m5, [r5 + 1 * mmsize]
    pmaddwd         m5, [r5]
    paddd           m3, m7
    movu            xm7, [r0 + r4]                  ; m7 = row 7
    punpckhwd       xm8, xm6, xm7
    punpcklwd       xm6, xm7
    vinserti128     m6, m6, xm8, 1
    pmaddwd         m8, m6, [r5 + 3 * mmsize]
    paddd           m0, m8
    pmaddwd         m8, m6, [r5 + 2 * mmsize]
    paddd           m2, m8
    pmaddwd         m8, m6, [r5 + 1 * mmsize]
    pmaddwd         m6, [r5]
    paddd           m4, m8
    lea             r0, [r0 + r1 * 4]
    movu            xm8, [r0]                       ; m8 = row 8
    punpckhwd       xm9, xm7, xm8
    punpcklwd       xm7, xm8
    vinserti128     m7, m7, xm9, 1
    pmaddwd         m9, m7, [r5 + 3 * mmsize]
    paddd           m1, m9
    pmaddwd         m9, m7, [r5 + 2 * mmsize]
    paddd           m3, m9
    pmaddwd         m9, m7, [r5 + 1 * mmsize]
    pmaddwd         m7, [r5]
    paddd           m5, m9
    movu            xm9, [r0 + r1]                  ; m9 = row 9
    punpckhwd       xm10, xm8, xm9
    punpcklwd       xm8, xm9
    vinserti128     m8, m8, xm10, 1
    pmaddwd         m10, m8, [r5 + 3 * mmsize]
    paddd           m2, m10
    pmaddwd         m10, m8, [r5 + 2 * mmsize]
    pmaddwd         m8, [r5 + 1 * mmsize]
    paddd           m4, m10
    paddd           m6, m8
    movu            xm10, [r0 + r1 * 2]             ; m10 = row 10
    punpckhwd       xm8, xm9, xm10
    punpcklwd       xm9, xm10
    vinserti128     m9, m9, xm8, 1
    pmaddwd         m8, m9, [r5 + 3 * mmsize]
    paddd           m3, m8
    pmaddwd         m8, m9, [r5 + 2 * mmsize]
    pmaddwd         m9, [r5 + 1 * mmsize]
    paddd           m5, m8
    paddd           m7, m9
    movu            xm8, [r0 + r4]                  ; m8 = row 11
    punpckhwd       xm9, xm10, xm8
    punpcklwd       xm10, xm8
    vinserti128     m10, m10, xm9, 1
    pmaddwd         m9, m10, [r5 + 3 * mmsize]
    pmaddwd         m10, [r5 + 2 * mmsize]
    paddd           m4, m9
    paddd           m6, m10

    lea             r4, [r3 * 3]
%ifidn %1,ss
    psrad           m0, 6
    psrad           m1, 6
    psrad           m2, 6
    psrad           m3, 6
%else
    paddd           m0, m11
    paddd           m1, m11
    paddd           m2, m11
    paddd           m3, m11
%ifidn %1,pp
    psrad           m0, INTERP_SHIFT_PP
    psrad           m1, INTERP_SHIFT_PP
    psrad           m2, INTERP_SHIFT_PP
    psrad           m3, INTERP_SHIFT_PP
%elifidn %1, sp
    psrad           m0, INTERP_SHIFT_SP
    psrad           m1, INTERP_SHIFT_SP
    psrad           m2, INTERP_SHIFT_SP
    psrad           m3, INTERP_SHIFT_SP
%else
    psrad           m0, INTERP_SHIFT_PS
    psrad           m1, INTERP_SHIFT_PS
    psrad           m2, INTERP_SHIFT_PS
    psrad           m3, INTERP_SHIFT_PS
%endif
%endif

    packssdw        m0, m1
    packssdw        m2, m3
    vpermq          m0, m0, 11011000b
    vpermq          m2, m2, 11011000b
    pxor            m10, m10
    mova            m9, [pw_pixel_max]
%ifidn %1,pp
    CLIPW           m0, m10, m9
    CLIPW           m2, m10, m9
%elifidn %1, sp
    CLIPW           m0, m10, m9
    CLIPW           m2, m10, m9
%endif

    vextracti128    xm1, m0, 1
    vextracti128    xm3, m2, 1
    movu            [r2], xm0
    movu            [r2 + r3], xm1
    movu            [r2 + r3 * 2], xm2
    movu            [r2 + r4], xm3

    lea             r0, [r0 + r1 * 4]
    movu            xm2, [r0]                       ; m2 = row 12
    punpckhwd       xm3, xm8, xm2
    punpcklwd       xm8, xm2
    vinserti128     m8, m8, xm3, 1
    pmaddwd         m3, m8, [r5 + 3 * mmsize]
    pmaddwd         m8, [r5 + 2 * mmsize]
    paddd           m5, m3
    paddd           m7, m8
    movu            xm3, [r0 + r1]                  ; m3 = row 13
    punpckhwd       xm0, xm2, xm3
    punpcklwd       xm2, xm3
    vinserti128     m2, m2, xm0, 1
    pmaddwd         m2, [r5 + 3 * mmsize]
    paddd           m6, m2
    movu            xm0, [r0 + r1 * 2]              ; m0 = row 14
    punpckhwd       xm1, xm3, xm0
    punpcklwd       xm3, xm0
    vinserti128     m3, m3, xm1, 1
    pmaddwd         m3, [r5 + 3 * mmsize]
    paddd           m7, m3

%ifidn %1,ss
    psrad           m4, 6
    psrad           m5, 6
    psrad           m6, 6
    psrad           m7, 6
%else
    paddd           m4, m11
    paddd           m5, m11
    paddd           m6, m11
    paddd           m7, m11
%ifidn %1,pp
    psrad           m4, INTERP_SHIFT_PP
    psrad           m5, INTERP_SHIFT_PP
    psrad           m6, INTERP_SHIFT_PP
    psrad           m7, INTERP_SHIFT_PP
%elifidn %1, sp
    psrad           m4, INTERP_SHIFT_SP
    psrad           m5, INTERP_SHIFT_SP
    psrad           m6, INTERP_SHIFT_SP
    psrad           m7, INTERP_SHIFT_SP
%else
    psrad           m4, INTERP_SHIFT_PS
    psrad           m5, INTERP_SHIFT_PS
    psrad           m6, INTERP_SHIFT_PS
    psrad           m7, INTERP_SHIFT_PS
%endif
%endif

    packssdw        m4, m5
    packssdw        m6, m7
    vpermq          m4, m4, 11011000b
    vpermq          m6, m6, 11011000b
%ifidn %1,pp
    CLIPW           m4, m10, m9
    CLIPW           m6, m10, m9
%elifidn %1, sp
    CLIPW           m4, m10, m9
    CLIPW           m6, m10, m9
%endif
    vextracti128    xm5, m4, 1
    vextracti128    xm7, m6, 1
    lea             r2, [r2 + r3 * 4]
    movu            [r2], xm4
    movu            [r2 + r3], xm5
    movu            [r2 + r3 * 2], xm6
    movu            [r2 + r4], xm7
    RET
%endif
%endmacro

FILTER_VER_LUMA_AVX2_8x8 pp
FILTER_VER_LUMA_AVX2_8x8 ps
FILTER_VER_LUMA_AVX2_8x8 sp
FILTER_VER_LUMA_AVX2_8x8 ss

%macro PROCESS_LUMA_AVX2_W8_16R 1
    movu            xm0, [r0]                       ; m0 = row 0
    movu            xm1, [r0 + r1]                  ; m1 = row 1
    punpckhwd       xm2, xm0, xm1
    punpcklwd       xm0, xm1
    vinserti128     m0, m0, xm2, 1
    pmaddwd         m0, [r5]
    movu            xm2, [r0 + r1 * 2]              ; m2 = row 2
    punpckhwd       xm3, xm1, xm2
    punpcklwd       xm1, xm2
    vinserti128     m1, m1, xm3, 1
    pmaddwd         m1, [r5]
    movu            xm3, [r0 + r4]                  ; m3 = row 3
    punpckhwd       xm4, xm2, xm3
    punpcklwd       xm2, xm3
    vinserti128     m2, m2, xm4, 1
    pmaddwd         m4, m2, [r5 + 1 * mmsize]
    paddd           m0, m4
    pmaddwd         m2, [r5]
    lea             r7, [r0 + r1 * 4]
    movu            xm4, [r7]                       ; m4 = row 4
    punpckhwd       xm5, xm3, xm4
    punpcklwd       xm3, xm4
    vinserti128     m3, m3, xm5, 1
    pmaddwd         m5, m3, [r5 + 1 * mmsize]
    paddd           m1, m5
    pmaddwd         m3, [r5]
    movu            xm5, [r7 + r1]                  ; m5 = row 5
    punpckhwd       xm6, xm4, xm5
    punpcklwd       xm4, xm5
    vinserti128     m4, m4, xm6, 1
    pmaddwd         m6, m4, [r5 + 2 * mmsize]
    paddd           m0, m6
    pmaddwd         m6, m4, [r5 + 1 * mmsize]
    paddd           m2, m6
    pmaddwd         m4, [r5]
    movu            xm6, [r7 + r1 * 2]              ; m6 = row 6
    punpckhwd       xm7, xm5, xm6
    punpcklwd       xm5, xm6
    vinserti128     m5, m5, xm7, 1
    pmaddwd         m7, m5, [r5 + 2 * mmsize]
    paddd           m1, m7
    pmaddwd         m7, m5, [r5 + 1 * mmsize]
    paddd           m3, m7
    pmaddwd         m5, [r5]
    movu            xm7, [r7 + r4]                  ; m7 = row 7
    punpckhwd       xm8, xm6, xm7
    punpcklwd       xm6, xm7
    vinserti128     m6, m6, xm8, 1
    pmaddwd         m8, m6, [r5 + 3 * mmsize]
    paddd           m0, m8
    pmaddwd         m8, m6, [r5 + 2 * mmsize]
    paddd           m2, m8
    pmaddwd         m8, m6, [r5 + 1 * mmsize]
    paddd           m4, m8
    pmaddwd         m6, [r5]
    lea             r7, [r7 + r1 * 4]
    movu            xm8, [r7]                       ; m8 = row 8
    punpckhwd       xm9, xm7, xm8
    punpcklwd       xm7, xm8
    vinserti128     m7, m7, xm9, 1
    pmaddwd         m9, m7, [r5 + 3 * mmsize]
    paddd           m1, m9
    pmaddwd         m9, m7, [r5 + 2 * mmsize]
    paddd           m3, m9
    pmaddwd         m9, m7, [r5 + 1 * mmsize]
    paddd           m5, m9
    pmaddwd         m7, [r5]
    movu            xm9, [r7 + r1]                  ; m9 = row 9
    punpckhwd       xm10, xm8, xm9
    punpcklwd       xm8, xm9
    vinserti128     m8, m8, xm10, 1
    pmaddwd         m10, m8, [r5 + 3 * mmsize]
    paddd           m2, m10
    pmaddwd         m10, m8, [r5 + 2 * mmsize]
    paddd           m4, m10
    pmaddwd         m10, m8, [r5 + 1 * mmsize]
    paddd           m6, m10
    pmaddwd         m8, [r5]
    movu            xm10, [r7 + r1 * 2]             ; m10 = row 10
    punpckhwd       xm11, xm9, xm10
    punpcklwd       xm9, xm10
    vinserti128     m9, m9, xm11, 1
    pmaddwd         m11, m9, [r5 + 3 * mmsize]
    paddd           m3, m11
    pmaddwd         m11, m9, [r5 + 2 * mmsize]
    paddd           m5, m11
    pmaddwd         m11, m9, [r5 + 1 * mmsize]
    paddd           m7, m11
    pmaddwd         m9, [r5]
    movu            xm11, [r7 + r4]                 ; m11 = row 11
    punpckhwd       xm12, xm10, xm11
    punpcklwd       xm10, xm11
    vinserti128     m10, m10, xm12, 1
    pmaddwd         m12, m10, [r5 + 3 * mmsize]
    paddd           m4, m12
    pmaddwd         m12, m10, [r5 + 2 * mmsize]
    paddd           m6, m12
    pmaddwd         m12, m10, [r5 + 1 * mmsize]
    paddd           m8, m12
    pmaddwd         m10, [r5]
    lea             r7, [r7 + r1 * 4]
    movu            xm12, [r7]                      ; m12 = row 12
    punpckhwd       xm13, xm11, xm12
    punpcklwd       xm11, xm12
    vinserti128     m11, m11, xm13, 1
    pmaddwd         m13, m11, [r5 + 3 * mmsize]
    paddd           m5, m13
    pmaddwd         m13, m11, [r5 + 2 * mmsize]
    paddd           m7, m13
    pmaddwd         m13, m11, [r5 + 1 * mmsize]
    paddd           m9, m13
    pmaddwd         m11, [r5]

%ifidn %1,ss
    psrad           m0, 6
    psrad           m1, 6
    psrad           m2, 6
    psrad           m3, 6
    psrad           m4, 6
    psrad           m5, 6
%else
    paddd           m0, m14
    paddd           m1, m14
    paddd           m2, m14
    paddd           m3, m14
    paddd           m4, m14
    paddd           m5, m14
%ifidn %1,pp
    psrad           m0, INTERP_SHIFT_PP
    psrad           m1, INTERP_SHIFT_PP
    psrad           m2, INTERP_SHIFT_PP
    psrad           m3, INTERP_SHIFT_PP
    psrad           m4, INTERP_SHIFT_PP
    psrad           m5, INTERP_SHIFT_PP
%elifidn %1, sp
    psrad           m0, INTERP_SHIFT_SP
    psrad           m1, INTERP_SHIFT_SP
    psrad           m2, INTERP_SHIFT_SP
    psrad           m3, INTERP_SHIFT_SP
    psrad           m4, INTERP_SHIFT_SP
    psrad           m5, INTERP_SHIFT_SP
%else
    psrad           m0, INTERP_SHIFT_PS
    psrad           m1, INTERP_SHIFT_PS
    psrad           m2, INTERP_SHIFT_PS
    psrad           m3, INTERP_SHIFT_PS
    psrad           m4, INTERP_SHIFT_PS
    psrad           m5, INTERP_SHIFT_PS
%endif
%endif

    packssdw        m0, m1
    packssdw        m2, m3
    packssdw        m4, m5
    vpermq          m0, m0, 11011000b
    vpermq          m2, m2, 11011000b
    vpermq          m4, m4, 11011000b
    pxor            m5, m5
    mova            m3, [pw_pixel_max]
%ifidn %1,pp
    CLIPW           m0, m5, m3
    CLIPW           m2, m5, m3
    CLIPW           m4, m5, m3
%elifidn %1, sp
    CLIPW           m0, m5, m3
    CLIPW           m2, m5, m3
    CLIPW           m4, m5, m3
%endif

    vextracti128    xm1, m0, 1
    movu            [r2], xm0
    movu            [r2 + r3], xm1
    vextracti128    xm1, m2, 1
    movu            [r2 + r3 * 2], xm2
    movu            [r2 + r6], xm1
    lea             r8, [r2 + r3 * 4]
    vextracti128    xm1, m4, 1
    movu            [r8], xm4
    movu            [r8 + r3], xm1

    movu            xm13, [r7 + r1]                 ; m13 = row 13
    punpckhwd       xm0, xm12, xm13
    punpcklwd       xm12, xm13
    vinserti128     m12, m12, xm0, 1
    pmaddwd         m0, m12, [r5 + 3 * mmsize]
    paddd           m6, m0
    pmaddwd         m0, m12, [r5 + 2 * mmsize]
    paddd           m8, m0
    pmaddwd         m0, m12, [r5 + 1 * mmsize]
    paddd           m10, m0
    pmaddwd         m12, [r5]
    movu            xm0, [r7 + r1 * 2]              ; m0 = row 14
    punpckhwd       xm1, xm13, xm0
    punpcklwd       xm13, xm0
    vinserti128     m13, m13, xm1, 1
    pmaddwd         m1, m13, [r5 + 3 * mmsize]
    paddd           m7, m1
    pmaddwd         m1, m13, [r5 + 2 * mmsize]
    paddd           m9, m1
    pmaddwd         m1, m13, [r5 + 1 * mmsize]
    paddd           m11, m1
    pmaddwd         m13, [r5]

%ifidn %1,ss
    psrad           m6, 6
    psrad           m7, 6
%else
    paddd           m6, m14
    paddd           m7, m14
%ifidn %1,pp
    psrad           m6, INTERP_SHIFT_PP
    psrad           m7, INTERP_SHIFT_PP
%elifidn %1, sp
    psrad           m6, INTERP_SHIFT_SP
    psrad           m7, INTERP_SHIFT_SP
%else
    psrad           m6, INTERP_SHIFT_PS
    psrad           m7, INTERP_SHIFT_PS
%endif
%endif

    packssdw        m6, m7
    vpermq          m6, m6, 11011000b
%ifidn %1,pp
    CLIPW           m6, m5, m3
%elifidn %1, sp
    CLIPW           m6, m5, m3
%endif
    vextracti128    xm7, m6, 1
    movu            [r8 + r3 * 2], xm6
    movu            [r8 + r6], xm7

    movu            xm1, [r7 + r4]                  ; m1 = row 15
    punpckhwd       xm2, xm0, xm1
    punpcklwd       xm0, xm1
    vinserti128     m0, m0, xm2, 1
    pmaddwd         m2, m0, [r5 + 3 * mmsize]
    paddd           m8, m2
    pmaddwd         m2, m0, [r5 + 2 * mmsize]
    paddd           m10, m2
    pmaddwd         m2, m0, [r5 + 1 * mmsize]
    paddd           m12, m2
    pmaddwd         m0, [r5]
    lea             r7, [r7 + r1 * 4]
    movu            xm2, [r7]                       ; m2 = row 16
    punpckhwd       xm6, xm1, xm2
    punpcklwd       xm1, xm2
    vinserti128     m1, m1, xm6, 1
    pmaddwd         m6, m1, [r5 + 3 * mmsize]
    paddd           m9, m6
    pmaddwd         m6, m1, [r5 + 2 * mmsize]
    paddd           m11, m6
    pmaddwd         m6, m1, [r5 + 1 * mmsize]
    paddd           m13, m6
    pmaddwd         m1, [r5]
    movu            xm6, [r7 + r1]                  ; m6 = row 17
    punpckhwd       xm4, xm2, xm6
    punpcklwd       xm2, xm6
    vinserti128     m2, m2, xm4, 1
    pmaddwd         m4, m2, [r5 + 3 * mmsize]
    paddd           m10, m4
    pmaddwd         m4, m2, [r5 + 2 * mmsize]
    paddd           m12, m4
    pmaddwd         m2, [r5 + 1 * mmsize]
    paddd           m0, m2
    movu            xm4, [r7 + r1 * 2]              ; m4 = row 18
    punpckhwd       xm2, xm6, xm4
    punpcklwd       xm6, xm4
    vinserti128     m6, m6, xm2, 1
    pmaddwd         m2, m6, [r5 + 3 * mmsize]
    paddd           m11, m2
    pmaddwd         m2, m6, [r5 + 2 * mmsize]
    paddd           m13, m2
    pmaddwd         m6, [r5 + 1 * mmsize]
    paddd           m1, m6
    movu            xm2, [r7 + r4]                  ; m2 = row 19
    punpckhwd       xm6, xm4, xm2
    punpcklwd       xm4, xm2
    vinserti128     m4, m4, xm6, 1
    pmaddwd         m6, m4, [r5 + 3 * mmsize]
    paddd           m12, m6
    pmaddwd         m4, [r5 + 2 * mmsize]
    paddd           m0, m4
    lea             r7, [r7 + r1 * 4]
    movu            xm6, [r7]                       ; m6 = row 20
    punpckhwd       xm7, xm2, xm6
    punpcklwd       xm2, xm6
    vinserti128     m2, m2, xm7, 1
    pmaddwd         m7, m2, [r5 + 3 * mmsize]
    paddd           m13, m7
    pmaddwd         m2, [r5 + 2 * mmsize]
    paddd           m1, m2
    movu            xm7, [r7 + r1]                  ; m7 = row 21
    punpckhwd       xm2, xm6, xm7
    punpcklwd       xm6, xm7
    vinserti128     m6, m6, xm2, 1
    pmaddwd         m6, [r5 + 3 * mmsize]
    paddd           m0, m6
    movu            xm2, [r7 + r1 * 2]              ; m2 = row 22
    punpckhwd       xm6, xm7, xm2
    punpcklwd       xm7, xm2
    vinserti128     m7, m7, xm6, 1
    pmaddwd         m7, [r5 + 3 * mmsize]
    paddd           m1, m7

%ifidn %1,ss
    psrad           m8, 6
    psrad           m9, 6
    psrad           m10, 6
    psrad           m11, 6
    psrad           m12, 6
    psrad           m13, 6
    psrad           m0, 6
    psrad           m1, 6
%else
    paddd           m8, m14
    paddd           m9, m14
    paddd           m10, m14
    paddd           m11, m14
    paddd           m12, m14
    paddd           m13, m14
    paddd           m0, m14
    paddd           m1, m14
%ifidn %1,pp
    psrad           m8, INTERP_SHIFT_PP
    psrad           m9, INTERP_SHIFT_PP
    psrad           m10, INTERP_SHIFT_PP
    psrad           m11, INTERP_SHIFT_PP
    psrad           m12, INTERP_SHIFT_PP
    psrad           m13, INTERP_SHIFT_PP
    psrad           m0, INTERP_SHIFT_PP
    psrad           m1, INTERP_SHIFT_PP
%elifidn %1, sp
    psrad           m8, INTERP_SHIFT_SP
    psrad           m9, INTERP_SHIFT_SP
    psrad           m10, INTERP_SHIFT_SP
    psrad           m11, INTERP_SHIFT_SP
    psrad           m12, INTERP_SHIFT_SP
    psrad           m13, INTERP_SHIFT_SP
    psrad           m0, INTERP_SHIFT_SP
    psrad           m1, INTERP_SHIFT_SP
%else
    psrad           m8, INTERP_SHIFT_PS
    psrad           m9, INTERP_SHIFT_PS
    psrad           m10, INTERP_SHIFT_PS
    psrad           m11, INTERP_SHIFT_PS
    psrad           m12, INTERP_SHIFT_PS
    psrad           m13, INTERP_SHIFT_PS
    psrad           m0, INTERP_SHIFT_PS
    psrad           m1, INTERP_SHIFT_PS
%endif
%endif

    packssdw        m8, m9
    packssdw        m10, m11
    packssdw        m12, m13
    packssdw        m0, m1
    vpermq          m8, m8, 11011000b
    vpermq          m10, m10, 11011000b
    vpermq          m12, m12, 11011000b
    vpermq          m0, m0, 11011000b
%ifidn %1,pp
    CLIPW           m8, m5, m3
    CLIPW           m10, m5, m3
    CLIPW           m12, m5, m3
    CLIPW           m0, m5, m3
%elifidn %1, sp
    CLIPW           m8, m5, m3
    CLIPW           m10, m5, m3
    CLIPW           m12, m5, m3
    CLIPW           m0, m5, m3
%endif
    vextracti128    xm9, m8, 1
    vextracti128    xm11, m10, 1
    vextracti128    xm13, m12, 1
    vextracti128    xm1, m0, 1
    lea             r8, [r8 + r3 * 4]
    movu            [r8], xm8
    movu            [r8 + r3], xm9
    movu            [r8 + r3 * 2], xm10
    movu            [r8 + r6], xm11
    lea             r8, [r8 + r3 * 4]
    movu            [r8], xm12
    movu            [r8 + r3], xm13
    movu            [r8 + r3 * 2], xm0
    movu            [r8 + r6], xm1
%endmacro

%macro FILTER_VER_LUMA_AVX2_Nx16 2
INIT_YMM avx2
%if ARCH_X86_64 == 1
cglobal interp_8tap_vert_%1_%2x16, 4, 10, 15
    mov             r4d, r4m
    shl             r4d, 7
    add             r1d, r1d
    add             r3d, r3d

%ifdef PIC
    lea             r5, [tab_LumaCoeffVer]
    add             r5, r4
%else
    lea             r5, [tab_LumaCoeffVer + r4]
%endif

    lea             r4, [r1 * 3]
    sub             r0, r4
%ifidn %1,pp
    vbroadcasti128  m14, [pd_32]
%elifidn %1, sp
    vbroadcasti128  m14, [INTERP_OFFSET_SP]
%else
    vbroadcasti128  m14, [INTERP_OFFSET_PS]
%endif
    lea             r6, [r3 * 3]
    mov             r9d, %2 / 8
.loopW:
    PROCESS_LUMA_AVX2_W8_16R %1
    add             r2, 16
    add             r0, 16
    dec             r9d
    jnz             .loopW
    RET
%endif
%endmacro

FILTER_VER_LUMA_AVX2_Nx16 pp, 16
FILTER_VER_LUMA_AVX2_Nx16 pp, 32
FILTER_VER_LUMA_AVX2_Nx16 pp, 64
FILTER_VER_LUMA_AVX2_Nx16 ps, 16
FILTER_VER_LUMA_AVX2_Nx16 ps, 32
FILTER_VER_LUMA_AVX2_Nx16 ps, 64
FILTER_VER_LUMA_AVX2_Nx16 sp, 16
FILTER_VER_LUMA_AVX2_Nx16 sp, 32
FILTER_VER_LUMA_AVX2_Nx16 sp, 64
FILTER_VER_LUMA_AVX2_Nx16 ss, 16
FILTER_VER_LUMA_AVX2_Nx16 ss, 32
FILTER_VER_LUMA_AVX2_Nx16 ss, 64

%macro FILTER_VER_LUMA_AVX2_NxN 3
INIT_YMM avx2
%if ARCH_X86_64 == 1
cglobal interp_8tap_vert_%3_%1x%2, 4, 12, 15
    mov             r4d, r4m
    shl             r4d, 7
    add             r1d, r1d
    add             r3d, r3d

%ifdef PIC
    lea             r5, [tab_LumaCoeffVer]
    add             r5, r4
%else
    lea             r5, [tab_LumaCoeffVer + r4]
%endif

    lea             r4, [r1 * 3]
    sub             r0, r4

%ifidn %3,pp
    vbroadcasti128  m14, [pd_32]
%elifidn %3, sp
    vbroadcasti128  m14, [INTERP_OFFSET_SP]
%else
    vbroadcasti128  m14, [INTERP_OFFSET_PS]
%endif

    lea             r6, [r3 * 3]
    lea             r11, [r1 * 4]
    mov             r9d, %2 / 16
.loopH:
    mov             r10d, %1 / 8
.loopW:
    PROCESS_LUMA_AVX2_W8_16R %3
    add             r2, 16
    add             r0, 16
    dec             r10d
    jnz             .loopW
    sub             r7, r11
    lea             r0, [r7 - 2 * %1 + 16]
    lea             r2, [r8 + r3 * 4 - 2 * %1 + 16]
    dec             r9d
    jnz             .loopH
    RET
%endif
%endmacro

FILTER_VER_LUMA_AVX2_NxN 16, 32, pp
FILTER_VER_LUMA_AVX2_NxN 16, 64, pp
FILTER_VER_LUMA_AVX2_NxN 24, 32, pp
FILTER_VER_LUMA_AVX2_NxN 32, 32, pp
FILTER_VER_LUMA_AVX2_NxN 32, 64, pp
FILTER_VER_LUMA_AVX2_NxN 48, 64, pp
FILTER_VER_LUMA_AVX2_NxN 64, 32, pp
FILTER_VER_LUMA_AVX2_NxN 64, 48, pp
FILTER_VER_LUMA_AVX2_NxN 64, 64, pp
FILTER_VER_LUMA_AVX2_NxN 16, 32, ps
FILTER_VER_LUMA_AVX2_NxN 16, 64, ps
FILTER_VER_LUMA_AVX2_NxN 24, 32, ps
FILTER_VER_LUMA_AVX2_NxN 32, 32, ps
FILTER_VER_LUMA_AVX2_NxN 32, 64, ps
FILTER_VER_LUMA_AVX2_NxN 48, 64, ps
FILTER_VER_LUMA_AVX2_NxN 64, 32, ps
FILTER_VER_LUMA_AVX2_NxN 64, 48, ps
FILTER_VER_LUMA_AVX2_NxN 64, 64, ps
FILTER_VER_LUMA_AVX2_NxN 16, 32, sp
FILTER_VER_LUMA_AVX2_NxN 16, 64, sp
FILTER_VER_LUMA_AVX2_NxN 24, 32, sp
FILTER_VER_LUMA_AVX2_NxN 32, 32, sp
FILTER_VER_LUMA_AVX2_NxN 32, 64, sp
FILTER_VER_LUMA_AVX2_NxN 48, 64, sp
FILTER_VER_LUMA_AVX2_NxN 64, 32, sp
FILTER_VER_LUMA_AVX2_NxN 64, 48, sp
FILTER_VER_LUMA_AVX2_NxN 64, 64, sp
FILTER_VER_LUMA_AVX2_NxN 16, 32, ss
FILTER_VER_LUMA_AVX2_NxN 16, 64, ss
FILTER_VER_LUMA_AVX2_NxN 24, 32, ss
FILTER_VER_LUMA_AVX2_NxN 32, 32, ss
FILTER_VER_LUMA_AVX2_NxN 32, 64, ss
FILTER_VER_LUMA_AVX2_NxN 48, 64, ss
FILTER_VER_LUMA_AVX2_NxN 64, 32, ss
FILTER_VER_LUMA_AVX2_NxN 64, 48, ss
FILTER_VER_LUMA_AVX2_NxN 64, 64, ss

%macro FILTER_VER_LUMA_AVX2_8xN 2
INIT_YMM avx2
%if ARCH_X86_64 == 1
cglobal interp_8tap_vert_%1_8x%2, 4, 9, 15
    mov             r4d, r4m
    shl             r4d, 7
    add             r1d, r1d
    add             r3d, r3d

%ifdef PIC
    lea             r5, [tab_LumaCoeffVer]
    add             r5, r4
%else
    lea             r5, [tab_LumaCoeffVer + r4]
%endif

    lea             r4, [r1 * 3]
    sub             r0, r4
%ifidn %1,pp
    vbroadcasti128  m14, [pd_32]
%elifidn %1, sp
    vbroadcasti128  m14, [INTERP_OFFSET_SP]
%else
    vbroadcasti128  m14, [INTERP_OFFSET_PS]
%endif
    lea             r6, [r3 * 3]
    lea             r7, [r1 * 4]
    mov             r8d, %2 / 16
.loopH:
    movu            xm0, [r0]                       ; m0 = row 0
    movu            xm1, [r0 + r1]                  ; m1 = row 1
    punpckhwd       xm2, xm0, xm1
    punpcklwd       xm0, xm1
    vinserti128     m0, m0, xm2, 1
    pmaddwd         m0, [r5]
    movu            xm2, [r0 + r1 * 2]              ; m2 = row 2
    punpckhwd       xm3, xm1, xm2
    punpcklwd       xm1, xm2
    vinserti128     m1, m1, xm3, 1
    pmaddwd         m1, [r5]
    movu            xm3, [r0 + r4]                  ; m3 = row 3
    punpckhwd       xm4, xm2, xm3
    punpcklwd       xm2, xm3
    vinserti128     m2, m2, xm4, 1
    pmaddwd         m4, m2, [r5 + 1 * mmsize]
    paddd           m0, m4
    pmaddwd         m2, [r5]
    lea             r0, [r0 + r1 * 4]
    movu            xm4, [r0]                       ; m4 = row 4
    punpckhwd       xm5, xm3, xm4
    punpcklwd       xm3, xm4
    vinserti128     m3, m3, xm5, 1
    pmaddwd         m5, m3, [r5 + 1 * mmsize]
    paddd           m1, m5
    pmaddwd         m3, [r5]
    movu            xm5, [r0 + r1]                  ; m5 = row 5
    punpckhwd       xm6, xm4, xm5
    punpcklwd       xm4, xm5
    vinserti128     m4, m4, xm6, 1
    pmaddwd         m6, m4, [r5 + 2 * mmsize]
    paddd           m0, m6
    pmaddwd         m6, m4, [r5 + 1 * mmsize]
    paddd           m2, m6
    pmaddwd         m4, [r5]
    movu            xm6, [r0 + r1 * 2]              ; m6 = row 6
    punpckhwd       xm7, xm5, xm6
    punpcklwd       xm5, xm6
    vinserti128     m5, m5, xm7, 1
    pmaddwd         m7, m5, [r5 + 2 * mmsize]
    paddd           m1, m7
    pmaddwd         m7, m5, [r5 + 1 * mmsize]
    paddd           m3, m7
    pmaddwd         m5, [r5]
    movu            xm7, [r0 + r4]                  ; m7 = row 7
    punpckhwd       xm8, xm6, xm7
    punpcklwd       xm6, xm7
    vinserti128     m6, m6, xm8, 1
    pmaddwd         m8, m6, [r5 + 3 * mmsize]
    paddd           m0, m8
    pmaddwd         m8, m6, [r5 + 2 * mmsize]
    paddd           m2, m8
    pmaddwd         m8, m6, [r5 + 1 * mmsize]
    paddd           m4, m8
    pmaddwd         m6, [r5]
    lea             r0, [r0 + r1 * 4]
    movu            xm8, [r0]                       ; m8 = row 8
    punpckhwd       xm9, xm7, xm8
    punpcklwd       xm7, xm8
    vinserti128     m7, m7, xm9, 1
    pmaddwd         m9, m7, [r5 + 3 * mmsize]
    paddd           m1, m9
    pmaddwd         m9, m7, [r5 + 2 * mmsize]
    paddd           m3, m9
    pmaddwd         m9, m7, [r5 + 1 * mmsize]
    paddd           m5, m9
    pmaddwd         m7, [r5]
    movu            xm9, [r0 + r1]                  ; m9 = row 9
    punpckhwd       xm10, xm8, xm9
    punpcklwd       xm8, xm9
    vinserti128     m8, m8, xm10, 1
    pmaddwd         m10, m8, [r5 + 3 * mmsize]
    paddd           m2, m10
    pmaddwd         m10, m8, [r5 + 2 * mmsize]
    paddd           m4, m10
    pmaddwd         m10, m8, [r5 + 1 * mmsize]
    paddd           m6, m10
    pmaddwd         m8, [r5]
    movu            xm10, [r0 + r1 * 2]             ; m10 = row 10
    punpckhwd       xm11, xm9, xm10
    punpcklwd       xm9, xm10
    vinserti128     m9, m9, xm11, 1
    pmaddwd         m11, m9, [r5 + 3 * mmsize]
    paddd           m3, m11
    pmaddwd         m11, m9, [r5 + 2 * mmsize]
    paddd           m5, m11
    pmaddwd         m11, m9, [r5 + 1 * mmsize]
    paddd           m7, m11
    pmaddwd         m9, [r5]
    movu            xm11, [r0 + r4]                 ; m11 = row 11
    punpckhwd       xm12, xm10, xm11
    punpcklwd       xm10, xm11
    vinserti128     m10, m10, xm12, 1
    pmaddwd         m12, m10, [r5 + 3 * mmsize]
    paddd           m4, m12
    pmaddwd         m12, m10, [r5 + 2 * mmsize]
    paddd           m6, m12
    pmaddwd         m12, m10, [r5 + 1 * mmsize]
    paddd           m8, m12
    pmaddwd         m10, [r5]
    lea             r0, [r0 + r1 * 4]
    movu            xm12, [r0]                      ; m12 = row 12
    punpckhwd       xm13, xm11, xm12
    punpcklwd       xm11, xm12
    vinserti128     m11, m11, xm13, 1
    pmaddwd         m13, m11, [r5 + 3 * mmsize]
    paddd           m5, m13
    pmaddwd         m13, m11, [r5 + 2 * mmsize]
    paddd           m7, m13
    pmaddwd         m13, m11, [r5 + 1 * mmsize]
    paddd           m9, m13
    pmaddwd         m11, [r5]

%ifidn %1,ss
    psrad           m0, 6
    psrad           m1, 6
    psrad           m2, 6
    psrad           m3, 6
    psrad           m4, 6
    psrad           m5, 6
%else
    paddd           m0, m14
    paddd           m1, m14
    paddd           m2, m14
    paddd           m3, m14
    paddd           m4, m14
    paddd           m5, m14
%ifidn %1,pp
    psrad           m0, INTERP_SHIFT_PP
    psrad           m1, INTERP_SHIFT_PP
    psrad           m2, INTERP_SHIFT_PP
    psrad           m3, INTERP_SHIFT_PP
    psrad           m4, INTERP_SHIFT_PP
    psrad           m5, INTERP_SHIFT_PP
%elifidn %1, sp
    psrad           m0, INTERP_SHIFT_SP
    psrad           m1, INTERP_SHIFT_SP
    psrad           m2, INTERP_SHIFT_SP
    psrad           m3, INTERP_SHIFT_SP
    psrad           m4, INTERP_SHIFT_SP
    psrad           m5, INTERP_SHIFT_SP
%else
    psrad           m0, INTERP_SHIFT_PS
    psrad           m1, INTERP_SHIFT_PS
    psrad           m2, INTERP_SHIFT_PS
    psrad           m3, INTERP_SHIFT_PS
    psrad           m4, INTERP_SHIFT_PS
    psrad           m5, INTERP_SHIFT_PS
%endif
%endif

    packssdw        m0, m1
    packssdw        m2, m3
    packssdw        m4, m5
    vpermq          m0, m0, 11011000b
    vpermq          m2, m2, 11011000b
    vpermq          m4, m4, 11011000b
    pxor            m5, m5
    mova            m3, [pw_pixel_max]
%ifidn %1,pp
    CLIPW           m0, m5, m3
    CLIPW           m2, m5, m3
    CLIPW           m4, m5, m3
%elifidn %1, sp
    CLIPW           m0, m5, m3
    CLIPW           m2, m5, m3
    CLIPW           m4, m5, m3
%endif

    vextracti128    xm1, m0, 1
    movu            [r2], xm0
    movu            [r2 + r3], xm1
    vextracti128    xm1, m2, 1
    movu            [r2 + r3 * 2], xm2
    movu            [r2 + r6], xm1
    lea             r2, [r2 + r3 * 4]
    vextracti128    xm1, m4, 1
    movu            [r2], xm4
    movu            [r2 + r3], xm1

    movu            xm13, [r0 + r1]                 ; m13 = row 13
    punpckhwd       xm0, xm12, xm13
    punpcklwd       xm12, xm13
    vinserti128     m12, m12, xm0, 1
    pmaddwd         m0, m12, [r5 + 3 * mmsize]
    paddd           m6, m0
    pmaddwd         m0, m12, [r5 + 2 * mmsize]
    paddd           m8, m0
    pmaddwd         m0, m12, [r5 + 1 * mmsize]
    paddd           m10, m0
    pmaddwd         m12, [r5]
    movu            xm0, [r0 + r1 * 2]              ; m0 = row 14
    punpckhwd       xm1, xm13, xm0
    punpcklwd       xm13, xm0
    vinserti128     m13, m13, xm1, 1
    pmaddwd         m1, m13, [r5 + 3 * mmsize]
    paddd           m7, m1
    pmaddwd         m1, m13, [r5 + 2 * mmsize]
    paddd           m9, m1
    pmaddwd         m1, m13, [r5 + 1 * mmsize]
    paddd           m11, m1
    pmaddwd         m13, [r5]

%ifidn %1,ss
    psrad           m6, 6
    psrad           m7, 6
%else
    paddd           m6, m14
    paddd           m7, m14
%ifidn %1,pp
    psrad           m6, INTERP_SHIFT_PP
    psrad           m7, INTERP_SHIFT_PP
%elifidn %1, sp
    psrad           m6, INTERP_SHIFT_SP
    psrad           m7, INTERP_SHIFT_SP
%else
    psrad           m6, INTERP_SHIFT_PS
    psrad           m7, INTERP_SHIFT_PS
%endif
%endif

    packssdw        m6, m7
    vpermq          m6, m6, 11011000b
%ifidn %1,pp
    CLIPW           m6, m5, m3
%elifidn %1, sp
    CLIPW           m6, m5, m3
%endif
    vextracti128    xm7, m6, 1
    movu            [r2 + r3 * 2], xm6
    movu            [r2 + r6], xm7

    movu            xm1, [r0 + r4]                  ; m1 = row 15
    punpckhwd       xm2, xm0, xm1
    punpcklwd       xm0, xm1
    vinserti128     m0, m0, xm2, 1
    pmaddwd         m2, m0, [r5 + 3 * mmsize]
    paddd           m8, m2
    pmaddwd         m2, m0, [r5 + 2 * mmsize]
    paddd           m10, m2
    pmaddwd         m2, m0, [r5 + 1 * mmsize]
    paddd           m12, m2
    pmaddwd         m0, [r5]
    lea             r0, [r0 + r1 * 4]
    movu            xm2, [r0]                       ; m2 = row 16
    punpckhwd       xm6, xm1, xm2
    punpcklwd       xm1, xm2
    vinserti128     m1, m1, xm6, 1
    pmaddwd         m6, m1, [r5 + 3 * mmsize]
    paddd           m9, m6
    pmaddwd         m6, m1, [r5 + 2 * mmsize]
    paddd           m11, m6
    pmaddwd         m6, m1, [r5 + 1 * mmsize]
    paddd           m13, m6
    pmaddwd         m1, [r5]
    movu            xm6, [r0 + r1]                  ; m6 = row 17
    punpckhwd       xm4, xm2, xm6
    punpcklwd       xm2, xm6
    vinserti128     m2, m2, xm4, 1
    pmaddwd         m4, m2, [r5 + 3 * mmsize]
    paddd           m10, m4
    pmaddwd         m4, m2, [r5 + 2 * mmsize]
    paddd           m12, m4
    pmaddwd         m2, [r5 + 1 * mmsize]
    paddd           m0, m2
    movu            xm4, [r0 + r1 * 2]              ; m4 = row 18
    punpckhwd       xm2, xm6, xm4
    punpcklwd       xm6, xm4
    vinserti128     m6, m6, xm2, 1
    pmaddwd         m2, m6, [r5 + 3 * mmsize]
    paddd           m11, m2
    pmaddwd         m2, m6, [r5 + 2 * mmsize]
    paddd           m13, m2
    pmaddwd         m6, [r5 + 1 * mmsize]
    paddd           m1, m6
    movu            xm2, [r0 + r4]                  ; m2 = row 19
    punpckhwd       xm6, xm4, xm2
    punpcklwd       xm4, xm2
    vinserti128     m4, m4, xm6, 1
    pmaddwd         m6, m4, [r5 + 3 * mmsize]
    paddd           m12, m6
    pmaddwd         m4, [r5 + 2 * mmsize]
    paddd           m0, m4
    lea             r0, [r0 + r1 * 4]
    movu            xm6, [r0]                       ; m6 = row 20
    punpckhwd       xm7, xm2, xm6
    punpcklwd       xm2, xm6
    vinserti128     m2, m2, xm7, 1
    pmaddwd         m7, m2, [r5 + 3 * mmsize]
    paddd           m13, m7
    pmaddwd         m2, [r5 + 2 * mmsize]
    paddd           m1, m2
    movu            xm7, [r0 + r1]                  ; m7 = row 21
    punpckhwd       xm2, xm6, xm7
    punpcklwd       xm6, xm7
    vinserti128     m6, m6, xm2, 1
    pmaddwd         m6, [r5 + 3 * mmsize]
    paddd           m0, m6
    movu            xm2, [r0 + r1 * 2]              ; m2 = row 22
    punpckhwd       xm6, xm7, xm2
    punpcklwd       xm7, xm2
    vinserti128     m7, m7, xm6, 1
    pmaddwd         m7, [r5 + 3 * mmsize]
    paddd           m1, m7

%ifidn %1,ss
    psrad           m8, 6
    psrad           m9, 6
    psrad           m10, 6
    psrad           m11, 6
    psrad           m12, 6
    psrad           m13, 6
    psrad           m0, 6
    psrad           m1, 6
%else
    paddd           m8, m14
    paddd           m9, m14
    paddd           m10, m14
    paddd           m11, m14
    paddd           m12, m14
    paddd           m13, m14
    paddd           m0, m14
    paddd           m1, m14
%ifidn %1,pp
    psrad           m8, INTERP_SHIFT_PP
    psrad           m9, INTERP_SHIFT_PP
    psrad           m10, INTERP_SHIFT_PP
    psrad           m11, INTERP_SHIFT_PP
    psrad           m12, INTERP_SHIFT_PP
    psrad           m13, INTERP_SHIFT_PP
    psrad           m0, INTERP_SHIFT_PP
    psrad           m1, INTERP_SHIFT_PP
%elifidn %1, sp
    psrad           m8, INTERP_SHIFT_SP
    psrad           m9, INTERP_SHIFT_SP
    psrad           m10, INTERP_SHIFT_SP
    psrad           m11, INTERP_SHIFT_SP
    psrad           m12, INTERP_SHIFT_SP
    psrad           m13, INTERP_SHIFT_SP
    psrad           m0, INTERP_SHIFT_SP
    psrad           m1, INTERP_SHIFT_SP
%else
    psrad           m8, INTERP_SHIFT_PS
    psrad           m9, INTERP_SHIFT_PS
    psrad           m10, INTERP_SHIFT_PS
    psrad           m11, INTERP_SHIFT_PS
    psrad           m12, INTERP_SHIFT_PS
    psrad           m13, INTERP_SHIFT_PS
    psrad           m0, INTERP_SHIFT_PS
    psrad           m1, INTERP_SHIFT_PS
%endif
%endif

    packssdw        m8, m9
    packssdw        m10, m11
    packssdw        m12, m13
    packssdw        m0, m1
    vpermq          m8, m8, 11011000b
    vpermq          m10, m10, 11011000b
    vpermq          m12, m12, 11011000b
    vpermq          m0, m0, 11011000b
%ifidn %1,pp
    CLIPW           m8, m5, m3
    CLIPW           m10, m5, m3
    CLIPW           m12, m5, m3
    CLIPW           m0, m5, m3
%elifidn %1, sp
    CLIPW           m8, m5, m3
    CLIPW           m10, m5, m3
    CLIPW           m12, m5, m3
    CLIPW           m0, m5, m3
%endif
    vextracti128    xm9, m8, 1
    vextracti128    xm11, m10, 1
    vextracti128    xm13, m12, 1
    vextracti128    xm1, m0, 1
    lea             r2, [r2 + r3 * 4]
    movu            [r2], xm8
    movu            [r2 + r3], xm9
    movu            [r2 + r3 * 2], xm10
    movu            [r2 + r6], xm11
    lea             r2, [r2 + r3 * 4]
    movu            [r2], xm12
    movu            [r2 + r3], xm13
    movu            [r2 + r3 * 2], xm0
    movu            [r2 + r6], xm1
    lea             r2, [r2 + r3 * 4]
    sub             r0, r7
    dec             r8d
    jnz             .loopH
    RET
%endif
%endmacro

FILTER_VER_LUMA_AVX2_8xN pp, 16
FILTER_VER_LUMA_AVX2_8xN pp, 32
FILTER_VER_LUMA_AVX2_8xN ps, 16
FILTER_VER_LUMA_AVX2_8xN ps, 32
FILTER_VER_LUMA_AVX2_8xN sp, 16
FILTER_VER_LUMA_AVX2_8xN sp, 32
FILTER_VER_LUMA_AVX2_8xN ss, 16
FILTER_VER_LUMA_AVX2_8xN ss, 32

%macro PROCESS_LUMA_AVX2_W8_8R 1
    movu            xm0, [r0]                       ; m0 = row 0
    movu            xm1, [r0 + r1]                  ; m1 = row 1
    punpckhwd       xm2, xm0, xm1
    punpcklwd       xm0, xm1
    vinserti128     m0, m0, xm2, 1
    pmaddwd         m0, [r5]
    movu            xm2, [r0 + r1 * 2]              ; m2 = row 2
    punpckhwd       xm3, xm1, xm2
    punpcklwd       xm1, xm2
    vinserti128     m1, m1, xm3, 1
    pmaddwd         m1, [r5]
    movu            xm3, [r0 + r4]                  ; m3 = row 3
    punpckhwd       xm4, xm2, xm3
    punpcklwd       xm2, xm3
    vinserti128     m2, m2, xm4, 1
    pmaddwd         m4, m2, [r5 + 1 * mmsize]
    paddd           m0, m4
    pmaddwd         m2, [r5]
    lea             r7, [r0 + r1 * 4]
    movu            xm4, [r7]                       ; m4 = row 4
    punpckhwd       xm5, xm3, xm4
    punpcklwd       xm3, xm4
    vinserti128     m3, m3, xm5, 1
    pmaddwd         m5, m3, [r5 + 1 * mmsize]
    paddd           m1, m5
    pmaddwd         m3, [r5]
    movu            xm5, [r7 + r1]                  ; m5 = row 5
    punpckhwd       xm6, xm4, xm5
    punpcklwd       xm4, xm5
    vinserti128     m4, m4, xm6, 1
    pmaddwd         m6, m4, [r5 + 2 * mmsize]
    paddd           m0, m6
    pmaddwd         m6, m4, [r5 + 1 * mmsize]
    paddd           m2, m6
    pmaddwd         m4, [r5]
    movu            xm6, [r7 + r1 * 2]              ; m6 = row 6
    punpckhwd       xm7, xm5, xm6
    punpcklwd       xm5, xm6
    vinserti128     m5, m5, xm7, 1
    pmaddwd         m7, m5, [r5 + 2 * mmsize]
    paddd           m1, m7
    pmaddwd         m7, m5, [r5 + 1 * mmsize]
    paddd           m3, m7
    pmaddwd         m5, [r5]
    movu            xm7, [r7 + r4]                  ; m7 = row 7
    punpckhwd       xm8, xm6, xm7
    punpcklwd       xm6, xm7
    vinserti128     m6, m6, xm8, 1
    pmaddwd         m8, m6, [r5 + 3 * mmsize]
    paddd           m0, m8
    pmaddwd         m8, m6, [r5 + 2 * mmsize]
    paddd           m2, m8
    pmaddwd         m8, m6, [r5 + 1 * mmsize]
    paddd           m4, m8
    pmaddwd         m6, [r5]
    lea             r7, [r7 + r1 * 4]
    movu            xm8, [r7]                       ; m8 = row 8
    punpckhwd       xm9, xm7, xm8
    punpcklwd       xm7, xm8
    vinserti128     m7, m7, xm9, 1
    pmaddwd         m9, m7, [r5 + 3 * mmsize]
    paddd           m1, m9
    pmaddwd         m9, m7, [r5 + 2 * mmsize]
    paddd           m3, m9
    pmaddwd         m9, m7, [r5 + 1 * mmsize]
    paddd           m5, m9
    pmaddwd         m7, [r5]
    movu            xm9, [r7 + r1]                  ; m9 = row 9
    punpckhwd       xm10, xm8, xm9
    punpcklwd       xm8, xm9
    vinserti128     m8, m8, xm10, 1
    pmaddwd         m10, m8, [r5 + 3 * mmsize]
    paddd           m2, m10
    pmaddwd         m10, m8, [r5 + 2 * mmsize]
    paddd           m4, m10
    pmaddwd         m8, [r5 + 1 * mmsize]
    paddd           m6, m8
    movu            xm10, [r7 + r1 * 2]             ; m10 = row 10
    punpckhwd       xm8, xm9, xm10
    punpcklwd       xm9, xm10
    vinserti128     m9, m9, xm8, 1
    pmaddwd         m8, m9, [r5 + 3 * mmsize]
    paddd           m3, m8
    pmaddwd         m8, m9, [r5 + 2 * mmsize]
    paddd           m5, m8
    pmaddwd         m9, [r5 + 1 * mmsize]
    paddd           m7, m9
    movu            xm8, [r7 + r4]                  ; m8 = row 11
    punpckhwd       xm9, xm10, xm8
    punpcklwd       xm10, xm8
    vinserti128     m10, m10, xm9, 1
    pmaddwd         m9, m10, [r5 + 3 * mmsize]
    paddd           m4, m9
    pmaddwd         m10, [r5 + 2 * mmsize]
    paddd           m6, m10
    lea             r7, [r7 + r1 * 4]
    movu            xm9, [r7]                       ; m9 = row 12
    punpckhwd       xm10, xm8, xm9
    punpcklwd       xm8, xm9
    vinserti128     m8, m8, xm10, 1
    pmaddwd         m10, m8, [r5 + 3 * mmsize]
    paddd           m5, m10
    pmaddwd         m8, [r5 + 2 * mmsize]
    paddd           m7, m8

%ifidn %1,ss
    psrad           m0, 6
    psrad           m1, 6
    psrad           m2, 6
    psrad           m3, 6
    psrad           m4, 6
    psrad           m5, 6
%else
    paddd           m0, m11
    paddd           m1, m11
    paddd           m2, m11
    paddd           m3, m11
    paddd           m4, m11
    paddd           m5, m11
%ifidn %1,pp
    psrad           m0, INTERP_SHIFT_PP
    psrad           m1, INTERP_SHIFT_PP
    psrad           m2, INTERP_SHIFT_PP
    psrad           m3, INTERP_SHIFT_PP
    psrad           m4, INTERP_SHIFT_PP
    psrad           m5, INTERP_SHIFT_PP
%elifidn %1, sp
    psrad           m0, INTERP_SHIFT_SP
    psrad           m1, INTERP_SHIFT_SP
    psrad           m2, INTERP_SHIFT_SP
    psrad           m3, INTERP_SHIFT_SP
    psrad           m4, INTERP_SHIFT_SP
    psrad           m5, INTERP_SHIFT_SP
%else
    psrad           m0, INTERP_SHIFT_PS
    psrad           m1, INTERP_SHIFT_PS
    psrad           m2, INTERP_SHIFT_PS
    psrad           m3, INTERP_SHIFT_PS
    psrad           m4, INTERP_SHIFT_PS
    psrad           m5, INTERP_SHIFT_PS
%endif
%endif

    packssdw        m0, m1
    packssdw        m2, m3
    packssdw        m4, m5
    vpermq          m0, m0, 11011000b
    vpermq          m2, m2, 11011000b
    vpermq          m4, m4, 11011000b
    pxor            m8, m8
%ifidn %1,pp
    CLIPW           m0, m8, m12
    CLIPW           m2, m8, m12
    CLIPW           m4, m8, m12
%elifidn %1, sp
    CLIPW           m0, m8, m12
    CLIPW           m2, m8, m12
    CLIPW           m4, m8, m12
%endif

    vextracti128    xm1, m0, 1
    vextracti128    xm3, m2, 1
    vextracti128    xm5, m4, 1
    movu            [r2], xm0
    movu            [r2 + r3], xm1
    movu            [r2 + r3 * 2], xm2
    movu            [r2 + r6], xm3
    lea             r8, [r2 + r3 * 4]
    movu            [r8], xm4
    movu            [r8 + r3], xm5

    movu            xm10, [r7 + r1]                 ; m10 = row 13
    punpckhwd       xm0, xm9, xm10
    punpcklwd       xm9, xm10
    vinserti128     m9, m9, xm0, 1
    pmaddwd         m9, [r5 + 3 * mmsize]
    paddd           m6, m9
    movu            xm0, [r7 + r1 * 2]              ; m0 = row 14
    punpckhwd       xm1, xm10, xm0
    punpcklwd       xm10, xm0
    vinserti128     m10, m10, xm1, 1
    pmaddwd         m10, [r5 + 3 * mmsize]
    paddd           m7, m10

%ifidn %1,ss
    psrad           m6, 6
    psrad           m7, 6
%else
    paddd           m6, m11
    paddd           m7, m11
%ifidn %1,pp
    psrad           m6, INTERP_SHIFT_PP
    psrad           m7, INTERP_SHIFT_PP
%elifidn %1, sp
    psrad           m6, INTERP_SHIFT_SP
    psrad           m7, INTERP_SHIFT_SP
%else
    psrad           m6, INTERP_SHIFT_PS
    psrad           m7, INTERP_SHIFT_PS
%endif
%endif

    packssdw        m6, m7
    vpermq          m6, m6, 11011000b
%ifidn %1,pp
    CLIPW           m6, m8, m12
%elifidn %1, sp
    CLIPW           m6, m8, m12
%endif
    vextracti128    xm7, m6, 1
    movu            [r8 + r3 * 2], xm6
    movu            [r8 + r6], xm7
%endmacro

%macro FILTER_VER_LUMA_AVX2_Nx8 2
INIT_YMM avx2
%if ARCH_X86_64 == 1
cglobal interp_8tap_vert_%1_%2x8, 4, 10, 13
    mov             r4d, r4m
    shl             r4d, 7
    add             r1d, r1d
    add             r3d, r3d

%ifdef PIC
    lea             r5, [tab_LumaCoeffVer]
    add             r5, r4
%else
    lea             r5, [tab_LumaCoeffVer + r4]
%endif

    lea             r4, [r1 * 3]
    sub             r0, r4
%ifidn %1,pp
    vbroadcasti128  m11, [pd_32]
%elifidn %1, sp
    vbroadcasti128  m11, [INTERP_OFFSET_SP]
%else
    vbroadcasti128  m11, [INTERP_OFFSET_PS]
%endif
    mova            m12, [pw_pixel_max]
    lea             r6, [r3 * 3]
    mov             r9d, %2 / 8
.loopW:
    PROCESS_LUMA_AVX2_W8_8R %1
    add             r2, 16
    add             r0, 16
    dec             r9d
    jnz             .loopW
    RET
%endif
%endmacro

FILTER_VER_LUMA_AVX2_Nx8 pp, 32
FILTER_VER_LUMA_AVX2_Nx8 pp, 16
FILTER_VER_LUMA_AVX2_Nx8 ps, 32
FILTER_VER_LUMA_AVX2_Nx8 ps, 16
FILTER_VER_LUMA_AVX2_Nx8 sp, 32
FILTER_VER_LUMA_AVX2_Nx8 sp, 16
FILTER_VER_LUMA_AVX2_Nx8 ss, 32
FILTER_VER_LUMA_AVX2_Nx8 ss, 16

%macro FILTER_VER_LUMA_AVX2_32x24 1
INIT_YMM avx2
%if ARCH_X86_64 == 1
cglobal interp_8tap_vert_%1_32x24, 4, 10, 15
    mov             r4d, r4m
    shl             r4d, 7
    add             r1d, r1d
    add             r3d, r3d

%ifdef PIC
    lea             r5, [tab_LumaCoeffVer]
    add             r5, r4
%else
    lea             r5, [tab_LumaCoeffVer + r4]
%endif

    lea             r4, [r1 * 3]
    sub             r0, r4
%ifidn %1,pp
    vbroadcasti128  m14, [pd_32]
%elifidn %1, sp
    vbroadcasti128  m14, [INTERP_OFFSET_SP]
%else
    vbroadcasti128  m14, [INTERP_OFFSET_PS]
%endif
    lea             r6, [r3 * 3]
    mov             r9d, 4
.loopW:
    PROCESS_LUMA_AVX2_W8_16R %1
    add             r2, 16
    add             r0, 16
    dec             r9d
    jnz             .loopW
    lea             r9, [r1 * 4]
    sub             r7, r9
    lea             r0, [r7 - 48]
    lea             r2, [r8 + r3 * 4 - 48]
    mova            m11, m14
    mova            m12, m3
    mov             r9d, 4
.loop:
    PROCESS_LUMA_AVX2_W8_8R %1
    add             r2, 16
    add             r0, 16
    dec             r9d
    jnz             .loop
    RET
%endif
%endmacro

FILTER_VER_LUMA_AVX2_32x24 pp
FILTER_VER_LUMA_AVX2_32x24 ps
FILTER_VER_LUMA_AVX2_32x24 sp
FILTER_VER_LUMA_AVX2_32x24 ss

%macro PROCESS_LUMA_AVX2_W8_4R 1
    movu            xm0, [r0]                       ; m0 = row 0
    movu            xm1, [r0 + r1]                  ; m1 = row 1
    punpckhwd       xm2, xm0, xm1
    punpcklwd       xm0, xm1
    vinserti128     m0, m0, xm2, 1
    pmaddwd         m0, [r5]
    movu            xm2, [r0 + r1 * 2]              ; m2 = row 2
    punpckhwd       xm3, xm1, xm2
    punpcklwd       xm1, xm2
    vinserti128     m1, m1, xm3, 1
    pmaddwd         m1, [r5]
    movu            xm3, [r0 + r4]                  ; m3 = row 3
    punpckhwd       xm4, xm2, xm3
    punpcklwd       xm2, xm3
    vinserti128     m2, m2, xm4, 1
    pmaddwd         m4, m2, [r5 + 1 * mmsize]
    paddd           m0, m4
    pmaddwd         m2, [r5]
    lea             r0, [r0 + r1 * 4]
    movu            xm4, [r0]                       ; m4 = row 4
    punpckhwd       xm5, xm3, xm4
    punpcklwd       xm3, xm4
    vinserti128     m3, m3, xm5, 1
    pmaddwd         m5, m3, [r5 + 1 * mmsize]
    paddd           m1, m5
    pmaddwd         m3, [r5]
    movu            xm5, [r0 + r1]                  ; m5 = row 5
    punpckhwd       xm6, xm4, xm5
    punpcklwd       xm4, xm5
    vinserti128     m4, m4, xm6, 1
    pmaddwd         m6, m4, [r5 + 2 * mmsize]
    paddd           m0, m6
    pmaddwd         m4, [r5 + 1 * mmsize]
    paddd           m2, m4
    movu            xm6, [r0 + r1 * 2]              ; m6 = row 6
    punpckhwd       xm4, xm5, xm6
    punpcklwd       xm5, xm6
    vinserti128     m5, m5, xm4, 1
    pmaddwd         m4, m5, [r5 + 2 * mmsize]
    paddd           m1, m4
    pmaddwd         m5, [r5 + 1 * mmsize]
    paddd           m3, m5
    movu            xm4, [r0 + r4]                  ; m4 = row 7
    punpckhwd       xm5, xm6, xm4
    punpcklwd       xm6, xm4
    vinserti128     m6, m6, xm5, 1
    pmaddwd         m5, m6, [r5 + 3 * mmsize]
    paddd           m0, m5
    pmaddwd         m6, [r5 + 2 * mmsize]
    paddd           m2, m6
    lea             r0, [r0 + r1 * 4]
    movu            xm5, [r0]                       ; m5 = row 8
    punpckhwd       xm6, xm4, xm5
    punpcklwd       xm4, xm5
    vinserti128     m4, m4, xm6, 1
    pmaddwd         m6, m4, [r5 + 3 * mmsize]
    paddd           m1, m6
    pmaddwd         m4, [r5 + 2 * mmsize]
    paddd           m3, m4
    movu            xm6, [r0 + r1]                  ; m6 = row 9
    punpckhwd       xm4, xm5, xm6
    punpcklwd       xm5, xm6
    vinserti128     m5, m5, xm4, 1
    pmaddwd         m5, [r5 + 3 * mmsize]
    paddd           m2, m5
    movu            xm4, [r0 + r1 * 2]              ; m4 = row 10
    punpckhwd       xm5, xm6, xm4
    punpcklwd       xm6, xm4
    vinserti128     m6, m6, xm5, 1
    pmaddwd         m6, [r5 + 3 * mmsize]
    paddd           m3, m6

%ifidn %1,ss
    psrad           m0, 6
    psrad           m1, 6
    psrad           m2, 6
    psrad           m3, 6
%else
    paddd           m0, m7
    paddd           m1, m7
    paddd           m2, m7
    paddd           m3, m7
%ifidn %1,pp
    psrad           m0, INTERP_SHIFT_PP
    psrad           m1, INTERP_SHIFT_PP
    psrad           m2, INTERP_SHIFT_PP
    psrad           m3, INTERP_SHIFT_PP
%elifidn %1, sp
    psrad           m0, INTERP_SHIFT_SP
    psrad           m1, INTERP_SHIFT_SP
    psrad           m2, INTERP_SHIFT_SP
    psrad           m3, INTERP_SHIFT_SP
%else
    psrad           m0, INTERP_SHIFT_PS
    psrad           m1, INTERP_SHIFT_PS
    psrad           m2, INTERP_SHIFT_PS
    psrad           m3, INTERP_SHIFT_PS
%endif
%endif

    packssdw        m0, m1
    packssdw        m2, m3
    vpermq          m0, m0, 11011000b
    vpermq          m2, m2, 11011000b
    pxor            m4, m4
%ifidn %1,pp
    CLIPW           m0, m4, [pw_pixel_max]
    CLIPW           m2, m4, [pw_pixel_max]
%elifidn %1, sp
    CLIPW           m0, m4, [pw_pixel_max]
    CLIPW           m2, m4, [pw_pixel_max]
%endif

    vextracti128    xm1, m0, 1
    vextracti128    xm3, m2, 1
%endmacro

%macro FILTER_VER_LUMA_AVX2_16x4 1
INIT_YMM avx2
cglobal interp_8tap_vert_%1_16x4, 4, 7, 8, 0-gprsize
    mov             r4d, r4m
    shl             r4d, 7
    add             r1d, r1d
    add             r3d, r3d

%ifdef PIC
    lea             r5, [tab_LumaCoeffVer]
    add             r5, r4
%else
    lea             r5, [tab_LumaCoeffVer + r4]
%endif

    lea             r4, [r1 * 3]
    sub             r0, r4
%ifidn %1,pp
    vbroadcasti128  m7, [pd_32]
%elifidn %1, sp
    vbroadcasti128  m7, [INTERP_OFFSET_SP]
%else
    vbroadcasti128  m7, [INTERP_OFFSET_PS]
%endif
    mov             dword [rsp], 2
.loopW:
    PROCESS_LUMA_AVX2_W8_4R %1
    movu            [r2], xm0
    movu            [r2 + r3], xm1
    movu            [r2 + r3 * 2], xm2
    lea             r6, [r3 * 3]
    movu            [r2 + r6], xm3
    add             r2, 16
    lea             r6, [8 * r1 - 16]
    sub             r0, r6
    dec             dword [rsp]
    jnz             .loopW
    RET
%endmacro

FILTER_VER_LUMA_AVX2_16x4 pp
FILTER_VER_LUMA_AVX2_16x4 ps
FILTER_VER_LUMA_AVX2_16x4 sp
FILTER_VER_LUMA_AVX2_16x4 ss

%macro FILTER_VER_LUMA_AVX2_8x4 1
INIT_YMM avx2
cglobal interp_8tap_vert_%1_8x4, 4, 6, 8
    mov             r4d, r4m
    shl             r4d, 7
    add             r1d, r1d
    add             r3d, r3d

%ifdef PIC
    lea             r5, [tab_LumaCoeffVer]
    add             r5, r4
%else
    lea             r5, [tab_LumaCoeffVer + r4]
%endif

    lea             r4, [r1 * 3]
    sub             r0, r4
%ifidn %1,pp
    vbroadcasti128  m7, [pd_32]
%elifidn %1, sp
    vbroadcasti128  m7, [INTERP_OFFSET_SP]
%else
    vbroadcasti128  m7, [INTERP_OFFSET_PS]
%endif

    PROCESS_LUMA_AVX2_W8_4R %1
    movu            [r2], xm0
    movu            [r2 + r3], xm1
    movu            [r2 + r3 * 2], xm2
    lea             r4, [r3 * 3]
    movu            [r2 + r4], xm3
    RET
%endmacro

FILTER_VER_LUMA_AVX2_8x4 pp
FILTER_VER_LUMA_AVX2_8x4 ps
FILTER_VER_LUMA_AVX2_8x4 sp
FILTER_VER_LUMA_AVX2_8x4 ss

%macro FILTER_VER_LUMA_AVX2_16x12 1
INIT_YMM avx2
%if ARCH_X86_64 == 1
cglobal interp_8tap_vert_%1_16x12, 4, 10, 15
    mov             r4d, r4m
    shl             r4d, 7
    add             r1d, r1d
    add             r3d, r3d

%ifdef PIC
    lea             r5, [tab_LumaCoeffVer]
    add             r5, r4
%else
    lea             r5, [tab_LumaCoeffVer + r4]
%endif

    lea             r4, [r1 * 3]
    sub             r0, r4
%ifidn %1,pp
    vbroadcasti128  m14, [pd_32]
%elifidn %1, sp
    vbroadcasti128  m14, [INTERP_OFFSET_SP]
%else
    vbroadcasti128  m14, [INTERP_OFFSET_PS]
%endif
    mova            m13, [pw_pixel_max]
    pxor            m12, m12
    lea             r6, [r3 * 3]
    mov             r9d, 2
.loopW:
    movu            xm0, [r0]                       ; m0 = row 0
    movu            xm1, [r0 + r1]                  ; m1 = row 1
    punpckhwd       xm2, xm0, xm1
    punpcklwd       xm0, xm1
    vinserti128     m0, m0, xm2, 1
    pmaddwd         m0, [r5]
    movu            xm2, [r0 + r1 * 2]              ; m2 = row 2
    punpckhwd       xm3, xm1, xm2
    punpcklwd       xm1, xm2
    vinserti128     m1, m1, xm3, 1
    pmaddwd         m1, [r5]
    movu            xm3, [r0 + r4]                  ; m3 = row 3
    punpckhwd       xm4, xm2, xm3
    punpcklwd       xm2, xm3
    vinserti128     m2, m2, xm4, 1
    pmaddwd         m4, m2, [r5 + 1 * mmsize]
    paddd           m0, m4
    pmaddwd         m2, [r5]
    lea             r7, [r0 + r1 * 4]
    movu            xm4, [r7]                       ; m4 = row 4
    punpckhwd       xm5, xm3, xm4
    punpcklwd       xm3, xm4
    vinserti128     m3, m3, xm5, 1
    pmaddwd         m5, m3, [r5 + 1 * mmsize]
    paddd           m1, m5
    pmaddwd         m3, [r5]
    movu            xm5, [r7 + r1]                  ; m5 = row 5
    punpckhwd       xm6, xm4, xm5
    punpcklwd       xm4, xm5
    vinserti128     m4, m4, xm6, 1
    pmaddwd         m6, m4, [r5 + 2 * mmsize]
    paddd           m0, m6
    pmaddwd         m6, m4, [r5 + 1 * mmsize]
    paddd           m2, m6
    pmaddwd         m4, [r5]
    movu            xm6, [r7 + r1 * 2]              ; m6 = row 6
    punpckhwd       xm7, xm5, xm6
    punpcklwd       xm5, xm6
    vinserti128     m5, m5, xm7, 1
    pmaddwd         m7, m5, [r5 + 2 * mmsize]
    paddd           m1, m7
    pmaddwd         m7, m5, [r5 + 1 * mmsize]
    paddd           m3, m7
    pmaddwd         m5, [r5]
    movu            xm7, [r7 + r4]                  ; m7 = row 7
    punpckhwd       xm8, xm6, xm7
    punpcklwd       xm6, xm7
    vinserti128     m6, m6, xm8, 1
    pmaddwd         m8, m6, [r5 + 3 * mmsize]
    paddd           m0, m8
    pmaddwd         m8, m6, [r5 + 2 * mmsize]
    paddd           m2, m8
    pmaddwd         m8, m6, [r5 + 1 * mmsize]
    paddd           m4, m8
    pmaddwd         m6, [r5]
    lea             r7, [r7 + r1 * 4]
    movu            xm8, [r7]                       ; m8 = row 8
    punpckhwd       xm9, xm7, xm8
    punpcklwd       xm7, xm8
    vinserti128     m7, m7, xm9, 1
    pmaddwd         m9, m7, [r5 + 3 * mmsize]
    paddd           m1, m9
    pmaddwd         m9, m7, [r5 + 2 * mmsize]
    paddd           m3, m9
    pmaddwd         m9, m7, [r5 + 1 * mmsize]
    paddd           m5, m9
    pmaddwd         m7, [r5]
    movu            xm9, [r7 + r1]                  ; m9 = row 9
    punpckhwd       xm10, xm8, xm9
    punpcklwd       xm8, xm9
    vinserti128     m8, m8, xm10, 1
    pmaddwd         m10, m8, [r5 + 3 * mmsize]
    paddd           m2, m10
    pmaddwd         m10, m8, [r5 + 2 * mmsize]
    paddd           m4, m10
    pmaddwd         m10, m8, [r5 + 1 * mmsize]
    paddd           m6, m10
    pmaddwd         m8, [r5]
    movu            xm10, [r7 + r1 * 2]             ; m10 = row 10
    punpckhwd       xm11, xm9, xm10
    punpcklwd       xm9, xm10
    vinserti128     m9, m9, xm11, 1
    pmaddwd         m11, m9, [r5 + 3 * mmsize]
    paddd           m3, m11
    pmaddwd         m11, m9, [r5 + 2 * mmsize]
    paddd           m5, m11
    pmaddwd         m11, m9, [r5 + 1 * mmsize]
    paddd           m7, m11
    pmaddwd         m9, [r5]

%ifidn %1,ss
    psrad           m0, 6
    psrad           m1, 6
    psrad           m2, 6
    psrad           m3, 6
%else
    paddd           m0, m14
    paddd           m1, m14
    paddd           m2, m14
    paddd           m3, m14
%ifidn %1,pp
    psrad           m0, INTERP_SHIFT_PP
    psrad           m1, INTERP_SHIFT_PP
    psrad           m2, INTERP_SHIFT_PP
    psrad           m3, INTERP_SHIFT_PP
%elifidn %1, sp
    psrad           m0, INTERP_SHIFT_SP
    psrad           m1, INTERP_SHIFT_SP
    psrad           m2, INTERP_SHIFT_SP
    psrad           m3, INTERP_SHIFT_SP
%else
    psrad           m0, INTERP_SHIFT_PS
    psrad           m1, INTERP_SHIFT_PS
    psrad           m2, INTERP_SHIFT_PS
    psrad           m3, INTERP_SHIFT_PS
%endif
%endif

    packssdw        m0, m1
    packssdw        m2, m3
    vpermq          m0, m0, 11011000b
    vpermq          m2, m2, 11011000b
%ifidn %1,pp
    CLIPW           m0, m12, m13
    CLIPW           m2, m12, m13
%elifidn %1, sp
    CLIPW           m0, m12, m13
    CLIPW           m2, m12, m13
%endif

    vextracti128    xm1, m0, 1
    vextracti128    xm3, m2, 1
    movu            [r2], xm0
    movu            [r2 + r3], xm1
    movu            [r2 + r3 * 2], xm2
    movu            [r2 + r6], xm3

    movu            xm11, [r7 + r4]                 ; m11 = row 11
    punpckhwd       xm0, xm10, xm11
    punpcklwd       xm10, xm11
    vinserti128     m10, m10, xm0, 1
    pmaddwd         m0, m10, [r5 + 3 * mmsize]
    paddd           m4, m0
    pmaddwd         m0, m10, [r5 + 2 * mmsize]
    paddd           m6, m0
    pmaddwd         m0, m10, [r5 + 1 * mmsize]
    paddd           m8, m0
    pmaddwd         m10, [r5]
    lea             r7, [r7 + r1 * 4]
    movu            xm0, [r7]                      ; m0 = row 12
    punpckhwd       xm1, xm11, xm0
    punpcklwd       xm11, xm0
    vinserti128     m11, m11, xm1, 1
    pmaddwd         m1, m11, [r5 + 3 * mmsize]
    paddd           m5, m1
    pmaddwd         m1, m11, [r5 + 2 * mmsize]
    paddd           m7, m1
    pmaddwd         m1, m11, [r5 + 1 * mmsize]
    paddd           m9, m1
    pmaddwd         m11, [r5]
    movu            xm2, [r7 + r1]                 ; m2 = row 13
    punpckhwd       xm1, xm0, xm2
    punpcklwd       xm0, xm2
    vinserti128     m0, m0, xm1, 1
    pmaddwd         m1, m0, [r5 + 3 * mmsize]
    paddd           m6, m1
    pmaddwd         m1, m0, [r5 + 2 * mmsize]
    paddd           m8, m1
    pmaddwd         m0, [r5 + 1 * mmsize]
    paddd           m10, m0
    movu            xm0, [r7 + r1 * 2]              ; m0 = row 14
    punpckhwd       xm1, xm2, xm0
    punpcklwd       xm2, xm0
    vinserti128     m2, m2, xm1, 1
    pmaddwd         m1, m2, [r5 + 3 * mmsize]
    paddd           m7, m1
    pmaddwd         m1, m2, [r5 + 2 * mmsize]
    paddd           m9, m1
    pmaddwd         m2, [r5 + 1 * mmsize]
    paddd           m11, m2

%ifidn %1,ss
    psrad           m4, 6
    psrad           m5, 6
    psrad           m6, 6
    psrad           m7, 6
%else
    paddd           m4, m14
    paddd           m5, m14
    paddd           m6, m14
    paddd           m7, m14
%ifidn %1,pp
    psrad           m4, INTERP_SHIFT_PP
    psrad           m5, INTERP_SHIFT_PP
    psrad           m6, INTERP_SHIFT_PP
    psrad           m7, INTERP_SHIFT_PP
%elifidn %1, sp
    psrad           m4, INTERP_SHIFT_SP
    psrad           m5, INTERP_SHIFT_SP
    psrad           m6, INTERP_SHIFT_SP
    psrad           m7, INTERP_SHIFT_SP
%else
    psrad           m4, INTERP_SHIFT_PS
    psrad           m5, INTERP_SHIFT_PS
    psrad           m6, INTERP_SHIFT_PS
    psrad           m7, INTERP_SHIFT_PS
%endif
%endif

    packssdw        m4, m5
    packssdw        m6, m7
    vpermq          m4, m4, 11011000b
    vpermq          m6, m6, 11011000b
%ifidn %1,pp
    CLIPW           m4, m12, m13
    CLIPW           m6, m12, m13
%elifidn %1, sp
    CLIPW           m4, m12, m13
    CLIPW           m6, m12, m13
%endif
    lea             r8, [r2 + r3 * 4]
    vextracti128    xm1, m4, 1
    vextracti128    xm7, m6, 1
    movu            [r8], xm4
    movu            [r8 + r3], xm1
    movu            [r8 + r3 * 2], xm6
    movu            [r8 + r6], xm7

    movu            xm1, [r7 + r4]                  ; m1 = row 15
    punpckhwd       xm2, xm0, xm1
    punpcklwd       xm0, xm1
    vinserti128     m0, m0, xm2, 1
    pmaddwd         m2, m0, [r5 + 3 * mmsize]
    paddd           m8, m2
    pmaddwd         m0, [r5 + 2 * mmsize]
    paddd           m10, m0
    lea             r7, [r7 + r1 * 4]
    movu            xm2, [r7]                       ; m2 = row 16
    punpckhwd       xm3, xm1, xm2
    punpcklwd       xm1, xm2
    vinserti128     m1, m1, xm3, 1
    pmaddwd         m3, m1, [r5 + 3 * mmsize]
    paddd           m9, m3
    pmaddwd         m1, [r5 + 2 * mmsize]
    paddd           m11, m1
    movu            xm3, [r7 + r1]                  ; m3 = row 17
    punpckhwd       xm4, xm2, xm3
    punpcklwd       xm2, xm3
    vinserti128     m2, m2, xm4, 1
    pmaddwd         m2, [r5 + 3 * mmsize]
    paddd           m10, m2
    movu            xm4, [r7 + r1 * 2]              ; m4 = row 18
    punpckhwd       xm2, xm3, xm4
    punpcklwd       xm3, xm4
    vinserti128     m3, m3, xm2, 1
    pmaddwd         m3, [r5 + 3 * mmsize]
    paddd           m11, m3

%ifidn %1,ss
    psrad           m8, 6
    psrad           m9, 6
    psrad           m10, 6
    psrad           m11, 6
%else
    paddd           m8, m14
    paddd           m9, m14
    paddd           m10, m14
    paddd           m11, m14
%ifidn %1,pp
    psrad           m8, INTERP_SHIFT_PP
    psrad           m9, INTERP_SHIFT_PP
    psrad           m10, INTERP_SHIFT_PP
    psrad           m11, INTERP_SHIFT_PP
%elifidn %1, sp
    psrad           m8, INTERP_SHIFT_SP
    psrad           m9, INTERP_SHIFT_SP
    psrad           m10, INTERP_SHIFT_SP
    psrad           m11, INTERP_SHIFT_SP
%else
    psrad           m8, INTERP_SHIFT_PS
    psrad           m9, INTERP_SHIFT_PS
    psrad           m10, INTERP_SHIFT_PS
    psrad           m11, INTERP_SHIFT_PS
%endif
%endif

    packssdw        m8, m9
    packssdw        m10, m11
    vpermq          m8, m8, 11011000b
    vpermq          m10, m10, 11011000b
%ifidn %1,pp
    CLIPW           m8, m12, m13
    CLIPW           m10, m12, m13
%elifidn %1, sp
    CLIPW           m8, m12, m13
    CLIPW           m10, m12, m13
%endif
    vextracti128    xm9, m8, 1
    vextracti128    xm11, m10, 1
    lea             r8, [r8 + r3 * 4]
    movu            [r8], xm8
    movu            [r8 + r3], xm9
    movu            [r8 + r3 * 2], xm10
    movu            [r8 + r6], xm11
    add             r2, 16
    add             r0, 16
    dec             r9d
    jnz             .loopW
    RET
%endif
%endmacro

FILTER_VER_LUMA_AVX2_16x12 pp
FILTER_VER_LUMA_AVX2_16x12 ps
FILTER_VER_LUMA_AVX2_16x12 sp
FILTER_VER_LUMA_AVX2_16x12 ss

%macro FILTER_VER_LUMA_AVX2_4x8 1
INIT_YMM avx2
cglobal interp_8tap_vert_%1_4x8, 4, 7, 8
    mov             r4d, r4m
    shl             r4d, 7
    add             r1d, r1d
    add             r3d, r3d

%ifdef PIC
    lea             r5, [tab_LumaCoeffVer]
    add             r5, r4
%else
    lea             r5, [tab_LumaCoeffVer + r4]
%endif

    lea             r4, [r1 * 3]
    sub             r0, r4

%ifidn %1,pp
    vbroadcasti128  m7, [pd_32]
%elifidn %1, sp
    vbroadcasti128  m7, [INTERP_OFFSET_SP]
%else
    vbroadcasti128  m7, [INTERP_OFFSET_PS]
%endif
    lea             r6, [r3 * 3]

    movq            xm0, [r0]
    movq            xm1, [r0 + r1]
    punpcklwd       xm0, xm1
    movq            xm2, [r0 + r1 * 2]
    punpcklwd       xm1, xm2
    vinserti128     m0, m0, xm1, 1                  ; m0 = [2 1 1 0]
    pmaddwd         m0, [r5]
    movq            xm3, [r0 + r4]
    punpcklwd       xm2, xm3
    lea             r0, [r0 + 4 * r1]
    movq            xm4, [r0]
    punpcklwd       xm3, xm4
    vinserti128     m2, m2, xm3, 1                  ; m2 = [4 3 3 2]
    pmaddwd         m5, m2, [r5 + 1 * mmsize]
    pmaddwd         m2, [r5]
    paddd           m0, m5
    movq            xm3, [r0 + r1]
    punpcklwd       xm4, xm3
    movq            xm1, [r0 + r1 * 2]
    punpcklwd       xm3, xm1
    vinserti128     m4, m4, xm3, 1                  ; m4 = [6 5 5 4]
    pmaddwd         m5, m4, [r5 + 2 * mmsize]
    paddd           m0, m5
    pmaddwd         m5, m4, [r5 + 1 * mmsize]
    paddd           m2, m5
    pmaddwd         m4, [r5]
    movq            xm3, [r0 + r4]
    punpcklwd       xm1, xm3
    lea             r0, [r0 + 4 * r1]
    movq            xm6, [r0]
    punpcklwd       xm3, xm6
    vinserti128     m1, m1, xm3, 1                  ; m1 = [8 7 7 6]
    pmaddwd         m5, m1, [r5 + 3 * mmsize]
    paddd           m0, m5
    pmaddwd         m5, m1, [r5 + 2 * mmsize]
    paddd           m2, m5
    pmaddwd         m5, m1, [r5 + 1 * mmsize]
    paddd           m4, m5
    pmaddwd         m1, [r5]
    movq            xm3, [r0 + r1]
    punpcklwd       xm6, xm3
    movq            xm5, [r0 + 2 * r1]
    punpcklwd       xm3, xm5
    vinserti128     m6, m6, xm3, 1                  ; m6 = [A 9 9 8]
    pmaddwd         m3, m6, [r5 + 3 * mmsize]
    paddd           m2, m3
    pmaddwd         m3, m6, [r5 + 2 * mmsize]
    paddd           m4, m3
    pmaddwd         m6, [r5 + 1 * mmsize]
    paddd           m1, m6

%ifidn %1,ss
    psrad           m0, 6
    psrad           m2, 6
%else
    paddd           m0, m7
    paddd           m2, m7
%ifidn %1,pp
    psrad           m0, INTERP_SHIFT_PP
    psrad           m2, INTERP_SHIFT_PP
%elifidn %1, sp
    psrad           m0, INTERP_SHIFT_SP
    psrad           m2, INTERP_SHIFT_SP
%else
    psrad           m0, INTERP_SHIFT_PS
    psrad           m2, INTERP_SHIFT_PS
%endif
%endif

    packssdw        m0, m2
    pxor            m6, m6
    mova            m3, [pw_pixel_max]
%ifidn %1,pp
    CLIPW           m0, m6, m3
%elifidn %1, sp
    CLIPW           m0, m6, m3
%endif

    vextracti128    xm2, m0, 1
    movq            [r2], xm0
    movq            [r2 + r3], xm2
    movhps          [r2 + r3 * 2], xm0
    movhps          [r2 + r6], xm2

    movq            xm2, [r0 + r4]
    punpcklwd       xm5, xm2
    lea             r0, [r0 + 4 * r1]
    movq            xm0, [r0]
    punpcklwd       xm2, xm0
    vinserti128     m5, m5, xm2, 1                  ; m5 = [C B B A]
    pmaddwd         m2, m5, [r5 + 3 * mmsize]
    paddd           m4, m2
    pmaddwd         m5, [r5 + 2 * mmsize]
    paddd           m1, m5
    movq            xm2, [r0 + r1]
    punpcklwd       xm0, xm2
    movq            xm5, [r0 + 2 * r1]
    punpcklwd       xm2, xm5
    vinserti128     m0, m0, xm2, 1                  ; m0 = [E D D C]
    pmaddwd         m0, [r5 + 3 * mmsize]
    paddd           m1, m0

%ifidn %1,ss
    psrad           m4, 6
    psrad           m1, 6
%else
    paddd           m4, m7
    paddd           m1, m7
%ifidn %1,pp
    psrad           m4, INTERP_SHIFT_PP
    psrad           m1, INTERP_SHIFT_PP
%elifidn %1, sp
    psrad           m4, INTERP_SHIFT_SP
    psrad           m1, INTERP_SHIFT_SP
%else
    psrad           m4, INTERP_SHIFT_PS
    psrad           m1, INTERP_SHIFT_PS
%endif
%endif

    packssdw        m4, m1
%ifidn %1,pp
    CLIPW           m4, m6, m3
%elifidn %1, sp
    CLIPW           m4, m6, m3
%endif

    vextracti128    xm1, m4, 1
    lea             r2, [r2 + r3 * 4]
    movq            [r2], xm4
    movq            [r2 + r3], xm1
    movhps          [r2 + r3 * 2], xm4
    movhps          [r2 + r6], xm1
    RET
%endmacro

FILTER_VER_LUMA_AVX2_4x8 pp
FILTER_VER_LUMA_AVX2_4x8 ps
FILTER_VER_LUMA_AVX2_4x8 sp
FILTER_VER_LUMA_AVX2_4x8 ss

%macro PROCESS_LUMA_AVX2_W4_16R 1
    movq            xm0, [r0]
    movq            xm1, [r0 + r1]
    punpcklwd       xm0, xm1
    movq            xm2, [r0 + r1 * 2]
    punpcklwd       xm1, xm2
    vinserti128     m0, m0, xm1, 1                  ; m0 = [2 1 1 0]
    pmaddwd         m0, [r5]
    movq            xm3, [r0 + r4]
    punpcklwd       xm2, xm3
    lea             r0, [r0 + 4 * r1]
    movq            xm4, [r0]
    punpcklwd       xm3, xm4
    vinserti128     m2, m2, xm3, 1                  ; m2 = [4 3 3 2]
    pmaddwd         m5, m2, [r5 + 1 * mmsize]
    pmaddwd         m2, [r5]
    paddd           m0, m5
    movq            xm3, [r0 + r1]
    punpcklwd       xm4, xm3
    movq            xm1, [r0 + r1 * 2]
    punpcklwd       xm3, xm1
    vinserti128     m4, m4, xm3, 1                  ; m4 = [6 5 5 4]
    pmaddwd         m5, m4, [r5 + 2 * mmsize]
    paddd           m0, m5
    pmaddwd         m5, m4, [r5 + 1 * mmsize]
    paddd           m2, m5
    pmaddwd         m4, [r5]
    movq            xm3, [r0 + r4]
    punpcklwd       xm1, xm3
    lea             r0, [r0 + 4 * r1]
    movq            xm6, [r0]
    punpcklwd       xm3, xm6
    vinserti128     m1, m1, xm3, 1                  ; m1 = [8 7 7 6]
    pmaddwd         m5, m1, [r5 + 3 * mmsize]
    paddd           m0, m5
    pmaddwd         m5, m1, [r5 + 2 * mmsize]
    paddd           m2, m5
    pmaddwd         m5, m1, [r5 + 1 * mmsize]
    paddd           m4, m5
    pmaddwd         m1, [r5]
    movq            xm3, [r0 + r1]
    punpcklwd       xm6, xm3
    movq            xm5, [r0 + 2 * r1]
    punpcklwd       xm3, xm5
    vinserti128     m6, m6, xm3, 1                  ; m6 = [10 9 9 8]
    pmaddwd         m3, m6, [r5 + 3 * mmsize]
    paddd           m2, m3
    pmaddwd         m3, m6, [r5 + 2 * mmsize]
    paddd           m4, m3
    pmaddwd         m3, m6, [r5 + 1 * mmsize]
    paddd           m1, m3
    pmaddwd         m6, [r5]

%ifidn %1,ss
    psrad           m0, 6
    psrad           m2, 6
%else
    paddd           m0, m7
    paddd           m2, m7
%ifidn %1,pp
    psrad           m0, INTERP_SHIFT_PP
    psrad           m2, INTERP_SHIFT_PP
%elifidn %1, sp
    psrad           m0, INTERP_SHIFT_SP
    psrad           m2, INTERP_SHIFT_SP
%else
    psrad           m0, INTERP_SHIFT_PS
    psrad           m2, INTERP_SHIFT_PS
%endif
%endif

    packssdw        m0, m2
    pxor            m3, m3
%ifidn %1,pp
    CLIPW           m0, m3, [pw_pixel_max]
%elifidn %1, sp
    CLIPW           m0, m3, [pw_pixel_max]
%endif

    vextracti128    xm2, m0, 1
    movq            [r2], xm0
    movq            [r2 + r3], xm2
    movhps          [r2 + r3 * 2], xm0
    movhps          [r2 + r6], xm2

    movq            xm2, [r0 + r4]
    punpcklwd       xm5, xm2
    lea             r0, [r0 + 4 * r1]
    movq            xm0, [r0]
    punpcklwd       xm2, xm0
    vinserti128     m5, m5, xm2, 1                  ; m5 = [12 11 11 10]
    pmaddwd         m2, m5, [r5 + 3 * mmsize]
    paddd           m4, m2
    pmaddwd         m2, m5, [r5 + 2 * mmsize]
    paddd           m1, m2
    pmaddwd         m2, m5, [r5 + 1 * mmsize]
    paddd           m6, m2
    pmaddwd         m5, [r5]
    movq            xm2, [r0 + r1]
    punpcklwd       xm0, xm2
    movq            xm3, [r0 + 2 * r1]
    punpcklwd       xm2, xm3
    vinserti128     m0, m0, xm2, 1                  ; m0 = [14 13 13 12]
    pmaddwd         m2, m0, [r5 + 3 * mmsize]
    paddd           m1, m2
    pmaddwd         m2, m0, [r5 + 2 * mmsize]
    paddd           m6, m2
    pmaddwd         m2, m0, [r5 + 1 * mmsize]
    paddd           m5, m2
    pmaddwd         m0, [r5]

%ifidn %1,ss
    psrad           m4, 6
    psrad           m1, 6
%else
    paddd           m4, m7
    paddd           m1, m7
%ifidn %1,pp
    psrad           m4, INTERP_SHIFT_PP
    psrad           m1, INTERP_SHIFT_PP
%elifidn %1, sp
    psrad           m4, INTERP_SHIFT_SP
    psrad           m1, INTERP_SHIFT_SP
%else
    psrad           m4, INTERP_SHIFT_PS
    psrad           m1, INTERP_SHIFT_PS
%endif
%endif

    packssdw        m4, m1
    pxor            m2, m2
%ifidn %1,pp
    CLIPW           m4, m2, [pw_pixel_max]
%elifidn %1, sp
    CLIPW           m4, m2, [pw_pixel_max]
%endif

    vextracti128    xm1, m4, 1
    lea             r2, [r2 + r3 * 4]
    movq            [r2], xm4
    movq            [r2 + r3], xm1
    movhps          [r2 + r3 * 2], xm4
    movhps          [r2 + r6], xm1

    movq            xm4, [r0 + r4]
    punpcklwd       xm3, xm4
    lea             r0, [r0 + 4 * r1]
    movq            xm1, [r0]
    punpcklwd       xm4, xm1
    vinserti128     m3, m3, xm4, 1                  ; m3 = [16 15 15 14]
    pmaddwd         m4, m3, [r5 + 3 * mmsize]
    paddd           m6, m4
    pmaddwd         m4, m3, [r5 + 2 * mmsize]
    paddd           m5, m4
    pmaddwd         m4, m3, [r5 + 1 * mmsize]
    paddd           m0, m4
    pmaddwd         m3, [r5]
    movq            xm4, [r0 + r1]
    punpcklwd       xm1, xm4
    movq            xm2, [r0 + 2 * r1]
    punpcklwd       xm4, xm2
    vinserti128     m1, m1, xm4, 1                  ; m1 = [18 17 17 16]
    pmaddwd         m4, m1, [r5 + 3 * mmsize]
    paddd           m5, m4
    pmaddwd         m4, m1, [r5 + 2 * mmsize]
    paddd           m0, m4
    pmaddwd         m1, [r5 + 1 * mmsize]
    paddd           m3, m1

%ifidn %1,ss
    psrad           m6, 6
    psrad           m5, 6
%else
    paddd           m6, m7
    paddd           m5, m7
%ifidn %1,pp
    psrad           m6, INTERP_SHIFT_PP
    psrad           m5, INTERP_SHIFT_PP
%elifidn %1, sp
    psrad           m6, INTERP_SHIFT_SP
    psrad           m5, INTERP_SHIFT_SP
%else
    psrad           m6, INTERP_SHIFT_PS
    psrad           m5, INTERP_SHIFT_PS
%endif
%endif

    packssdw        m6, m5
    pxor            m1, m1
%ifidn %1,pp
    CLIPW           m6, m1, [pw_pixel_max]
%elifidn %1, sp
    CLIPW           m6, m1, [pw_pixel_max]
%endif

    vextracti128    xm5, m6, 1
    lea             r2, [r2 + r3 * 4]
    movq            [r2], xm6
    movq            [r2 + r3], xm5
    movhps          [r2 + r3 * 2], xm6
    movhps          [r2 + r6], xm5

    movq            xm4, [r0 + r4]
    punpcklwd       xm2, xm4
    lea             r0, [r0 + 4 * r1]
    movq            xm6, [r0]
    punpcklwd       xm4, xm6
    vinserti128     m2, m2, xm4, 1                  ; m2 = [20 19 19 18]
    pmaddwd         m4, m2, [r5 + 3 * mmsize]
    paddd           m0, m4
    pmaddwd         m2, [r5 + 2 * mmsize]
    paddd           m3, m2
    movq            xm4, [r0 + r1]
    punpcklwd       xm6, xm4
    movq            xm2, [r0 + 2 * r1]
    punpcklwd       xm4, xm2
    vinserti128     m6, m6, xm4, 1                  ; m6 = [22 21 21 20]
    pmaddwd         m6, [r5 + 3 * mmsize]
    paddd           m3, m6

%ifidn %1,ss
    psrad           m0, 6
    psrad           m3, 6
%else
    paddd           m0, m7
    paddd           m3, m7
%ifidn %1,pp
    psrad           m0, INTERP_SHIFT_PP
    psrad           m3, INTERP_SHIFT_PP
%elifidn %1, sp
    psrad           m0, INTERP_SHIFT_SP
    psrad           m3, INTERP_SHIFT_SP
%else
    psrad           m0, INTERP_SHIFT_PS
    psrad           m3, INTERP_SHIFT_PS
%endif
%endif

    packssdw        m0, m3
%ifidn %1,pp
    CLIPW           m0, m1, [pw_pixel_max]
%elifidn %1, sp
    CLIPW           m0, m1, [pw_pixel_max]
%endif

    vextracti128    xm3, m0, 1
    lea             r2, [r2 + r3 * 4]
    movq            [r2], xm0
    movq            [r2 + r3], xm3
    movhps          [r2 + r3 * 2], xm0
    movhps          [r2 + r6], xm3
%endmacro

%macro FILTER_VER_LUMA_AVX2_4x16 1
INIT_YMM avx2
cglobal interp_8tap_vert_%1_4x16, 4, 7, 8
    mov             r4d, r4m
    shl             r4d, 7
    add             r1d, r1d
    add             r3d, r3d

%ifdef PIC
    lea             r5, [tab_LumaCoeffVer]
    add             r5, r4
%else
    lea             r5, [tab_LumaCoeffVer + r4]
%endif

    lea             r4, [r1 * 3]
    sub             r0, r4
%ifidn %1,pp
    vbroadcasti128  m7, [pd_32]
%elifidn %1, sp
    vbroadcasti128  m7, [INTERP_OFFSET_SP]
%else
    vbroadcasti128  m7, [INTERP_OFFSET_PS]
%endif
    lea             r6, [r3 * 3]
    PROCESS_LUMA_AVX2_W4_16R %1
    RET
%endmacro

FILTER_VER_LUMA_AVX2_4x16 pp
FILTER_VER_LUMA_AVX2_4x16 ps
FILTER_VER_LUMA_AVX2_4x16 sp
FILTER_VER_LUMA_AVX2_4x16 ss

%macro FILTER_VER_LUMA_AVX2_12x16 1
INIT_YMM avx2
%if ARCH_X86_64 == 1
cglobal interp_8tap_vert_%1_12x16, 4, 9, 15
    mov             r4d, r4m
    shl             r4d, 7
    add             r1d, r1d
    add             r3d, r3d

%ifdef PIC
    lea             r5, [tab_LumaCoeffVer]
    add             r5, r4
%else
    lea             r5, [tab_LumaCoeffVer + r4]
%endif

    lea             r4, [r1 * 3]
    sub             r0, r4
%ifidn %1,pp
    vbroadcasti128  m14, [pd_32]
%elifidn %1, sp
    vbroadcasti128  m14, [INTERP_OFFSET_SP]
%else
    vbroadcasti128  m14, [INTERP_OFFSET_PS]
%endif
    lea             r6, [r3 * 3]
    PROCESS_LUMA_AVX2_W8_16R %1
    add             r2, 16
    add             r0, 16
    mova            m7, m14
    PROCESS_LUMA_AVX2_W4_16R %1
    RET
%endif
%endmacro

FILTER_VER_LUMA_AVX2_12x16 pp
FILTER_VER_LUMA_AVX2_12x16 ps
FILTER_VER_LUMA_AVX2_12x16 sp
FILTER_VER_LUMA_AVX2_12x16 ss

;---------------------------------------------------------------------------------------------------------------
; void interp_8tap_vert_ps_%1x%2(pixel *src, intptr_t srcStride, int16_t *dst, intptr_t dstStride, int coeffIdx)
;---------------------------------------------------------------------------------------------------------------
%macro FILTER_VER_LUMA_PS 2
INIT_XMM sse4
cglobal interp_8tap_vert_ps_%1x%2, 5, 7, 8 ,0-gprsize

    add       r1d, r1d
    add       r3d, r3d
    lea       r5, [r1 + 2 * r1]
    sub       r0, r5
    shl       r4d, 6

%ifdef PIC
    lea       r5, [tab_LumaCoeffV]
    lea       r6, [r5 + r4]
%else
    lea       r6, [tab_LumaCoeffV + r4]
%endif

    mova      m7, [INTERP_OFFSET_PS]

    mov       dword [rsp], %2/4
.loopH:
    mov       r4d, (%1/4)
.loopW:
    PROCESS_LUMA_VER_W4_4R

    paddd     m0, m7
    paddd     m1, m7
    paddd     m2, m7
    paddd     m3, m7

    psrad     m0, INTERP_SHIFT_PS
    psrad     m1, INTERP_SHIFT_PS
    psrad     m2, INTERP_SHIFT_PS
    psrad     m3, INTERP_SHIFT_PS

    packssdw  m0, m1
    packssdw  m2, m3

    movh      [r2], m0
    movhps    [r2 + r3], m0
    lea       r5, [r2 + 2 * r3]
    movh      [r5], m2
    movhps    [r5 + r3], m2

    lea       r5, [8 * r1 - 2 * 4]
    sub       r0, r5
    add       r2, 2 * 4

    dec       r4d
    jnz       .loopW

    lea       r0, [r0 + 4 * r1 - 2 * %1]
    lea       r2, [r2 + 4 * r3 - 2 * %1]

    dec       dword [rsp]
    jnz       .loopH
    RET
%endmacro

;---------------------------------------------------------------------------------------------------------------
; void interp_8tap_vert_ps_%1x%2(pixel *src, intptr_t srcStride, int16_t *dst, intptr_t dstStride, int coeffIdx)
;---------------------------------------------------------------------------------------------------------------
    FILTER_VER_LUMA_PS 4, 4
    FILTER_VER_LUMA_PS 8, 8
    FILTER_VER_LUMA_PS 8, 4
    FILTER_VER_LUMA_PS 4, 8
    FILTER_VER_LUMA_PS 16, 16
    FILTER_VER_LUMA_PS 16, 8
    FILTER_VER_LUMA_PS 8, 16
    FILTER_VER_LUMA_PS 16, 12
    FILTER_VER_LUMA_PS 12, 16
    FILTER_VER_LUMA_PS 16, 4
    FILTER_VER_LUMA_PS 4, 16
    FILTER_VER_LUMA_PS 32, 32
    FILTER_VER_LUMA_PS 32, 16
    FILTER_VER_LUMA_PS 16, 32
    FILTER_VER_LUMA_PS 32, 24
    FILTER_VER_LUMA_PS 24, 32
    FILTER_VER_LUMA_PS 32, 8
    FILTER_VER_LUMA_PS 8, 32
    FILTER_VER_LUMA_PS 64, 64
    FILTER_VER_LUMA_PS 64, 32
    FILTER_VER_LUMA_PS 32, 64
    FILTER_VER_LUMA_PS 64, 48
    FILTER_VER_LUMA_PS 48, 64
    FILTER_VER_LUMA_PS 64, 16
    FILTER_VER_LUMA_PS 16, 64

;--------------------------------------------------------------------------------------------------------------
; void interp_8tap_vert_sp_%1x%2(int16_t *src, intptr_t srcStride, pixel *dst, intptr_t dstStride, int coeffIdx)
;--------------------------------------------------------------------------------------------------------------
%macro FILTER_VER_LUMA_SP 2
INIT_XMM sse4
cglobal interp_8tap_vert_sp_%1x%2, 5, 7, 8 ,0-gprsize

    add       r1d, r1d
    add       r3d, r3d
    lea       r5, [r1 + 2 * r1]
    sub       r0, r5
    shl       r4d, 6

%ifdef PIC
    lea       r5, [tab_LumaCoeffV]
    lea       r6, [r5 + r4]
%else
    lea       r6, [tab_LumaCoeffV + r4]
%endif

    mova      m7, [INTERP_OFFSET_SP]

    mov       dword [rsp], %2/4
.loopH:
    mov       r4d, (%1/4)
.loopW:
    PROCESS_LUMA_VER_W4_4R

    paddd     m0, m7
    paddd     m1, m7
    paddd     m2, m7
    paddd     m3, m7

    psrad     m0, INTERP_SHIFT_SP
    psrad     m1, INTERP_SHIFT_SP
    psrad     m2, INTERP_SHIFT_SP
    psrad     m3, INTERP_SHIFT_SP

    packssdw  m0, m1
    packssdw  m2, m3

    pxor      m1, m1
    CLIPW2    m0, m2, m1, [pw_pixel_max]

    movh      [r2], m0
    movhps    [r2 + r3], m0
    lea       r5, [r2 + 2 * r3]
    movh      [r5], m2
    movhps    [r5 + r3], m2

    lea       r5, [8 * r1 - 2 * 4]
    sub       r0, r5
    add       r2, 2 * 4

    dec       r4d
    jnz       .loopW

    lea       r0, [r0 + 4 * r1 - 2 * %1]
    lea       r2, [r2 + 4 * r3 - 2 * %1]

    dec       dword [rsp]
    jnz       .loopH
    RET
%endmacro

;--------------------------------------------------------------------------------------------------------------
; void interp_8tap_vert_sp_%1x%2(int16_t *src, intptr_t srcStride, pixel *dst, intptr_t dstStride, int coeffIdx)
;--------------------------------------------------------------------------------------------------------------
    FILTER_VER_LUMA_SP 4, 4
    FILTER_VER_LUMA_SP 8, 8
    FILTER_VER_LUMA_SP 8, 4
    FILTER_VER_LUMA_SP 4, 8
    FILTER_VER_LUMA_SP 16, 16
    FILTER_VER_LUMA_SP 16, 8
    FILTER_VER_LUMA_SP 8, 16
    FILTER_VER_LUMA_SP 16, 12
    FILTER_VER_LUMA_SP 12, 16
    FILTER_VER_LUMA_SP 16, 4
    FILTER_VER_LUMA_SP 4, 16
    FILTER_VER_LUMA_SP 32, 32
    FILTER_VER_LUMA_SP 32, 16
    FILTER_VER_LUMA_SP 16, 32
    FILTER_VER_LUMA_SP 32, 24
    FILTER_VER_LUMA_SP 24, 32
    FILTER_VER_LUMA_SP 32, 8
    FILTER_VER_LUMA_SP 8, 32
    FILTER_VER_LUMA_SP 64, 64
    FILTER_VER_LUMA_SP 64, 32
    FILTER_VER_LUMA_SP 32, 64
    FILTER_VER_LUMA_SP 64, 48
    FILTER_VER_LUMA_SP 48, 64
    FILTER_VER_LUMA_SP 64, 16
    FILTER_VER_LUMA_SP 16, 64

;-----------------------------------------------------------------------------------------------------------------
; void interp_8tap_vert_ss_%1x%2(int16_t *src, intptr_t srcStride, int16_t *dst, intptr_t dstStride, int coeffIdx)
;-----------------------------------------------------------------------------------------------------------------
%macro FILTER_VER_LUMA_SS 2
INIT_XMM sse2
cglobal interp_8tap_vert_ss_%1x%2, 5, 7, 7 ,0-gprsize

    add        r1d, r1d
    add        r3d, r3d
    lea        r5, [3 * r1]
    sub        r0, r5
    shl        r4d, 6

%ifdef PIC
    lea        r5, [tab_LumaCoeffV]
    lea        r6, [r5 + r4]
%else
    lea        r6, [tab_LumaCoeffV + r4]
%endif

    mov        dword [rsp], %2/4
.loopH:
    mov        r4d, (%1/4)
.loopW:
    PROCESS_LUMA_VER_W4_4R

    psrad      m0, 6
    psrad      m1, 6
    packssdw   m0, m1
    movlps     [r2], m0
    movhps     [r2 + r3], m0

    psrad      m2, 6
    psrad      m3, 6
    packssdw   m2, m3
    movlps     [r2 + 2 * r3], m2
    lea        r5, [3 * r3]
    movhps     [r2 + r5], m2

    lea        r5, [8 * r1 - 2 * 4]
    sub        r0, r5
    add        r2, 2 * 4

    dec        r4d
    jnz        .loopW

    lea        r0, [r0 + 4 * r1 - 2 * %1]
    lea        r2, [r2 + 4 * r3 - 2 * %1]

    dec        dword [rsp]
    jnz        .loopH
    RET
%endmacro

    FILTER_VER_LUMA_SS 4, 4
    FILTER_VER_LUMA_SS 8, 8
    FILTER_VER_LUMA_SS 8, 4
    FILTER_VER_LUMA_SS 4, 8
    FILTER_VER_LUMA_SS 16, 16
    FILTER_VER_LUMA_SS 16, 8
    FILTER_VER_LUMA_SS 8, 16
    FILTER_VER_LUMA_SS 16, 12
    FILTER_VER_LUMA_SS 12, 16
    FILTER_VER_LUMA_SS 16, 4
    FILTER_VER_LUMA_SS 4, 16
    FILTER_VER_LUMA_SS 32, 32
    FILTER_VER_LUMA_SS 32, 16
    FILTER_VER_LUMA_SS 16, 32
    FILTER_VER_LUMA_SS 32, 24
    FILTER_VER_LUMA_SS 24, 32
    FILTER_VER_LUMA_SS 32, 8
    FILTER_VER_LUMA_SS 8, 32
    FILTER_VER_LUMA_SS 64, 64
    FILTER_VER_LUMA_SS 64, 32
    FILTER_VER_LUMA_SS 32, 64
    FILTER_VER_LUMA_SS 64, 48
    FILTER_VER_LUMA_SS 48, 64
    FILTER_VER_LUMA_SS 64, 16
    FILTER_VER_LUMA_SS 16, 64

;-----------------------------------------------------------------------------
; void filterPixelToShort(pixel *src, intptr_t srcStride, int16_t *dst, intptr_t dstStride)
;-----------------------------------------------------------------------------
%macro P2S_H_2xN 1
INIT_XMM sse4
cglobal filterPixelToShort_2x%1, 3, 6, 2
    add        r1d, r1d
    mov        r3d, r3m
    add        r3d, r3d
    lea        r4, [r1 * 3]
    lea        r5, [r3 * 3]

    ; load constant
    mova       m1, [pw_2000]

%rep %1/4
    movd       m0, [r0]
    movhps     m0, [r0 + r1]
    psllw      m0, (14 - BIT_DEPTH)
    psubw      m0, m1

    movd       [r2 + r3 * 0], m0
    pextrd     [r2 + r3 * 1], m0, 2

    movd       m0, [r0 + r1 * 2]
    movhps     m0, [r0 + r4]
    psllw      m0, (14 - BIT_DEPTH)
    psubw      m0, m1

    movd       [r2 + r3 * 2], m0
    pextrd     [r2 + r5], m0, 2

    lea        r0, [r0 + r1 * 4]
    lea        r2, [r2 + r3 * 4]
%endrep
    RET
%endmacro
P2S_H_2xN 4
P2S_H_2xN 8
P2S_H_2xN 16

;-----------------------------------------------------------------------------
; void filterPixelToShort(pixel *src, intptr_t srcStride, int16_t *dst, intptr_t dstStride)
;-----------------------------------------------------------------------------
%macro P2S_H_4xN 1
INIT_XMM ssse3
cglobal filterPixelToShort_4x%1, 3, 6, 2
    add        r1d, r1d
    mov        r3d, r3m
    add        r3d, r3d
    lea        r4, [r3 * 3]
    lea        r5, [r1 * 3]

    ; load constant
    mova       m1, [pw_2000]

%rep %1/4
    movh       m0, [r0]
    movhps     m0, [r0 + r1]
    psllw      m0, (14 - BIT_DEPTH)
    psubw      m0, m1
    movh       [r2 + r3 * 0], m0
    movhps     [r2 + r3 * 1], m0

    movh       m0, [r0 + r1 * 2]
    movhps     m0, [r0 + r5]
    psllw      m0, (14 - BIT_DEPTH)
    psubw      m0, m1
    movh       [r2 + r3 * 2], m0
    movhps     [r2 + r4], m0

    lea        r0, [r0 + r1 * 4]
    lea        r2, [r2 + r3 * 4]
%endrep
    RET
%endmacro
P2S_H_4xN 4
P2S_H_4xN 8
P2S_H_4xN 16
P2S_H_4xN 32

;-----------------------------------------------------------------------------
; void filterPixelToShort(pixel *src, intptr_t srcStride, int16_t *dst, intptr_t dstStride)
;-----------------------------------------------------------------------------
INIT_XMM ssse3
cglobal filterPixelToShort_4x2, 3, 4, 1
    add        r1d, r1d
    mov        r3d, r3m
    add        r3d, r3d

    movh       m0, [r0]
    movhps     m0, [r0 + r1]
    psllw      m0, (14 - BIT_DEPTH)
    psubw      m0, [pw_2000]
    movh       [r2 + r3 * 0], m0
    movhps     [r2 + r3 * 1], m0
    RET

;-----------------------------------------------------------------------------
; void filterPixelToShort(pixel *src, intptr_t srcStride, int16_t *dst, intptr_t dstStride)
;-----------------------------------------------------------------------------
%macro P2S_H_6xN 1
INIT_XMM sse4
cglobal filterPixelToShort_6x%1, 3, 7, 3
    add        r1d, r1d
    mov        r3d, r3m
    add        r3d, r3d
    lea        r4, [r3 * 3]
    lea        r5, [r1 * 3]

    ; load height
    mov        r6d, %1/4

    ; load constant
    mova       m2, [pw_2000]

.loop:
    movu       m0, [r0]
    movu       m1, [r0 + r1]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psubw      m0, m2
    psubw      m1, m2

    movh       [r2 + r3 * 0], m0
    pextrd     [r2 + r3 * 0 + 8], m0, 2
    movh       [r2 + r3 * 1], m1
    pextrd     [r2 + r3 * 1 + 8], m1, 2

    movu       m0, [r0 + r1 * 2]
    movu       m1, [r0 + r5]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psubw      m0, m2
    psubw      m1, m2

    movh       [r2 + r3 * 2], m0
    pextrd     [r2 + r3 * 2 + 8], m0, 2
    movh       [r2 + r4], m1
    pextrd     [r2 + r4 + 8], m1, 2

    lea        r0, [r0 + r1 * 4]
    lea        r2, [r2 + r3 * 4]

    dec        r6d
    jnz        .loop
    RET
%endmacro
P2S_H_6xN 8
P2S_H_6xN 16

;-----------------------------------------------------------------------------
; void filterPixelToShort(pixel *src, intptr_t srcStride, int16_t *dst, intptr_t dstStride)
;-----------------------------------------------------------------------------
%macro P2S_H_8xN 1
INIT_XMM ssse3
cglobal filterPixelToShort_8x%1, 3, 7, 2
    add        r1d, r1d
    mov        r3d, r3m
    add        r3d, r3d
    lea        r4, [r3 * 3]
    lea        r5, [r1 * 3]

    ; load height
    mov        r6d, %1/4

    ; load constant
    mova       m1, [pw_2000]

.loop:
    movu       m0, [r0]
    psllw      m0, (14 - BIT_DEPTH)
    psubw      m0, m1
    movu       [r2 + r3 * 0], m0

    movu       m0, [r0 + r1]
    psllw      m0, (14 - BIT_DEPTH)
    psubw      m0, m1
    movu       [r2 + r3 * 1], m0

    movu       m0, [r0 + r1 * 2]
    psllw      m0, (14 - BIT_DEPTH)
    psubw      m0, m1
    movu       [r2 + r3 * 2], m0

    movu       m0, [r0 + r5]
    psllw      m0, (14 - BIT_DEPTH)
    psubw      m0, m1
    movu       [r2 + r4], m0

    lea        r0, [r0 + r1 * 4]
    lea        r2, [r2 + r3 * 4]

    dec        r6d
    jnz        .loop
    RET
%endmacro
P2S_H_8xN 8
P2S_H_8xN 4
P2S_H_8xN 16
P2S_H_8xN 32
P2S_H_8xN 12
P2S_H_8xN 64

;-----------------------------------------------------------------------------
; void filterPixelToShort(pixel *src, intptr_t srcStride, int16_t *dst, intptr_t dstStride)
;-----------------------------------------------------------------------------
INIT_XMM ssse3
cglobal filterPixelToShort_8x2, 3, 4, 2
    add        r1d, r1d
    mov        r3d, r3m
    add        r3d, r3d

    movu       m0, [r0]
    movu       m1, [r0 + r1]

    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psubw      m0, [pw_2000]
    psubw      m1, [pw_2000]

    movu       [r2 + r3 * 0], m0
    movu       [r2 + r3 * 1], m1
    RET

;-----------------------------------------------------------------------------
; void filterPixelToShort(pixel *src, intptr_t srcStride, int16_t *dst, intptr_t dstStride)
;-----------------------------------------------------------------------------
INIT_XMM ssse3
cglobal filterPixelToShort_8x6, 3, 7, 4
    add        r1d, r1d
    mov        r3d, r3m
    add        r3d, r3d
    lea        r4, [r1 * 3]
    lea        r5, [r1 * 5]
    lea        r6, [r3 * 3]

    ; load constant
    mova       m3, [pw_2000]

    movu       m0, [r0]
    movu       m1, [r0 + r1]
    movu       m2, [r0 + r1 * 2]

    psllw      m0, (14 - BIT_DEPTH)
    psubw      m0, m3
    psllw      m1, (14 - BIT_DEPTH)
    psubw      m1, m3
    psllw      m2, (14 - BIT_DEPTH)
    psubw      m2, m3

    movu       [r2 + r3 * 0], m0
    movu       [r2 + r3 * 1], m1
    movu       [r2 + r3 * 2], m2

    movu       m0, [r0 + r4]
    movu       m1, [r0 + r1 * 4]
    movu       m2, [r0 + r5 ]

    psllw      m0, (14 - BIT_DEPTH)
    psubw      m0, m3
    psllw      m1, (14 - BIT_DEPTH)
    psubw      m1, m3
    psllw      m2, (14 - BIT_DEPTH)
    psubw      m2, m3

    movu       [r2 + r6], m0
    movu       [r2 + r3 * 4], m1
    lea        r2, [r2 + r3 * 4]
    movu       [r2 + r3], m2
    RET

;-----------------------------------------------------------------------------
; void filterPixelToShort(pixel *src, intptr_t srcStride, int16_t *dst, intptr_t dstStride)
;-----------------------------------------------------------------------------
%macro P2S_H_16xN 1
INIT_XMM ssse3
cglobal filterPixelToShort_16x%1, 3, 7, 3
    add        r1d, r1d
    mov        r3d, r3m
    add        r3d, r3d
    lea        r4, [r3 * 3]
    lea        r5, [r1 * 3]

    ; load height
    mov        r6d, %1/4

    ; load constant
    mova       m2, [pw_2000]

.loop:
    movu       m0, [r0]
    movu       m1, [r0 + r1]
    psllw      m0, (14 - BIT_DEPTH)
    psubw      m0, m2
    psllw      m1, (14 - BIT_DEPTH)
    psubw      m1, m2

    movu       [r2 + r3 * 0], m0
    movu       [r2 + r3 * 1], m1

    movu       m0, [r0 + r1 * 2]
    movu       m1, [r0 + r5]
    psllw      m0, (14 - BIT_DEPTH)
    psubw      m0, m2
    psllw      m1, (14 - BIT_DEPTH)
    psubw      m1, m2

    movu       [r2 + r3 * 2], m0
    movu       [r2 + r4], m1

    movu       m0, [r0 + 16]
    movu       m1, [r0 + r1 + 16]
    psllw      m0, (14 - BIT_DEPTH)
    psubw      m0, m2
    psllw      m1, (14 - BIT_DEPTH)
    psubw      m1, m2

    movu       [r2 + r3 * 0 + 16], m0
    movu       [r2 + r3 * 1 + 16], m1

    movu       m0, [r0 + r1 * 2 + 16]
    movu       m1, [r0 + r5 + 16]
    psllw      m0, (14 - BIT_DEPTH)
    psubw      m0, m2
    psllw      m1, (14 - BIT_DEPTH)
    psubw      m1, m2

    movu       [r2 + r3 * 2 + 16], m0
    movu       [r2 + r4 + 16], m1

    lea        r0, [r0 + r1 * 4]
    lea        r2, [r2 + r3 * 4]

    dec        r6d
    jnz        .loop
    RET
%endmacro
P2S_H_16xN 16
P2S_H_16xN 4
P2S_H_16xN 8
P2S_H_16xN 12
P2S_H_16xN 32
P2S_H_16xN 64
P2S_H_16xN 24

;-----------------------------------------------------------------------------
; void filterPixelToShort(pixel *src, intptr_t srcStride, int16_t *dst, intptr_t dstStride)
;-----------------------------------------------------------------------------
%macro P2S_H_16xN_avx2 1
INIT_YMM avx2
cglobal filterPixelToShort_16x%1, 3, 7, 3
    add        r1d, r1d
    mov        r3d, r3m
    add        r3d, r3d
    lea        r4, [r3 * 3]
    lea        r5, [r1 * 3]

    ; load height
    mov        r6d, %1/4

    ; load constant
    mova       m2, [pw_2000]

.loop:
    movu       m0, [r0]
    movu       m1, [r0 + r1]
    psllw      m0, (14 - BIT_DEPTH)
    psubw      m0, m2
    psllw      m1, (14 - BIT_DEPTH)
    psubw      m1, m2

    movu       [r2 + r3 * 0], m0
    movu       [r2 + r3 * 1], m1

    movu       m0, [r0 + r1 * 2]
    movu       m1, [r0 + r5]
    psllw      m0, (14 - BIT_DEPTH)
    psubw      m0, m2
    psllw      m1, (14 - BIT_DEPTH)
    psubw      m1, m2

    movu       [r2 + r3 * 2], m0
    movu       [r2 + r4], m1

    lea        r0, [r0 + r1 * 4]
    lea        r2, [r2 + r3 * 4]

    dec        r6d
    jnz        .loop
    RET
%endmacro
P2S_H_16xN_avx2 16
P2S_H_16xN_avx2 4
P2S_H_16xN_avx2 8
P2S_H_16xN_avx2 12
P2S_H_16xN_avx2 32
P2S_H_16xN_avx2 64
P2S_H_16xN_avx2 24

;-----------------------------------------------------------------------------
; void filterPixelToShort(pixel *src, intptr_t srcStride, int16_t *dst, intptr_t dstStride)
;-----------------------------------------------------------------------------
%macro P2S_H_32xN 1
INIT_XMM ssse3
cglobal filterPixelToShort_32x%1, 3, 7, 5
    add        r1d, r1d
    mov        r3d, r3m
    add        r3d, r3d
    lea        r4, [r3 * 3]
    lea        r5, [r1 * 3]

    ; load height
    mov        r6d, %1/4

    ; load constant
    mova       m4, [pw_2000]

.loop:
    movu       m0, [r0]
    movu       m1, [r0 + r1]
    movu       m2, [r0 + r1 * 2]
    movu       m3, [r0 + r5]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psllw      m2, (14 - BIT_DEPTH)
    psllw      m3, (14 - BIT_DEPTH)
    psubw      m0, m4
    psubw      m1, m4
    psubw      m2, m4
    psubw      m3, m4

    movu       [r2 + r3 * 0], m0
    movu       [r2 + r3 * 1], m1
    movu       [r2 + r3 * 2], m2
    movu       [r2 + r4], m3

    movu       m0, [r0 + 16]
    movu       m1, [r0 + r1 + 16]
    movu       m2, [r0 + r1 * 2 + 16]
    movu       m3, [r0 + r5 + 16]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psllw      m2, (14 - BIT_DEPTH)
    psllw      m3, (14 - BIT_DEPTH)
    psubw      m0, m4
    psubw      m1, m4
    psubw      m2, m4
    psubw      m3, m4

    movu       [r2 + r3 * 0 + 16], m0
    movu       [r2 + r3 * 1 + 16], m1
    movu       [r2 + r3 * 2 + 16], m2
    movu       [r2 + r4 + 16], m3

    movu       m0, [r0 + 32]
    movu       m1, [r0 + r1 + 32]
    movu       m2, [r0 + r1 * 2 + 32]
    movu       m3, [r0 + r5 + 32]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psllw      m2, (14 - BIT_DEPTH)
    psllw      m3, (14 - BIT_DEPTH)
    psubw      m0, m4
    psubw      m1, m4
    psubw      m2, m4
    psubw      m3, m4

    movu       [r2 + r3 * 0 + 32], m0
    movu       [r2 + r3 * 1 + 32], m1
    movu       [r2 + r3 * 2 + 32], m2
    movu       [r2 + r4 + 32], m3

    movu       m0, [r0 + 48]
    movu       m1, [r0 + r1 + 48]
    movu       m2, [r0 + r1 * 2 + 48]
    movu       m3, [r0 + r5 + 48]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psllw      m2, (14 - BIT_DEPTH)
    psllw      m3, (14 - BIT_DEPTH)
    psubw      m0, m4
    psubw      m1, m4
    psubw      m2, m4
    psubw      m3, m4

    movu       [r2 + r3 * 0 + 48], m0
    movu       [r2 + r3 * 1 + 48], m1
    movu       [r2 + r3 * 2 + 48], m2
    movu       [r2 + r4 + 48], m3

    lea        r0, [r0 + r1 * 4]
    lea        r2, [r2 + r3 * 4]

    dec        r6d
    jnz        .loop
    RET
%endmacro
P2S_H_32xN 32
P2S_H_32xN 8
P2S_H_32xN 16
P2S_H_32xN 24
P2S_H_32xN 64
P2S_H_32xN 48

;-----------------------------------------------------------------------------
; void filterPixelToShort(pixel *src, intptr_t srcStride, int16_t *dst, intptr_t dstStride)
;-----------------------------------------------------------------------------
%macro P2S_H_32xN_avx2 1
INIT_YMM avx2
cglobal filterPixelToShort_32x%1, 3, 7, 3
    add        r1d, r1d
    mov        r3d, r3m
    add        r3d, r3d
    lea        r4, [r3 * 3]
    lea        r5, [r1 * 3]

    ; load height
    mov        r6d, %1/4

    ; load constant
    mova       m2, [pw_2000]

.loop:
    movu       m0, [r0]
    movu       m1, [r0 + r1]
    psllw      m0, (14 - BIT_DEPTH)
    psubw      m0, m2
    psllw      m1, (14 - BIT_DEPTH)
    psubw      m1, m2

    movu       [r2 + r3 * 0], m0
    movu       [r2 + r3 * 1], m1

    movu       m0, [r0 + r1 * 2]
    movu       m1, [r0 + r5]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psubw      m0, m2
    psubw      m1, m2

    movu       [r2 + r3 * 2], m0
    movu       [r2 + r4], m1

    movu       m0, [r0 + 32]
    movu       m1, [r0 + r1 + 32]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psubw      m0, m2
    psubw      m1, m2

    movu       [r2 + r3 * 0 + 32], m0
    movu       [r2 + r3 * 1 + 32], m1

    movu       m0, [r0 + r1 * 2 + 32]
    movu       m1, [r0 + r5 + 32]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psubw      m0, m2
    psubw      m1, m2

    movu       [r2 + r3 * 2 + 32], m0
    movu       [r2 + r4 + 32], m1

    lea        r0, [r0 + r1 * 4]
    lea        r2, [r2 + r3 * 4]

    dec        r6d
    jnz        .loop
    RET
%endmacro
P2S_H_32xN_avx2 32
P2S_H_32xN_avx2 8
P2S_H_32xN_avx2 16
P2S_H_32xN_avx2 24
P2S_H_32xN_avx2 64
P2S_H_32xN_avx2 48

;-----------------------------------------------------------------------------
; void filterPixelToShort(pixel *src, intptr_t srcStride, int16_t *dst, intptr_t dstStride)
;-----------------------------------------------------------------------------
%macro P2S_H_64xN 1
INIT_XMM ssse3
cglobal filterPixelToShort_64x%1, 3, 7, 5
    add        r1d, r1d
    mov        r3d, r3m
    add        r3d, r3d
    lea        r4, [r3 * 3]
    lea        r5, [r1 * 3]

    ; load height
    mov        r6d, %1/4

    ; load constant
    mova       m4, [pw_2000]

.loop:
    movu       m0, [r0]
    movu       m1, [r0 + r1]
    movu       m2, [r0 + r1 * 2]
    movu       m3, [r0 + r5]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psllw      m2, (14 - BIT_DEPTH)
    psllw      m3, (14 - BIT_DEPTH)
    psubw      m0, m4
    psubw      m1, m4
    psubw      m2, m4
    psubw      m3, m4

    movu       [r2 + r3 * 0], m0
    movu       [r2 + r3 * 1], m1
    movu       [r2 + r3 * 2], m2
    movu       [r2 + r4], m3

    movu       m0, [r0 + 16]
    movu       m1, [r0 + r1 + 16]
    movu       m2, [r0 + r1 * 2 + 16]
    movu       m3, [r0 + r5 + 16]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psllw      m2, (14 - BIT_DEPTH)
    psllw      m3, (14 - BIT_DEPTH)
    psubw      m0, m4
    psubw      m1, m4
    psubw      m2, m4
    psubw      m3, m4

    movu       [r2 + r3 * 0 + 16], m0
    movu       [r2 + r3 * 1 + 16], m1
    movu       [r2 + r3 * 2 + 16], m2
    movu       [r2 + r4 + 16], m3

    movu       m0, [r0 + 32]
    movu       m1, [r0 + r1 + 32]
    movu       m2, [r0 + r1 * 2 + 32]
    movu       m3, [r0 + r5 + 32]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psllw      m2, (14 - BIT_DEPTH)
    psllw      m3, (14 - BIT_DEPTH)
    psubw      m0, m4
    psubw      m1, m4
    psubw      m2, m4
    psubw      m3, m4

    movu       [r2 + r3 * 0 + 32], m0
    movu       [r2 + r3 * 1 + 32], m1
    movu       [r2 + r3 * 2 + 32], m2
    movu       [r2 + r4 + 32], m3

    movu       m0, [r0 + 48]
    movu       m1, [r0 + r1 + 48]
    movu       m2, [r0 + r1 * 2 + 48]
    movu       m3, [r0 + r5 + 48]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psllw      m2, (14 - BIT_DEPTH)
    psllw      m3, (14 - BIT_DEPTH)
    psubw      m0, m4
    psubw      m1, m4
    psubw      m2, m4
    psubw      m3, m4

    movu       [r2 + r3 * 0 + 48], m0
    movu       [r2 + r3 * 1 + 48], m1
    movu       [r2 + r3 * 2 + 48], m2
    movu       [r2 + r4 + 48], m3

    movu       m0, [r0 + 64]
    movu       m1, [r0 + r1 + 64]
    movu       m2, [r0 + r1 * 2 + 64]
    movu       m3, [r0 + r5 + 64]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psllw      m2, (14 - BIT_DEPTH)
    psllw      m3, (14 - BIT_DEPTH)
    psubw      m0, m4
    psubw      m1, m4
    psubw      m2, m4
    psubw      m3, m4

    movu       [r2 + r3 * 0 + 64], m0
    movu       [r2 + r3 * 1 + 64], m1
    movu       [r2 + r3 * 2 + 64], m2
    movu       [r2 + r4 + 64], m3

    movu       m0, [r0 + 80]
    movu       m1, [r0 + r1 + 80]
    movu       m2, [r0 + r1 * 2 + 80]
    movu       m3, [r0 + r5 + 80]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psllw      m2, (14 - BIT_DEPTH)
    psllw      m3, (14 - BIT_DEPTH)
    psubw      m0, m4
    psubw      m1, m4
    psubw      m2, m4
    psubw      m3, m4

    movu       [r2 + r3 * 0 + 80], m0
    movu       [r2 + r3 * 1 + 80], m1
    movu       [r2 + r3 * 2 + 80], m2
    movu       [r2 + r4 + 80], m3

    movu       m0, [r0 + 96]
    movu       m1, [r0 + r1 + 96]
    movu       m2, [r0 + r1 * 2 + 96]
    movu       m3, [r0 + r5 + 96]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psllw      m2, (14 - BIT_DEPTH)
    psllw      m3, (14 - BIT_DEPTH)
    psubw      m0, m4
    psubw      m1, m4
    psubw      m2, m4
    psubw      m3, m4

    movu       [r2 + r3 * 0 + 96], m0
    movu       [r2 + r3 * 1 + 96], m1
    movu       [r2 + r3 * 2 + 96], m2
    movu       [r2 + r4 + 96], m3

    movu       m0, [r0 + 112]
    movu       m1, [r0 + r1 + 112]
    movu       m2, [r0 + r1 * 2 + 112]
    movu       m3, [r0 + r5 + 112]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psllw      m2, (14 - BIT_DEPTH)
    psllw      m3, (14 - BIT_DEPTH)
    psubw      m0, m4
    psubw      m1, m4
    psubw      m2, m4
    psubw      m3, m4

    movu       [r2 + r3 * 0 + 112], m0
    movu       [r2 + r3 * 1 + 112], m1
    movu       [r2 + r3 * 2 + 112], m2
    movu       [r2 + r4 + 112], m3

    lea        r0, [r0 + r1 * 4]
    lea        r2, [r2 + r3 * 4]

    dec        r6d
    jnz        .loop
    RET
%endmacro
P2S_H_64xN 64
P2S_H_64xN 16
P2S_H_64xN 32
P2S_H_64xN 48

;-----------------------------------------------------------------------------
; void filterPixelToShort(pixel *src, intptr_t srcStride, int16_t *dst, intptr_t dstStride)
;-----------------------------------------------------------------------------
%macro P2S_H_64xN_avx2 1
INIT_YMM avx2
cglobal filterPixelToShort_64x%1, 3, 7, 3
    add        r1d, r1d
    mov        r3d, r3m
    add        r3d, r3d
    lea        r4, [r3 * 3]
    lea        r5, [r1 * 3]

    ; load height
    mov        r6d, %1/4

    ; load constant
    mova       m2, [pw_2000]

.loop:
    movu       m0, [r0]
    movu       m1, [r0 + r1]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psubw      m0, m2
    psubw      m1, m2

    movu       [r2 + r3 * 0], m0
    movu       [r2 + r3 * 1], m1

    movu       m0, [r0 + r1 * 2]
    movu       m1, [r0 + r5]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psubw      m0, m2
    psubw      m1, m2

    movu       [r2 + r3 * 2], m0
    movu       [r2 + r4], m1

    movu       m0, [r0 + 32]
    movu       m1, [r0 + r1 + 32]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psubw      m0, m2
    psubw      m1, m2

    movu       [r2 + r3 * 0 + 32], m0
    movu       [r2 + r3 * 1 + 32], m1

    movu       m0, [r0 + r1 * 2 + 32]
    movu       m1, [r0 + r5 + 32]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psubw      m0, m2
    psubw      m1, m2

    movu       [r2 + r3 * 2 + 32], m0
    movu       [r2 + r4 + 32], m1

    movu       m0, [r0 + 64]
    movu       m1, [r0 + r1 + 64]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psubw      m0, m2
    psubw      m1, m2

    movu       [r2 + r3 * 0 + 64], m0
    movu       [r2 + r3 * 1 + 64], m1

    movu       m0, [r0 + r1 * 2 + 64]
    movu       m1, [r0 + r5 + 64]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psubw      m0, m2
    psubw      m1, m2

    movu       [r2 + r3 * 2 + 64], m0
    movu       [r2 + r4 + 64], m1

    movu       m0, [r0 + 96]
    movu       m1, [r0 + r1 + 96]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psubw      m0, m2
    psubw      m1, m2

    movu       [r2 + r3 * 0 + 96], m0
    movu       [r2 + r3 * 1 + 96], m1

    movu       m0, [r0 + r1 * 2 + 96]
    movu       m1, [r0 + r5 + 96]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psubw      m0, m2
    psubw      m1, m2

    movu       [r2 + r3 * 2 + 96], m0
    movu       [r2 + r4 + 96], m1

    lea        r0, [r0 + r1 * 4]
    lea        r2, [r2 + r3 * 4]

    dec        r6d
    jnz        .loop
    RET
%endmacro
P2S_H_64xN_avx2 64
P2S_H_64xN_avx2 16
P2S_H_64xN_avx2 32
P2S_H_64xN_avx2 48

;-----------------------------------------------------------------------------
; void filterPixelToShort(pixel *src, intptr_t srcStride, int16_t *dst, intptr_t dstStride)
;-----------------------------------------------------------------------------
%macro P2S_H_24xN 1
INIT_XMM ssse3
cglobal filterPixelToShort_24x%1, 3, 7, 5
    add        r1d, r1d
    mov        r3d, r3m
    add        r3d, r3d
    lea        r4, [r3 * 3]
    lea        r5, [r1 * 3]

    ; load height
    mov        r6d, %1/4

    ; load constant
    mova       m4, [pw_2000]

.loop:
    movu       m0, [r0]
    movu       m1, [r0 + r1]
    movu       m2, [r0 + r1 * 2]
    movu       m3, [r0 + r5]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psllw      m2, (14 - BIT_DEPTH)
    psllw      m3, (14 - BIT_DEPTH)
    psubw      m0, m4
    psubw      m1, m4
    psubw      m2, m4
    psubw      m3, m4

    movu       [r2 + r3 * 0], m0
    movu       [r2 + r3 * 1], m1
    movu       [r2 + r3 * 2], m2
    movu       [r2 + r4], m3

    movu       m0, [r0 + 16]
    movu       m1, [r0 + r1 + 16]
    movu       m2, [r0 + r1 * 2 + 16]
    movu       m3, [r0 + r5 + 16]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psllw      m2, (14 - BIT_DEPTH)
    psllw      m3, (14 - BIT_DEPTH)
    psubw      m0, m4
    psubw      m1, m4
    psubw      m2, m4
    psubw      m3, m4

    movu       [r2 + r3 * 0 + 16], m0
    movu       [r2 + r3 * 1 + 16], m1
    movu       [r2 + r3 * 2 + 16], m2
    movu       [r2 + r4 + 16], m3

    movu       m0, [r0 + 32]
    movu       m1, [r0 + r1 + 32]
    movu       m2, [r0 + r1 * 2 + 32]
    movu       m3, [r0 + r5 + 32]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psllw      m2, (14 - BIT_DEPTH)
    psllw      m3, (14 - BIT_DEPTH)
    psubw      m0, m4
    psubw      m1, m4
    psubw      m2, m4
    psubw      m3, m4

    movu       [r2 + r3 * 0 + 32], m0
    movu       [r2 + r3 * 1 + 32], m1
    movu       [r2 + r3 * 2 + 32], m2
    movu       [r2 + r4 + 32], m3

    lea        r0, [r0 + r1 * 4]
    lea        r2, [r2 + r3 * 4]

    dec        r6d
    jnz        .loop
    RET
%endmacro
P2S_H_24xN 32
P2S_H_24xN 64

;-----------------------------------------------------------------------------
; void filterPixelToShort(pixel *src, intptr_t srcStride, int16_t *dst, intptr_t dstStride)
;-----------------------------------------------------------------------------
%macro P2S_H_24xN_avx2 1
INIT_YMM avx2
cglobal filterPixelToShort_24x%1, 3, 7, 3
    add        r1d, r1d
    mov        r3d, r3m
    add        r3d, r3d
    lea        r4, [r3 * 3]
    lea        r5, [r1 * 3]

    ; load height
    mov        r6d, %1/4

    ; load constant
    mova       m2, [pw_2000]

.loop:
    movu       m0, [r0]
    movu       m1, [r0 + 32]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psubw      m0, m2
    psubw      m1, m2
    movu       [r2 + r3 * 0], m0
    movu       [r2 + r3 * 0 + 32], xm1

    movu       m0, [r0 + r1]
    movu       m1, [r0 + r1 + 32]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psubw      m0, m2
    psubw      m1, m2
    movu       [r2 + r3 * 1], m0
    movu       [r2 + r3 * 1 + 32], xm1

    movu       m0, [r0 + r1 * 2]
    movu       m1, [r0 + r1 * 2 + 32]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psubw      m0, m2
    psubw      m1, m2
    movu       [r2 + r3 * 2], m0
    movu       [r2 + r3 * 2 + 32], xm1

    movu       m0, [r0 + r5]
    movu       m1, [r0 + r5 + 32]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psubw      m0, m2
    psubw      m1, m2
    movu       [r2 + r4], m0
    movu       [r2 + r4 + 32], xm1

    lea        r0, [r0 + r1 * 4]
    lea        r2, [r2 + r3 * 4]

    dec        r6d
    jnz        .loop
    RET
%endmacro
P2S_H_24xN_avx2 32
P2S_H_24xN_avx2 64

;-----------------------------------------------------------------------------
; void filterPixelToShort(pixel *src, intptr_t srcStride, int16_t *dst, intptr_t dstStride)
;-----------------------------------------------------------------------------
%macro P2S_H_12xN 1
INIT_XMM ssse3
cglobal filterPixelToShort_12x%1, 3, 7, 3
    add        r1d, r1d
    mov        r3d, r3m
    add        r3d, r3d
    lea        r4, [r3 * 3]
    lea        r5, [r1 * 3]

    ; load height
    mov        r6d, %1/4

    ; load constant
    mova       m2, [pw_2000]

.loop:
    movu       m0, [r0]
    movu       m1, [r0 + r1]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psubw      m0, m2
    psubw      m1, m2

    movu       [r2 + r3 * 0], m0
    movu       [r2 + r3 * 1], m1

    movu       m0, [r0 + r1 * 2]
    movu       m1, [r0 + r5]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psubw      m0, m2
    psubw      m1, m2

    movu       [r2 + r3 * 2], m0
    movu       [r2 + r4], m1

    movh       m0, [r0 + 16]
    movhps     m0, [r0 + r1 + 16]
    psllw      m0, (14 - BIT_DEPTH)
    psubw      m0, m2

    movh       [r2 + r3 * 0 + 16], m0
    movhps     [r2 + r3 * 1 + 16], m0

    movh       m0, [r0 + r1 * 2 + 16]
    movhps     m0, [r0 + r5 + 16]
    psllw      m0, (14 - BIT_DEPTH)
    psubw      m0, m2

    movh       [r2 + r3 * 2 + 16], m0
    movhps     [r2 + r4 + 16], m0

    lea        r0, [r0 + r1 * 4]
    lea        r2, [r2 + r3 * 4]

    dec        r6d
    jnz        .loop
    RET
%endmacro
P2S_H_12xN 16
P2S_H_12xN 32

;-----------------------------------------------------------------------------
; void filterPixelToShort(pixel *src, intptr_t srcStride, int16_t *dst, intptr_t dstStride)
;-----------------------------------------------------------------------------
INIT_XMM ssse3
cglobal filterPixelToShort_48x64, 3, 7, 5
    add        r1d, r1d
    mov        r3d, r3m
    add        r3d, r3d
    lea        r4, [r3 * 3]
    lea        r5, [r1 * 3]

    ; load height
    mov        r6d, 16

    ; load constant
    mova       m4, [pw_2000]

.loop:
    movu       m0, [r0]
    movu       m1, [r0 + r1]
    movu       m2, [r0 + r1 * 2]
    movu       m3, [r0 + r5]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psllw      m2, (14 - BIT_DEPTH)
    psllw      m3, (14 - BIT_DEPTH)
    psubw      m0, m4
    psubw      m1, m4
    psubw      m2, m4
    psubw      m3, m4

    movu       [r2 + r3 * 0], m0
    movu       [r2 + r3 * 1], m1
    movu       [r2 + r3 * 2], m2
    movu       [r2 + r4], m3

    movu       m0, [r0 + 16]
    movu       m1, [r0 + r1 + 16]
    movu       m2, [r0 + r1 * 2 + 16]
    movu       m3, [r0 + r5 + 16]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psllw      m2, (14 - BIT_DEPTH)
    psllw      m3, (14 - BIT_DEPTH)
    psubw      m0, m4
    psubw      m1, m4
    psubw      m2, m4
    psubw      m3, m4

    movu       [r2 + r3 * 0 + 16], m0
    movu       [r2 + r3 * 1 + 16], m1
    movu       [r2 + r3 * 2 + 16], m2
    movu       [r2 + r4 + 16], m3

    movu       m0, [r0 + 32]
    movu       m1, [r0 + r1 + 32]
    movu       m2, [r0 + r1 * 2 + 32]
    movu       m3, [r0 + r5 + 32]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psllw      m2, (14 - BIT_DEPTH)
    psllw      m3, (14 - BIT_DEPTH)
    psubw      m0, m4
    psubw      m1, m4
    psubw      m2, m4
    psubw      m3, m4

    movu       [r2 + r3 * 0 + 32], m0
    movu       [r2 + r3 * 1 + 32], m1
    movu       [r2 + r3 * 2 + 32], m2
    movu       [r2 + r4 + 32], m3

    movu       m0, [r0 + 48]
    movu       m1, [r0 + r1 + 48]
    movu       m2, [r0 + r1 * 2 + 48]
    movu       m3, [r0 + r5 + 48]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psllw      m2, (14 - BIT_DEPTH)
    psllw      m3, (14 - BIT_DEPTH)
    psubw      m0, m4
    psubw      m1, m4
    psubw      m2, m4
    psubw      m3, m4

    movu       [r2 + r3 * 0 + 48], m0
    movu       [r2 + r3 * 1 + 48], m1
    movu       [r2 + r3 * 2 + 48], m2
    movu       [r2 + r4 + 48], m3

    movu       m0, [r0 + 64]
    movu       m1, [r0 + r1 + 64]
    movu       m2, [r0 + r1 * 2 + 64]
    movu       m3, [r0 + r5 + 64]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psllw      m2, (14 - BIT_DEPTH)
    psllw      m3, (14 - BIT_DEPTH)
    psubw      m0, m4
    psubw      m1, m4
    psubw      m2, m4
    psubw      m3, m4

    movu       [r2 + r3 * 0 + 64], m0
    movu       [r2 + r3 * 1 + 64], m1
    movu       [r2 + r3 * 2 + 64], m2
    movu       [r2 + r4 + 64], m3

    movu       m0, [r0 + 80]
    movu       m1, [r0 + r1 + 80]
    movu       m2, [r0 + r1 * 2 + 80]
    movu       m3, [r0 + r5 + 80]
    psllw      m0, (14 - BIT_DEPTH)
    psllw      m1, (14 - BIT_DEPTH)
    psllw      m2, (14 - BIT_DEPTH)
    psllw      m3, (14 - BIT_DEPTH)
    psubw      m0, m4
    psubw      m1, m4
    psubw      m2, m4
    psubw      m3, m4

    movu       [r2 + r3 * 0 + 80], m0
    movu       [r2 + r3 * 1 + 80], m1
    movu       [r2 + r3 * 2 + 80], m2
    movu       [r2 + r4 + 80], m3

    lea        r0, [r0 + r1 * 4]
    lea        r2, [r2 + r3 * 4]

    dec        r6d
    jnz        .loop
    RET

