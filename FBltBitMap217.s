

*-----------------------------------------------------------------------------
*
*	FBltBitMap.s V2.17 04.02.2001
*
*	© Stephen Brookes 1997-99
*
*	BltBitMap replacement using 020+ code and allowing blits
*	outside chip RAM.
*
*-----------------------------------------------------------------------------
*
* Input:		d0=SrcX.w
*			d1=SrcY.w
*			d2=DstX.w
*			d3=DstY.w
*			d4=SizeX.w
*			d5=SizeY.w
*			d6=Minterm.b
*			d7=Mask.b
*			a0=*SrcBitMap.BitMap
*			a1=*DstBitMap.BitMap
*			[a2=*TempA]
*
*			a6=*gfxbase
*
* Output:		d0=planecnt.l
*
* Trashed:		-
*
*-----------------------------------------------------------------------------


	include "graphics/gfx.i"
	
	include "lvo/graphics_lib.i"
	include "lvo/exec_lib.i"
	
	include	"fblit_library/fblit_lib.i"

	machine MC68030


	rsreset

l_Pad			rs.l	-1
l_SrcBmpDelta		rs.l	-1		;src inter bmp delta
l_DstBmpDelta		rs.l	-1		;dst bmp delta
l_SrcXFLW		rs.l	-1		;src base (1st lw)
l_DstXFLW		rs.l	-1		;dst base offset (first long word)
l_SrcXLLW		rs.l	-1		;src last lw
l_DstXLLW		rs.l	-1		;dst base (last long word)
l_DstPlanes		rs.l	-1		;OR'd dst planes
l_SrcPlanes		rs.l	-1		;OR'd src planes
l_PlaneStore		rs.l	-16		;planes storage
l_BTH			rs.l	-1		;Body:Tail/Head (for NON-aligned blits only!!!)
l_DstStart		rs.l	-1		;dest start bit
l_SrcStart		rs.l	-1		;source start bit
l_Temp0 		rs.l	-1
l_Temp1 		rs.l	-1
l_Temp2 		rs.l	-1
l_BTH2			rs.l	-1		;BTH with never combined head/tail

w_DstX			rs.w	-1		;dest X
w_SizeX 		rs.w	-1		;size X
w_Rows			rs.w	-1		;rows to render
w_DynNP 		rs.w	-1		;#planes (dynamic)

b_Depth 		rs.b	-1		;render depth
b_Minterm		rs.b	-1		;minterm
b_Mask			rs.b	-1		;mask
b_NumPlanes		rs.b	-1		;#planes again (still dynamic)
b_FBFlags		rs.b	-1		;flags
b_Pad			rs.b	-1

FBF_LEFT		equ	0		;go left
FBF_LEXEMPT		equ	1		;left exempt
FBF_ALLCHIP		equ	2		;all planes chip
FBF_ALIGNED		equ	3		;src/dst aligned (bitwise in X)


	;generate VSPACE to lw align plus one lw for stack alignment error

VSPACE			equ	((__RS-7)/4)*4

	;set 'Planes' to BOTTOM of 'PlaneStore'

_Planes 		equ	l_BTH+4


b_HEAD			equ	l_BTH+3
w_BODY			equ	l_BTH
b_TAIL			equ	l_BTH+2

	;set 'magic'

MAGIC			equ	$805c

BADPAD1 		equ	$f8c1


Entry:		bra.s		SubMain


w_FField	dc.w	0					;non-Chip range
l_OldBlit	dc.l	0					;*BltBitMap
l_FastCnt	dc.l	0					;counters
l_ProcCnt	dc.l	0
l_PassCnt	dc.l	0
l_BrkCnt	dc.l	0
l_Debug 	dc.l	0					;debug output
l_user2 	dc.l	0
l_Flags 	dc.l	0					;control flags
l_user3		dc.l	0
l_FBlitBase	dc.l	0

