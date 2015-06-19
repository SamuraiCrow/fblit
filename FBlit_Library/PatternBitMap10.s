


	;
	;PatternBitMap (fill a rectangular region with 16bit pattern, masking etc.)
	;<d0- minx.w:miny.w	(rectangle in bitmap)
	; d1- maxx.w:maxy.w
	; d2- pen0.b|pen1.b:mask.b|flags.b
	; d3- minxm.w:minym.w	(top left in mask)
	; d4- patx.w:paty.w	(top left in pattern)
	; d5- 0.w:0.b|patsize.b	(power of 2, height of pattern)
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
	;	FB_INVERSVID	(combines with previous and inverts pattern (when specified!))
	;

PatternBitMap:
		tst.l		a3
		bne.s		PatBMPattern			;--> patterned
		
	;hmm, WTF is going on here?!
	;right... behaviour is like this... if no pattern is specified, then....
	;JAM1			- acts as you would expect (ie. just like BltTemplate())
	;JAM1|INVERSVID		- does nothing at all
	;JAM2			- ==JAM1
	;JAM2|INVERSVID		- ==JAM1, but uses the secondary pen (note: NOT like JAM1|INVERSVID in BltTemplate()
	;								    where INVERSVID inverts the template)
	;COMPLEMENT		- acts as for BltTemplate()
	;COMPLEMENT|INVERSVID	- does nothing at all
	;so, here JAM2 is converted to an appropriate JAM1 call, illegals are discraded and TemplateBitMap() does the job...
		
		move.l		d2,-(sp)
		bclr		#FB_JAM2,d2			;clear JAM2 (if it was JAM2, now it's JAM1) 		
		beq.s		PatBMs0				;--> it wan't JAM2
		
		bclr		#FB_INVERSVID,d2		;clear INVERSVID
		beq.s		PatBMs1				;--> it wasn't INVERSVID
		
		swap		d2				;it was JAM2|INVERSVID, so exchange pen0/1
		rol.w		#$08,d2
		swap		d2
		bra.s		PatBMs1
PatBMs0:		
		btst		#FB_INVERSVID,d2
		bne.s		PatBMQx				;--> INVERSVID|JAM1/COMPLEMENT not allowed.
PatBMs1:		
		jsr		(_LVOTemplateBitMap,a6)
PatBMQx:		
		move.l		(sp)+,d2
		rts
		
	;at this point, only patterned calls apply and things get simpler, maybe.

PatBMPattern:
		movem.l		d0-d7/a0-a5,-(sp)
		
		move.l		d3,a4				;a4- minxm:minym
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
		move.b		(bm_Depth,a0),d6		;d6- depth
		jsr		(_LVOMakeBTH,a6)		;d0- firstx, d1- BTH
		add.l		d4,d2				;d2- flw offset
		subq.b		#$01,d6
		bmi		PatBMx				;--> no planes
		
		move.l		a1,a5				;a5- *mask
		exg		a4,d6				;a4- depth-1, d6- minxm:minym
		tst.l		a5
		beq.s		PatBMnomask			;--> no mask
		
		move.l		a2,d4				;d4- maskmod
		muls.w		d6,d4				;d4- first row offset
		add.l		d4,a5				;a5- first mask row addr
		swap		d0				;d0- destx:****
		swap		d6				;d6- ****:minxm
		move.w		#$1f,d0
		and.w		d6,d0				;d0- destx:maskx
		sub.w		d0,d6
		asr.w		#$03,d6
		swap		d0				;d0- maskx:destx
		add.w		d6,a5				;a5- first mask lw (auto extend!)
PatBMnomask:		
		btst		#FB_INVERSVID,d5
		beq.s		PatBMms0			;--> no inversvid
		
		bset		#FB_INVERSVID+8,d7
