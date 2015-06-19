		
		
	;
	;TemplateBitMap (fill a rectangular region, with template and stuff)
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
	;
	;flags-	none(JAM1)	(rectangle/mask 1s set to pen1)
	;	FB_JAM2		(rectangle/mask 1s set to pen1, mask 0s set to pen0)
	;	FB_COMPLEMENT	(rectangle/mask 1s complement dest)
	;	FB_INVERSVID	(combines with previous and inverts mask)
	;
	
TemplateBitMap:
		movem.l		d0-d7/a0-a6,-(sp)
		
		move.l		d3,a3				;a3- minxm:minym
		moveq		#$00,d7
		moveq		#$00,d3
		moveq		#$00,d4
		move.w		d1,d7				;d7- maxy
		sub.w		d0,d7				;d7- #rows-1
		swap		d7				;d7- #rows-1:0000
		move.w		(bm_BytesPerRow,a0),d3		;d3- dest bpr
		move.w		d0,d4				;d4- miny
		muls.w		d3,d4				;d4- first row offset
		move.l		d2,d5				;d5- pen0|pen1:mask|flags
		swap		d0				;d0- minx
		swap		d1				;d1- maxx
		ext.l		d0
		ext.l		d1
		moveq		#$00,d6
		move.b		(bm_Depth,a0),d6		;d6- #planes		
		jsr		(_LVOMakeBTH,a6)		;d0- firstx, d1- BTH
		add.l		d4,d2				;d2- flw offset
		subq.b		#$01,d6
		bmi		RFBMx				;--> no planes

		tst.l		a1
		beq		RFBMnomask			;--> no mask
		
		move.l		a2,d4				;d4- maskmod
		exg		a3,d6				;d6- minxt:minyt, a3- #planes-1
		muls.w		d6,d4				;d4- first row offset
		add.l		d4,a1				;a1- first mask row addr
		swap		d0				;d0- destx:****
		swap		d6				;d6- ****:minxm
		move.w		#$1f,d0
		and.w		d6,d0				;d0- destx:maskx
		sub.w		d0,d6
		asr.w		#$03,d6
		swap		d0				;d0- maskx:destx
		add.w		d6,a1				;a1- first mask lw (auto extend!)
		move.l		a1,a5				;a5- *mask
		move.l		a3,d6
		btst		#FB_INVERSVID,d5
		beq.s		RFBMms0				;--> no inversvid
		
		bset		#FB_INVERSVID+8,d7
RFBMms0:		
		btst		#FB_COMPLEMENT,d5
		beq.s		RFBMmjam1			;--> not complement

	;complement mask
	
		move.l		a2,d4				;d4- maskmod
		lsr.w		#$08,d5				;d5- mask
		move.l		sp,a3
RFBMmcompl1:		
		btst		d6,d5
		beq.s		RFBMmcomps1			;--> plane masked
	
		move.l		(bm_Planes,a0,d6.l*4),-(sp)
		addq.b		#$01,d7
RFBMmcomps1:		
		dbra		d6,RFBMmcompl1
		
		tst.b		d7
		beq		RFBMx				;--> all planes masked
		
		move.l		sp,a4				;a4- *planes
		jsr		(_LVOCompTemplatePlanes,a6)
		move.l		a3,sp
		bra		RFBMx
	
	;jam1
	
RFBMmjam1:
		btst		#FB_JAM2,d5
		bne.s		RFBMmjam2			;--> jam2		
		
		;for pen1=1, set mask's 1s in planes

		move.l		d5,d4
		lsr.w		#$08,d5				;d5- mask
		move.l		d6,a3				;a3- #planes-1
		swap		d4				;d4- pen1
RFBMmjam1l1:
		btst		d6,d5
		beq.s		RFBMmjam1s1			;--> masked
		
		btst		d6,d4
		beq.s		RFBMmjam1s1			;--> clear this plane
		
		move.l		(bm_Planes,a0,d6.l*4),-(sp)
		addq.b		#$01,d7
		bclr		d6,d5				;don't look at this one again
