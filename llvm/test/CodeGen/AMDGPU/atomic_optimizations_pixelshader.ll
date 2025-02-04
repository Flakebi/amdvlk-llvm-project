; Modifications Copyright (c) 2020 Advanced Micro Devices, Inc. All rights reserved.
; Notified per clause 4(b) of the license.
; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mtriple=amdgcn-- -amdgpu-atomic-optimizations=true -verify-machineinstrs -simplifycfg-require-and-preserve-domtree=1 < %s | FileCheck -enable-var-scope -check-prefixes=GFX7 %s
; RUN: llc  -mtriple=amdgcn-- -mcpu=tonga -mattr=-flat-for-global -amdgpu-atomic-optimizations=true -verify-machineinstrs -simplifycfg-require-and-preserve-domtree=1 < %s | FileCheck -enable-var-scope -check-prefixes=GFX8 %s
; RUN: llc -mtriple=amdgcn-- -mcpu=gfx900 -mattr=-flat-for-global -amdgpu-atomic-optimizations=true -verify-machineinstrs -simplifycfg-require-and-preserve-domtree=1 < %s | FileCheck -enable-var-scope -check-prefixes=GFX9 %s
; RUN: llc -mtriple=amdgcn-- -mcpu=gfx1010 -mattr=-wavefrontsize32,+wavefrontsize64 -mattr=-flat-for-global -amdgpu-atomic-optimizations=true -verify-machineinstrs -simplifycfg-require-and-preserve-domtree=1 < %s | FileCheck -enable-var-scope -check-prefixes=GFX1064 %s
; RUN: llc -mtriple=amdgcn-- -mcpu=gfx1010 -mattr=+wavefrontsize32,-wavefrontsize64 -mattr=-flat-for-global -amdgpu-atomic-optimizations=true -verify-machineinstrs -simplifycfg-require-and-preserve-domtree=1 < %s | FileCheck -enable-var-scope -check-prefixes=GFX1032 %s

declare i1 @llvm.amdgcn.wqm.vote(i1)
declare i32 @llvm.amdgcn.raw.buffer.atomic.add(i32, <4 x i32>, i32, i32, i32 immarg)
declare void @llvm.amdgcn.raw.buffer.store.f32(float, <4 x i32>, i32, i32, i32 immarg)

; Show what the atomic optimization pass will do for raw buffers.