PatBMms0:	
	
	;d0-	maskx:masky		a0-	*bitmap
	;d1-	BTH			a1-	
	;d2-	flw			a2-	maskmod(d4)
	;d3-	destmod			a3-	*pattern
	;d4-				a4-	depth-1
	;d5-	pen0|pen1:mask|flags	a5-	*mask
	;d6-				a6-	(lib)
	;d7-	#rows-1:flags|#planes	a7-	(sp)
	
		move.l		($14,sp),d4			;d4- 0.w:0.b|patsize.b
		tst.b		d4
		bmi		MColPat				;--> multi-colour pattern			
	
		moveq		#$01,d6
		lsl.l		d4,d6
		subq.l		#$01,d6				;((2^patsize)-1)
		move.l		($10,sp),d4			;d4- patx.w:paty.w
		add.l		d6,d6				;d6- patymask	
		add.w		d4,d4
		and.w		d6,d4				;d4- patx.w:patyoff.w
		move.w		d4,-(sp)
		move.w		#$00,-(sp)
		move.w		d6,d4				;d4- patx.w:patymask.w
		and.l		#$000fffff,d4			;(patx - 0-15)
		move.l		d4,-(sp)					
		
		btst		#FB_COMPLEMENT,d5
		beq.s		PatBMmjam1			;--> not complement

	;complement
	
		move.l		a2,d4				;d4- maskmod
		lsr.w		#$08,d5				;d5- mask
		move.l		sp,a1				;a1- stack
		move.l		a4,d6				;d6- depth-1
PatBMmcompl1:		
		btst		d6,d5
		beq.s		PatBMmcomps1			;--> plane masked
	
		move.l		(bm_Planes,a0,d6.l*4),-(sp)
		addq.b		#$01,d7
PatBMmcomps1:		
		dbra		d6,PatBMmcompl1
		
		tst.b		d7
		beq.s		PatBMcompx			;--> all planes masked

		move.l		sp,a4				;a4- *planes
		movem.l		(a1),d5/d6			;d5/d6- pattern stuff
		tst.l		a5
		bne.s		PatBMmcomps10			;--> mask
		
		jsr		(_LVOCompPatternPlanes,a6)
		lea		(8,a1),sp
		bra		PatBMx				;--> exit
PatBMmcomps10:
		move.l		a2,d4				;d4- maskmod				
		jsr		(_LVOCompPatternMaskPlanes,a6)
PatBMcompx:		
		lea		(8,a1),sp			;restore stack
		bra		PatBMx
	
	;jam1
	
PatBMmjam1:
		btst		#FB_JAM2,d5
		bne		PatBMmjam2			;--> jam2		
		
		;for pen1=1, set mask's 1s in planes

		move.l		d5,d4
		move.l		a4,d6				;d6- depth-1
		lsr.w		#$08,d5				;d5- mask
		swap		d4				;d4- pen1
		move.l		sp,a1				;a1- sp
PatBMmjam1l1:
		btst		d6,d5
		beq.s		PatBMmjam1s1			;--> masked
		
		btst		d6,d4
		beq.s		PatBMmjam1s1			;--> clear this plane
		
		move.l		(bm_Planes,a0,d6.l*4),-(sp)
		addq.b		#$01,d7
		bclr		d6,d5				;don't look at this one again
PatBMmjam1s1:
		dbra		d6,PatBMmjam1l1
		
		tst.b		d7
		beq.s		PatBMmjam1s2			;--> no planes to fill
		
		movem.l		d5/a4,-(sp)
		movem.l		(a1),d5/d6
		lea		(8,sp),a4			;a4- *planes
		tst.l		a5
		bne.s		PatBMmjam1s10			;--> mask
		
		jsr		(_LVOFillPatternPlanes,a6)
		bra.s		PatBMmjam1s11			;--> continue
PatBMmjam1s10:		
		move.l		a2,d4				;d4- maskmod
		jsr		(_LVOFillPatternMaskPlanes,a6)
PatBMmjam1s11:		
		movem.l		(sp),d5/a4
		move.l		a1,sp
			
		;for pen1=0, clear mask's 1s in planes
		
PatBMmjam1s2:
		move.l		a4,d6
		clr.b		d7
PatBMmjam1l2:
		btst		d6,d5
		beq.s		PatBMmjam1s3			;--> masked
		
		move.l		(bm_Planes,a0,d6.l*4),-(sp)
		addq.b		#$01,d7
PatBMmjam1s3:
		dbra		d6,PatBMmjam1l2
		
		tst.b		d7
		beq.s		PatBMmjam1s31			;--> all done
		
		movem.l		(a1),d5/d6
		move.l		sp,a4				;a4- *planes
		tst.l		a5
		bne.s		PatBMmjam1s30			;--> mask
		
		jsr		(_LVOClearPatternPlanes,a6)
		lea		(8,a1),sp
		bra		PatBMx				;--> exit
