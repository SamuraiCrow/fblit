

*-----------------------------------------------------------------------------
*
*	PrettyCopyBlit.s V0.97 08.04.2000
*
*	© Stephen Brookes 1997-2000
*
*	Copy(&inv) a region in pretty (slow) mode.
*
*-----------------------------------------------------------------------------
*
*
*	Input:
*
*			_DstBmpDelta	- inter row delta
*			_DstStart	- dest start bit
*			_BTH2		- body:tail/head(non-combined!)
*			_Rows		- #rows
*			_Left		- null-right, else left
*			_LExempt	- null-right, else '_Left'
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




PCopyBlitI:
		moveq		#-1,d0				;invert
		bra.s		PCBlits1
PCopyBlit:
		clr.l		d0				;non-inverting
PCBlits1:
		move.w		(w_DynNP,a6),d1			;set planes done
		addq.w		#$01,d1				;to final value
		add.b		d1,(b_NumPlanes,a6)
		
		move.l		(l_DstStart,a6),d5		;d5 - dst start
		move.l		(l_SrcStart,a6),d4		;d4 - src start
		move.l		(l_SrcXFLW,a6),a4		;a4 - src offset




	;do small blits (<33bits) here
	;this is mostly to simplify the non-aligned copy operation later
	
		move.w		(w_SizeX,a6),d6
		cmp.w		#$21,d6
		bcc.s		PCBlitfat			;--> >1lw
		
		moveq		#$00,d7
		move.l		(l_DstXFLW,a6),a3		;a3 - dst offset
		move.w		(w_Rows,a6),d2			;d2 - rows
		move.w		(w_DynNP,a6),d7
		move.l		(l_SrcBmpDelta,a6),a2
		move.l		(l_DstBmpDelta,a6),a5
		
	;start of row loop

PCBSRow:
		move.l		d7,d3

	;start of the plane loop

PCBSPlane:
		move.l		(_Planes,a6,d3.l*8),a0		;fetch planes (dst)
		move.l		(4+_Planes,a6,d3.l*8),a1	;(src)
		add.l		a3,a0
		add.l		a4,a1

		bfextu		(a1){d4:d6},d1			;get src field
		eor.l		d0,d1				;invert (maybe)
		bfins		d1,(a0){d5:d6}			;put dest field

		dbra		d3,PCBSPlane

		add.l		a2,a4				;next row
		add.l		a5,a3
		
		dbra		d2,PCBSRow
		
		bra		DisBlitX




		
	;deal with big blits		

PCBlitfat:
		move.l		(l_BTH2,a6),d7			;set up static reg's
		move.l		d7,d2
		move.w		(w_Rows,a6),d2			;d2-body:rows (for a2)
		move.b		d7,d6
		extb.l		d6				;d6-head
		lsr.w		#$08,d7
		ext.l		d7				;d7-tail
		sub.l		#$10000,d2			;body-1
		
		move.b		(b_FBFlags,a6),d1
		tst.l		d0
		bne		PCBlitRight			;--> inverted op'
		
		btst		#FBF_ALIGNED,d1
		beq		PCBlitRight			;non-aligned



	;** Aligned copy only blit

PCBlitAlig:	moveq		#0,d0
		bfset		d0{d5:d6}			;d0-head imask
		move.l		d0,d5
		not.l		d5				;d5-head xmask

		moveq		#0,d3
		bfset		d3{0:d7}			;d3-tail imask
		move.l		d3,d4
		not.l		d4				;d4-tail xmask
		
		btst		#FBF_LEXEMPT,d1
		bne.s		PCBlitARight
		btst		#FBF_LEFT,d1
		bne.s		PCBlitALeft

PCBlitARight:	move.l		(l_DstXFLW,a6),a3		;a3-dst offset

	;start of row loop

PCBARow:	move.w		(w_DynNP,a6),d1
		swap		d2
		move.l		d2,a2				;a2-rows:body


	;start of the plane loop

PCBAPlane:
		move.l		(_Planes,a6,d1.w*8),a0		;fetch planes (dst)
		move.w		d1,a5				;a5-#planes store
		move.l		(4+_Planes,a6,d1.w*8),a1	;(src)
		add.l		a3,a0				;dst to 1st lw
		add.l		a4,a1				;src to 1st lw