define amdgpu_ps void @add_i32_constant(<4 x i32> inreg %out, <4 x i32> inreg %inout) {
; GFX7-LABEL: add_i32_constant:
; GFX7:       ; %bb.0: ; %entry
; GFX7-NEXT:    s_mov_b64 s[10:11], exec
; GFX7-NEXT:    ; implicit-def: $vgpr0
; GFX7-NEXT:    s_and_saveexec_b64 s[8:9], s[10:11]
; GFX7-NEXT:    s_cbranch_execz BB0_4
; GFX7-NEXT:  ; %bb.1:
; GFX7-NEXT:    s_mov_b64 s[12:13], exec
; GFX7-NEXT:    v_mbcnt_lo_u32_b32_e64 v0, s12, 0
; GFX7-NEXT:    v_mbcnt_hi_u32_b32_e32 v0, s13, v0
; GFX7-NEXT:    v_cmp_eq_u32_e32 vcc, 0, v0
; GFX7-NEXT:    ; implicit-def: $vgpr1
; GFX7-NEXT:    s_and_saveexec_b64 s[10:11], vcc
; GFX7-NEXT:    s_cbranch_execz BB0_3
; GFX7-NEXT:  ; %bb.2:
; GFX7-NEXT:    s_bcnt1_i32_b64 s12, s[12:13]
; GFX7-NEXT:    v_mul_u32_u24_e64 v1, s12, 5
; GFX7-NEXT:    buffer_atomic_add v1, off, s[4:7], 0 glc
; GFX7-NEXT:  BB0_3:
; GFX7-NEXT:    s_or_b64 exec, exec, s[10:11]
; GFX7-NEXT:    s_waitcnt vmcnt(0)
; GFX7-NEXT:    v_readfirstlane_b32 s4, v1
; GFX7-NEXT:    v_mad_u32_u24 v0, v0, 5, s4
; GFX7-NEXT:  BB0_4: ; %Flow
; GFX7-NEXT:    s_or_b64 exec, exec, s[8:9]
; GFX7-NEXT:    s_wqm_b64 s[4:5], -1
; GFX7-NEXT:    s_andn2_b64 vcc, exec, s[4:5]
; GFX7-NEXT:    s_cbranch_vccnz BB0_6
; GFX7-NEXT:  ; %bb.5: ; %if
; GFX7-NEXT:    buffer_store_dword v0, off, s[0:3], 0
; GFX7-NEXT:  BB0_6: ; %UnifiedReturnBlock
; GFX7-NEXT:    s_endpgm
;
; GFX8-LABEL: add_i32_constant:
; GFX8:       ; %bb.0: ; %entry
; GFX8-NEXT:    s_mov_b64 s[10:11], exec
; GFX8-NEXT:    ; implicit-def: $vgpr0
; GFX8-NEXT:    s_and_saveexec_b64 s[8:9], s[10:11]
; GFX8-NEXT:    s_cbranch_execz BB0_4
; GFX8-NEXT:  ; %bb.1:
; GFX8-NEXT:    s_mov_b64 s[12:13], exec
; GFX8-NEXT:    v_mbcnt_lo_u32_b32 v0, s12, 0
; GFX8-NEXT:    v_mbcnt_hi_u32_b32 v0, s13, v0
; GFX8-NEXT:    v_cmp_eq_u32_e32 vcc, 0, v0
; GFX8-NEXT:    ; implicit-def: $vgpr1
; GFX8-NEXT:    s_and_saveexec_b64 s[10:11], vcc
; GFX8-NEXT:    s_cbranch_execz BB0_3
; GFX8-NEXT:  ; %bb.2:
; GFX8-NEXT:    s_bcnt1_i32_b64 s12, s[12:13]
; GFX8-NEXT:    v_mul_u32_u24_e64 v1, s12, 5
; GFX8-NEXT:    buffer_atomic_add v1, off, s[4:7], 0 glc
; GFX8-NEXT:  BB0_3:
; GFX8-NEXT:    s_or_b64 exec, exec, s[10:11]
; GFX8-NEXT:    s_waitcnt vmcnt(0)
; GFX8-NEXT:    v_readfirstlane_b32 s4, v1
; GFX8-NEXT:    v_mad_u32_u24 v0, v0, 5, s4
; GFX8-NEXT:  BB0_4: ; %Flow
; GFX8-NEXT:    s_or_b64 exec, exec, s[8:9]
; GFX8-NEXT:    s_wqm_b64 s[4:5], -1
; GFX8-NEXT:    s_andn2_b64 vcc, exec, s[4:5]
; GFX8-NEXT:    s_cbranch_vccnz BB0_6
; GFX8-NEXT:  ; %bb.5: ; %if
; GFX8-NEXT:    buffer_store_dword v0, off, s[0:3], 0
; GFX8-NEXT:  BB0_6: ; %UnifiedReturnBlock
; GFX8-NEXT:    s_endpgm
;
; GFX9-LABEL: add_i32_constant:
; GFX9:       ; %bb.0: ; %entry
; GFX9-NEXT:    s_mov_b64 s[10:11], exec
; GFX9-NEXT:    ; implicit-def: $vgpr0
; GFX9-NEXT:    s_and_saveexec_b64 s[8:9], s[10:11]
; GFX9-NEXT:    s_cbranch_execz BB0_4
; GFX9-NEXT:  ; %bb.1:
; GFX9-NEXT:    s_mov_b64 s[12:13], exec
; GFX9-NEXT:    v_mbcnt_lo_u32_b32 v0, s12, 0
; GFX9-NEXT:    v_mbcnt_hi_u32_b32 v0, s13, v0
; GFX9-NEXT:    v_cmp_eq_u32_e32 vcc, 0, v0
; GFX9-NEXT:    ; implicit-def: $vgpr1
; GFX9-NEXT:    s_and_saveexec_b64 s[10:11], vcc
; GFX9-NEXT:    s_cbranch_execz BB0_3
; GFX9-NEXT:  ; %bb.2:
; GFX9-NEXT:    s_bcnt1_i32_b64 s12, s[12:13]
; GFX9-NEXT:    v_mul_u32_u24_e64 v1, s12, 5
; GFX9-NEXT:    buffer_atomic_add v1, off, s[4:7], 0 glc
; GFX9-NEXT:  BB0_3:
; GFX9-NEXT:    s_or_b64 exec, exec, s[10:11]
; GFX9-NEXT:    s_waitcnt vmcnt(0)
; GFX9-NEXT:    v_readfirstlane_b32 s4, v1
; GFX9-NEXT:    v_mad_u32_u24 v0, v0, 5, s4
; GFX9-NEXT:  BB0_4: ; %Flow
; GFX9-NEXT:    s_or_b64 exec, exec, s[8:9]
; GFX9-NEXT:    s_wqm_b64 s[4:5], -1
; GFX9-NEXT:    s_andn2_b64 vcc, exec, s[4:5]
; GFX9-NEXT:    s_cbranch_vccnz BB0_6
; GFX9-NEXT:  ; %bb.5: ; %if
; GFX9-NEXT:    buffer_store_dword v0, off, s[0:3], 0
; GFX9-NEXT:  BB0_6: ; %UnifiedReturnBlock
; GFX9-NEXT:    s_endpgm
;
; GFX1064-LABEL: add_i32_constant:
; GFX1064:       ; %bb.0: ; %entry
; GFX1064-NEXT:    s_mov_b64 s[10:11], exec
; GFX1064-NEXT:    ; implicit-def: $vgpr0
; GFX1064-NEXT:    s_and_saveexec_b64 s[8:9], s[10:11]
; GFX1064-NEXT:    s_cbranch_execz BB0_4
; GFX1064-NEXT:  ; %bb.1:
; GFX1064-NEXT:    s_mov_b64 s[12:13], exec
; GFX1064-NEXT:    ; implicit-def: $vgpr1
; GFX1064-NEXT:    v_mbcnt_lo_u32_b32_e64 v0, s12, 0
; GFX1064-NEXT:    v_mbcnt_hi_u32_b32_e64 v0, s13, v0
; GFX1064-NEXT:    v_cmp_eq_u32_e32 vcc, 0, v0
; GFX1064-NEXT:    s_and_saveexec_b64 s[28:29], vcc
; GFX1064-NEXT:    s_cbranch_execz BB0_3
; GFX1064-NEXT:  ; %bb.2:
; GFX1064-NEXT:    s_bcnt1_i32_b64 s12, s[12:13]
; GFX1064-NEXT:    v_mul_u32_u24_e64 v1, s12, 5
; GFX1064-NEXT:    buffer_atomic_add v1, off, s[4:7], 0 glc
; GFX1064-NEXT:  BB0_3:
; GFX1064-NEXT:    s_waitcnt_depctr 0xffe3
; GFX1064-NEXT:    s_or_b64 exec, exec, s[28:29]
; GFX1064-NEXT:    s_waitcnt vmcnt(0)
; GFX1064-NEXT:    v_readfirstlane_b32 s4, v1
; GFX1064-NEXT:    v_mad_u32_u24 v0, v0, 5, s4
; GFX1064-NEXT:  BB0_4: ; %Flow
; GFX1064-NEXT:    s_or_b64 exec, exec, s[8:9]
; GFX1064-NEXT:    s_wqm_b64 s[4:5], -1
; GFX1064-NEXT:    s_andn2_b64 vcc, exec, s[4:5]
; GFX1064-NEXT:    s_cbranch_vccnz BB0_6
; GFX1064-NEXT:  ; %bb.5: ; %if
; GFX1064-NEXT:    buffer_store_dword v0, off, s[0:3], 0
; GFX1064-NEXT:  BB0_6: ; %UnifiedReturnBlock
; GFX1064-NEXT:    s_endpgm
;
; GFX1032-LABEL: add_i32_constant:
; GFX1032:       ; %bb.0: ; %entry
; GFX1032-NEXT:    s_mov_b32 s9, exec_lo
; GFX1032-NEXT:    ; implicit-def: $vgpr0
; GFX1032-NEXT:    s_and_saveexec_b32 s8, s9
; GFX1032-NEXT:    s_cbranch_execz BB0_4
; GFX1032-NEXT:  ; %bb.1:
; GFX1032-NEXT:    s_mov_b32 s10, exec_lo
; GFX1032-NEXT:    ; implicit-def: $vgpr1
; GFX1032-NEXT:    v_mbcnt_lo_u32_b32_e64 v0, s10, 0
; GFX1032-NEXT:    v_cmp_eq_u32_e32 vcc_lo, 0, v0
; GFX1032-NEXT:    s_and_saveexec_b32 s9, vcc_lo
; GFX1032-NEXT:    s_cbranch_execz BB0_3
; GFX1032-NEXT:  ; %bb.2:
; GFX1032-NEXT:    s_bcnt1_i32_b32 s10, s10
; GFX1032-NEXT:    v_mul_u32_u24_e64 v1, s10, 5
; GFX1032-NEXT:    buffer_atomic_add v1, off, s[4:7], 0 glc
; GFX1032-NEXT:  BB0_3:
; GFX1032-NEXT:    s_waitcnt_depctr 0xffe3
; GFX1032-NEXT:    s_or_b32 exec_lo, exec_lo, s9
; GFX1032-NEXT:    s_waitcnt vmcnt(0)
; GFX1032-NEXT:    v_readfirstlane_b32 s4, v1
; GFX1032-NEXT:    v_mad_u32_u24 v0, v0, 5, s4
; GFX1032-NEXT:  BB0_4: ; %Flow
; GFX1032-NEXT:    s_or_b32 exec_lo, exec_lo, s8
; GFX1032-NEXT:    s_wqm_b32 s4, -1
; GFX1032-NEXT:    s_andn2_b32 vcc_lo, exec_lo, s4
; GFX1032-NEXT:    s_cbranch_vccnz BB0_6
; GFX1032-NEXT:  ; %bb.5: ; %if
; GFX1032-NEXT:    buffer_store_dword v0, off, s[0:3], 0
; GFX1032-NEXT:  BB0_6: ; %UnifiedReturnBlock
; GFX1032-NEXT:    s_endpgm
entry:
  %cond1 = call i1 @llvm.amdgcn.wqm.vote(i1 true)
  %old = call i32 @llvm.amdgcn.raw.buffer.atomic.add(i32 5, <4 x i32> %inout, i32 0, i32 0, i32 0)
  %cond2 = call i1 @llvm.amdgcn.wqm.vote(i1 true)
  %cond = and i1 %cond1, %cond2
  br i1 %cond, label %if, label %else
if:
  %bitcast = bitcast i32 %old to float
  call void @llvm.amdgcn.raw.buffer.store.f32(float %bitcast, <4 x i32> %out, i32 0, i32 0, i32 0)
  ret void
else:
  ret void
}