PatBMmjam1s30:		
		move.l		a2,d4				;d4- maskmod
		jsr		(_LVOClearPatternMaskPlanes,a6)
PatBMmjam1s31:		
		lea		(8,a1),sp
		bra		PatBMx				;--> all done
		
	;jam2		
		
PatBMmjam2:		
		;clear rectangle where pen0=0 and pen1=0
		
		move.l		d5,d4
		lsr.l		#$08,d5				;d5- 00|pen0:pen1|mask
		swap		d4				;d4- pen0|pen1
		move.l		a4,d6				;d6- depth-1
		movem.l		d4/a4,-(sp)		
		swap		d5				;d5- pen1|mask:00|pen0
		move.l		sp,a1				;a1- sp
		or.b		d5,d4
		swap		d5
PatBMmjam2l1:
		btst		d6,d5
		beq.s		PatBMmjam2s1			;--> masked
		
		btst		d6,d4
		bne.s		PatBMmjam2s1			;--> don't clear this plane
		
		move.l		(bm_Planes,a0,d6.l*4),-(sp)
		addq.b		#$01,d7
		bclr		d6,d5				;mask this plane
PatBMmjam2s1:
		dbra		d6,PatBMmjam2l1
		
		tst.b		d7
		beq.s		PatBMmjam2s2			;--> no planes to clear
		
		move.l		sp,a4				;a4- *planes
		tst.l		a5
		bne.s		PatBMmjam2s10			;--> masked
		
		move.l		d7,a2
		bclr		#FB_INVERSVID+8,d7
		jsr		(_LVOClearPlanes,a6)
		move.l		a2,d7
		bra.s		PatBMmjam2s11			;--> continue
PatBMmjam2s10:		
		move.l		a2,d4				;d4- maskmod
		move.l		d7,a2
		bclr		#FB_INVERSVID+8,d7
		jsr		(_LVOClearTemplatePlanes,a6)
		move.l		a2,d7				;restore d7/a2
		move.l		d4,a2
PatBMmjam2s11:		
		move.l		a1,sp
		
		;fill rectangle for pen0=1 and pen1=1
		
PatBMmjam2s2:
		movem.l		(a1),d4/d6			;d4- pen0|pen1, d6- depth-1
		swap		d5
		and.b		d5,d4
		swap		d5
		clr.b		d7
PatBMmjam2l2:
		btst		d6,d5
		beq.s		PatBMmjam2s3			;--> masked
		
		btst		d6,d4
		beq.s		PatBMmjam2s3			;--> don't fill plane
		
		move.l		(bm_Planes,a0,d6.l*4),-(sp)
		addq.b		#$01,d7
		bclr		d6,d5				;mask plane
PatBMmjam2s3:
		dbra		d6,PatBMmjam2l2
		
		tst.b		d7
		beq.s		PatBMmjam2s4			;--> no planes to fill

		move.l		sp,a4
		tst.l		a5
		bne.s		PatBMmjam2s30			;--> masked
		
		move.l		d7,a2
		bclr		#FB_INVERSVID+8,d7
		jsr		(_LVOFillPlanes,a6)
		move.l		a2,d7
		bra.s		PatBMmjam2s31			;--> continue
PatBMmjam2s30:		
		move.l		a2,d4				;d4- maskmod
		move.l		d7,a2
		bclr		#FB_INVERSVID+8,d7
		jsr		(_LVOFillTemplatePlanes,a6)
		move.l		a2,d7				;restore d7/a2
		move.l		d4,a2
PatBMmjam2s31:		
		move.l		a1,sp
		
		;copy pattern(or NOT pattern) for pen0=0 and pen1=1
		
PatBMmjam2s4:
		movem.l		(a1),d4/d6
		clr.b		d7
PatBMmjam2l3:
		btst		d6,d5
		beq.s		PatBMmjam2s5			;--> masked
		
		btst		d6,d4
		beq.s		PatBMmjam2s5			;--> pen0=1, pen1=0, do later
		
		move.l		(bm_Planes,a0,d6.l*4),-(sp)
		addq.b		#$01,d7
		bclr		d6,d5				;mask plane