ACTIVE			equ	1				;patch activation
CPASSON 		equ	2				;pass all chip
CPASSCMX		equ	3				;pass complex chip
CPROCESS		equ	4				;process all chip
CPRETTY 		equ	5				;pretty mode
CNOFLICK		equ	6				;avoid flicker
CNOPRETTY		equ	7				;never pretty
FPASSON 		equ	8				;pass on fast!!!
FPROCESS		equ	9				;process fast
FDISCARD		equ	10				;discard fast
FOLDPASSON		equ	11				;old pass on broken
STACKCHECK		equ	12				;check stack





	; BltBitMap()
	
SubMain:	cnop	0,4
		btst		#ACTIVE,(l_Flags+3,pc)
		bne.s		NewMain				;--> active...

		move.l		(l_OldBlit,pc),-(sp)
		rts

	;optimize interleaved		
NewMain:		
		cmp.b		#$ff,d7
		bne		Main				;--> not all planes
		
		cmp.w		#MAGIC,(bm_Pad,a0)
		bne		Main				;--> src not magic
		
		cmp.w		#MAGIC,(bm_Pad,a1)
		bne.s		Main				;--> dst not magic
		
		move.b		(bm_Depth,a0),d7
		cmp.b		#$02,d7
		bcs.s		FixMain				;--> depth < 2
		
		cmp.b		(bm_Depth,a1),d7
		bne.s		FixMain				;--> not same depth
		
		movem.l		d1/d3/d5/d7,-(sp)		;save stuff
		
		ext.w		d7
		mulu.w		d7,d1
		mulu.w		d7,d3
		mulu.w		d7,d5				;modify src/dst/size Y
		
		sub.l		#2*bm_SIZEOF,sp			;space for two bitmaps
		
		move.l		(bm_Planes+4,a0),d7		;get new src bpr
		sub.l		(bm_Planes,a0),d7
		swap		d7
		move.w		(bm_Rows,a0),d7			;d7 - bpr:rows
		move.l		d7,(sp)
		move.l		#$10000,(bm_Flags,sp)		;flags/depth (pad...)
		move.l		(bm_Planes,a0),(bm_Planes,sp)	;plane
		
		move.l		(bm_Planes+4,a1),d7
		sub.l		(bm_Planes,a1),d7
		swap		d7
		move.w		(bm_Rows,a1),d7
		move.l		d7,(bm_SIZEOF,sp)
		move.l		#$10000,(bm_Flags+bm_SIZEOF,sp)
		move.l		(bm_Planes,a1),(bm_Planes+bm_SIZEOF,sp)
		
		move.l		sp,a0				;src bitmap
		lea		(bm_SIZEOF,sp),a1		;dst bitmap
		
		bsr.s		FixMain
		
		add.l		#2*bm_SIZEOF,sp
		movem.l		(sp)+,d1/d3/d5/d7
		move.b		#$ff,d7
		rts
FixMain:
		move.b		#$ff,d7
Main:	
		link		a6,#VSPACE			;*** (a6)=gfxbase ***
		movem.l 	d0-d7/a0-a5,-(sp)		;store reg's
		sub.l		a2,a2				;kill temp

	;
	;clean up/check reg's
	;

	;*** these two required for any call to 'OldBltBitMap' ***

		clr.b		(b_NumPlanes,a6)		;#planes done
		move.b		d7,(b_Mask,a6)			;make mask valid
		beq		BadExit 			;--> no planes selected

		clr.b		(b_FBFlags,a6)			;clear flags

		and.b		#$f0,d6 			;minterm
		cmp.b		#$a0,d6
		beq		BadExit 			;--> copy dest->dest
		
		move.b		d6,(b_Minterm,a6)

FBFx2:		moveq		#0,d6  
		not.w		d6     
		and.l		d6,d0
		and.l		d6,d1
		move.w		d2,(w_DstX,a6)
		and.l		d6,d3
		move.w		d4,(w_SizeX,a6)
		beq		BadExit 			;no zero size!
		and.l		d6,d5
		bne.s		FRD
		bra		BadExit				;no zero size!

CFDPass:	lea.l		(l_PassCnt,pc),a4
		addq.l		#$01,(a4)
		bra		OldBltBitMap



	;
	;find render depth
	;

FRD:		moveq		#$00,d6
		move.b		(bm_Depth,a0),d6
		cmp.b		(bm_Depth,a1),d6
		ble.s		FBlits1
		move.b		(bm_Depth,a1),d6