PCBAHead:	tst.b		d6				;any head?
		beq.s		PCBABody

		move.l		(a1)+,d1			;src
		move.l		d5,d2				;copy hxmask
		and.l		d0,d1				;extract source data
		and.l		(a0),d2				;extract dest data
		or.l		d1,d2				;combine
		move.l		d2,(a0)+			;write


PCBABody:	move.l		a2,d2				;any body?
		tst.w		d2
		bmi.s		PCBATail

		lsr.w		#$01,d2
		bcc.s		PCBABl1s0

PCBABl1:	move.l		(a1)+,(a0)+			;copy...
PCBABl1s0:	move.l		(a1)+,(a0)+
		dbra		d2,PCBABl1


PCBATail:	tst.b		d7				;any tail?
		beq.s		PCBAPlaneX

		move.l		(a1),d1
		move.l		d4,d2				;txmask...
		and.l		d3,d1
		and.l		(a0),d2
		or.l		d1,d2
		move.l		d2,(a0)


PCBAPlaneX:	move.w		a5,d1				;next plane
		dbra		d1,PCBAPlane


PCBARowX:	move.l		a2,d2
		swap		d2
		add.l		(l_SrcBmpDelta,a6),a4		;next row
		add.l		(l_DstBmpDelta,a6),a3
		dbra		d2,PCBARow
		bra		DisBlitX



PCBlitALeft:	move.l		(l_DstXLLW,a6),a3		;a3-dst offset
		move.l		(l_SrcXLLW,a6),a4
		addq.l		#$04,a3				;point to next lw
		addq.l		#$04,a4				;for pre-dec nonsense


PCBALRow:	move.w		(w_DynNP,a6),d1
		swap		d2
		move.l		d2,a2


PCBALPlane:	move.l		(_Planes,a6,d1.w*8),a0
		move.w		d1,a5
		move.l		(4+_Planes,a6,d1.w*8),a1
		add.l		a3,a0
		add.l		a4,a1


PCBALTail:	tst.b		d7
		beq.s		PCBALBody

		move.l		-(a1),d1
		move.l		d4,d2
		and.l		d3,d1
		and.l		-(a0),d2
		or.l		d1,d2
		move.l		d2,(a0)


PCBALBody:	move.l		a2,d2
		tst.w		d2
		bmi.s		PCBALHead

		lsr.w		#$01,d2
		bcc.s		PCBALBl1s0
		
PCBALBl1:	move.l		-(a1),-(a0)
PCBALBl1s0:	move.l		-(a1),-(a0)
		dbra		d2,PCBALBl1



PCBALHead:	tst.b		d6
		beq.s		PCBALPlaneX

		move.l		-(a1),d1
		move.l		d5,d2
		and.l		d0,d1
		and.l		-(a0),d2
		or.l		d1,d2
		move.l		d2,(a0)


PCBALPlaneX:	move.l		a5,d1
		dbra		d1,PCBALPlane