PatBMmjam2s5:
		dbra		d6,PatBMmjam2l3
		
		tst.b		d7
		beq.s		PatBMmjam2s6			;--> no planes to fill
		
		move.l		sp,a4
		move.l		d5,-(sp)
		movem.l		($08,a1),d5/d6
		tst.l		a5
		bne.s		PatBMmjam2s50			;--> mask
		
		jsr		(_LVOCopyPatternPlanes,a6)
		bra.s		PatBMmjam2s51			;--> continue
PatBMmjam2s50:
		move.l		a2,d4
		jsr		(_LVOCopyPatternMaskPlanes,a6)
PatBMmjam2s51:				
		move.l		(sp)+,d5
		move.l		a1,sp
		
		;copy NOT pattern (or pattern) for pen0=1 and pen1=0
		
PatBMmjam2s6:
		movem.l		(a1)+,d4/d6
		clr.b		d7
PatBMmjam2l4:
		btst		d6,d5
		beq.s		PatBMmjam2s7			;--> masked
		
		move.l		(bm_Planes,a0,d6.l*4),-(sp)
		addq.b		#$01,d7
PatBMmjam2s7:		
		dbra		d6,PatBMmjam2l4				
	
		tst.b		d7
		beq.s		PatBMmjam2s71

		move.l		sp,a4
		bchg		#FB_INVERSVID+8,d7
		movem.l		(a1),d5/d6
		tst.l		a5
		bne.s		PatBMmjam2s70			;--> mask
		
		jsr		(_LVOCopyPatternPlanes,a6)
		lea		(8,a1),sp
		bra		PatBMx
PatBMmjam2s70:
		move.l		a2,d4				;d4- maskmod
		jsr		(_LVOCopyPatternMaskPlanes,a6)		
PatBMmjam2s71:		
		lea		(8,a1),sp
		bra		PatBMx
		
		
		
		
		
	;multi-colour pattern...
	
MColPat:			
		neg.b		d4
		moveq		#$01,d6
		lsl.l		d4,d6
		subq.l		#$01,d6				;((2^patsize)-1)
		move.l		($10,sp),d4			;d4- patx.w:paty.w
		add.l		d6,d6				;d6- patymask	
		add.w		d4,d4
		and.w		d6,d4				;d4- patx.w:patyoff.w
		move.w		d4,-(sp)
		move.w		#$00,-(sp)
		move.w		d6,d4				;d4- patx.w:patymask.w
		and.l		#$000fffff,d4			;(patx - 0-15)
		move.l		d4,-(sp)	
		addq.l		#$02,d6				;d6- pattern plane size
		clr.w		d4
		move.l		d6,-(sp)
		move.w		a4,d4				;d4- depth-1
		mulu.w		d4,d6
		add.l		d6,a3				;a3- last pattern plane addr
		move.l		a3,-(sp)
	
	;(sp)-		last pattern plane addr
	;($04,sp)-	pattern plane modulo
	;($08,sp)-	patx.w:patymask.w
	;($0c,sp)-	0.w:paty.w
		
		btst		#FB_COMPLEMENT,d5
		beq.s		MCPatBMjam1			;--> not complement

	;complement
	
		lsr.w		#$08,d5				;d5- mask
		move.l		a4,d6				;d6- depth-1
		move.b		#$01,d7				;d7- #rows-1.w:flags.b|#planes.b (one)
		move.l		a2,d4				;d4- maskmod(maybe)
		movem.l		($08,sp),a1/a2			;a1/a2- (d5/d6) pattern stuff
		tst.l		a5
		bne.s		MCPatBMMcompl1			;--> masked	
MCPatBMcompl1:
		btst		d6,d5
		beq.s		MCPatBMcomps1			;--> plane masked
		
		lea		(bm_Planes,d6.l*4,a0),a4	;a4- *plane
		exg		d5,a1
		exg		d6,a2
		jsr		(_LVOCompPatternPlanes,a6)		
		exg		d6,a2
		exg		d5,a1
MCPatBMcomps1:
		sub.l		($04,sp),a3			;a3- next pattern
		dbra		d6,MCPatBMcompl1		;--> next plane
		
		lea		($10,sp),sp
		bra		PatBMx				;--> all done
		
		;masked
				
MCPatBMMcompl1:		
		btst		d6,d5
		beq.s		MCPatBMMcomps1			;--> plane masked
		
		lea		(bm_Planes,d6.l*4,a0),a4	;a4- *plane
		exg		d5,a1
		exg		d6,a2
		jsr		(_LVOCompPatternMaskPlanes,a6)
		exg		d6,a2
		exg		d5,a1