RFBMmjam1s1:
		dbra		d6,RFBMmjam1l1
		
		tst.b		d7
		beq.s		RFBMmjam1s2			;--> no planes to fill
		
		move.l		sp,a4
		move.l		a2,d4				;d4- maskmod
		jsr		(_LVOFillTemplatePlanes,a6)
		move.l		d7,a4
		extb.l		d7
		lea		(sp,d7.l*4),sp
		move.l		a4,d7
			
		;for pen1=0, clear mask's 1s in planes
		
RFBMmjam1s2:
		move.l		a3,d6				;d6- #planes-1
		clr.b		d7
		move.l		sp,a3
RFBMmjam1l2:
		btst		d6,d5
		beq.s		RFBMmjam1s3			;--> masked
		
		move.l		(bm_Planes,a0,d6.l*4),-(sp)
		addq.b		#$01,d7
RFBMmjam1s3:
		dbra		d6,RFBMmjam1l2
		
		tst.b		d7
		beq		RFBMx				;--> all done
		
		move.l		sp,a4
		move.l		a2,d4				;d4- maskmod
		jsr		(_LVOClearTemplatePlanes,a6)
		move.l		a3,sp
		bra		RFBMx				;--> all done
		
	;jam2		
		
RFBMmjam2:		
		bclr		#FB_INVERSVID+8,d7
		beq.s		RFBMmjam2s0			;--> not inversvid
		
		swap		d5
		rol.w		#$08,d5
		swap		d5				;d5- pen1|pen0:mask|flags
		
		;clear rectangle where pen0=0 and pen1=0
		
RFBMmjam2s0:		
		move.l		d5,d4
		lsr.l		#$08,d5				;d5- 00|pen0:pen1|mask
		swap		d4				;d4- pen0|pen1
		move.l		d6,a3				;a3- #planes-1
		move.l		d4,a1				;a1- pen0|pen1
		swap		d5				;d5- pen1|mask:00|pen0
		or.b		d5,d4
		swap		d5
RFBMmjam2l1:
		btst		d6,d5
		beq.s		RFBMmjam2s1			;--> masked
		
		btst		d6,d4
		bne.s		RFBMmjam2s1			;--> don't clear this plane
		
		move.l		(bm_Planes,a0,d6.l*4),-(sp)
		addq.b		#$01,d7
		bclr		d6,d5				;mask this plane
RFBMmjam2s1:
		dbra		d6,RFBMmjam2l1
		
		tst.b		d7
		beq.s		RFBMmjam2s2			;--> no planes to clear
		
		move.l		sp,a4			
		jsr		(_LVOClearPlanes,a6)		
		move.l		d7,a4
		extb.l		d7
		lea		(sp,d7.l*4),sp
		move.l		a4,d7
		
		;fill rectangle for pen0=1 and pen1=1
		
RFBMmjam2s2:
		move.l		a1,d4				;d4- pen0|pen1
		swap		d5
		and.b		d5,d4
		move.l		a3,d6				;d6- #planes-1
		swap		d5
		clr.b		d7
RFBMmjam2l2:
		btst		d6,d5
		beq.s		RFBMmjam2s3			;--> masked
		
		btst		d6,d4
		beq.s		RFBMmjam2s3			;--> don't fill plane
		
		move.l		(bm_Planes,a0,d6.l*4),-(sp)
		addq.b		#$01,d7
		bclr		d6,d5				;mask plane
RFBMmjam2s3:
		dbra		d6,RFBMmjam2l2
		
		tst.b		d7
		beq.s		RFBMmjam2s4			;--> no planes to fill

		
		move.l		sp,a4
		jsr		(_LVOFillPlanes,a6)
		move.l		d7,a4
		extb.l		d7
		lea		(sp,d7.l*4),sp
		move.l		a4,d7
		
		;copy mask for pen0=0 and pen1=1
		
RFBMmjam2s4:
		move.l		a1,d4				;d4- pen0|pen1
		move.l		a3,d6				;d6- #planes
		clr.b		d7
