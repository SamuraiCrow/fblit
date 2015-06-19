

*-----------------------------------------------------------------------------
*
*	FBlit_lib.s
*
*	© Stephen Brookes 1998-2001
*
*	Support routines for FBlit patches
*
*-----------------------------------------------------------------------------

	machine MC68030

	include "exec/types.i"
	include "exec/initializers.i"
	include "exec/resident.i"
	include "exec/alerts.i"
	include "exec/libraries.i"
	include "exec/semaphores.i"
	include "exec/memory.i"
	include "exec/tasks.i"
	include	"exec/execbase.i"

	include "graphics/gfx.i"
	include "graphics/rastport.i"
	include "graphics/clip.i"
	include "graphics/gels.i"

	include "utility/hooks.i"

	include "lvo/exec_lib.i"
	include "lvo/graphics_lib.i"
	include "lvo/layers_lib.i"
	include	"lvo/intuition_lib.i"
	include	"lvo/utility_lib.i"

	include "fblitbase.i"
	include "fblit_lib.i"


VERSION 	equ		2
REVISION	equ		0



	;
	;don't run me!
	;

main:
		moveq		#-1,d0
		rts



romtag:
	dc.w	RTC_MATCHWORD
	dc.l	romtag
	dc.l	endlib
	dc.b	RTF_AUTOINIT
	dc.b	VERSION
	dc.b	NT_LIBRARY
	dc.b	0
	dc.l	libname
	dc.l	idstring
	dc.l	inittable


libname:
	dc.b	'fblit.library',0

layersname:
	dc.b	'layers.library',0

graphicsname:
	dc.b	'graphics.library',0
	
intuitionname:
	dc.b	'intuition.library',0
	
utilityname:
	dc.b	'utility.library',0		

	dc.b	'$VER: '

idstring:
	dc.b	'fblit.library 2.0 (10.02.2002)',0


	cnop	0,4

inittable:
	dc.l	fblbase_SIZEOF
	dc.l	functable
	dc.l	datatable
	dc.l	libinit


functable:
	dc.l	open
	dc.l	close
	dc.l	expunge
	dc.l	null

	dc.l	VectorBitMap
	dc.l	VectorRastPort
	dc.l	TypeOfBitMap
	dc.l	TypeOfRastPort
	dc.l	Dummy
	dc.l	TemplateBitMap
	dc.l	MakeBTH
	dc.l	BlitEmThin
	dc.l	BlitEmFat
	dc.l	Dummy
	dc.l	Dummy
	dc.l	ReverseLong
	dc.l	GetBlitter
	dc.l	FreeBlitter
	dc.l	FillPlanes
	dc.l	ClearPlanes
	dc.l	CompPlanes
	dc.l	FillTemplatePlanes
	dc.l	ClearTemplatePlanes
	dc.l	CopyTemplatePlanes
	dc.l	CompTemplatePlanes
	dc.l	StackCheck
	dc.l	TemplateRastPort
	dc.l	PatternBitMap
	dc.l	PatternRastPort
	dc.l	FillPatternPlanes
	dc.l	ClearPatternPlanes
	dc.l	CopyPatternPlanes
	dc.l	CompPatternPlanes	
	dc.l	AddFastBOB
	dc.l	RemFastBOB
	dc.l	FillPatternMaskPlanes
	dc.l	ClearPatternMaskPlanes
	dc.l	CopyPatternMaskPlanes
	dc.l	CompPatternMaskPlanes
	dc.l	FillVectorPlanesVert
	dc.l	FillVectorPlanesHoriz
	dc.l	ClearVectorPlanesVert
	dc.l	ClearVectorPlanesHoriz
	dc.l	CopyVectorPlanesVert
	dc.l	CopyVectorPlanesHoriz
	dc.l	CompVectorPlanesVert
	dc.l	CompVectorPlanesHoriz
	dc.l	FillMemory

	dc.l	-1


datatable:
	INITBYTE	LN_TYPE,NT_LIBRARY
	INITLONG	LN_NAME,libname
	INITBYTE	LIB_FLAGS,LIBF_SUMUSED!LIBF_CHANGED
	INITWORD	LIB_VERSION,VERSION
	INITWORD	LIB_REVISION,REVISION
	INITLONG	LIB_IDSTRING,idstring

	dc.l	0


	cnop	0,4

	;
	;init
	;<d0- libbase
	;

libinit:
		movem.l 	d1-d7/a0-a6,-(sp)
		move.l		d0,a5
		move.l		a0,(fbl_SegList,a5)
		move.l		a6,(fbl_ExecBase,a5)
		move.l		(MaxLocMem,a6),d0
		subq.l		#$01,d0
		move.l		d0,(fbl_ChipMax,a5)
		move.l		#MINSTACK,(fbl_MinStack,a5)

		lea		(layersname,pc),a1
		moveq		#39,d0
		jsr		(_LVOOpenLibrary,a6)
		move.l		d0,(fbl_LayersBase,a5)
		bne.s		libins0 				;--> got layers

		ALERT		AG_OpenLib!AO_LayersLib
		bra		libinx					;--> bomb
libins0:
		lea		(graphicsname,pc),a1
		moveq		#39,d0
		jsr		(_LVOOpenLibrary,a6)
		move.l		d0,(fbl_GraphicsBase,a5)
		bne.s		libins1 				;--> got gfx

		ALERT		AG_OpenLib!AO_GraphicsLib
		bra		libinx