MCPatBMMcomps1:
		sub.l		($04,sp),a3			;a3- next pattern
		dbra		d6,MCPatBMMcompl1		;--> next plane
		
		lea		($10,sp),sp
		bra		PatBMx				;--> all done		
		
	;jam1
	
MCPatBMjam1:		
		btst		#FB_JAM2,d5
		bne		MCPatBMjam2			;--> jam2		

		move.l		d5,d4
		move.l		($08,sp),a1			;(d5)
		tst.l		a5
		bne.s		MCPatBMjam1s01			;--> masked
		
		move.l		($0c,sp),a2			;(d6)
MCPatBMjam1s01:		
		move.l		a4,d6				;d6- depth-1
		lsr.w		#$08,d5				;d5- mask
		move.b		#$01,d7
		swap		d4				;d4- pen1
MCPatBMjam1l1:
		btst		d6,d5
		beq.s		MCPatBMjam1s3			;--> masked, next plane
		
		lea		(bm_Planes,d6.l*4,a0),a4	;a4- *plane
		btst		d6,d4
		beq.s		MCPatBMjam1s1			;--> clear this plane
		
		tst.l		a5
		bne.s		MCPatBMjam1s0			;--> mask(fill)

		exg		d6,a2
		exg		d5,a1		
		jsr		(_LVOFillPatternPlanes,a6)
		exg		d6,a2
		exg		d5,a1
		bra.s		MCPatBMjam1s3			;--> next
MCPatBMjam1s0:
		move.l		d6,-(sp)
		exg		a2,d4
		move.l		($10,sp),d6
		exg		a1,d5
		jsr		(_LVOFillPatternMaskPlanes,a6)
		exg		a1,d5
		move.l		(sp)+,d6
		exg		a2,d4
		bra.s		MCPatBMjam1s3			;--> next
MCPatBMjam1s1:
		tst.l		a5
		bne.s		MCPatBMjam1s2			;--> mask(clear)

		exg		d6,a2
		exg		d5,a1		
		jsr		(_LVOClearPatternPlanes,a6)
		exg		d6,a2
		exg		d5,a1
		bra.s		MCPatBMjam1s3			;--> next
MCPatBMjam1s2:
		move.l		d6,-(sp)
		exg		a2,d4
		move.l		($10,sp),d6
		exg		a1,d5
		jsr		(_LVOClearPatternMaskPlanes,a6)
		exg		a1,d5
		move.l		(sp)+,d6
		exg		a2,d4
MCPatBMjam1s3:
		sub.l		($04,sp),a3
		dbra		d6,MCPatBMjam1l1
		
		lea		($10,sp),sp
		bra		PatBMx				;--> all done
		
	;jam2		
		
MCPatBMjam2:		
		;clear rectangle where pen0=0 and pen1=0
		
		move.l		d5,d4
		lsr.l		#$08,d5				;d5- 00|pen0:pen1|mask
		swap		d4				;d4- pen0|pen1
		move.l		a4,d6				;d6- depth-1
		movem.l		d4/a4,-(sp)		
		swap		d5				;d5- pen1|mask:00|pen0
		move.l		sp,a1				;a1- sp
		or.b		d5,d4
		clr.b		d7
		swap		d5
MCPatBMjam2l1:
		btst		d6,d5
		beq.s		MCPatBMjam2s1			;--> masked
		
		btst		d6,d4
		bne.s		MCPatBMjam2s1			;--> don't clear this plane
		
		move.l		(bm_Planes,a0,d6.l*4),-(sp)
		addq.b		#$01,d7
		bclr		d6,d5				;mask this plane
MCPatBMjam2s1:
		dbra		d6,MCPatBMjam2l1
		
		tst.b		d7
		beq.s		MCPatBMjam2s2			;--> no planes to clear
		
		move.l		sp,a4				;a4- *planes
		tst.l		a5
		bne.s		MCPatBMjam2s10			;--> masked
		
		move.l		d7,a2
		bclr		#FB_INVERSVID+8,d7
		jsr		(_LVOClearPlanes,a6)
		move.l		a2,d7
		bra.s		MCPatBMjam2s11			;--> continue