FBlits1:	subq.b		#$01,d6
		bmi		BadExit 			;no planes
		move.b		d6,(b_Depth,a6)

	;
	;chip/fast data?
	;
	
		move.l		d3,a3
		moveq		#$00,d2
		moveq		#$00,d3
		
cfl0:		btst		d6,d7
		beq.s		cfs0
		
		or.l		(bm_Planes,a1,d6.w*4),d3	;dst
		move.l		(bm_Planes,a0,d6.w*4),d4	;src
		beq.s		cfs0
		not.l		d4
		beq.s		cfs0
		not.l		d4
cfs1:		or.l		d4,d2
		
cfs0:		dbra		d6,cfl0		
		
		move.l		d2,(l_SrcPlanes,a6)
		move.l		d3,(l_DstPlanes,a6)
		
		move.l		(l_Flags,pc),d7
		or.l		d3,d2
		move.w		(w_FField,pc),d6
		move.l		a3,d3
		bftst		d2{0:d6}
		beq.s		CFDAllChip


CFDs2:		btst		#FDISCARD,d7			;discard fast?
		bne		GoodExit

		lea.l		(l_FastCnt,pc),a4
		addq.l		#$01,(a4)

		btst		#FPROCESS,d7			;process
		bne.s		CFDfx

		bra		CFDPass 			;pass on

CFDAllChip:	btst		#CPASSON,d7			;pass on
		bne		CFDPass 			;yes...
		bset		#FBF_ALLCHIP,(b_FBFlags,a6)



CFDfx:		moveq		#0,d2
		move.w		(w_DstX,a6),d2
		move.w		(w_SizeX,a6),d4
		lea.l		(l_ProcCnt,pc),a4
		addq.l		#$01,(a4)

		subq.l		#$01,d5 			;set #rows
		move.w		d5,(w_Rows,a6)

	;
	;set up head, tail, body, bmpdelta/offset and startbits
	;NOTE that up/down refer to 'on screen' view ie. opposite of 'in memory' view,
	;and refers to travel through the data, again the opposite of the direction of
	;data movement! Simple huh?
	;NOTE again. '_rows' is still in d5!!
	;


		moveq		#0,d6

		cmp.w		d0,d2				;left or right?
		ble.s		FBlits2
		bset		#FBF_LEFT,(b_FBFlags,a6)

FBlits2:	move.l		d6,d7

		cmp.w		d1,d3				;allways exempt if
		beq.s		FBlits3 			;srcy<>dsty
		bset		#FBF_LEXEMPT,(b_FBFlags,a6)


FBlits3:	move.w		(bm_BytesPerRow,a0),d6		;init bmp deltas
		move.w		(bm_BytesPerRow,a1),d7
		move.l		d6,a2
		move.l		d7,a3

		cmp.w		d3,d1				;go up or down?
		bcc.s		FBlitSet			;going down...

		add.w		d5,d1				;go to last row
		add.w		d5,d3
		neg.l		d6				;negate bmp deltas
		neg.l		d7
		exg.l		d6,a2
		exg.l		d7,a3