libins1:
		lea		(intuitionname,pc),a1
		moveq		#39,d0
		jsr		(_LVOOpenLibrary,a6)
		move.l		d0,(fbl_IntuitionBase,a5)
		beq.s		libinx
		
		lea		(utilityname,pc),a1
		moveq		#39,d0
		jsr		(_LVOOpenLibrary,a6)
		move.l		d0,(fbl_UtilityBase,a5)
		beq.s		libinx
		
		move.l		#BEC_SIZEOF,d0
		move.l		#MEMF_CLEAR|MEMF_FAST,d1
		jsr		(_LVOAllocMem,a6)
		move.l		d0,(fbl_BECustom,a5)

		move.l		#LASTCHANCE_SIZEOF,d0
		move.l		#MEMF_CLEAR|MEMF_FAST,d1
		jsr		(_LVOAllocMem,a6)
		move.l		d0,(fbl_LastChance,a5)

		move.l		#SS_SIZE,d0
		move.l		#MEMF_FAST|MEMF_CLEAR,d1
		jsr		(_LVOAllocMem,a6)
		move.l		d0,(fbl_LCSemaphore,a5)
		tst.l		d0
		beq.s		libinx

		move.l		d0,a0
		jsr		(_LVOInitSemaphore,a6)
		
		clr.l		(fbl_BOBBuf,a5)
		move.l		#SS_SIZE,d0
		move.l		#MEMF_FAST|MEMF_CLEAR,d1
		jsr		(_LVOAllocMem,a6)
		move.l		d0,(fbl_BOBSem,a5)
		tst.l		d0
		beq.s		libinx

		move.l		d0,a0
		jsr		(_LVOInitSemaphore,a6)

libinx:
		move.l		a5,d0
		movem.l 	(sp)+,d1-d7/a0-a6
		rts


	;
	;open
	;<d0- version
	;>d0- libbase
	;

open:
		addq.w		#$01,(LIB_OPENCNT,a6)
		bclr		#LIBB_DELEXP,(LIB_FLAGS,a6)
		move.l		a6,d0
		rts


	;
	;close
	;>d0- null/seglist
	;

close:
		subq.w		#$01,(LIB_OPENCNT,a6)
		bne.s		nullx				;--> still in use

		btst		#LIBB_DELEXP,(LIB_FLAGS,a6)
		bne.s		expunge 			;--> expunge

nullx:
		moveq		#$00,d0
		rts



	;
	;expunge
	;>d0- null/seglist
	;

expunge:
		tst.w		(LIB_OPENCNT,a6)
		beq.s		expuns0 			;--> not in use, kill!!!

		bset		#LIBB_DELEXP,(LIB_FLAGS,a6)
		moveq		#$00,d0
		rts

expuns0:
		movem.l 	d1-d7/a0-a6,-(sp)
		move.l		a6,a5
		move.l		a6,a1
		move.l		(fbl_SegList,a5),d2
		move.l		(fbl_ExecBase,a5),a6
		jsr		(_LVORemove,a6)
		move.l		(fbl_LayersBase,a5),d0
		jsr		(_LVOCloseLibrary,a6)
		move.l		(fbl_GraphicsBase,a5),d0
		jsr		(_LVOCloseLibrary,a6)

		move.l		(fbl_BECustom,a5),a1
		tst.l		a1
		beq.s		expuns1 			;--> no bec

		move.l		#BEC_SIZEOF,d0
		jsr		(_LVOFreeMem,a6)
expuns1:
		move.l		(fbl_LastChance,a5),a1
		tst.l		a1
		beq.s		expuns2

		move.l		#LASTCHANCE_SIZEOF,d0
		jsr		(_LVOFreeMem,a6)
expuns2:
		move.l		(fbl_LCSemaphore,a5),a1
		tst.l		a1
		beq.s		expuns3

		move.l		#SS_SIZE,d0
		jsr		(_LVOFreeMem,a6)
expuns3:
		moveq		#$00,d0
		move.l		a5,a1
		move.w		(LIB_NEGSIZE,a5),d0
		sub.l		d0,a1
		add.w		(LIB_POSSIZE,a5),d0
		jsr		(_LVOFreeMem,a6)
		move.l		d2,d0
		movem.l 	(sp)+,d1-d7/a0-a6
		rts



	;
	;null
	;>d0- null
	;

null:
		moveq		#$00,d0
		rts




	;
	;VectorBitMap	(render vector section to bitmap)
	;
	;<a0- *BitMap
	; d0- aX.w:aY.w 	(vector)
	; d1- bX.w:bY.w
	; d2- MinX.w:MinY.w	(clip Rectangle)
	; d3- MaxX.w:MaxY.w
	; d4- Pen0.b|Pen1.b:Mask.b|Flags.b
	; d5- Pttrn.w:PatCnt.w
	;
	;>
	;
	;all reg's preserved
	;

	include "VectorBitMap56.s"




	;
	;VectorRastPort (render vector to rastport)
	;
	;<a1- *RastPort
	; d0- aX.w:aY.w 	(vector)
	; d1- bX.w:bY.w
	; d2- flags.l
	;
	;
	;>
	;
	;all reg's preserved
	;

VectorRastPort:
		move.l		d7,-(sp)
		movem.l 	d0-d2/a0-a2/a6,-(sp)		;save stuff

	;build cliprect

		cmp.l		d0,d1
		bge.s		VRPfs0				;--> bx=>ax

		exg		d1,d0
