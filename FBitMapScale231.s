

*-----------------------------------------------------------------------------
*
*	FBitMapScale.s V2.31 24.02.99
*
*	© Stephen Brookes 1997-99
*
*
*-----------------------------------------------------------------------------
*
* Input:		a0=*BitScaleArgs
*	
* Output:		-
*
* Trashed:		-
*
*-----------------------------------------------------------------------------


	include	"graphics/gfx.i"
	include	"graphics/rastport.i"
	include	"lvo/graphics_lib.i"
	include	"fblit_library/fblit_lib.i"
	include	"graphics/scale.i"

	machine MC68030

	rsreset
	
l_Pad0			rs.l	-1
l_SrcBase		rs.l	-1				;initial source addr offset
l_DstBase		rs.l	-1				;lw 0 addr offset
l_SrcX			rs.l	-1				;current src X (16:frac)
l_SrcXDelta		rs.l	-1				;X delta
l_SrcY			rs.l	-1				;current src Y (16:frac)
l_SrcYDelta		rs.l	-1				;Y delta

w_Pad1			rs.w	-1
w_LastY			rs.w	-1				;last source line scaled

b_Pad2			rs.b	-1	
b_Depth			rs.b	-1				;total depth
b_DstStartBit		rs.b	-1				;start bit in lw 0
b_SpecMask		rs.b	-1				;special planes mask



VSPACE			equ	((__RS-7)/4)*4			;set dataspace size


BADPAD1			equ	$f8c1



Entry:		bra.s		Main


w_FField	dc.w	0					;non-Chip range
l_OldBmpScale	dc.l	0					;*BitMapScale
l_FastCnt	dc.l	0					;counters
l_ProcCnt	dc.l	0
l_PassCnt	dc.l	0
l_Pad4		dc.l	0
l_Pad5		dc.l	0
l_Pad6		dc.l	0
l_Flags		dc.l	0					;control
l_user3		dc.l	0
l_FBlitBase	dc.l	0
				
ACTIVE			equ	1				;patch activation
CPASSON			equ	2				;pass on chip
CPROCESS		equ	3				;process chip
FPASSON			equ	4				;pass on fast!!!
FPROCESS		equ	5				;process fast
FDISCARD		equ	6				;discard fast

	

Main:		
		btst		#ACTIVE,(l_Flags+3,pc)
		bne.s		mfx0
		
		move.l		(l_OldBmpScale,pc),-(sp)
		rts
mfx0:		
		link		a6,#VSPACE
		movem.l		d0-d7/a0-a5,-(sp)		;store reg's
		
		move.l		a0,a5				;save argbase
				
		move.l		(bsa_SrcBitMap,a5),a3
		move.l		(bsa_DestBitMap,a5),a4
		
		moveq		#0,d2				;find depth
		move.b		(bm_Depth,a3),d2
		cmp.b		(bm_Depth,a4),d2
		ble.s		bmfx0
		
		move.b		(bm_Depth,a4),d2
bmfx0:
		subq.w		#$01,d2
		bmi		BadExit				;no zero depth
		
		move.b		d2,(b_Depth,a6)
		
		move.l		a6,a2
		move.l		(l_FBlitBase,pc),a6
		move.l		#$ff,d1
		move.l		a3,a0
		jsr		(_LVOTypeOfBitMap,a6)
		tst.l		d0
		bne.s		FastBS				;fast...
		
		move.l		a4,a0
		jsr		(_LVOTypeOfBitMap,a6)
		tst.l		d0
		bne.s		FastBS
		
		move.l		a2,a6
		btst		#CPROCESS,(l_Flags+3,pc)
		bne.s		DoProc				;process chip...
DoOldBS:
		lea		(l_PassCnt,pc),a1		;all chip...
		addq.l		#$01,(a1)
		bra		OldBS				
FastBS:
		move.l		a2,a6
		move.l		(l_Flags,pc),d0
		btst		#FDISCARD,d0
		bne		BadExit
		
		lea		(l_FastCnt,pc),a1
		addq.l		#$01,(a1)
		
		btst		#FPASSON,d0
		bne		DoOldBS
		
DoProc:		lea		(l_ProcCnt,pc),a1
		addq.l		#$01,(a1)

		move.l		(a6),d7				;fetch gfxbase
		move.w		(bsa_SrcWidth,a5),d0		;get dest size
		beq		BadExit
		move.w		(bsa_XDestFactor,a5),d1
		move.w		(bsa_XSrcFactor,a5),d2
		exg.l		a6,d7
		jsr		(_LVOScalerDiv,a6)
		exg.l		a6,d7
		move.w		d0,(bsa_DestWidth,a5)
		beq		BadExit				;ignore null
		
		move.w		(bsa_SrcHeight,a5),d0
		beq		BadExit
		move.w		(bsa_YDestFactor,a5),d1
		move.w		(bsa_YSrcFactor,a5),d2
		exg.l		a6,d7
		jsr		(_LVOScalerDiv,a6)
		exg.l		a6,d7
		move.w		d0,(bsa_DestHeight,a5)
		beq		BadExit
	
		
	;set up base addr
	
		move.w		(bsa_SrcY,a5),d0		;set source base offset
		mulu.w		(bm_BytesPerRow,a3),d0		;to start of first line
		move.l		d0,(l_SrcBase,a6)
		
		move.w		(bsa_DestY,a5),d1		;set dest base to first
		mulu.w		(bm_BytesPerRow,a4),d1		;lw (line+xlw)
		moveq		#0,d0
		move.w		(bsa_DestX,a5),d0
		move.w		#$1f,d2	
		and.b		d0,d2
		sub.w		d2,d0
		lsr.w		#$03,d0
		add.l		d0,d1
		move.b		d2,(b_DstStartBit,a6)		;dst start bit in 1st lw
		move.l		d1,(l_DstBase,a6)
		
		
	;set up scale factors
	
		moveq		#0,d1
		move.w		(bsa_SrcWidth,a5),d0
		move.w		(bsa_DestWidth,a5),d1
		swap		d0
		clr.w		d0
FLGFix0:	divu.l		d1,d0
		
		moveq		#0,d3
		move.w		(bsa_SrcHeight,a5),d2
		move.w		(bsa_DestHeight,a5),d3
		move.l		d0,(l_SrcXDelta,a6)
		swap		d2
		clr.w		d2
FLGFix1:	divu.l		d3,d2
		move.l		d2,(l_SrcYDelta,a6)
		

	;parse the planes
	
		moveq		#$00,d6
		move.b		(b_Depth,a6),d6
		
		move.l		a6,-(sp)
		move.l		(a6),a6
		jsr		(_LVOOwnBlitter,a6)
		jsr		(_LVOWaitBlit,a6)
		move.l		(sp)+,a6
		
PPLoop		move.l		(bm_Planes,d6.w*4,a4),d0
		move.l		(bm_Planes,d6.w*4,a3),d1
		bsr.s		BMScalePlane			;do the scale		

		dbra		d6,PPLoop			;all planes

		move.l		a6,-(sp)
		move.l		(a6),a6
		jsr		(_LVODisownBlitter,a6)
		move.l		(sp)+,a6
		bra.s		GoodExit
			
		
	;do old bitmapscale (a5-*bitscaleargs)

OldBS:		move.l		(l_OldBmpScale,pc),a4
		move.l		a5,a0
		move.l		(a6),d7				;fetch gfxbase
		exg.l		a6,d7
		jsr		(a4)
		exg.l		a6,d7
		bra.s		GoodExit
		
		
		
		
	;
	;exit stuff
	;		
		
		
		
BadExit:	clr.l		(bsa_DestWidth,a5)
	
GoodExit:	movem.l		(sp)+,d0-d7/a0-a5		;restore reg's
		unlk		a6
			