FBlitSet:	move.l		a2,(l_SrcBmpDelta,a6)
		moveq		#$1f,d5
		move.l		a3,(l_DstBmpDelta,a6)

		muls.w		d6,d1				;make initial bmp offsets
		muls.w		d7,d3				;(bpr*row)
		move.l		d0,d6				;copy SrcX
		move.l		d2,d7
		and.w		d5,d0			;d5=#$001f (issolate bits)
		and.w		d5,d2
		move.l		d0,a2				;save src start bit
		move.l		d2,a3
		move.l		d0,(l_SrcStart,a6)
		move.l		d2,(l_DstStart,a6)
		eor.w		d6,d0				;d0=d6 & ffe0...
		eor.w		d7,d2				;(or whole lw bits)
		lsr.w		#$03,d0 			;bits->bytes
		lsr.w		#$03,d2
		add.l		d1,d0				;+base offset
		add.l		d3,d2
		move.l		d0,(l_SrcXFLW,a6)		;offset to 1st lw
		not.b		d5			;d5=#$00e0
		move.l		d2,(l_DstXFLW,a6)
		add.w		d4,d6				;SizeX+SrcX
		add.w		d4,d7
		subq.w		#$01,d6
		subq.w		#$01,d7
		and.b		d5,d6			;issolate lw's
		and.b		d5,d7
		lsr.w		#$03,d6 			;bits->bytes
		lsr.w		#$03,d7
		add.l		d1,d6
		add.l		d3,d7
		move.l		d6,(l_SrcXLLW,a6)		;offset to last lw
		not.b		d5			;d5=#$001f
		move.l		d7,(l_DstXLLW,a6)
		move.l		a3,d2				;restore start bit
		move.l		a2,d0


		moveq		#$20,d6 			;calculate #head bits
		sub.b		d2,d6
		and.b		d5,d6
		move.w		d6,a2				;a2-#head bits

		cmp.b		d2,d0				;set aligned flag
		bne.s		FBSs0
		bset		#FBF_ALIGNED,(b_FBFlags,a6)

FBSs0:		move.w		d4,d6				;copy SizeX
		sub.w		a2,d6				;SizeX-#head bits
		bpl.s		FBSs1

		move.w		d4,a2				;SizeX<#head bits
		moveq		#0,d6				;(#head bits=SizeX)
		sub.l		a5,a5				;no body, no tail
		bclr		#FBF_LEFT,(b_FBFlags,a6)	;no left
		bra.s		FBSs3