VRPfs0:
		cmp.w		d0,d1
		bge.s		VRPfs1				;--> by=>ay

		move.w		d0,d2
		move.w		d1,d0
		move.w		d2,d1
VRPfs1:
		move.l		d1,d2				;d2- maxx:maxy
		sub.l		d0,d2				;d2- deltax:deltay
		move.l		d2,d7
		swap		d7				;d7- #pixels.w(-1)
		cmp.w		d2,d7
		bge.s		VRPfs10 			;--> deltax>=deltay

		move.w		d2,d7
		
	;d0- minx:miny, d1- maxx:maxy, d2- deltax:deltay, d7- xxxx:#pixels(-1)
	;sp- ax:ay, bx:by
	
	;frst_dot stuff
			
VRPfs10:
		bclr		#FB_FRST_DOT,(rp_Flags+1,a1)	;clear frst_dot flag
		bne.s		VRPfs10c			;--> render first pixel

		btst		#FB_COMPLEMENT,(rp_DrawMode,a1)
		beq.s		VRPfs10c			;--> not COMPLEMENT, render first pixel
		
		tst.w		d7
		beq		VRPx				;--> line is only 1 pixel long (exit)
		
		cmp.w		d2,d7
		bgt.s		VRPfs10a			;--> #pixels(-1)>deltay (horizontal)
	
	;frst_dot (V)

		cmp.w		(2,sp),d0
		bne.s		VRPfs10d			;--> ay=maxy
		
		addq.w		#$01,d0				;miny+1
		bra.s		VRPfs10g
VRPfs10d:		
		subq.w		#$01,d1				;maxy-1
VRPfs10g:		
		subq.w		#$01,d2				;deltay-1 (redundant)
		bra.s		VRPfs10c			;--> continue
		
	;frst_dot (H)
			
VRPfs10a:
		swap		d0				;d0- miny:minx
		cmp.w		(sp),d0
		bne.s		VRPfs10e			;--> ax=maxx
		
		addq.w		#$01,d0				;minx+1
		bra.s		VRPfs10f
VRPfs10e:		
		sub.l		#$10000,d1			;maxx-1
VRPfs10f:		
		sub.l		#$10000,d2			;deltax-1 (irrelevent)
		swap		d0				;d0- minx:miny
		
	;on with the show	
					
VRPfs10c:
		tst.l		(rp_Layer,a1)
		bne.s		VRPlayered			;--> layered

		movem.l 	d3-d5,-(sp)
		tst.w		d1
		bmi.s		VRPulX				;--> maxy -ve (not doing this one)
		
		tst.l		d1
		bmi.s		VRPulX				;--> maxx -ve (ditto)
		
		tst.w		d0
		bpl.s		VRPfs11				;--> miny +ve
	
		clr.w		d0
VRPfs11:
		tst.l		d0
		bpl.s		VRPfs12				;--> minx +ve
		
		and.l		#$ffff,d0				
VRPfs12:		
		move.l		(rp_BitMap,a1),a0		;a0- *bitmap
		moveq		#$00,d4
		moveq		#$00,d5
		move.b		(rp_BgPen,a1),d4		
		lsl.l		#$08,d4
		move.b		(rp_FgPen,a1),d4
		lsl.l		#$08,d4
		move.b		(rp_Mask,a1),d4
		lsl.l		#$08,d4		
		move.b		(rp_DrawMode,a1),d4		;d4- pen0|pen1:mask|flags
		move.l		d0,d2				;d2/3- cliprect
		move.l		d1,d3
		move.w		(rp_LinePtrn,a1),d5		;d5- Pttrn
		movem.l 	($0c,sp),d0/d1			;d0/1- vector
		swap		d5				;d5- Pttrn:****
		move.b		(rp_linpatcnt,a1),d5		;d5- Pttrn:00|PatCnt
		jsr		(_LVOVectorBitMap,a6)
VRPulX:		
		movem.l 	(sp)+,d3-d5
		bra.s		VRPx
VRPlayered:
		move.l		sp,d2				;d2- *reg's
		sub.l		#h_SIZEOF+ra_SIZEOF,sp		;struct(Hook),struct(Rectangle)

		lea		(VRPHook,pc),a2
		move.l		sp,a0				;a0- *Hook
		move.l		a2,(h_Entry,a0) 		;hook funtion call
		move.l		d2,(h_Data,a0)			;hook data ($0-Vector,$18-*FBlitBase)
		lea		(h_SIZEOF,sp),a2		;a2- *Rectangle
		movem.l 	d0/d1,(a2)			;set Rectangle

		move.l		(fbl_LayersBase,a6),a6
		jsr		(_LVODoHookClipRects,a6)

		add.l		#h_SIZEOF+ra_SIZEOF,sp		;pop
