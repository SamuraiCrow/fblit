

*-----------------------------------------------------------------------------
*
*	FAreaEnd.s V1.25 15.02.2000
*
*-----------------------------------------------------------------------------
*
* Input:		a1- rastport
*	
* Output:		-
*
* Trashed:		-
*
*-----------------------------------------------------------------------------


	include "graphics/gfx.i"
	include "graphics/rastport.i"
	include "graphics/gfxbase.i"
	include	"graphics/clip.i"

	include "lvo/graphics_lib.i"
	include "lvo/exec_lib.i"
	include "lvo/layers_lib.i"
	include	"fblit_library/fblit_lib.i"

	include "exec/memory.i"

	include "hardware/custom.i"
	include blitem/be_custom.i

	machine MC68030


Entry:		bra.s		Main


w_FField	dc.w	0					;non-Chip range
l_OldAreaEnd	dc.l	0
l_FastCnt	dc.l	0					;counter
l_ProcCnt	dc.l	0
l_PassCnt	dc.l	0
l_BlitEm	dc.l	0
l_Pad2		dc.l	0
l_Pad3		dc.l	0
l_Flags		dc.l	0					;control
l_user3		dc.l	0
l_FBlitBase	dc.l	0
		
ACTIVE			equ	1				;patch activation
FPASSON			equ	2				;pass on fast!!!
	

Main:		btst		#ACTIVE,(l_Flags+3,pc)
		bne.s		mains0
		
		move.l		(l_OldAreaEnd,pc),-(sp)
		rts
mains0:	
		movem.l		d1/a0/a1/a5,-(sp)		;store reg's

		move.l		#$00,-(sp)			;my tmpras memory!
		move.l		#$00,-(sp)			;old tmpras memory

		move.l		(rp_TmpRas,a1),a5
		tst.l		a5
		beq.s		OldAE				;--> no tmp ras
		
		move.l		(tr_RasPtr,a5),d0
		move.w		(w_FField,pc),d1
		move.l		d0,(sp)				;set old tmpras memory
		bftst		d0{0:d1}
		beq.s		OldAE				;--> chip tmpras
		
	;allocate new tmpras
	
		move.l		(tr_Size,a5),d0
		move.l		#MEMF_CHIP,d1
		move.l		a6,-(sp)
		move.l		(gb_ExecBase,a6),a6
		jsr		(_LVOAllocMem,a6)
		
		move.l		(sp)+,a6			;recover gfxbase
		move.l		($10,sp),a1			;recover rastport
		
		tst.l		d0
		beq.s		BadAE				;--> no memory!!!
		
		move.l		d0,(4,sp)			;save my tmpras memory
		move.l		d0,(tr_RasPtr,a5)		;modify rastport tmpras
		bra.s		OldAE				;--> dooo it.
		
	;
	;bad areaend
	;		
			
	
BadAE:
		movea.l		(rp_AreaInfo,a1),a5			;a5- areainfo
		clr.w		(ai_Count,a5)
		move.l		(ai_VctrTbl,a5),(ai_VctrPtr,a5)
		move.l		(ai_FlagTbl,a5),(ai_FlagPtr,a5)
		move.l		(rp_Layer,a1),a5
		moveq		#$00,d0
		bra.s		AEExit
		
	;
	;do old areaend
	;
	
OldAE:		
		move.l		(l_OldAreaEnd,pc),a5
		jsr		(a5)
		move.l		($10,sp),a1
		
	;exit		
		
AEExit:		
		move.l		d0,-(sp)				;save result
		jsr		(_LVOWaitBlit,a6)			;just in case...
		
		move.l		(4,sp),d1				;d1 - old tmpras memory
		beq.s		fix04					;--> no old tmpras!
		
		move.l		(rp_TmpRas,a1),a5			;a5 - tmpras
		move.l		d1,(tr_RasPtr,a5)			;restore old tmpras
		
		move.l		(8,sp),d1				;d1 - my tmpras memory
		beq.s		fix04					;--> no memory
		
		move.l		(tr_Size,a5),d0				;get rid of my tmpras
		move.l		a6,a5
		move.l		(gb_ExecBase,a5),a6
		move.l		d1,a1
		jsr		(_LVOFreeMem,a6)
		
		move.l		a5,a6
fix04:		
		move.l		(sp),d0					;recover d0
		add.w		#$0c,sp					;adjust stack		
		movem.l		(sp)+,d1/a0/a1/a5		
		rts
		





		
		