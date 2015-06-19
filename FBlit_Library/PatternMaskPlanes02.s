

	;
	;FillPatternMaskPlanes	(set pattern 1's in all planes)
	;<d0- maskx.w:destx.w (1st pixel in 1st lw (must be <32))
	; d1- BTH
	; d2- flw.l (offset to 1st dest lw)
	; d3- destmod.l (row modulos)
	; d4- maskmod.l
	; d5- patx.w:patymask.w (patx - 1st pat pixel (0-15), patymask - ((2^patsize)-1)*2)
	; d6- 0:patyoff.w (initial pattern y offset)
	; d7- #rows-1.w:flags.b|#planes.b
	;
	; a3- *pattern (pointer to 2d array of word*2^patsize)
	; a4- *planes (pointer to array of *planes)
	; a5- *mask (pointer to 1st lw in 2d array)
	; 
	;>
	;all reg's preserved
	;
	;flags-	FB_INVERSVID		(invert pattern)
	;

FillPatternMaskPlanes:
		movem.l		d0-d7/a0-a6,-(sp)
		swap		d5				;d5- patymask:patx
		sub.w		d0,d5
		and.w		#$0f,d5
		ext.l		d0
		move.l		d5,a6				;a6- patymask:patlshift
		move.l		d2,a2				;a2- flw 
		move.l		d1,a1				;a1- BTH
FPMPRowLoop:
		move.l		a6,d5				;d5- patymask:patlshift
		move.w		(d6.w,a3),d4			;d4- 0:pat(raw)
		addq.w		#$02,d6
		rol.w		d5,d4
		move.w		d4,d5				;d5- patymask:pat
		swap		d5
		and.w		d5,d6				;d6- 0:nextpatoffset
		move.w		d4,d5				;d5- pattern
		
		move.w		($1e,sp),d7			;d7- rows(cur):flags|planes
		btst		#FB_INVERSVID+8,d7
		beq.s		FPMPRows0			;--> no inversvid
		
		not.l		d5
FPMPRows0:
		and.w		#$ff,d7
		subq.w		#$01,d7				;d7- rows(cur):planes-1
FPMPPlaneLoop:
		moveq		#$00,d3
		move.l		a2,a0				;a0- flw offset
		move.w		(sp),d3				;d3- destx
		move.l		a1,d1				;d1- BTH
		add.l		(d7.w*4,a4),a0			;a0- *plane(flw)
FPMPHead:		
		tst.b		d1
		beq.s		FPMPBody
		
		bfextu		(a5){d3:d1},d4
		moveq		#$00,d2
		bfins		d4,d2{d0:d1}
		and.l		d5,d2
		or.l		d2,(a0)+
		add.b		d1,d3
FPMPBody:
		swap		d1
		subq.w		#$01,d1
		bmi.s		FPMPTail
FPMPBodyl1:
		bfextu		(a5){d3:32},d2
		and.l		d5,d2
		or.l		d2,(a0)+
		add.l		#$20,d3
		dbra		d1,FPMPBodyl1		
FPMPTail:				
		rol.l		#$08,d1
		tst.b		d1
		beq.s		FPMPPlaneLoopx
		
		bfextu		(a5){d3:d1},d4
		moveq		#$00,d2
		bfins		d4,d2{0:d1}
		and.l		d5,d2
		or.l		d2,(a0)
FPMPPlaneLoopx:
		dbra		d7,FPMPPlaneLoop
FPMPRowLoopx:
		add.l		($0c,sp),a2			;a2- next dest row flw offset
		add.l		($10,sp),a5			;a5- next mask..
		sub.l		#$10000,d7
		bpl		FPMPRowLoop
FPMPx:
		movem.l		(sp)+,d0-d7/a0-a6
		rts
	
			
	;
	;ClearPatternMaskPlanes	(clear pattern 1's in all planes)
	;<d0- maskx.w:destx.w (1st pixel in 1st lw (must be <32))
	; d1- BTH
	; d2- flw.l (offset to 1st dest lw)
	; d3- destmod.l (row modulos)
	; d4- maskmod.l
	; d5- patx.w:patymask.w (patx - 1st pat pixel (0-15), patymask - ((2^patsize)-1)*2)
	; d6- 0:patyoff.w (initial pattern y offset)
	; d7- #rows-1.w:flags.b|#planes.b
	;
	; a3- *pattern (pointer to 2d array of word*2^patsize)
	; a4- *planes (pointer to array of *planes)
	; a5- *mask
	; 
	;>
	;all reg's preserved
	;
	;flags-	FB_INVERSVID		(invert pattern)
	;
	

ClearPatternMaskPlanes:
		movem.l		d0-d7/a0-a6,-(sp)
		swap		d5				;d5- patymask:patx
		sub.w		d0,d5
		and.w		#$0f,d5
		ext.l		d0
		move.l		d5,a6				;a6- patymask:patlshift
		move.l		d2,a2				;a2- flw 
		move.l		d1,a1				;a1- BTH
CPMPRowLoop:
		move.l		a6,d5				;d5- patymask:patlshift
		move.w		(d6.w,a3),d4			;d4- 0:pat(raw)
		addq.w		#$02,d6
		rol.w		d5,d4
		move.w		d4,d5				;d5- patymask:pat
		swap		d5
		and.w		d5,d6				;d6- 0:nextpatoffset
		move.w		d4,d5				;d5- pattern
		
		move.w		($1e,sp),d7			;d7- rows(cur):flags|planes
		btst		#FB_INVERSVID+8,d7
		bne.s		CPMPRows0			;--> inversvid(=don't invert for this case!)
		
		not.l		d5
CPMPRows0:
		and.w		#$ff,d7
		subq.w		#$01,d7				;d7- rows(cur):planes-1
CPMPPlaneLoop:
		moveq		#$00,d3
		move.l		a2,a0				;a0- flw offset
		move.w		(sp),d3
		move.l		a1,d1				;d1- BTH
		add.l		(d7.w*4,a4),a0			;a0- *plane(flw)
CPMPHead:		
		tst.b		d1
		beq.s		CPMPBody
		
		bfextu		(a5){d3:d1},d4
		moveq		#00,d2
		bfins		d4,d2{d0:d1}
		not.l		d2
		add.b		d1,d3
		or.l		d5,d2
		and.l		d2,(a0)+
CPMPBody:
		swap		d1
		subq.w		#$01,d1
		bmi.s		CPMPTail
CPMPBodyl1:
		bfextu		(a5){d3:32},d2
		not.l		d2
		or.l		d5,d2
		add.l		#$20,d3
		and.l		d2,(a0)+
		dbra		d1,CPMPBodyl1		
CPMPTail:				
		rol.l		#$08,d1
		tst.b		d1
		beq.s		CPMPPlaneLoopx
		
		bfextu		(a5){d3:d1},d4
		moveq		#00,d2
		bfins		d4,d2{0:d1}
		not.l		d2
		or.l		d5,d2
		and.l		d2,(a0)
CPMPPlaneLoopx:
		dbra		d7,CPMPPlaneLoop
CPMPRowLoopx:
		add.l		($0c,sp),a2			;a2- next row flw offset
		add.l		($10,sp),a5
		sub.l		#$10000,d7
		bpl		CPMPRowLoop
CPMPx:
		movem.l		(sp)+,d0-d7/a0-a6
		rts

			

	;
	;CopyPatternMaskPlanes	(copy pattern to planes)
	;<d0- maskx.w:destx.w (1st pixel in 1st lw (must be <32))
	; d1- BTH
	; d2- flw.l (offset to 1st dest lw)
	; d3- destmod.l (row modulos)
	; d4- maskmod.l
	; d5- patx.w:patymask.w (patx - 1st pat pixel (0-15), patymask - ((2^patsize)-1)*2)
	; d6- 0:patyoff.w (initial pattern y offset)
	; d7- #rows-1.w:flags.b|#planes.b
	;
	; a3- *pattern (pointer to 2d array of word*2^patsize)
	; a4- *planes (pointer to array of *planes)
	; a5- *mask
	; 
	;>
	;all reg's preserved
	;
	;flags-	FB_INVERSVID		(invert pattern)
	;
	

CopyPatternMaskPlanes:
		movem.l		d0-d7/a0-a6,-(sp)
		swap		d5				;d5- patymask:patx
		sub.w		d0,d5
		and.w		#$0f,d5
		ext.l		d0
		move.l		d5,a6				;a6- patymask:patlshift
		move.l		d2,a2				;a2- flw 
		move.l		d1,a1				;a1- BTH
CopyPMPRowLoop:
		move.l		a6,d5				;d5- patymask:patlshift
		move.w		(d6.w,a3),d4			;d4- 0:pat(raw)
		addq.w		#$02,d6
		rol.w		d5,d4
		move.w		d4,d5				;d5- patymask:pat
		swap		d5
		and.w		d5,d6				;d6- 0:nextpatoffset
		move.w		d4,d5				;d5- pattern
		
		move.w		($1e,sp),d7			;d7- rows(cur):flags|planes
		btst		#FB_INVERSVID+8,d7
		beq.s		CopyPMPRows0			;--> no inversvid
		
		not.l		d5
CopyPMPRows0:
		and.w		#$ff,d7
		subq.w		#$01,d7				;d7- rows(cur):planes-1
CopyPMPPlaneLoop:
		moveq		#$00,d3
		move.l		a2,a0				;a0- flw offset
		move.w		(sp),d3
		move.l		a1,d1				;d1- BTH
		add.l		(d7.w*4,a4),a0			;a0- *plane(flw)
CopyPMPHead:		
		tst.b		d1
		beq.s		CopyPMPBody
		
		moveq		#$00,d2
		bfextu		(a5){d3:d1},d4
		bfins		d4,d2{d0:d1}
		move.l		d2,d4
		and.l		d5,d4
		not.l		d2
		and.l		(a0),d2
		add.b		d1,d3
		or.l		d4,d2
		move.l		d2,(a0)+
CopyPMPBody:
		swap		d1
		subq.w		#$01,d1
		bmi.s		CopyPMPTail
CopyPMPBodyl1:
		bfextu		(a5){d3:32},d4
		move.l		d4,d2
		and.l		d5,d4
		not.l		d2
		and.l		(a0),d2
		add.l		#$20,d3
		or.l		d4,d2				
		move.l		d2,(a0)+
		dbra		d1,CopyPMPBodyl1		
CopyPMPTail:				
		rol.l		#$08,d1
		tst.b		d1
		beq.s		CopyPMPPlaneLoopx
		
		moveq		#$00,d2
		bfextu		(a5){d3:d1},d4
		bfins		d4,d2{0:d1}
		move.l		d2,d4
		and.l		d5,d4
		not.l		d2
		and.l		(a0),d2
		or.l		d4,d2
		move.l		d2,(a0)
CopyPMPPlaneLoopx:
		dbra		d7,CopyPMPPlaneLoop
CopyPMPRowLoopx:
		add.l		($0c,sp),a2			;a2- next row flw offset
		add.l		($10,sp),a5
		sub.l		#$10000,d7
		bpl		CopyPMPRowLoop
CopyPMPx:
		movem.l		(sp)+,d0-d7/a0-a6
		rts
			


	;
	;CompPatternMaskPlanes	(complement pattern 1's in all planes)
	;<d0- maskx.w:destx.w (1st pixel in 1st lw (must be <32))
	; d1- BTH
	; d2- flw.l (offset to 1st dest lw)
	; d3- destmod.l (row modulos)
	; d4- maskmod.l
	; d5- patx.w:patymask.w (patx - 1st pat pixel (0-15), patymask - ((2^patsize)-1)*2)
	; d6- 0:patyoff.w (initial pattern y offset)
	; d7- #rows-1.w:flags.b|#planes.b
	;
	; a3- *pattern (pointer to 2d array of word*2^patsize)
	; a4- *planes (pointer to array of *planes)
	; a5- *mask
	; 
	;>
	;all reg's preserved
	;
	;flags-	FB_INVERSVID		(invert pattern)
	;

CompPatternMaskPlanes:
		movem.l		d0-d7/a0-a6,-(sp)
		swap		d5				;d5- patymask:patx
		sub.w		d0,d5
		and.w		#$0f,d5
		ext.l		d0
		move.l		d5,a6				;a6- patymask:patlshift
		move.l		d2,a2				;a2- flw 
		move.l		d1,a1				;a1- BTH
CompPMPRowLoop:
		move.l		a6,d5				;d5- patymask:patlshift
		move.w		(d6.w,a3),d4			;d4- 0:pat(raw)
		addq.w		#$02,d6
		rol.w		d5,d4
		move.w		d4,d5				;d5- patymask:pat
		swap		d5
		and.w		d5,d6				;d6- 0:nextpatoffset
		move.w		d4,d5				;d5- pattern
		
		move.w		($1e,sp),d7			;d7- rows(cur):flags|planes
		btst		#FB_INVERSVID+8,d7
		beq.s		CompPMPRows0			;--> no inversvid
		
		not.l		d5
CompPMPRows0:
		and.w		#$ff,d7
		subq.w		#$01,d7				;d7- rows(cur):planes-1
CompPMPPlaneLoop:
		moveq		#$00,d3
		move.l		a2,a0				;a0- flw offset
		move.w		(sp),d3
		move.l		a1,d1				;d1- BTH
		add.l		(d7.w*4,a4),a0			;a0- *plane(flw)
CompPMPHead:		
		tst.b		d1
		beq.s		CompPMPBody
		
		bfextu		(a5){d3:d1},d4
		moveq		#$00,d2
		bfins		d4,d2{d0:d1}
		and.l		d5,d2
		eor.l		d2,(a0)+
		add.b		d1,d3
CompPMPBody:
		swap		d1
		subq.w		#$01,d1
		bmi.s		CompPMPTail
CompPMPBodyl1:
		bfextu		(a5){d3:32},d2
		and.l		d5,d2
		eor.l		d2,(a0)+
		add.l		#$20,d3
		dbra		d1,CompPMPBodyl1		
CompPMPTail:				
		rol.l		#$08,d1
		tst.b		d1
		beq.s		CompPMPPlaneLoopx
		
		bfextu		(a5){d3:d1},d4
		moveq		#$00,d2
		bfins		d4,d2{0:d1}
		and.l		d5,d2
		eor.l		d2,(a0)
CompPMPPlaneLoopx:
		dbra		d7,CompPMPPlaneLoop
CompPMPRowLoopx:
		add.l		($0c,sp),a2			;a2- next row flw offset
		add.l		($10,sp),a5
		sub.l		#$10000,d7
		bpl		CompPMPRowLoop
CompPMPx:
		movem.l		(sp)+,d0-d7/a0-a6
		rts
	