define amdgpu_ps void @add_i32_varying(<4 x i32> inreg %out, <4 x i32> inreg %inout, i32 %val) {
; GFX7-LABEL: add_i32_varying:
; GFX7:       ; %bb.0: ; %entry
; GFX7-NEXT:    s_wqm_b64 s[8:9], -1
; GFX7-NEXT:    buffer_atomic_add v0, off, s[4:7], 0 glc
; GFX7-NEXT:    s_andn2_b64 vcc, exec, s[8:9]
; GFX7-NEXT:    s_cbranch_vccnz BB1_2
; GFX7-NEXT:  ; %bb.1: ; %if
; GFX7-NEXT:    s_waitcnt vmcnt(0)
; GFX7-NEXT:    buffer_store_dword v0, off, s[0:3], 0
; GFX7-NEXT:  BB1_2: ; %else
; GFX7-NEXT:    s_endpgm
;
; GFX8-LABEL: add_i32_varying:
; GFX8:       ; %bb.0: ; %entry
; GFX8-NEXT:    s_mov_b64 s[10:11], exec
; GFX8-NEXT:    ; implicit-def: $vgpr3
; GFX8-NEXT:    v_mov_b32_e32 v2, v0
; GFX8-NEXT:    s_and_saveexec_b64 s[8:9], s[10:11]
; GFX8-NEXT:    s_cbranch_execz BB1_4
; GFX8-NEXT:  ; %bb.1:
; GFX8-NEXT:    s_mov_b64 s[10:11], exec
; GFX8-NEXT:    s_or_saveexec_b64 s[12:13], -1
; GFX8-NEXT:    v_mov_b32_e32 v1, 0
; GFX8-NEXT:    s_mov_b64 exec, s[12:13]
; GFX8-NEXT:    v_mbcnt_lo_u32_b32 v0, s10, 0
; GFX8-NEXT:    v_mbcnt_hi_u32_b32 v0, s11, v0
; GFX8-NEXT:    s_not_b64 exec, exec
; GFX8-NEXT:    v_mov_b32_e32 v2, 0
; GFX8-NEXT:    s_not_b64 exec, exec
; GFX8-NEXT:    s_or_saveexec_b64 s[10:11], -1
; GFX8-NEXT:    v_add_u32_dpp v2, vcc, v2, v2 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:0
; GFX8-NEXT:    s_nop 1
; GFX8-NEXT:    v_add_u32_dpp v2, vcc, v2, v2 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:0
; GFX8-NEXT:    s_nop 1
; GFX8-NEXT:    v_add_u32_dpp v2, vcc, v2, v2 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:0
; GFX8-NEXT:    s_nop 1
; GFX8-NEXT:    v_add_u32_dpp v2, vcc, v2, v2 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:0
; GFX8-NEXT:    s_nop 1
; GFX8-NEXT:    v_add_u32_dpp v2, vcc, v2, v2 row_bcast:15 row_mask:0xa bank_mask:0xf
; GFX8-NEXT:    s_nop 1
; GFX8-NEXT:    v_add_u32_dpp v2, vcc, v2, v2 row_bcast:31 row_mask:0xc bank_mask:0xf
; GFX8-NEXT:    v_readlane_b32 s12, v2, 63
; GFX8-NEXT:    s_nop 0
; GFX8-NEXT:    v_mov_b32_dpp v1, v2 wave_shr:1 row_mask:0xf bank_mask:0xf
; GFX8-NEXT:    s_mov_b64 exec, s[10:11]
; GFX8-NEXT:    v_cmp_eq_u32_e32 vcc, 0, v0
; GFX8-NEXT:    ; implicit-def: $vgpr0
; GFX8-NEXT:    s_and_saveexec_b64 s[10:11], vcc
; GFX8-NEXT:    s_cbranch_execz BB1_3
; GFX8-NEXT:  ; %bb.2:
; GFX8-NEXT:    v_mov_b32_e32 v0, s12
; GFX8-NEXT:    buffer_atomic_add v0, off, s[4:7], 0 glc
; GFX8-NEXT:  BB1_3:
; GFX8-NEXT:    s_or_b64 exec, exec, s[10:11]
; GFX8-NEXT:    s_waitcnt vmcnt(0)
; GFX8-NEXT:    v_readfirstlane_b32 s4, v0
; GFX8-NEXT:    v_mov_b32_e32 v0, v1
; GFX8-NEXT:    v_add_u32_e32 v3, vcc, s4, v0
; GFX8-NEXT:  BB1_4: ; %Flow
; GFX8-NEXT:    s_or_b64 exec, exec, s[8:9]
; GFX8-NEXT:    s_wqm_b64 s[4:5], -1
; GFX8-NEXT:    s_andn2_b64 vcc, exec, s[4:5]
; GFX8-NEXT:    s_cbranch_vccnz BB1_6
; GFX8-NEXT:  ; %bb.5: ; %if
; GFX8-NEXT:    buffer_store_dword v3, off, s[0:3], 0
; GFX8-NEXT:  BB1_6: ; %UnifiedReturnBlock
; GFX8-NEXT:    s_endpgm
;
; GFX9-LABEL: add_i32_varying:
; GFX9:       ; %bb.0: ; %entry
; GFX9-NEXT:    s_mov_b64 s[10:11], exec
; GFX9-NEXT:    ; implicit-def: $vgpr3
; GFX9-NEXT:    v_mov_b32_e32 v2, v0
; GFX9-NEXT:    s_and_saveexec_b64 s[8:9], s[10:11]
; GFX9-NEXT:    s_cbranch_execz BB1_4
; GFX9-NEXT:  ; %bb.1:
; GFX9-NEXT:    s_mov_b64 s[10:11], exec
; GFX9-NEXT:    s_or_saveexec_b64 s[12:13], -1
; GFX9-NEXT:    v_mov_b32_e32 v1, 0
; GFX9-NEXT:    s_mov_b64 exec, s[12:13]
; GFX9-NEXT:    v_mbcnt_lo_u32_b32 v0, s10, 0
; GFX9-NEXT:    v_mbcnt_hi_u32_b32 v0, s11, v0
; GFX9-NEXT:    s_not_b64 exec, exec
; GFX9-NEXT:    v_mov_b32_e32 v2, 0
; GFX9-NEXT:    s_not_b64 exec, exec
; GFX9-NEXT:    s_or_saveexec_b64 s[10:11], -1
; GFX9-NEXT:    v_add_u32_dpp v2, v2, v2 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:0
; GFX9-NEXT:    s_nop 1
; GFX9-NEXT:    v_add_u32_dpp v2, v2, v2 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:0
; GFX9-NEXT:    s_nop 1
; GFX9-NEXT:    v_add_u32_dpp v2, v2, v2 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:0
; GFX9-NEXT:    s_nop 1
; GFX9-NEXT:    v_add_u32_dpp v2, v2, v2 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:0
; GFX9-NEXT:    s_nop 1
; GFX9-NEXT:    v_add_u32_dpp v2, v2, v2 row_bcast:15 row_mask:0xa bank_mask:0xf
; GFX9-NEXT:    s_nop 1
; GFX9-NEXT:    v_add_u32_dpp v2, v2, v2 row_bcast:31 row_mask:0xc bank_mask:0xf
; GFX9-NEXT:    v_readlane_b32 s12, v2, 63
; GFX9-NEXT:    s_nop 0
; GFX9-NEXT:    v_mov_b32_dpp v1, v2 wave_shr:1 row_mask:0xf bank_mask:0xf
; GFX9-NEXT:    s_mov_b64 exec, s[10:11]
; GFX9-NEXT:    v_cmp_eq_u32_e32 vcc, 0, v0
; GFX9-NEXT:    ; implicit-def: $vgpr0
; GFX9-NEXT:    s_and_saveexec_b64 s[10:11], vcc
; GFX9-NEXT:    s_cbranch_execz BB1_3
; GFX9-NEXT:  ; %bb.2:
; GFX9-NEXT:    v_mov_b32_e32 v0, s12
; GFX9-NEXT:    buffer_atomic_add v0, off, s[4:7], 0 glc
; GFX9-NEXT:  BB1_3:
; GFX9-NEXT:    s_or_b64 exec, exec, s[10:11]
; GFX9-NEXT:    s_waitcnt vmcnt(0)
; GFX9-NEXT:    v_readfirstlane_b32 s4, v0
; GFX9-NEXT:    v_mov_b32_e32 v0, v1
; GFX9-NEXT:    v_add_u32_e32 v3, s4, v0
; GFX9-NEXT:  BB1_4: ; %Flow
; GFX9-NEXT:    s_or_b64 exec, exec, s[8:9]
; GFX9-NEXT:    s_wqm_b64 s[4:5], -1
; GFX9-NEXT:    s_andn2_b64 vcc, exec, s[4:5]
; GFX9-NEXT:    s_cbranch_vccnz BB1_6
; GFX9-NEXT:  ; %bb.5: ; %if
; GFX9-NEXT:    buffer_store_dword v3, off, s[0:3], 0
; GFX9-NEXT:  BB1_6: ; %UnifiedReturnBlock
; GFX9-NEXT:    s_endpgm
;
; GFX1064-LABEL: add_i32_varying:
; GFX1064:       ; %bb.0: ; %entry
; GFX1064-NEXT:    s_mov_b64 s[10:11], exec
; GFX1064-NEXT:    ; implicit-def: $vgpr4
; GFX1064-NEXT:    v_mov_b32_e32 v2, v0
; GFX1064-NEXT:    s_and_saveexec_b64 s[8:9], s[10:11]
; GFX1064-NEXT:    s_cbranch_execz BB1_4
; GFX1064-NEXT:  ; %bb.1:
; GFX1064-NEXT:    s_mov_b64 s[10:11], exec
; GFX1064-NEXT:    s_or_saveexec_b64 s[12:13], -1
; GFX1064-NEXT:    v_mov_b32_e32 v1, 0
; GFX1064-NEXT:    s_mov_b64 exec, s[12:13]
; GFX1064-NEXT:    v_mbcnt_lo_u32_b32_e64 v0, s10, 0
; GFX1064-NEXT:    v_mbcnt_hi_u32_b32_e64 v0, s11, v0
; GFX1064-NEXT:    s_not_b64 exec, exec
; GFX1064-NEXT:    v_mov_b32_e32 v2, 0
; GFX1064-NEXT:    s_not_b64 exec, exec
; GFX1064-NEXT:    s_or_saveexec_b64 s[10:11], -1
; GFX1064-NEXT:    v_add_nc_u32_dpp v2, v2, v2 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:0
; GFX1064-NEXT:    v_add_nc_u32_dpp v2, v2, v2 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:0
; GFX1064-NEXT:    v_add_nc_u32_dpp v2, v2, v2 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:0
; GFX1064-NEXT:    v_add_nc_u32_dpp v2, v2, v2 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:0
; GFX1064-NEXT:    v_mov_b32_e32 v3, v2
; GFX1064-NEXT:    v_permlanex16_b32 v3, v3, -1, -1
; GFX1064-NEXT:    v_add_nc_u32_dpp v2, v3, v2 quad_perm:[0,1,2,3] row_mask:0xa bank_mask:0xf
; GFX1064-NEXT:    v_readlane_b32 s12, v2, 31
; GFX1064-NEXT:    v_mov_b32_e32 v3, s12
; GFX1064-NEXT:    v_add_nc_u32_dpp v2, v3, v2 quad_perm:[0,1,2,3] row_mask:0xc bank_mask:0xf
; GFX1064-NEXT:    v_mov_b32_dpp v1, v2 row_shr:1 row_mask:0xf bank_mask:0xf
; GFX1064-NEXT:    v_readlane_b32 s12, v2, 15
; GFX1064-NEXT:    v_readlane_b32 s13, v2, 31
; GFX1064-NEXT:    v_writelane_b32 v1, s12, 16
; GFX1064-NEXT:    v_readlane_b32 s12, v2, 63
; GFX1064-NEXT:    v_writelane_b32 v1, s13, 32
; GFX1064-NEXT:    v_readlane_b32 s13, v2, 47
; GFX1064-NEXT:    v_writelane_b32 v1, s13, 48
; GFX1064-NEXT:    s_mov_b64 exec, s[10:11]
; GFX1064-NEXT:    v_cmp_eq_u32_e32 vcc, 0, v0
; GFX1064-NEXT:    ; implicit-def: $vgpr0
; GFX1064-NEXT:    s_and_saveexec_b64 s[28:29], vcc
; GFX1064-NEXT:    s_cbranch_execz BB1_3
; GFX1064-NEXT:  ; %bb.2:
; GFX1064-NEXT:    v_mov_b32_e32 v0, s12
; GFX1064-NEXT:    buffer_atomic_add v0, off, s[4:7], 0 glc
; GFX1064-NEXT:  BB1_3:
; GFX1064-NEXT:    s_waitcnt_depctr 0xffe3
; GFX1064-NEXT:    s_or_b64 exec, exec, s[28:29]
; GFX1064-NEXT:    s_waitcnt vmcnt(0)
; GFX1064-NEXT:    v_readfirstlane_b32 s4, v0
; GFX1064-NEXT:    v_mov_b32_e32 v0, v1
; GFX1064-NEXT:    v_add_nc_u32_e32 v4, s4, v0
; GFX1064-NEXT:  BB1_4: ; %Flow
; GFX1064-NEXT:    s_or_b64 exec, exec, s[8:9]
; GFX1064-NEXT:    s_wqm_b64 s[4:5], -1
; GFX1064-NEXT:    s_andn2_b64 vcc, exec, s[4:5]
; GFX1064-NEXT:    s_cbranch_vccnz BB1_6
; GFX1064-NEXT:  ; %bb.5: ; %if
; GFX1064-NEXT:    buffer_store_dword v4, off, s[0:3], 0
; GFX1064-NEXT:  BB1_6: ; %UnifiedReturnBlock
; GFX1064-NEXT:    s_endpgm
;
; GFX1032-LABEL: add_i32_varying:
; GFX1032:       ; %bb.0: ; %entry
; GFX1032-NEXT:    s_mov_b32 s9, exec_lo
; GFX1032-NEXT:    ; implicit-def: $vgpr4
; GFX1032-NEXT:    v_mov_b32_e32 v2, v0
; GFX1032-NEXT:    s_and_saveexec_b32 s8, s9
; GFX1032-NEXT:    s_cbranch_execz BB1_4
; GFX1032-NEXT:  ; %bb.1:
; GFX1032-NEXT:    s_mov_b32 s9, exec_lo
; GFX1032-NEXT:    s_or_saveexec_b32 s10, -1
; GFX1032-NEXT:    v_mov_b32_e32 v1, 0
; GFX1032-NEXT:    s_mov_b32 exec_lo, s10
; GFX1032-NEXT:    v_mbcnt_lo_u32_b32_e64 v0, s9, 0
; GFX1032-NEXT:    s_not_b32 exec_lo, exec_lo
; GFX1032-NEXT:    v_mov_b32_e32 v2, 0
; GFX1032-NEXT:    s_not_b32 exec_lo, exec_lo
; GFX1032-NEXT:    s_or_saveexec_b32 s9, -1
; GFX1032-NEXT:    v_add_nc_u32_dpp v2, v2, v2 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:0
; GFX1032-NEXT:    v_add_nc_u32_dpp v2, v2, v2 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:0
; GFX1032-NEXT:    v_add_nc_u32_dpp v2, v2, v2 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:0
; GFX1032-NEXT:    v_add_nc_u32_dpp v2, v2, v2 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:0
; GFX1032-NEXT:    v_mov_b32_e32 v3, v2
; GFX1032-NEXT:    v_permlanex16_b32 v3, v3, -1, -1
; GFX1032-NEXT:    v_add_nc_u32_dpp v2, v3, v2 quad_perm:[0,1,2,3] row_mask:0xa bank_mask:0xf
; GFX1032-NEXT:    v_readlane_b32 s10, v2, 31
; GFX1032-NEXT:    v_mov_b32_dpp v1, v2 row_shr:1 row_mask:0xf bank_mask:0xf
; GFX1032-NEXT:    v_readlane_b32 s11, v2, 15
; GFX1032-NEXT:    v_writelane_b32 v1, s11, 16
; GFX1032-NEXT:    s_mov_b32 exec_lo, s9
; GFX1032-NEXT:    v_cmp_eq_u32_e32 vcc_lo, 0, v0
; GFX1032-NEXT:    ; implicit-def: $vgpr0
; GFX1032-NEXT:    s_and_saveexec_b32 s9, vcc_lo
; GFX1032-NEXT:    s_cbranch_execz BB1_3
; GFX1032-NEXT:  ; %bb.2:
; GFX1032-NEXT:    v_mov_b32_e32 v0, s10
; GFX1032-NEXT:    buffer_atomic_add v0, off, s[4:7], 0 glc
; GFX1032-NEXT:  BB1_3:
; GFX1032-NEXT:    s_waitcnt_depctr 0xffe3
; GFX1032-NEXT:    s_or_b32 exec_lo, exec_lo, s9
; GFX1032-NEXT:    s_waitcnt vmcnt(0)
; GFX1032-NEXT:    v_readfirstlane_b32 s4, v0
; GFX1032-NEXT:    v_mov_b32_e32 v0, v1
; GFX1032-NEXT:    v_add_nc_u32_e32 v4, s4, v0
; GFX1032-NEXT:  BB1_4: ; %Flow
; GFX1032-NEXT:    s_or_b32 exec_lo, exec_lo, s8
; GFX1032-NEXT:    s_wqm_b32 s4, -1
; GFX1032-NEXT:    s_andn2_b32 vcc_lo, exec_lo, s4
; GFX1032-NEXT:    s_cbranch_vccnz BB1_6
; GFX1032-NEXT:  ; %bb.5: ; %if
; GFX1032-NEXT:    buffer_store_dword v4, off, s[0:3], 0
; GFX1032-NEXT:  BB1_6: ; %UnifiedReturnBlock
; GFX1032-NEXT:    s_endpgm
entry:
  %cond1 = call i1 @llvm.amdgcn.wqm.vote(i1 true)
  %old = call i32 @llvm.amdgcn.raw.buffer.atomic.add(i32 %val, <4 x i32> %inout, i32 0, i32 0, i32 0)
  %cond2 = call i1 @llvm.amdgcn.wqm.vote(i1 true)
  %cond = and i1 %cond1, %cond2
  br i1 %cond, label %if, label %else
if:
  %bitcast = bitcast i32 %old to float
  call void @llvm.amdgcn.raw.buffer.store.f32(float %bitcast, <4 x i32> %out, i32 0, i32 0, i32 0)
  ret void
else:
  ret void
}