VRPx:
		movem.l 	(sp)+,d0-d2/a0-a2/a6		;recover
		sub.b		d7,(rp_linpatcnt,a1)
		move.l		(sp)+,d7
		rts

	;
	;Internal Vector->RP render hook
	;
	;<a0- *hook(data->$0-Vector,$18-*FBlitBase)
	; a1- *message(*Layer,struct(Rectangle),Xoff.l,Yoff.l
	; a2- object(*RastPort)
	;
	;>
	;

VRPHook:	movem.l 	d0-d7/a0-a2/a6,-(sp)

		move.l		(h_Data,a0),a0			;a0- data
		move.l		($18,a0),a6			;a6- FBlitBase
		movem.l 	(a0),d0/d1			;d0/d1- vector
		movem.l 	(4,a1),d2/d3/d6/d7		;d2/d3- clip rectangle, d6/7- offset
		moveq		#$00,d4

	;translate vector->cliprect space

		swap		d6				;d6- Xoff:****
		move.l		d2,d5				;d5- MinX:MinY
		clr.w		d6				;d6- Xoff:0000
		sub.w		d7,d5				;d5- MinX:MinY-Yoff
		sub.l		d6,d5				;d5- MinX-Xoff:MinY-Yoff

		add.w		d5,d0
		add.w		d5,d1
		clr.w		d5
		add.l		d5,d0
		add.l		d5,d1

		moveq		#$00,d4
		moveq		#$00,d5
		move.b		(rp_BgPen,a2),d4		
		lsl.l		#$08,d4
		move.b		(rp_FgPen,a2),d4
		lsl.l		#$08,d4
		move.b		(rp_Mask,a2),d4
		lsl.l		#$08,d4		
		move.b		(rp_DrawMode,a2),d4		;d4- pen1|pen0:mask|flags
		move.w		(rp_LinePtrn,a2),d5		;d5- Pttrn
		swap		d5				;d5- Pttrn:****
		move.b		(rp_linpatcnt,a2),d5		;d5- Pttrn:00|PatCnt
		move.l		(rp_BitMap,a2),a0
		jsr		(_LVOVectorBitMap,a6)

		movem.l 	(sp)+,d0-d7/a0-a2/a6
		rts





	;
	;TypeOfBitMap (return memory type of bitmap planes)
	;
	;<a0- *BitMap
	; d1- mask.l	(bitmap mask of active planes)
	;
	;>d0- null if all data in chip mem
	;
	;all other reg's preserved
	;

TypeOfBitMap:
		movem.l 	d2/d7,-(sp)
		moveq		#$00,d7
		move.l		(fbl_ChipMax,a6),d0		;d0- chipmax
		move.b		(bm_Depth,a0),d7		;d7- depth
		subq.l		#$01,d7
		bmi.s		TOBMx				;--> bad depth

TOBMl1: 	btst		d7,d1
		beq.s		TOBMs0				;--> plane innactive

		move.l		(bm_Planes,a0,d7.l*4),d2	;d2- *plane

		cmp.l		d2,d0
		bge.s		TOBMs0				;--> chip plane

		not.l		d2
		bne.s		TOBMx				;--> non-chip plane

TOBMs0: 	dbra		d7,TOBMl1

		moveq		#$00,d0
TOBMx:		movem.l 	(sp)+,d7/d2
		rts




	;
	;TypeOfRastPort (return memory type of rastports planes)
	;
	;<a1- *RastPort
	;
	;>d0- null if all data in chip mem
	;
	;all other reg's preserved
	;note: layers must be locked before calling this!
	;

TypeOfRastPort:
		movem.l 	d1-d2/a0-a1,-(sp)
		move.l		(fbl_ChipMax,a6),d2		;d2- chipmax
		moveq		#$00,d1
		move.l		(rp_BitMap,a1),a0
		move.b		(rp_Mask,a1),d1 		;d1- rpmask
		bsr		TypeOfBitMap
		tst.l		d0
		bne.s		TORPfx				;--> non-chip

		move.l		(rp_TmpRas,a1),a0		;a0- *tmpras
		tst.l		a0
		beq.s		TORPs0				;--> no tmpras

		cmp.l		(tr_RasPtr,a0),d2
		bcs.s		TORPfx				;--> non-chip

TORPs0: 	move.l		(rp_Layer,a1),a1		;a1- *Layer
		tst.l		a1
		beq.s		TORPcx				;--> all chip

		move.l		(lr_SuperBitMap,a1),a0		;a0- *BitMap
		tst.l		a0
		beq.s		TORPs1				;--> no supbitmap

		bsr		TypeOfBitMap
		tst.l		d0
		bne.s		TORPfx				;--> non chip

TORPs1: 	move.l		(lr_ClipRect,a1),a1		;a1- *ClipRect
		tst.l		a1
		beq.s		TORPcx				;--> all chip

TORPs11:	move.l		(cr_BitMap,a1),a0		;a0- *BitMap
		tst.l		a0
		beq.s		TORPs2				;--> no bitmap

		bsr		TypeOfBitMap
		tst.l		d0
		bne.s		TORPfx				;--> non chip

TORPs2: 	move.l		(cr_Next,a1),a1
		tst.l		a1
		bne.s		TORPs11 			;--> next ClipRect

TORPcx: 	moveq		#$00,d0
		bra.s		TORPx

TORPfx: 	moveq		#$01,d0

TORPx:		movem.l 	(sp)+,d1-d2/a0-a1
		rts



	;
	;no function
	;

Dummy:
		movem.l		d0-d7/a0-a6,-(sp)
		move.l		(fbl_ExecBase,a6),a6
		move.l		#AO_Unknown,d7
		jsr		(_LVOAlert,a6)
		movem.l		(sp)+,d0-d7/a0-a6
		rts
		


		
		

	;
	;TemplateBitMap (fill a rectangular region with template and stuff)
	;<d0- minx.w:miny.w	(rectangle in bitmap)
	; d1- maxx.w:maxy.w
	; d2- pen0.b|pen1.b:mask.b|flags.b
	; d3- minxt.w:minyt.w	(top left in template)
	;
	; a0- *BitMap
	; a1- *template (2d array)
	; a2- template row modulo
	;
	;>
	;all reg's preserved
	;*template=0 effect whole rectangle
	;
	;flags- none		(rectangle/mask 1s set to pen1)
	;	FB_JAM2 	(rectangle/mask 1s set to pen1, mask 0s set to pen0)
	;	FB_COMPLEMENT	(rectangle/mask 1s complement dest)
	;	FB_INVERSVID	(combines with previous and inverts mask)
	;

	include "TemplateBitMap04.s"






	;
	;MakeBTH (calculate BTH etc.)
	;<d0- start bit
	; d1- end bit
	;
	;>d0- start bit# within first lw
	; d1- BTH (body(#lw):tail(#bits)|head(#bits)
	; d2- byte offset to first lw
	;
	;all other reg's preserved
	;

MakeBTH:
		movem.l 	d3-d4,-(sp)
		sub.l		d0,d1				;d1- #bits-1
		moveq		#$1f,d4
		move.l		d0,d2				;d2- start
		and.l		d4,d0				;d0- start bit# in first lw
		move.l		#$20,d3
		sub.l		d0,d2
		asr.l		#$03,d2 			;d2- byte offset to first lw
		sub.l		d0,d3
		and.l		d4,d3				;d3- 0000:00|#head bits
		addq.l		#$01,d1 			;d1- #bits
		cmp.l		d1,d3
		bcc.s		MBTHx				;--> #headbits>=#bits

		sub.l		d3,d1				;d1- #bits-#head bits
		and.l		d1,d4				;d4- #tail bits
		sub.l		d4,d1				;d1- #body bits
		lsl.w		#$08,d4 			;d4- #tail bits|00
		lsr.l		#$05,d1 			;d1- 0000:#body lws
		or.w		d4,d3				;d3- #tail bits|#head bits
		swap		d1				;d1- #body lws:0000
		move.w		d3,d1				;d1- #body lws:#tail bits|#head bits
MBTHx:
		movem.l 	(sp)+,d3-d4
		rts




	;
	;BlitEm......
	;

	include "BlitEm/BlitEm0044.s"



	;
	;ReverseLong
	;<d0- long
	;
	;>d0- reversed(bitwise) long
	;

ReverseLong:
		movem.l 	d1/d2,-(sp)

		moveq		#$1f,d2
RLl0:
		add.l		d0,d0
		roxr.l		#$01,d1
		dbra		d2,RLl0

		move.l		d1,d0

		movem.l 	(sp)+,d1/d2
		rts




	;
	;planes stuff (no data)
	;

	include "Planes04.s"






	;
	;more planes stuff (with mask)
	;

	include "TempPlanes14.s"






	;
	;StackCheck	(check caller for stack overflow)
	;<
	;
	;>
	;all reg's preserved
	;

StackCheck:
		movem.l 	d0-d1/d7/a0-a1/a6,-(sp)

		move.l		(fbl_MinStack,a6),d7
		sub.l		a1,a1
		move.l		(fbl_ExecBase,a6),a6
		jsr		(_LVOFindTask,a6)
		tst.l		d0
		beq.s		SCx					;--> no task

		move.l		d0,a0
		move.l		sp,d1
		move.l		(TC_SPLOWER,a0),a0
		sub.l		a0,d1
		bcc.s		SCs1					;--> no overflow
SCs0:
		move.l		#$c0ded00d,d0
		sub.l		a1,a1
		move.l		(a1),a1
		bra.s		SCx
SCs1:
		cmp.l		d7,d1
		blt.s		SCs0					;--> <minstack
SCx:
		movem.l 	(sp)+,d0-d1/d7/a0-a1/a6
		rts







	;
	;TemplateRastPort (fill a rectangular region with template and stuff)
	;<d0- minx.w:miny.w	(rectangle in rastport)
	; d1- maxx.w:maxy.w
	; d2- flags.l
	; d3- minxt.w:minyt.w	(top left in template)
	;
	; a0- *template (2d array)
	; a1- *rastport
	; a2- template row modulo
	;
	;>
	;all reg's preserved
	;*template=0 effects whole rectangle
	;

TemplateRastPort:

		movem.l 	d0-d3/a0-a2/a6,-(sp)
		tst.l		(rp_Layer,a1)
		bne.s		TRPLayered			;--> layers
		
		move.b		(rp_BgPen,a1),d2
		lsl.l		#$08,d2
		move.b		(rp_FgPen,a1),d2
		lsl.l		#$08,d2
		move.b		(rp_Mask,a1),d2
		lsl.l		#$08,d2
		move.b		(rp_DrawMode,a1),d2		;d2- pen0|pen1:mask|flags
		move.l		(rp_BitMap,a1),a1
		exg		a0,a1				;a1- *template, a0- *bitmap
		jsr		(_LVOTemplateBitMap,a6)
		bra.s		TRPx				;--> exit
TRPLayered:
		move.l		sp,d2				;d2- *reg's
		sub.l		#h_SIZEOF+ra_SIZEOF,sp		;struct(Hook),struct(Rectangle)

		lea		(TRPHook,pc),a2
		move.l		sp,a0				;a0- *Hook
		move.l		a2,(h_Entry,a0) 		;hook funtion call
		move.l		d2,(h_Data,a0)			;hook data ($0-Rect,$c-temp top left
								;$10-*temp,$18-tempmod,$1c-*FBlitBase)
		lea		(h_SIZEOF,sp),a2		;a2- *Rectangle
		movem.l 	d0/d1,(a2)			;set Rectangle

		move.l		(fbl_LayersBase,a6),a6
		jsr		(_LVODoHookClipRects,a6)

		add.l		#h_SIZEOF+ra_SIZEOF,sp		;pop
TRPx:
		movem.l 	(sp)+,d0-d3/a0-a2/a6
		rts

	;
	;Internal Template->RP render hook
	;
	;<a0- *hook(data->$0-Rect,$c-tempTL,$10-*temp,$18-tempmod,$1c-*FBlitBase)
	; a1- *message(*Layer,struct(Rectangle),Xoff.l,Yoff.l
	; a2- object(*RastPort)
	;
	;>
	;

TRPHook:	movem.l 	d0-d7/a0-a3/a6,-(sp)

		move.l		(h_Data,a0),a0			;a0- data
		move.l		($1c,a0),a6			;a6- FBlitBase
		movem.l 	(a0),d0-d3			;d0-d3- rect, tempTL
		movem.l 	(4,a1),d4-d7			;d4/d5- clip rectangle, d6/7- offset

	;translate template->cliprect space

		swap		d6				;d6- Xoff:****
		sub.w		d0,d7				;d7- ****:RectYoff
		move.w		d0,d6
		sub.l		d0,d6				;d6- RectXoff:0000
		add.w		d7,d3
		add.l		d6,d3				;d3- minxt:minyt
		move.l		d4,d0				;d0- minx:miny
		move.l		d5,d1				;d1- maxx:maxy

		move.b		(rp_BgPen,a2),d2
		lsl.l		#$08,d2
		move.b		(rp_FgPen,a2),d2
		lsl.l		#$08,d2
		move.b		(rp_Mask,a2),d2
		lsl.l		#$08,d2
		move.b		(rp_DrawMode,a2),d2		;d2- pen0|pen1:mask|flags
		move.l		(rp_BitMap,a2),a3
		move.l		($10,a0),a1			;a1- *template
		move.l		($18,a0),a2			;a2- tempmod
		move.l		a3,a0				;a0- *bitmap
		jsr		(_LVOTemplateBitMap,a6)

		movem.l 	(sp)+,d0-d7/a0-a3/a6
		rts



	;
	;PatternBitMap (fill a rectangular region with 16bit pattern, masking etc.)
	;<d0- minx.w:miny.w	(rectangle in bitmap)
	; d1- maxx.w:maxy.w
	; d2- pen0.b|pen1.b:mask.b|flags.b
	; d3- minxm.w:minym.w	(top left in mask)
	; d4- patx.w:paty.w	(top left in pattern)
	; d5- patsize.l		(power of 2, height of pattern)
	;
	; a0- *BitMap
	; a1- *mask (2d array)
	; a2- mask row modulo
	; a3- *pattern (array of word*2^patsize(*bm_Depth if -ve patsize))
	;
	;>
	;all reg's preserved
	;*mask=0 effects whole rectangular region
	;*pattern=0 interpreted as pattern of all 1s and nullyfies INVERSVID
	;
	;flags- none		(rectangle/mask AND pattern 1s set to pen1)
	;	FB_JAM2 	(rectangle/mask AND pattern 1s set to pen1, AND pattern 0s set to pen0)
	;	FB_COMPLEMENT	(rectangle/mask AND pattern 1s complement dest)
	;	FB_INVERSVID	(combines with previous and inverts pattern (if specified!))
	;

	include "PatternBitMap10.s"
	
	
	
	;
	;PatternRastPort (fill a rectangular region with masking using areafill rules)
	;<d0- minx.w:miny.w	(rectangle in rastport)
	; d1- maxx.w:maxy.w
	; d2- flags.l
	; d3- minxm.w:minym.w	(top left in mask)
	;
	; a0- *mask (2d array)
	; a1- *rastport
	; a2- mask row modulo
	;
	;>
	;all reg's preserved
	;

PatternRastPort:

		movem.l 	d0-d3/a0-a2/a6,-(sp)
		tst.l		(rp_Layer,a1)
		bne.s		PRPLayered			;--> layers
		
		movem.l		d4/d5/a3/a4,-(sp)
		
		move.b		(rp_BgPen,a1),d2
		lsl.l		#$08,d2
		move.b		(rp_FgPen,a1),d2
		moveq		#$00,d5
		lsl.l		#$08,d2
		move.b		(rp_Mask,a1),d2
		lsl.l		#$08,d2
		move.b		(rp_AreaPtSz,a1),d5		;d5- pattern size
		move.l		a4,d4				;d4- patx:paty
		move.b		(rp_DrawMode,a1),d2		;d2- pen0|pen1:mask|flags
		move.l		(rp_AreaPtrn,a1),a3		;a3- *pattern
		move.l		(rp_BitMap,a1),a1
		exg		a0,a1				;a1- *mask, a0- *bitmap
		jsr		(_LVOPatternBitMap,a6)
		
		movem.l		(sp)+,d4/d5/a3/a4
		bra.s		PRPx				;--> exit
PRPLayered:
		move.l		sp,d2				;d2- *reg's
		sub.l		#h_SIZEOF+ra_SIZEOF,sp		;struct(Hook),struct(Rectangle)

		lea		(PRPHook,pc),a2
		move.l		sp,a0				;a0- *Hook
		move.l		a2,(h_Entry,a0) 		;hook funtion call
		move.l		d2,(h_Data,a0)			;hook data ($0-Rect,$c-temp top left
								;$10-*temp,$18-tempmod,$1c-*FBlitBase)
		lea		(h_SIZEOF,sp),a2		;a2- *Rectangle
		movem.l 	d0/d1,(a2)			;set Rectangle

		move.l		(fbl_LayersBase,a6),a6
		jsr		(_LVODoHookClipRects,a6)

		add.l		#h_SIZEOF+ra_SIZEOF,sp		;pop
PRPx:
		movem.l 	(sp)+,d0-d3/a0-a2/a6
		rts

	;
	;Internal Pattern->RP render hook
	;
	;<a0- *hook(data->$0-Rect,$c-maskTL,$10-*mask,$18-maskmod,$1c-*FBlitBase)
	; a1- *message(*Layer,struct(Rectangle),Xoff.l,Yoff.l
	; a2- object(*RastPort)
	;
	;>
	;

PRPHook:	movem.l 	d0-d7/a0-a4/a6,-(sp)

		move.l		(h_Data,a0),a0			;a0- data
		move.l		($1c,a0),a6			;a6- FBlitBase
		movem.l 	(a0),d0-d3			;d0-d3- rect, tempTL
		movem.l 	(4,a1),d4-d7			;d4/d5- clip rectangle, d6/7- offset

	;translate mask->cliprect space

		swap		d6				;d6- Xoff:****
		move.w		d7,d6
		move.l		d6,a4				;a4- Xoff:Yoff
		sub.w		d0,d7				;d7- ****:RectYoff
		move.w		d0,d6
		sub.l		d0,d6				;d6- RectXoff:0000
		add.w		d7,d3
		add.l		d6,d3				;d3- minxm:minym
		move.l		d4,d0				;d0- minx:miny
		move.l		d5,d1				;d1- maxx:maxy

		move.b		(rp_BgPen,a2),d2
		lsl.l		#$08,d2
		move.b		(rp_FgPen,a2),d2
		moveq		#$00,d5
		lsl.l		#$08,d2
		move.b		(rp_Mask,a2),d2
		lsl.l		#$08,d2
		move.b		(rp_AreaPtSz,a2),d5		;d5- pattern size
		move.l		a4,d4				;d4- patx:paty
		move.b		(rp_DrawMode,a2),d2		;d2- pen0|pen1:mask|flags
		move.l		(rp_BitMap,a2),a4
		move.l		($10,a0),a1			;a1- *mask
		move.l		(rp_AreaPtrn,a2),a3		;a3- *pattern
		move.l		($18,a0),a2			;a2- maskmod
		move.l		a4,a0				;a0- *bitmap
		jsr		(_LVOPatternBitMap,a6)

		movem.l 	(sp)+,d0-d7/a0-a4/a6
		rts



	;
	;pattern planes stuff
	;

	include "PatternPlanes01.s"
	
	
	
	;
	;AddFastBOB (copy any fast mem vsprite BOB to chip)
	;>a0- *BOB
	;
	;<
	;all reg's preserved
	;
	
AddFastBOB:
		movem.l		d0/a3,-(sp)
					
	;check for fast BOBitis
			
		move.l		(bob_BobVSprite,a0),a3		;a3- *vsprite
		tst.l		a3
		beq		afbx				;--> no vprite (duh!)
			
		move.l		(vs_ImageData,a3),d0		;d0- *image
		beq		afbx				;--> no image
		
		cmp.l		(fbl_ChipMax,a6),d0
		bcs		afbx				;--> chip image
		
	;fast image
		
		movem.l		d1/d3/d4/a0-a2/a5,-(sp)
		move.l		a6,a5				;a5- fblbase
		move.l		(fbl_ExecBase,a5),a6		;a6- execbase
		move.l		(fbl_BOBSem,a5),a0
		jsr		(_LVOObtainSemaphore,a6)
		
		move.w		(vs_Width,a3),d3
		add.w		d3,d3
		mulu.w		(vs_Height,a3),d3
		mulu.w		(vs_Depth,a3),d3		;d3- sizeof image
	
	;initialize buffers?
	
		move.l		(fbl_BOBBuf,a5),d0		;d0- *BOB buf
		bne.s		afbs0				;--> allready have a buffer
		
		move.l		d0,(fbl_BOBCnt,a5)		;clear bobcnt
		lea		(fbl_BOBBuf,a5),a2		;a2- **buffer
		bsr.s		afbaddbuf
		
		tst.l		d0
		beq.s		afbxa				;--> no room

	;buffer big enough? (d0- *buffer, d3- sizeof image)
afbs0:
		move.l		d0,a2
		move.l		(4,a2),d2			;d2- sizeof buffer
		move.l		(8,a2),d4			;d4- next BOB offset
		add.l		d3,d4
		addq.l		#$04,d4				;d4- next next BOB offset
		cmp.l		d2,d4
		bcs.s		afbs2				;--> room enough...
		
		move.l		(a2),d0
		bne.s		afbs0				;--> try next buffer		
		
	;add a buffer...
		
		bsr.s		afbaddbuf
		
		tst.l		d0
		beq.s		afbxa				;--> no room
		
		move.l		d0,a2	
		
	;copy image (a3- *vsprite, a2- *bobbuf, d3- sizeof image)
afbs2:
		move.l		(8,a2),d0			;d0- this entry offset
		lea		(fbl_BOBCnt,a5),a0
		addq.l		#$01,(a0)			;count BOB		
		lea		(a2,d0.l),a1			;*this entry
		add.l		d3,d0
		move.l		(vs_ImageData,a3),a0		;a0- source
		addq.l		#$04,d0				;d0- next entry offset
		move.l		a0,(a1)+			;a1- dest (and save old image pointer)
		move.l		d0,(8,a2)			;save next entry offset
		move.l		a1,(vs_ImageData,a3)		;update vsprite *image
		move.l		d3,d0				;d0- size
		jsr		(_LVOCopyMem,a6)
afbxa:
		move.l		(fbl_BOBSem,a5),a0
		jsr		(_LVOReleaseSemaphore,a6)
		
		move.l		a5,a6				;restore a6
		movem.l		(sp)+,d1/d3/d4/a0-a2/a5
afbx:
		movem.l		(sp)+,d0/a3
		rts
		
	;'add a buffer', internal subroutine (a2- *current buffer, d3- sizeof current BOB)
	
afbaddbuf:		
		move.l		#BOBBUF_SIZEOF,d2
		moveq		#$00,d0
afbadl0:
		lsr.l		#$01,d2
		cmp.l		#$2000,d2
		bcs.s		afbadx				;--> not enough mem
		
		sub.l		#$10,d2
		cmp.l		d2,d3
		bcc.s		afbadx				;--> buffer too small
		
		add.l		#$10,d2
		move.l		d2,d0
		move.l		#MEMF_CHIP,d1
		jsr		(_LVOAllocMem,a6)
		
		tst.l		d0
		beq.s		afbadl0				;--> no mem, try again
		
		clr.l		(d0.l)				;clear *next buffer
		move.l		d2,(4,d0.l)			;save size
		move.l		d0,(a2)				;set *this biffer
		move.l		#$0c,(8,d0.l)			;offset to next BOB
afbadx:		
		rts
		
	


	
	;
	;RemFastBOB (remove a fast BOB from chip mem)
	;<a0- *BOB
	;
	;>
	;all reg's preserved
	;
	
RemFastBOB:
		movem.l		d1/a1/a2,-(sp)
	
		move.l		(bob_BobVSprite,a0),a2		;a2- *vsprite
		tst.l		a2
		beq.s		rfbx				;--> no vprite (duh!)
			
		move.l		(vs_ImageData,a2),d1		;d1- *image
		beq.s		rfbx				;--> no image
		
		lea		(fbl_BOBBuf,a6),a1		;a1- **buffer
		tst.l		(a1)
		beq.s		rfbx				;--> I have no BOBs
		
		movem.l		d0/d2/a0/a5,-(sp)
		move.l		a6,a5				;a5- fblbase
		move.l		(fbl_ExecBase,a5),a6		;a6- execbase
		move.l		(fbl_BOBSem,a5),a0
		jsr		(_LVOObtainSemaphore,a6)
		
	;is BOB one of mine?
rfbl1:		
		move.l		(a1),d0				;d0- next buffer
		beq.s		rfbxa				;--> no more buffers
		
		move.l		d0,a1				;a1- *buffer
		cmp.l		d0,d1
		bcs.s		rfbl1				;--> not mine (lower than buffer)
		
		add.l		(4,a1),d0			;d1- end of buffer
		cmp.l		d0,d1
		bcc.s		rfbl1				;--> not mine (higher than buffer)
		
	;BOB is mine!!?!
rfbs1:					
		move.l		(-4,d1.l),(vs_ImageData,a2)	;restore old image pointer	
		lea		(fbl_BOBCnt,a5),a1
		subq.l		#$01,(a1)			;uncount BOB
		bne.s		rfbxa				;--> not the last one
		
	;all BOBs gone, scrap buffers
			
		move.l		(fbl_BOBBuf,a5),a2		;a2- this buffer
rfbl2:		
		move.l		a2,a1				;a1- this buffer
		move.l		(a1),a2				;a2- next buffer
		move.l		(4,a1),d0			;d0- size of buffer
		jsr		(_LVOFreeMem,a6)		;free the buffer
		
		tst.l		a2
		bne.s		rfbl2				;--> more buffers
		
		clr.l		(fbl_BOBBuf,a5)
rfbxa:
		move.l		(fbl_BOBSem,a5),a0
		jsr		(_LVOReleaseSemaphore,a6)
		
		move.l		a5,a6
		movem.l		(sp)+,d0/d2/a0/a5		
rfbx:	
		movem.l		(sp)+,d1/a1/a2
		rts		



	;
	;pattern mask planes stuff
	;

	include "PatternMaskPlanes02.s"
	



	;
	;vector(pattern) planes
	;
	
	include "VectorPlanes14.s"
	




	;
	;GetBlitter
	;<
	;
	;>
	;

GetBlitter:
		movem.l 	d0/d1/a0/a1/a6,-(sp)

		move.l		(fbl_GraphicsBase,a6),a6
		jsr		(_LVOOwnBlitter,a6)
		jsr		(_LVOWaitBlit,a6)

		movem.l 	(sp)+,d0/d1/a0/a1/a6
		rts




	;
	;FreeBlitter
	;<
	;
	;>
	;

FreeBlitter:
		movem.l 	d0/d1/a0/a1/a6,-(sp)

		move.l		(fbl_GraphicsBase,a6),a6
		jsr		(_LVODisownBlitter,a6)

		movem.l 	(sp)+,d0/d1/a0/a1/a6
		rts




	;
	;FillMemory
	;fill/clear some memory
	;<
	;
	;>
	;
	
	include "FillMemory1.s"


endlib:


