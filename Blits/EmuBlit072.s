
*-----------------------------------------------------------------------------
*
*	EmuBlit.s V0.72 20.07.98
*
*	© Stephen Brookes 1997-98
*
*	Emulate blitter.
*
*-----------------------------------------------------------------------------
*
*
*	Input:	
*			_Minterm	- minterm
*			_DstBmpDelta	- inter row delta
*			_DstStart	- dest start bit
*			_BTH		- body:tail/head
*			_Rows		- #rows
*			_Left		- null-right, else left
*			_SrcStart	- source start bit
*			_SrcBmpDelta	- inter row delta (source)
*			_DstXFLW	- dest first lw bmp offset
*			_DstXLLW	- dest last lw offset
*			_DynNP		- #planes
*			_SizeX		- SizeX
*			
*
*	Trashed:	EVERYTHING!
*
*-----------------------------------------------------------------------------






EmuBlit:	move.b		(b_Minterm,a6),d6
		add.b		d6,d6				;expand minterm
		subx.l		d1,d1
		add.b		d6,d6
		subx.l		d2,d2
		add.b		d6,d6
		move.l		d1,a4				;a4-ch8
		subx.l		d5,d5				;d5-ch2
		add.b		d6,d6
		move.l		d2,a5				;a5-ch4
		subx.l		d6,d6				;d6-ch1

		move.w		(w_DynNP,a6),d1
		addq.w		#$01,d1
		add.b		d1,(b_NumPlanes,a6)
		subq.w		#$01,d1

		btst.b		#FBF_LEFT,(b_FBFlags,a6)	;go left or right?
		bne		EBlitLeft
	
		
EBlitRight:	move.l		(l_SrcStart,a6),(l_Temp2,a6)	;save srcstart

EBRPlaneLoop:	move.w		d1,(w_DynNP,a6)			;save current plane
		lea		(_Planes,a6,d1.w*8),a2		;current planes addrs
		move.l		(l_Temp2,a6),(l_SrcStart,a6)	;restore srcstart
		movem.l		(a2),a0-a1			;fetch plane addr's
		add.l		(l_DstXFLW,a6),a0
		add.l		(l_SrcXFLW,a6),a1
		
		
EBRCopyHead:	move.b		(b_HEAD,a6),d4
		beq		EBRCopyBody
		
		extb.l		d4
		move.l		(l_SrcStart,a6),d7
		move.l		d4,d0
		
		swap		d4
		move.w		(l_DstStart+2,a6),d4
		move.l		d4,a2				;a2-#headbits:dststart
		
		add.l		d7,d0				;next srcstart(+#headbits)
		move.l		d0,(l_SrcStart,a6)
		
		swap		d7
		move.w		(w_Rows,a6),d7			;d7-srcstart:#rows
		
		move.l		a0,(l_Temp0,a6)			;save dst addr
		move.l		a1,(l_Temp1,a6)
		
EBRCHl1:	move.l		a2,d3
		moveq		#0,d4
		move.w		d3,d4				;d4-dststart
		swap		d3				;d3-#head bits
		move.l		d7,d2
		clr.w		d2
		swap		d2				;d2-srcstart
		bfextu		(a1){d2:d3},d0			;d0-B
		move.l		d0,d1
		not.l		d1				;d1-b
		bfextu		(a0){d4:d3},d2			;d2-C
		move.l		d2,d3
		not.l		d3				;d3-c
		move.l		d2,d4				;d4-spare C
		and.l		d0,d2				;d2-BC (ch$8x)
		and.l		d3,d0				;d0-Bc (ch$4x)
		and.l		d1,d4				;d4-bC (ch$2x)
		and.l		d3,d1				;d1-bc (ch$1x)
		add.l		(l_SrcBmpDelta,a6),a1		;next src row
		and.l		d5,d4
		move.l		a4,d3
		and.l		d6,d1
		and.l		d3,d2
		move.l		a5,d3
		and.l		d3,d0
		or.l		d0,d2
		or.l		d4,d2
		or.l		d1,d2
		moveq		#0,d4
		move.l		a2,d3				;restore #head:dststart
		move.w		d3,d4				;d4-dststart
		swap		d3				;d3-#head bits		
		bfins		d2,(a0){d4:d3}
		add.l		(l_DstBmpDelta,a6),a0
		dbra		d7,EBRCHl1
		
		move.l		(l_Temp0,a6),a0
		addq.l		#$04,a0
		move.l		(l_Temp1,a6),a1

		
EBRCopyBody:	move.w		(w_BODY,a6),d7
		beq		EBRCopyTail
		
		move.w		(w_Rows,a6),d4
		ext.l		d7
		
		move.l		a0,d0				;figure out next dst/src
		move.l		d7,d1
		lsl.l		#$02,d1
		add.l		d1,d0
		move.l		d0,(l_Temp0,a6)			;save next dest
		
		lsl.l		#$03,d1
		move.l		(l_SrcStart,a6),d3
		add.l		d3,d1
		move.l		d1,(l_SrcStart,a6)		;next srcstart
		move.l		a1,(l_Temp1,a6)			;next src
		
		subq.l		#$01,d7
		
		swap		d3
		move.w		d4,d3				;srcstart:#rows
		
EBRCBl1:	move.l		d3,a3				;srcstart:#rows
		swap		d3
		move.w		d3,a2				;local srcstart (SIGNX!!)
				
EBRCBl2:	move.l		a2,d3
		bfextu		(a1){d3:32},d0			;d0-B
		add.l		#$20,a2
		move.l		d0,d1
		not.l		d1				;d1-b
		move.l		(a0),d2				;d2-C
		move.l		d2,d3
		not.l		d3				;d3-c
		move.l		d2,d4				;d4-spare C
		and.l		d0,d2				;d2-BC (ch$8x)
		and.l		d3,d0				;d0-Bc (ch$4x)
		and.l		d1,d4				;d4-bC (ch$2x)
		and.l		d3,d1				;d1-bc (ch$1x)
		and.l		d5,d4
		move.l		a4,d3
		and.l		d6,d1
		and.l		d3,d2
		move.l		a5,d3
		and.l		d3,d0		
		or.l		d0,d2
		or.l		d4,d2
		or.l		d1,d2			
		move.l		d2,(a0)+
		dbra		d7,EBRCBl2
		
		move.w		(w_BODY,a6),d7			;recover body count
		move.l		a3,d3				;fetch #rows
		move.w		d7,d0
		add.l		(l_SrcBmpDelta,a6),a1		;next src row
		lsl.w		#$02,d0
		sub.w		d0,a0				;to start of row
		add.l		(l_DstBmpDelta,a6),a0		;to start of next row
		subq.w		#$01,d7
		dbra		d3,EBRCBl1
		
		move.l		(l_Temp0,a6),a0
		move.l		(l_Temp1,a6),a1
		
		
EBRCopyTail:	move.b		(b_TAIL,a6),d4			;any tail?
		beq.s		EBRPlaneExit
		
		move.w		(w_Rows,a6),d7

		swap		d4
		move.w		(l_SrcStart+2,a6),d4
		move.l		d4,a2				;a2-#tail bits:srcstart
		
EBRCTl1:	move.l		a2,d3
		moveq		#0,d4
		move.w		d3,d4
		swap		d3
		bfextu		(a1){d4:d3},d0
		move.l		d0,d1
		not.l		d1				;d1-b
		move.l		(a0),d4
		bfextu		d4{0:d3},d2			;d2-C
		move.l		d4,a3				;save dest lw
		move.l		d2,d3
		not.l		d3				;d3-c
		move.l		d2,d4				;d4-spare C
		and.l		d0,d2				;d2-BC (ch$8x)
		and.l		d3,d0				;d0-Bc (ch$4x)
		and.l		d1,d4				;d4-bC (ch$2x)
		and.l		d3,d1				;d1-bc (ch$1x)
		add.l		(l_SrcBmpDelta,a6),a1
		and.l		d5,d4
		move.l		a4,d3
		and.l		d6,d1
		and.l		d3,d2
		move.l		a5,d3
		and.l		d3,d0
		or.l		d0,d2
		or.l		d4,d2
		or.l		d1,d2
		move.l		a2,d3
		swap		d3
		move.l		a3,d0				
		bfins		d2,d0{0:d3}
		move.l		d0,(a0)
		add.l		(l_DstBmpDelta,a6),a0
		dbra		d7,EBRCTl1
			
	

EBRPlaneExit:	move.w		(w_DynNP,a6),d1
		subq.w		#$01,d1				;next plane
		bpl		EBRPlaneLoop
		bra		DisBlitX
		


	
	
	
	;
	;Blit left (data going y-up/dn, x-right)
	;Inputs as 'EBlitRight'
	;		
		
EBlitLeft:	move.w		(w_SizeX,a6),d0
		ext.l		d0
		add.l		(l_SrcStart,a6),d0
		
		move.l		d0,(l_Temp2,a6)			;store new srcstart

EBLPlaneLoop:	move.w		d1,(w_DynNP,a6)
		lea		(_Planes,a6,d1.w*8),a2
		move.l		(l_Temp2,a6),(l_SrcStart,a6)	;restore srcstart
		movem.l		(a2),a0-a1			;fetch plane addr's
		add.l		(l_DstXLLW,a6),a0
		add.l		(l_SrcXFLW,a6),a1
		
		
		
EBLCopyTail:	move.b		(b_TAIL,a6),d4			;any tail?
		beq.s		EBLCopyBody
		
		extb.l		d4
		move.w		(w_Rows,a6),d7
		move.l		a0,(l_Temp0,a6)
		move.l		a1,(l_Temp1,a6)
		move.l		(l_SrcStart,a6),d3
		sub.l		d4,d3				;srcstart-#tail bits
		move.l		d3,(l_SrcStart,a6)
		swap		d4
		move.w		d3,d4
		move.l		d4,a2				;a2-#tail bits:srcstart
		
EBLCTl1:	move.l		a2,d3
		moveq		#0,d4
		move.w		d3,d4
		swap		d3
		bfextu		(a1){d4:d3},d0
		move.l		d0,d1
		not.l		d1				;d1-b
		move.l		(a0),d4
		bfextu		d4{0:d3},d2			;d2-C
		move.l		d4,a3				;save dest lw
		move.l		d2,d3
		not.l		d3				;d3-c
		move.l		d2,d4				;d4-spare C
		and.l		d0,d2				;d2-BC (ch$8x)
		and.l		d3,d0				;d0-Bc (ch$4x)
		and.l		d1,d4				;d4-bC (ch$2x)
		and.l		d3,d1				;d1-bc (ch$1x)
		add.l		(l_SrcBmpDelta,a6),a1
		and.l		d5,d4
		move.l		a4,d3
		and.l		d6,d1
		and.l		d3,d2
		move.l		a5,d3
		and.l		d3,d0
		or.l		d0,d2
		or.l		d4,d2
		or.l		d1,d2
		move.l		a2,d3
		swap		d3
		move.l		a3,d0		
		bfins		d2,d0{0:d3}
		move.l		d0,(a0)
		add.l		(l_DstBmpDelta,a6),a0
		dbra		d7,EBLCTl1
		
		move.l		(l_Temp0,a6),a0
		subq.l		#$04,a0
		move.l		(l_Temp1,a6),a1
		
EBLCopyBody:	move.w		(w_BODY,a6),d7
		subq.w		#$01,d7				;any body?
		bmi		EBLCopyHead
		
		ext.l		d7
		move.w		(w_Rows,a6),d4
		
		move.l		a0,d0				;figure out next dst/src
		subq.l		#$04,d0
		move.l		d7,d1
		lsl.l		#$02,d1
		sub.l		d1,d0
		move.l		d0,(l_Temp0,a6)
		
		lsl.l		#$03,d1
		move.l		(l_SrcStart,a6),d2
		sub.l		#$20,d2
		move.l		d2,d3
		sub.l		d1,d2
		move.l		d2,(l_SrcStart,a6)		;next srcstart
		move.l		a1,(l_Temp1,a6)			;next src
		
		swap		d3
		move.w		d4,d3				;srcstart:#rows
		
		addq.l		#$04,a0
		
EBLCBl1:	move.l		d3,a3				;srcstart:#rows
		swap		d3
		move.w		d3,a2				;local srcstart (SIGNX!!)
				
EBLCBl2:	move.l		a2,d3
		bfextu		(a1){d3:32},d0			;d0-B
		sub.l		#$20,a2
		move.l		d0,d1
		not.l		d1				;d1-b
		move.l		-(a0),d2			;d2-C
		move.l		d2,d3
		not.l		d3				;d3-c
		move.l		d2,d4				;d4-spare C
		and.l		d0,d2				;d2-BC (ch$8x)
		and.l		d3,d0				;d0-Bc (ch$4x)
		and.l		d1,d4				;d4-bC (ch$2x)
		and.l		d3,d1				;d1-bc (ch$1x)
		and.l		d5,d4
		move.l		a4,d3
		and.l		d6,d1
		and.l		d3,d2
		move.l		a5,d3
		and.l		d3,d0		
		or.l		d0,d2
		or.l		d4,d2
		or.l		d1,d2	
		move.l		d2,(a0)
		dbra		d7,EBLCBl2
		
		move.w		(w_BODY,a6),d7			;recover body count
		move.l		a3,d3				;fetch #rows
		add.l		(l_SrcBmpDelta,a6),a1		;next src row
		lea		(d7.w*4,a0),a0			;to start of row+1lw (END OF ROW!!)
		add.l		(l_DstBmpDelta,a6),a0		;to start of next row
		subq.w		#$01,d7
		dbra		d3,EBLCBl1
		
		move.l		(l_Temp0,a6),a0
		move.l		(l_Temp1,a6),a1
		
		
EBLCopyHead:	move.b		(b_HEAD,a6),d4			;any head?
		beq.s		EBLPlaneExit
		
		extb.l		d4
		move.l		(l_SrcStart,a6),d7
		sub.l		d4,d7				;srcstart-#head bits
		
		swap		d4
		move.w		(l_DstStart+2,a6),d4
		move.l		d4,a2				;a2-#head bits:dststart
		
		swap		d7
		move.w		(w_Rows,a6),d7			;d7-srcstart:#rows
		
EBLCHl1:	move.l		a2,d3
		moveq		#0,d4
		move.w		d3,d4				;d4-dststart
		swap		d3				;d3-#head bits
		move.l		d7,d2
		clr.w		d2
		swap		d2				;d2-srcstart
		bfextu		(a1){d2:d3},d0			;d0-B
		move.l		d0,d1
		not.l		d1				;d1-b
		bfextu		(a0){d4:d3},d2			;d2-C
		move.l		d2,d3
		not.l		d3				;d3-c
		move.l		d2,d4				;d4-spare C
		and.l		d0,d2				;d2-BC (ch$8x)
		and.l		d3,d0				;d0-Bc (ch$4x)
		and.l		d1,d4				;d4-bC (ch$2x)
		and.l		d3,d1				;d1-bc (ch$1x)
		add.l		(l_SrcBmpDelta,a6),a1		;next src row
		and.l		d5,d4
		move.l		a4,d3
		and.l		d6,d1
		and.l		d3,d2
		move.l		a5,d3
		and.l		d3,d0
		or.l		d0,d2
		or.l		d4,d2
		or.l		d1,d2
		moveq		#0,d4
		move.l		a2,d3				;restore #head:dststart
		move.w		d3,d4				;d4-dststart
		swap		d3				;d3-#head bits			
		bfins		d2,(a0){d4:d3}
		add.l		(l_DstBmpDelta,a6),a0
		dbra		d7,EBLCHl1


		
EBLPlaneExit:	move.w		(w_DynNP,a6),d1
		subq.w		#$01,d1				;next plane
		bpl		EBLPlaneLoop
		bra		DisBlitX
		


