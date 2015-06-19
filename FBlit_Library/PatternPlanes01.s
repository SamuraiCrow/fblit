

	;
	;FillPatternPlanes	(set pattern 1's in all planes)
	;<d0- 0.w:destx.w (1st pixel in 1st lw (must be <32))
	; d1- BTH
	; d2- flw.l (offset to 1st dest lw)
	; d3- destmod.l (row modulos)
	; d4- 
	; d5- patx.w:patymask.w (patx - 1st pat pixel (0-15), patymask - ((2^patsize)-1)*2)
	; d6- 0:patyoff.w (initial pattern y offset)
	; d7- #rows-1.w:flags.b|#planes.b
	;
	; a3- *pattern (pointer to 2d array of word*2^patsize)
	; a4- *planes (pointer to array of *planes)
	; 
	;>
	;all reg's preserved
	;
	;flags-	FB_INVERSVID		(invert pattern)
	;

FillPatternPlanes:
		movem.l		d0-d7/a0-a6,-(sp)
		swap		d5				;d5- patymask:patx
		sub.w		d0,d5
		and.w		#$0f,d5
		move.l		d5,a5				;a5- patymask:patlshift
		move.l		d2,a2				;a2- flw 
		move.l		d1,a1				;a1- BTH
FPPRowLoop:
		move.l		a5,d5				;d5- patymask:patlshift
		move.w		(d6.w,a3),d4			;d4- 0:pat(raw)
		addq.w		#$02,d6
		rol.w		d5,d4
		move.w		d4,d5				;d5- patymask:pat
		swap		d5
		and.w		d5,d6				;d6- 0:nextpatoffset
		move.w		d4,d5				;d5- pattern
		
		move.w		($1e,sp),d7			;d7- rows(cur):flags|planes
		btst		#FB_INVERSVID+8,d7
		beq.s		FPPRows0			;--> no inversvid
		
		not.l		d5
FPPRows0:
		and.w		#$ff,d7
		subq.w		#$01,d7				;d7- rows(cur):planes-1
FPPPlaneLoop:
		move.l		a2,a0				;a0- flw offset
		move.l		a1,d1				;d1- BTH
		add.l		(d7.w*4,a4),a0			;a0- *plane(flw)
FPPHead:		
		tst.b		d1
		beq.s		FPPBody
		
		moveq		#$00,d2
		bfset		d2{d0:d1}
		and.l		d5,d2
		or.l		d2,(a0)+
FPPBody:
		swap		d1
		subq.w		#$01,d1
		bmi.s		FPPTail
FPPBodyl1:
		or.l		d5,(a0)+
		dbra		d1,FPPBodyl1		
FPPTail:				
		rol.l		#$08,d1
		tst.b		d1
		beq.s		FPPPlaneLoopx
		
		moveq		#$00,d2
		bfset		d2{0:d1}
		and.l		d5,d2
		or.l		d2,(a0)
FPPPlaneLoopx:
		dbra		d7,FPPPlaneLoop
FPPRowLoopx:
		add.l		($0c,sp),a2			;a2- next row flw offset
		sub.l		#$10000,d7
		bpl		FPPRowLoop
FPPx:
		movem.l		(sp)+,d0-d7/a0-a6
		rts
	
			
	;
	;ClearPatternPlanes	(clear pattern 1's in all planes)
	;<d0- 0.w:destx.w (1st pixel in 1st lw (must be <32))
	; d1- BTH
	; d2- flw.l (offset to 1st dest lw)
	; d3- destmod.l (row modulos)
	; d4- 
	; d5- patx.w:patymask.w (patx - 1st pat pixel (0-15), patymask - ((2^patsize)-1)*2)
	; d6- 0:patyoff.w (initial pattern y offset)
	; d7- #rows-1.w:flags.b|#planes.b
	;
	; a3- *pattern (pointer to 2d array of word*2^patsize)
	; a4- *planes (pointer to array of *planes)
	; 
	;>
	;all reg's preserved
	;
	;flags-	FB_INVERSVID		(invert pattern)
	;
	

ClearPatternPlanes:
		movem.l		d0-d7/a0-a6,-(sp)
		swap		d5				;d5- patymask:patx
		sub.w		d0,d5
		and.w		#$0f,d5
		move.l		d5,a5				;a5- patymask:patlshift
		move.l		d2,a2				;a2- flw 
		move.l		d1,a1				;a1- BTH
CPPRowLoop:
		move.l		a5,d5				;d5- patymask:patlshift
		move.w		(d6.w,a3),d4			;d4- 0:pat(raw)
		addq.w		#$02,d6
		rol.w		d5,d4
		move.w		d4,d5				;d5- patymask:pat
		swap		d5
		and.w		d5,d6				;d6- 0:nextpatoffset
		move.w		d4,d5				;d5- pattern
		
		move.w		($1e,sp),d7			;d7- rows(cur):flags|planes
		btst		#FB_INVERSVID+8,d7
		bne.s		CPPRows0			;--> inversvid(=don't invert for this case!)
		
		not.l		d5
CPPRows0:
		and.w		#$ff,d7
		subq.w		#$01,d7				;d7- rows(cur):planes-1
CPPPlaneLoop:
		move.l		a2,a0				;a0- flw offset
		move.l		a1,d1				;d1- BTH
		add.l		(d7.w*4,a4),a0			;a0- *plane(flw)
CPPHead:		
		tst.b		d1
		beq.s		CPPBody
		
		moveq		#-1,d2
		bfclr		d2{d0:d1}
		or.l		d5,d2
		and.l		d2,(a0)+
CPPBody:
		swap		d1
		subq.w		#$01,d1
		bmi.s		CPPTail
CPPBodyl1:
		and.l		d5,(a0)+
		dbra		d1,CPPBodyl1		
CPPTail:				
		rol.l		#$08,d1
		tst.b		d1
		beq.s		CPPPlaneLoopx
		
		moveq		#-1,d2
		bfclr		d2{0:d1}
		or.l		d5,d2
		and.l		d2,(a0)
CPPPlaneLoopx:
		dbra		d7,CPPPlaneLoop
CPPRowLoopx:
		add.l		($0c,sp),a2			;a2- next row flw offset
		sub.l		#$10000,d7
		bpl		CPPRowLoop
CPPx:
		movem.l		(sp)+,d0-d7/a0-a6
		rts

			

	;
	;CopyPatternPlanes	(copy pattern to planes)
	;<d0- 0.w:destx.w (1st pixel in 1st lw (must be <32))
	; d1- BTH
	; d2- flw.l (offset to 1st dest lw)
	; d3- destmod.l (row modulos)
	; d4- 
	; d5- patx.w:patymask.w (patx - 1st pat pixel (0-15), patymask - ((2^patsize)-1)*2)
	; d6- 0:patyoff.w (initial pattern y offset)
	; d7- #rows-1.w:flags.b|#planes.b
	;
	; a3- *pattern (pointer to 2d array of word*2^patsize)
	; a4- *planes (pointer to array of *planes)
	; 
	;>
	;all reg's preserved
	;
	;flags-	FB_INVERSVID		(invert pattern)
	;
	

CopyPatternPlanes:
		movem.l		d0-d7/a0-a6,-(sp)
		swap		d5				;d5- patymask:patx
		sub.w		d0,d5
		and.w		#$0f,d5
		move.l		d5,a5				;a5- patymask:patlshift
		move.l		d2,a2				;a2- flw 
		move.l		d1,a1				;a1- BTH
CopyPPRowLoop:
		move.l		a5,d5				;d5- patymask:patlshift
		move.w		(d6.w,a3),d4			;d4- 0:pat(raw)
		addq.w		#$02,d6
		rol.w		d5,d4
		move.w		d4,d5				;d5- patymask:pat
		swap		d5
		and.w		d5,d6				;d6- 0:nextpatoffset
		move.w		d4,d5				;d5- pattern
		
		move.w		($1e,sp),d7			;d7- rows(cur):flags|planes
		btst		#FB_INVERSVID+8,d7
		beq.s		CopyPPRows0			;--> no inversvid
		
		not.l		d5
CopyPPRows0:
		and.w		#$ff,d7
		subq.w		#$01,d7				;d7- rows(cur):planes-1
CopyPPPlaneLoop:
		move.l		a2,a0				;a0- flw offset
		move.l		a1,d1				;d1- BTH
		add.l		(d7.w*4,a4),a0			;a0- *plane(flw)
CopyPPHead:		
		tst.b		d1
		beq.s		CopyPPBody
		
		bfextu		d5{d0:d1},d2
		bfins		d2,(a0){d0:d1}
		addq.l		#$04,a0
CopyPPBody:
		swap		d1
		subq.w		#$01,d1
		bmi.s		CopyPPTail
CopyPPBodyl1:
		move.l		d5,(a0)+
		dbra		d1,CopyPPBodyl1		
CopyPPTail:				
		rol.l		#$08,d1
		tst.b		d1
		beq.s		CopyPPPlaneLoopx
		
		bfextu		d5{0:d1},d2
		bfins		d2,(a0){0:d1}
CopyPPPlaneLoopx:
		dbra		d7,CopyPPPlaneLoop
CopyPPRowLoopx:
		add.l		($0c,sp),a2			;a2- next row flw offset
		sub.l		#$10000,d7
		bpl		CopyPPRowLoop
CopyPPx:
		movem.l		(sp)+,d0-d7/a0-a6
		rts
			


	;
	;CompPatternPlanes	(complement pattern 1's in all planes)
	;<d0- 0.w:destx.w (1st pixel in 1st lw (must be <32))
	; d1- BTH
	; d2- flw.l (offset to 1st dest lw)
	; d3- destmod.l (row modulos)
	; d4- 
	; d5- patx.w:patymask.w (patx - 1st pat pixel (0-15), patymask - ((2^patsize)-1)*2)
	; d6- 0:patyoff.w (initial pattern y offset)
	; d7- #rows-1.w:flags.b|#planes.b
	;
	; a3- *pattern (pointer to 2d array of word*2^patsize)
	; a4- *planes (pointer to array of *planes)
	; 
	;>
	;all reg's preserved
	;
	;flags-	FB_INVERSVID		(invert pattern)
	;

CompPatternPlanes:
		movem.l		d0-d7/a0-a6,-(sp)
		swap		d5				;d5- patymask:patx
		sub.w		d0,d5
		and.w		#$0f,d5
		move.l		d5,a5				;a5- patymask:patlshift
		move.l		d2,a2				;a2- flw 
		move.l		d1,a1				;a1- BTH
CompPPRowLoop:
		move.l		a5,d5				;d5- patymask:patlshift
		move.w		(d6.w,a3),d4			;d4- 0:pat(raw)
		addq.w		#$02,d6
		rol.w		d5,d4
		move.w		d4,d5				;d5- patymask:pat
		swap		d5
		and.w		d5,d6				;d6- 0:nextpatoffset
		move.w		d4,d5				;d5- pattern
		
		move.w		($1e,sp),d7			;d7- rows(cur):flags|planes
		btst		#FB_INVERSVID+8,d7
		beq.s		CompPPRows0			;--> no inversvid
		
		not.l		d5
CompPPRows0:
		and.w		#$ff,d7
		subq.w		#$01,d7				;d7- rows(cur):planes-1
CompPPPlaneLoop:
		move.l		a2,a0				;a0- flw offset
		move.l		a1,d1				;d1- BTH
		add.l		(d7.w*4,a4),a0			;a0- *plane(flw)
CompPPHead:		
		tst.b		d1
		beq.s		CompPPBody
		
		moveq		#$00,d2
		bfset		d2{d0:d1}
		and.l		d5,d2
		eor.l		d2,(a0)+
CompPPBody:
		swap		d1
		subq.w		#$01,d1
		bmi.s		CompPPTail
CompPPBodyl1:
		eor.l		d5,(a0)+
		dbra		d1,CompPPBodyl1		
CompPPTail:				
		rol.l		#$08,d1
		tst.b		d1
		beq.s		CompPPPlaneLoopx
		
		moveq		#$00,d2
		bfset		d2{0:d1}
		and.l		d5,d2
		eor.l		d2,(a0)
CompPPPlaneLoopx:
		dbra		d7,CompPPPlaneLoop
CompPPRowLoopx:
		add.l		($0c,sp),a2			;a2- next row flw offset
		sub.l		#$10000,d7
		bpl		CompPPRowLoop
CompPPx:
		movem.l		(sp)+,d0-d7/a0-a6
		rts
	