Exit:		rts	







	;
	;Scale one plane	d0-dest plane
	;			d1-source plane
	;			a3-src bitmap
	;			a4-dst bitmap
	;			d6-*PRESERVE* (#plane)
	;			a5-ScaleArg
	;


BMScalePlane:	move.l		d0,a1
		move.l		d1,a0
		move.w		d6,-(sp)			;save #plane
		
		move.w		(bsa_DestHeight,a5),d7		;rows to render
		subq.w		#$01,d7
		bmi.s		BMSPX
		
		moveq		#-1,d5
		move.w		d5,(w_LastY,a6)			;reset last source row
		
		add.l		(l_SrcBase,a6),a0		;set source addr(0,0)
		moveq		#0,d5				;reset source Y
		
		add.l		(l_DstBase,a6),a1		;set dest addr(x,0)
		
BMSPLoop:	moveq		#0,d6				;reset dest X
		moveq		#0,d4
		move.b		(b_DstStartBit,a6),d6
		move.w		(bsa_SrcX,a5),d4		;reset source X
		
		cmp.w		(w_LastY,a6),d5			;clone last row
		bne.s		BMSPL0s0			;no...
		
		bsr.s		BMSCloneRow			;copy last row
		bra.s		BMSPL0s1
		
BMSPL0s0:	move.w		d5,(w_LastY,a6)			;set last row
		bsr.s		BMScaleRow			;do the row
		
BMSPL0s1:	moveq		#0,d0
		move.w		(bm_BytesPerRow,a4),d0		;next dest row
		add.l		d0,a1
		
		move.w		d5,d0				;next source row
		swap		d5
		add.l		(l_SrcYDelta,a6),d5
		swap		d5
		move.w		d5,d1
		sub.w		d0,d1				;new row?
		beq.s		BMSPL0s2
		move.w		(bm_BytesPerRow,a3),d0
		mulu.w		d1,d0
		add.l		d0,a0
		
BMSPL0s2:	dbra		d7,BMSPLoop
		bra.s		BMSPX		

		
	;exit
		
BMSPX:		move.w		(sp)+,d6
		rts
		

		
	;clone last dest row...
	
BMSCloneRow:	move.l		a1,a2				;point to last line
		move.w		(bm_BytesPerRow,a4),d0	
		sub.l		d0,a2
		
		moveq		#0,d1				;X size
		move.w		(bsa_DestWidth,a5),d1
		moveq		#0,d4				;X offset
		
		tst.b		d6				;any head?
		beq.s		BMSCBody
		move.l		#$20,d2
		sub.l		d6,d2				;field width
		cmp.l		d2,d1				;width>X size?
		bcc.s		BMSCFix0
		move.l		d1,d2
BMSCFix0:	bfextu		(a2){d6:d2},d3
		sub.l		d2,d1				;update width
		bfins		d3,(a1){d6:d2}
		add.l		#$04,d4				;next lw
		
BMSCBody:	cmp.w		#$20,d1				;more whole lws?
		bcs.s		BMSCTail
		move.l		(a2,d4.w),(a1,d4.w)
		add.l		#$04,d4
		sub.l		#$20,d1
		bra.s		BMSCBody
		
BMSCTail:	tst.l		d1				;any tail?
		beq.s		BMSCTX
		bfextu		(a2,d4.w){0:d1},d3
		bfins		d3,(a1,d4.w){0:d1}
		
BMSCTX:		rts



	;scale source->dest row (d4-sourceXbit (frac:16))
	
BMScaleRow:	move.l		d5,-(sp)
		moveq		#0,d1
		moveq		#0,d5				;d5-dst offset
		moveq		#0,d3				;d3-source offset
		move.w		(bsa_DestWidth,a5),d1		;d1-X size
		move.w		d4,d3
		swap		d4
		move.l		(l_SrcXDelta,a6),a2
		
		tst.b		d6				;any head?
		beq.s		BMSRBody
		move.l		#$20,d2				;d6-dst field offset
		sub.l		d6,d2				;d2-dst field width
		cmp.l		d2,d1				;width>X Size?
		bcc.s		BMSRFix0
		move.l		d1,d2
BMSRFix0:	sub.l		d2,d1				;update width
		move.l		d2,-(sp)
		subq.l		#$01,d2
		
BMSRHl0:	bfextu		(a0){d3:1},d5			;fetch source bit
		add.l		a2,d4				;next src X
		swap		d4
		lsr.b		#$01,d5
		move.w		d4,d3
		swap		d4
		addx.l		d0,d0
		dbra		d2,BMSRHl0
		
		move.l		(sp)+,d2			;render
		bfins		d0,(a1){d6:d2}
		moveq		#$04,d5
		
BMSRBody:	cmp.l		#$20,d1				;more whole lws?
		bcs.s		BMSRTail
		
		move.w		#$1f,d2				;fetch $20 source bits
		
BMSRBl0:	bfextu		(a0){d3:1},d6
		add.l		a2,d4				;next src X
		swap		d4
		lsr.b		#$01,d6
		move.w		d4,d3
		swap		d4
		addx.l		d0,d0
		dbra		d2,BMSRBl0
				
		move.l		d0,(a1,d5.l)			;render
		add.l		#$04,d5
		sub.l		#$20,d1
		bra.s		BMSRBody
		
BMSRTail:	tst.l		d1				;any tail?
		beq.s		BMSRX
		move.l		d1,-(sp)
		subq.l		#$01,d1
		
BMSRTl0:	bfextu		(a0){d3:1},d6
		add.l		a2,d4				;next src X
		swap		d4
		lsr.b		#$01,d6
		move.w		d4,d3
		swap		d4
		addx.l		d0,d0
		dbra		d1,BMSRTl0
		
		move.l		(sp)+,d1			;render
		bfins		d0,(a1,d5.l){0:d1}
		
BMSRX:		move.l		(sp)+,d5
		rts		
		
				
	
	;
	;broken blah
	;
	
Broken:		lea		(l_Pad4,pc),a3		
		addq.l		#$01,(a3)
		bra		OldBS
	
					