PCBALRowX:	move.l		a2,d2
		swap		d2
		add.l		(l_SrcBmpDelta,a6),a4
		add.l		(l_DstBmpDelta,a6),a3
		dbra		d2,PCBALRow
		bra		DisBlitX



	;non-aligned nonsense
	;
	;d0 - invertion 	(****)
	;d1 - flags 		(****)
	;d2 - body-1:rows 	(****)
	;d3 - ****		(****)
	;d4 - src start 	(!src split mask)
	;d5 - dst start		(dst start)
	;d6 - head		(src split mask)
	;d7 - tail 		(src shift)
	;a0 - **** 		(dst plane)
	;a1 - **** 		(src plane)
	;a2 - **** 		(#planes:rows)
	;a3 - **** 		(dst offset)
	;a4 - src offset	(src offset)
	;a5 - **** 		(BTH)
	;a6 - data area base	(data area base)




PCBlitRight:
		btst		#FBF_LEXEMPT,d1
		bne.s		PCBRs0				;--> left exempt (doesn't matter, so
								;    go right)
		btst		#FBF_LEFT,d1
		bne		PCBlitLeft			;--> go left
PCBRs0:		
		move.l		(l_DstXFLW,a6),a3		;a3- dst offset
		exg.l		d4,d7				;d7- src start : d4- tail
		move.l		(l_BTH2,a6),a5			;a5- body:tail|head
		
		moveq		#-1,d6
		sub.l		d5,d7				;d7- src shift
		bpl.s		PCBRs1				;--> +ve shift
		
		add.b		#$20,d7				;make shift +ve
PCBRs1:
		lsr.l		d7,d6				;d6- src split mask
		not.l		d6				;d6- !src split mask
		
		moveq		#$20,d1
		sub.b		d7,d1				;d1- #pixels represented by src mask
		cmp.b		d4,d1
		bcc.s		PCBRRow				;--> tail<=#src mask pixels
								;    (skip last lw (for +ve shift))
		bset		#$0f,d7
		
	;start of row loop

PCBRRow:
		swap		d2				;d2- rows:****
		move.w		(w_DynNP,a6),d2			;d2- rows:#planes

	;start of the plane loop

PCBRPlane:
		move.l		(_Planes,a6,d2.w*8),a0		;fetch plane (dst)
		move.l		(4+_Planes,a6,d2.w*8),a1	;(src)
		add.l		a3,a0				;a0- 1st dst lw
		move.l		d2,a2				;a2- rows:#planes
		add.l		a4,a1				;a1- 1st src lw
		move.l		a5,d3				;d3- BTH
		moveq		#$00,d4
		
		tst.l		d7
		bmi.s		PCBRHead			;--> was -ve (all data is in next lw)
		
		move.l		(a1)+,d4			;otherwise, pre-charge real data
		not.l		d6
		eor.l		d0,d4
		and.l		d6,d4
		not.l		d6
PCBRHead:
		tst.b		d3	
		beq.s		PCBRBody			;--> no head

		move.l		(a1)+,d1			;d1- next src lw
		move.l		d6,d2				;d2- !src split mask
		eor.l		d0,d1
		and.l		d1,d2				;d2- valid new data
		sub.l		d2,d1
		or.l		d4,d2				;merge data
		rol.l		d7,d2				;align data
		bfins		d2,(a0){d5:d3}			;put dest field
		move.l		d1,d4				;d4- last src lw
		addq.l		#$04,a0 			;next dest
PCBRBody:
		swap		d3				;d3- tail|head:body
		subq.w		#$01,d3
		bmi.s		PCBRTail			;--> no body
PCBRBl1:
		move.l		(a1)+,d1			;d1- next src lw
		move.l		d6,d2				;d2- !src split mask
		eor.l		d0,d1
		and.l		d1,d2				;d2- valid data from next src lw
		sub.l		d2,d1
		or.l		d4,d2				;merge data
		rol.l		d7,d2				;align data
		move.l		d2,(a0)+			;put dest (and next dest)
		move.l		d1,d4				;d4- last src lw
		dbra		d3,PCBRBl1			;--> do all body lws
PCBRTail:
		rol.l		#$08,d3
		tst.b		d3
		beq.s		PCBRPlaneX			;--> no tail

		tst.w		d7
		bpl.s		PCBRTails0			;--> skip last src lw
				
		move.l		(a1),d1				;d1- next src lw
PCBRTails0:		
		moveq		#-1,d2
		eor.l		d0,d1
		lsr.l		d3,d2				;d2- !tail mask
		and.l		d6,d1				;d1- new valid src data
		move.l		d2,d3				;d3- !tail mask
		and.l		(a0),d2				;d2- valid dst data
		or.l		d1,d4				;d4- merged data
		not.l		d3				;d3- tail mask
		rol.l		d7,d4				;d4- aligned data
		and.l		d3,d4				;d3- valid src data
		or.l		d2,d4				;d4- merged dst data
		move.l		d4,(a0)				;put dest
PCBRPlaneX:
		move.l		a2,d2				;d2- rows:#planes
		dbra		d2,PCBRPlane			;--> do next plane
PCBRRowX:
		swap		d2				;d2- ****:rows
		add.l		(l_SrcBmpDelta,a6),a4		;next row deltas
		add.l		(l_DstBmpDelta,a6),a3
		dbra		d2,PCBRRow			;--> do next row
		
		bra		DisBlitX			;--> exit

	
	;
	;left non-aligned
	;

PCBlitLeft:
		move.l		(l_DstXLLW,a6),a3		;a3- dst offset
		move.l		d7,d3				;d3- #dst pixels in 1st lw
		bne.s		PCBLs0a				;--> >0
		
		moveq		#$20,d3				;32 pixels
PCBLs0a:		
		move.l		(l_SrcXLLW,a6),a4		;a4- src offset
		move.l		d4,d7				;d7- src start bit
		addq.l		#$04,a3				;offset fro pre-dec
		add.w		(w_SizeX,a6),d4			;d4- src end pixel
		addq.l		#$04,a4
		and.w		#$1f,d4				;d4- #src pixels in 1st lw
		bne.s		PCBLs0b				;--> >0
		
		moveq		#$20,d4				;32 pixels
PCBLs0b:		
		move.l		(l_BTH2,a6),d1			;d1- body:tail|head
		moveq		#-1,d6
		sub.l		d5,d7				;d7- src shift
		bpl.s		PCBLs1				;--> +ve shift
		
		add.w		#$20,d7				;make shift +ve
PCBLs1:
		rol.w		#$08,d1				;d1- body:head|tail
		lsr.l		d7,d6				;d6- src split mask
		move.l		d1,a5				;a5- body:head|tail
		
		cmp.b		d3,d4
		bcc.s		PCBLs2				;--> src tail<=dst tail
								;    (ie. 1st dst lw contains all		
		bset		#$0f,d7				;    data for 1st src lw)
PCBLs2:		
		moveq		#-1,d1
		lsr.l		d3,d1
		move.l		d1,a2				;a2- !tail mask 
	
	;row loop
		
PCBLRow:
		swap		d2
		move.w		(w_DynNP,a6),d2

	;plane loop

PCBLPlane:	
		move.l		d2,-(sp)
		move.l		(_Planes,a6,d2.w*8),a0
		move.l		(4+_Planes,a6,d2.w*8),a1
		add.l		a3,a0
		add.l		a4,a1
		move.l		a5,d3
		moveq		#$00,d4
		
		tst.w		d7
		bpl.s		PCBLTail			;--> no prefetch required
		
		move.l		-(a1),d4
		not.l		d6
		eor.l		d0,d4
		and.l		d6,d4
		not.l		d6
PCBLTail:
		tst.b		d3
		beq.s		PCBLBody
	
		move.l		-(a1),d1
		exg		a2,d5				;d5- !tail mask (a2- dst start)
		move.l		d6,d2				;d2- !src split mask
		eor.l		d0,d1
		and.l		d1,d2				;d2- valid new data
		sub.l		d2,d1
		or.l		d4,d2				;merge src
		move.l		d5,d4				;d4- !tail mask
		and.l		-(a0),d4			;d4- dst data
		not.l		d5				;d5- tail mask
		rol.l		d7,d2				;align src data
		and.l		d5,d2				;d2- src data
		or.l		d4,d2				;d2- new dst data
		move.l		d2,(a0)
		not.l		d5				;d5- !tail mask
		move.l		d1,d4				;d4- previous data
		exg		d5,a2				;d5- dst start (a2- !tail mask)
PCBLBody:
		swap		d3
		subq.w		#$01,d3
		bmi.s		PCBLHead
PCBLBl1:
		move.l		-(a1),d1			;d1- next src lw
		move.l		d6,d2				;d2- !src split mask
		eor.l		d0,d1
		and.l		d1,d2				;d2- valid data from next src lw
		sub.l		d2,d1
		or.l		d4,d2				;merge data
		rol.l		d7,d2				;align data
		move.l		d2,-(a0)			;put dest (and next dest)
		move.l		d1,d4				;d4- last src lw
		dbra		d3,PCBLBl1			;--> do all body lws
PCBLHead:
		rol.l		#$08,d3
		tst.b		d3
		beq.s		PCBLPlaneX

		tst.l		d7
		bmi.s		PCBLHeads0
		
		move.l		-(a1),d1
PCBLHeads0:	
		move.l		d6,d2				;d2- !src split mask
		subq.l		#$04,a0
		eor.l		d0,d1
		and.l		d1,d2				;d2- valid new data
		or.l		d4,d2				;merge data
		rol.l		d7,d2				;align data
		bfins		d2,(a0){d5:d3}			;put dest field
PCBLPlaneX:
		move.l		(sp)+,d2
		dbra		d2,PCBLPlane
PCBLRowX:
		swap		d2
		add.l		(l_SrcBmpDelta,a6),a4
		add.l		(l_DstBmpDelta,a6),a3
		dbra		d2,PCBLRow
		bra		DisBlitX