MCPatBMjam2s10:		
		move.l		a2,d4				;d4- maskmod
		move.l		d7,a2
		bclr		#FB_INVERSVID+8,d7
		jsr		(_LVOClearTemplatePlanes,a6)
		move.l		a2,d7				;restore d7/a2
		move.l		d4,a2
MCPatBMjam2s11:		
		move.l		a1,sp
		
		;fill rectangle for pen0=1 and pen1=1
		
MCPatBMjam2s2:
		movem.l		(a1),d4/d6			;d4- pen0|pen1, d6- depth-1
		swap		d5
		and.b		d5,d4
		swap		d5
		clr.b		d7
MCPatBMjam2l2:
		btst		d6,d5
		beq.s		MCPatBMjam2s3			;--> masked
		
		btst		d6,d4
		beq.s		MCPatBMjam2s3			;--> don't fill plane
		
		move.l		(bm_Planes,a0,d6.l*4),-(sp)
		addq.b		#$01,d7
		bclr		d6,d5				;mask plane
MCPatBMjam2s3:
		dbra		d6,MCPatBMjam2l2
		
		tst.b		d7
		beq.s		MCPatBMjam2s4			;--> no planes to fill

		move.l		sp,a4
		tst.l		a5
		bne.s		MCPatBMjam2s30			;--> masked
		
		move.l		d7,a2
		bclr		#FB_INVERSVID+8,d7
		jsr		(_LVOFillPlanes,a6)
		move.l		a2,d7
		bra.s		MCPatBMjam2s31			;--> continue
MCPatBMjam2s30:		
		move.l		a2,d4				;d4- maskmod
		move.l		d7,a2
		bclr		#FB_INVERSVID+8,d7
		jsr		(_LVOFillTemplatePlanes,a6)
		move.l		a2,d7				;restore d7/a2
		move.l		d4,a2
MCPatBMjam2s31:		
		move.l		a1,sp
		
		;copy pattern(or NOT pattern) for pen0=0 and pen1=1, and vice versa
		
MCPatBMjam2s4:
		movem.l		(sp)+,d4/d6			;d4- pen0|pen1, d6- depth-1
		move.b		#$01,d7
		move.l		($08,sp),a1			;a1- (d5)
		tst.l		a5
		bne.s		MCPatBMjam2l3			;--> masking
		
		move.l		($0c,sp),a2			;a2- (d6)
MCPatBMjam2l3:
		btst		d6,d5
		beq.s		MCPatBMjam2s23			;--> masked
		
		lea		(bm_Planes,d6.l*4,a0),a4
		btst		d6,d4
		beq.s		MCPatBMjam2s21			;--> pen0=1, pen1=0
		
		tst.l		a5
		bne.s		MCPatBMjam2s20			;--> mask
		
		exg		d6,a2
		exg		d5,a1
		jsr		(_LVOCopyPatternPlanes,a6)
		exg		d6,a2
		exg		d5,a1
		bra.s		MCPatBMjam2s23			;--> next
MCPatBMjam2s20:
		move.l		d6,-(sp)
		exg		a2,d4
		move.l		($10,sp),d6
		exg		a1,d5
		jsr		(_LVOCopyPatternMaskPlanes,a6)
		exg		a1,d5
		move.l		(sp)+,d6
		exg		a2,d4
		bra.s		MCPatBMjam2s23			;--> next
MCPatBMjam2s21:
		bchg		#FB_INVERSVID+8,d7
		tst.l		a5
		bne.s		MCPatBMjam2s22			;--> mask
		
		exg		d6,a2
		exg		d5,a1
		jsr		(_LVOCopyPatternPlanes,a6)
		exg		d6,a2
		exg		d5,a1
		bchg		#FB_INVERSVID+8,d7
		bra.s		MCPatBMjam2s23			;--> next
MCPatBMjam2s22:
		move.l		d6,-(sp)
		exg		a2,d4
		move.l		($10,sp),d6
		exg		a1,d5
		jsr		(_LVOCopyPatternMaskPlanes,a6)
		exg		a1,d5
		move.l		(sp)+,d6
		exg		a2,d4
		bchg		#FB_INVERSVID+8,d7
MCPatBMjam2s23:
		sub.l		($04,sp),a3
		dbra		d6,MCPatBMjam2l3
		
		lea		($10,sp),sp
	

PatBMx:		
		movem.l		(sp)+,d0-d7/a0-a5
		rts