FBSs1:		move.w		d6,d7				;(d6=SizeX-#head bits)
		and.w		d5,d7	 			;isolate tail bits(d5=#$001f)
		move.w		d7,a5				;a5-#tail bits
		sub.w		d7,d6				;SizeX-#headbits-tailbits
		lsr.w		#$05,d6 			;d6-#body lws

	;d0-srcstart($1f)
	;d2-dststart
	;d6-body lw
	;a2-head bits
	;a5-tail bits

FBSs2:		move.l		a2,d1				;copy #head bits
		tst.w		d6				;Do as all head?
		bne.s		FBSs3				;not if any body
		cmp.b		d2,d0
		beq.s		FBSs3				;not if aligned
		add.w		a5,d1
		cmp.b		#$21,d1
		bcc.s		FBSs3				;not if head+tail>32

		swap		d6				;non-combi BTH still
		move.w		a5,d6				;needed for Fill/DInv(and PrettyCopy!!!).
		lsl.w		#$08,d6
		move.w		a2,d0
		move.b		d0,d6
		move.l		d6,(l_BTH2,a6)
		move.w		d1,d6				;all head bits BTH
		bclr		#FBF_LEFT,(b_FBFlags,a6)
		bra.s		FBSs30


FBSs3:		swap		d6				;d6-body:X/X
		move.w		a5,d6				;   body:X/Tail
		lsl.w		#$08,d6 			;   body:Tail/X
		move.w		a2,d0
		move.b		d0,d6				;   body:Tail/Head
		move.l		d6,(l_BTH2,a6)
FBSs30: 	move.l		d6,(l_BTH,a6)




	;look through the planes. 'special' planes are dealt from here.
	;output, d7-newly valid plane mask
	;	'dynnp' has #planes left to deal with.

		lea		(bm_Planes,a0),a2
		lea		(bm_Planes,a1),a3
		lea		(_Planes,a6),a4
		move.b		(b_Depth,a6),d6
		move.b		(b_Mask,a6),d7
		move.w		#$ffff,(w_DynNP,a6)
		move.b		(b_Minterm,a6),d0
		extb.l		d6

		move.l		(l_FBlitBase,pc),a5		;obtain the blitter
		exg		a5,a6
		jsr		(_LVOGetBlitter,a6)
		move.l		a5,a6

FBlitl1:	bclr		d6,d7				;render this plane?
		beq.s		FBlitl1s1

		move.l		(a3,d6.w*4),d5			;d5-dst plane
		
		tst.b		d0
		beq.s		FFill				;$0x mint (fill0)

		cmp.b		#$f0,d0
		beq.s		FFill				;$fx mint (fill1)

		cmp.b		#$50,d0
		beq.s		FDInv				;$5x mint (DInv)

		move.l		(a2,d6.w*4),d4
		beq		FSrc0				;src plane 0
		not.l		d4
		beq.s		FSrc1				;src plane -1
		not.l		d4

		move.l		d5,(a4)+			;store dst
		move.l		d4,(a4)+			;store src
		addq.w		#$01,(w_DynNP,a6)
		bset		d6,d7				;do plane later...

FBlitl1s1:	dbra		d6,FBlitl1

		tst.w		(w_DynNP,a6)			;anything left to do?
		bmi		DisBlitX

		cmp.b		#$c0,d0 			;copy src->dst
		beq		PCopyBlit

		cmp.b		#$30,d0 			;invert src->dst
		beq		PCopyBlitI

		move.b		d7,(b_Mask,a6)			;save mask

		move.l		(l_Flags,pc),d2 		;pass on cmplx?
		btst		#CPASSCMX,d2
		beq		EmuBlit 			;no...

		btst		#FBF_ALLCHIP,(b_FBFlags,a6)	;all planes in chip?
		beq		EmuBlit 			;no...

		lea		(l_ProcCnt,pc),a5
		subq.l		#$01,(a5)
		lea		(l_PassCnt,pc),a5
		addq.l		#$01,(a5)

		move.l		(l_FBlitBase,pc),a5		;release blitter
		exg		a5,a6
		jsr		(_LVOFreeBlitter,a6)
		move.l		a5,a6
		
		bra.s		OldBltBitMap


	;
	;Call the fill function...
	;

FFill:		add.l		(l_DstXFLW,a6),d5		;make dst bmp offset
		move.l		d5,a1
		bsr.s		FillBlit
FFillX: 	move.b		(b_Minterm,a6),d0
		addq.b		#$01,(b_NumPlanes,a6)
		bra.s		FBlitl1s1


	;
	;Call dest inversion...
	;

FDInv:		add.l		(l_DstXFLW,a6),d5
		move.l		d5,a1				;point to first lw
		pea		(FFillX,pc)
		bra		DInvBlit   


	;
	;Special source planes...
	;

FSrc1:		lsr.b		#$02,d0

FSrc0:		and.b		#$30,d0 			;get method

		beq.s		FFill				;$0-fill zero

		cmp.b		#$30,d0
		beq.s		FFill				;$3-fill ones

		cmp.b		#$10,d0
		beq.s		FDInv				;$1-invert dest

		bra.s		FFillX				;$2-do nothing


	;
	;Call old 'BltBitMap' (_NumPlanes and _Mask must be valid) & exit
	;

OldBltBitMap:	movem.l 	(sp)+,d0-d7/a0-a4		;restore everything
		move.b		(b_Mask,a6),d7			;update mask
		move.l		a6,-(sp)			;save stuff

		move.l		(l_OldBlit,pc),a5		;get old BltBitMap
		move.l		(a6),a6 			;get gfxbase
		jsr		(a5)				;do BltBitMap

		move.l		(sp)+,a6			;recover
		move.l		(sp)+,a5			;recover
		add.b		(b_NumPlanes,a6),d0		;add planes I did
		unlk		a6
		rts


	;
	;exit stuff
	;
	
BadExit:	;discard
		lea.l		(l_BrkCnt,pc),a0
		addq.l		#$01,(a0)
		bra.s		GoodExit
DisBlitX:
		move.l		(l_FBlitBase,pc),a5		;release blitter
		exg		a5,a6
		jsr		(_LVOFreeBlitter,a6)
		move.l		a5,a6
GoodExit:
		movem.l 	(sp)+,d0-d7/a0-a5
		move.b		(b_NumPlanes,a6),d0
		extb.l		d0
		unlk		a6

Exit:		rts





	;
	;FillBlit
	;

	include "blits/FillBlit0423.s"


	;
	;DInvBlit
	;

	include "blits/DInvBlit041.s"


	;
	;CopyBlit
	;

	include "blits/PrettyCopyBlit097.s"


	;
	;EmuBlit
	;

	include "blits/EmuBlit072.s"