RFBMmjam2l3:
		btst		d6,d5
		beq.s		RFBMmjam2s5			;--> masked
		
		btst		d6,d4
		beq.s		RFBMmjam2s5			;--> pen0=1, pen1=0, do later
		
		move.l		(bm_Planes,a0,d6.l*4),-(sp)
		addq.b		#$01,d7
		bclr		d6,d5				;mask plane
RFBMmjam2s5:
		dbra		d6,RFBMmjam2l3
		
		tst.b		d7
		beq.s		RFBMmjam2s6			;--> no planes to fill
		
		move.l		sp,a4
		move.l		a2,d4				;d4- maskmod
		jsr		(_LVOCopyTemplatePlanes,a6)
		move.l		d7,a4
		extb.l		d7
		lea		(sp,d7.l*4),sp
		move.l		a4,d7
		
		;copy ~mask for pen0=1 and pen1=0
		
RFBMmjam2s6:
		move.l		a3,d6
		clr.b		d7
		move.l		sp,a3
RFBMmjam2l4:
		btst		d6,d5
		beq.s		RFBMmjam2s7			;--> masked
		
		move.l		(bm_Planes,a0,d6.l*4),-(sp)
		addq.b		#$01,d7
RFBMmjam2s7:		
		dbra		d6,RFBMmjam2l4				
	
		tst.b		d7
		beq		RFBMx
		
		move.l		sp,a4
		move.l		a2,d4
		bset		#FB_INVERSVID+8,d7
		jsr		(_LVOCopyTemplatePlanes,a6)
		move.l		a3,sp
		bra.s		RFBMx			
		
	;no mask ops
		
RFBMnomask:		
		btst		#FB_COMPLEMENT,d5
		beq.s		RFBMnmrectfill			;--> not complement
	
	;complement rectangle
			
		lsr.w		#$08,d5				;d5- mask
		move.l		sp,a3
RFBMnmcompl1:		
		btst		d6,d5
		beq.s		RFBMnmcomps1			;--> plane masked
	
		move.l		(bm_Planes,a0,d6.l*4),-(sp)
		addq.b		#$01,d7
RFBMnmcomps1:		
		dbra		d6,RFBMnmcompl1
		
		tst.b		d7
		beq.s		RFBMx				;--> all planes masked
		
		move.l		sp,a4				;a4- *planes
		jsr		(_LVOCompPlanes,a6)
		move.l		a3,sp
		bra.s		RFBMx
		
	;fill pen1 rectangle
	
		;fill planes where pen1=1
	
RFBMnmrectfill:
		move.l		d5,d4
		lsr.w		#$08,d5				;d5- mask
		move.l		d6,a3				;a3- #planes-1
		swap		d4				;d4- pen1
RFBMnmrfl1:
		btst		d6,d5
		beq.s		RFBMnmrfs1			;--> masked
		
		btst		d6,d4
		beq.s		RFBMnmrfs1			;--> clear this plane
		
		move.l		(bm_Planes,a0,d6.l*4),-(sp)
		addq.b		#$01,d7
		bclr		d6,d5				;don't check this one again
RFBMnmrfs1:
		dbra		d6,RFBMnmrfl1
		
		tst.b		d7
		beq.s		RFBMnmrfs2			;--> no planes to fill
		
		move.l		sp,a4
		jsr		(_LVOFillPlanes,a6)
		move.l		d7,a4
		extb.l		d7
		lea		(sp,d7.l*4),sp
		move.l		a4,d7
		
		;clear planes for pen1=0
RFBMnmrfs2:
		move.l		a3,d6				;d6- #planes-1
		clr.b		d7
		move.l		sp,a3
RFBMnmrfl2:
		btst		d6,d5
		beq.s		RFBMnmrfs3			;--> masked
		
		move.l		(bm_Planes,a0,d6.l*4),-(sp)
		addq.b		#$01,d7
RFBMnmrfs3:
		dbra		d6,RFBMnmrfl2
		
		tst.b		d7
		beq.s		RFBMx				;--> all done
		
		move.l		sp,a4
		jsr		(_LVOClearPlanes,a6)
		move.l		a3,sp

RFBMx:		
		movem.l		(sp)+,d0-d7/a0-a6
		rts


