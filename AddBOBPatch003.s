


*-----------------------------------------------------------------------------
*
*	AddBOBPatch.s V0.3 11.07.99
*
*	AddBOBPatch to convert fast vsprite images to chip
*
*-----------------------------------------------------------------------------
*
* Input:		a0 - *Bob
*			a1 - *rp
*
* Output:		-
*
* Trashed:		-
*
*-----------------------------------------------------------------------------



	machine mc68030

	include "lvo/exec_lib.i"
	include	"lvo/graphics_lib.i"
	
	include	"graphics/gfxbase.i"
	include	"graphics/gels.i"
	
	include "exec/memory.i"
	
	include	"hardware/custom.i"
	include	"hardware/blit.i"

	include fblit_library/fblit_lib.i
	include fblit_library/fblitbase.i

	cnop	0,4

Entry:		bra.s		main

w_FField	dc.w	0					;non-Chip range
l_OldAddBob	dc.l	0					;*AddBob
l_LineCnt	dc.l	0					;counters
l_ProcCnt	dc.l	0
l_PassCnt	dc.l	0
l_BlitEm	dc.l	0					;BlitEm
l_Debug 	dc.l	0					;debug output
l_user2 	dc.l	0
l_Flags 	dc.l	0					;control flags
l_user3		dc.l	0
l_FBlitBase	dc.l	0					;fblitbase

ACTIVE			equ	1				;patch activation
CBLITTER		equ	2				;use blitter in chip



	;
	;main
	;

main:		
		btst		#ACTIVE,(l_Flags+3,pc)
		beq.s		qbx1				;--> inactive

		move.l		a6,-(sp)
		move.l		(l_FBlitBase,pc),a6
		jsr		(_LVOAddFastBOB,a6)
		
		move.l		(sp)+,a6
qbx1:
		move.l		(l_OldAddBob,pc),-(sp)
		rts
	

		
		
