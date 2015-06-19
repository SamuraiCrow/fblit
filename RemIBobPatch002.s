


*-----------------------------------------------------------------------------
*
*	RemIBobPatch.s V0.2 11.07.99
*
*	remove my fast BOBs
*
*-----------------------------------------------------------------------------
*
* Input:		a0 - *Bob
*			a1 - *rp
*			a2 - *vp
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
l_OldRemIBob	dc.l	0					;*AddBob
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
		bne.s		ribps0
		
		move.l		(l_OldRemIBob,pc),-(sp)
		rts
ribps0:		
		movem.l		a0/a5/a6,-(sp)			;save stuff
		move.l		(l_OldRemIBob,pc),a5
		jsr		(a5)				;call RemIBob
		
		movem.l		(sp)+,a0/a5
		move.l		(l_FBlitBase,pc),a6
		jsr		(_LVORemFastBOB,a6)		;deal with my BOBs
		
		move.l		(sp)+,a6
		rts
		
		
